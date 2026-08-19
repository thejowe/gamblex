class_name PokerTableState
extends RefCounted

const SEAT_COUNT := 6
const SMALL_BLIND := 5
const BIG_BLIND := 10
const STARTING_BALANCE := 500

enum BettingRound { PREFLOP, FLOP, TURN, RIVER, SHOWDOWN }

class Seat:
    var player_id: int = 0
    var ledger: ChipLedger
    var hole_cards: Array[Card] = []
    var current_bet: int = 0
    var folded: bool = false
    var has_acted: bool = false

var seats: Array = []
var deck: Deck
var _injected_deck: Deck
var community_cards: Array[Card] = []
var pot: int = 0
var current_bet: int = 0
var min_raise: int = BIG_BLIND
var active_seat_index: int = -1
var betting_round: int = BettingRound.PREFLOP
var hand_active: bool = false
var dealer_button_index: int = -1
var last_winner_seats: Array = []

func _init(p_deck: Deck = null) -> void:
    _injected_deck = p_deck
    for i in range(SEAT_COUNT):
        seats.append(null)

func sit(seat_index: int, player_id: int) -> bool:
    if seat_index < 0 or seat_index >= SEAT_COUNT:
        return false
    if seats[seat_index] != null:
        return false
    for s in seats:
        if s != null and s.player_id == player_id:
            return false
    var seat := Seat.new()
    seat.player_id = player_id
    seat.ledger = ChipLedger.new(STARTING_BALANCE)
    seats[seat_index] = seat
    return true

func _seat_for(seat_index: int, player_id: int):
    if seat_index < 0 or seat_index >= SEAT_COUNT:
        return null
    var seat = seats[seat_index]
    if seat == null or seat.player_id != player_id:
        return null
    return seat

func _seated_indices() -> Array:
    var result := []
    for i in range(SEAT_COUNT):
        if seats[i] != null:
            result.append(i)
    return result

func _next_seated_index(from: int) -> int:
    var idx := from
    for _i in range(SEAT_COUNT):
        idx = (idx + 1) % SEAT_COUNT
        if seats[idx] != null:
            return idx
    return -1

func _next_active_seat_index(from: int) -> int:
    var idx := from
    for _i in range(SEAT_COUNT):
        idx = (idx + 1) % SEAT_COUNT
        var seat = seats[idx]
        if seat != null and not seat.folded:
            return idx
    return -1

# Reparte una mano nueva: rota el boton, cobra ciegas y reparte 2 cartas
# tapadas a cada sentado. Simplificacion de alcance v1 (sin side pots): todos
# los sentados deben tener al menos la ciega grande, si no la mesa no reparte.
func start_hand() -> bool:
    if hand_active:
        return false
    var seated := _seated_indices()
    if seated.size() < 2:
        return false
    for i in seated:
        if seats[i].ledger.balance < BIG_BLIND:
            return false

    if _injected_deck != null:
        deck = _injected_deck
    else:
        deck = Deck.new()
        var rng := RandomNumberGenerator.new()
        rng.randomize()
        deck.shuffle_deck(rng)

    for i in range(SEAT_COUNT):
        var seat = seats[i]
        if seat == null:
            continue
        seat.hole_cards.clear()
        seat.current_bet = 0
        seat.folded = false
        seat.has_acted = false

    if dealer_button_index == -1 or seats[dealer_button_index] == null:
        dealer_button_index = seated[0]
    else:
        dealer_button_index = _next_seated_index(dealer_button_index)

    var sb_index: int
    var bb_index: int
    if seated.size() == 2:
        sb_index = dealer_button_index
        bb_index = _next_seated_index(dealer_button_index)
    else:
        sb_index = _next_seated_index(dealer_button_index)
        bb_index = _next_seated_index(sb_index)

    var sb_seat = seats[sb_index]
    var bb_seat = seats[bb_index]
    sb_seat.ledger.place_bet(SMALL_BLIND)
    sb_seat.current_bet = SMALL_BLIND
    bb_seat.ledger.place_bet(BIG_BLIND)
    bb_seat.current_bet = BIG_BLIND
    pot = SMALL_BLIND + BIG_BLIND
    current_bet = BIG_BLIND
    min_raise = BIG_BLIND

    for _round in range(2):
        for i in seated:
            seats[i].hole_cards.append(deck.draw_card())

    community_cards = []
    betting_round = BettingRound.PREFLOP
    last_winner_seats = []
    hand_active = true
    active_seat_index = _next_active_seat_index(bb_index)
    return true

func _validate_turn(seat_index: int, player_id: int):
    var seat = _seat_for(seat_index, player_id)
    if seat == null or not hand_active or active_seat_index != seat_index or seat.folded:
        return null
    return seat

func fold(seat_index: int, player_id: int) -> bool:
    var seat = _validate_turn(seat_index, player_id)
    if seat == null:
        return false
    seat.folded = true
    seat.has_acted = true
    _after_action()
    return true

func check(seat_index: int, player_id: int) -> bool:
    var seat = _validate_turn(seat_index, player_id)
    if seat == null or seat.current_bet != current_bet:
        return false
    seat.has_acted = true
    _after_action()
    return true

func call_bet(seat_index: int, player_id: int) -> bool:
    var seat = _validate_turn(seat_index, player_id)
    if seat == null:
        return false
    var amount_to_call: int = current_bet - seat.current_bet
    if amount_to_call <= 0:
        return false
    if not seat.ledger.place_bet(amount_to_call):
        return false
    seat.current_bet += amount_to_call
    pot += amount_to_call
    seat.has_acted = true
    _after_action()
    return true

func raise_bet(seat_index: int, player_id: int, raise_to: int) -> bool:
    var seat = _validate_turn(seat_index, player_id)
    if seat == null:
        return false
    var increment := raise_to - current_bet
    if increment < min_raise:
        return false
    var amount_needed: int = raise_to - seat.current_bet
    if not seat.ledger.place_bet(amount_needed):
        return false
    seat.current_bet = raise_to
    pot += amount_needed
    current_bet = raise_to
    min_raise = increment
    seat.has_acted = true
    for i in range(SEAT_COUNT):
        var other = seats[i]
        if other != null and other != seat and not other.folded:
            other.has_acted = false
    _after_action()
    return true

func _active_seat_count() -> int:
    var count := 0
    for seat in seats:
        if seat != null and not seat.folded:
            count += 1
    return count

func _is_betting_round_complete() -> bool:
    for seat in seats:
        if seat == null or seat.folded:
            continue
        if not seat.has_acted or seat.current_bet != current_bet:
            return false
    return true

func _after_action() -> void:
    if _active_seat_count() <= 1:
        _award_pot_uncontested()
        return
    if _is_betting_round_complete():
        _advance_betting_round()
    else:
        active_seat_index = _next_active_seat_index(active_seat_index)

func _advance_betting_round() -> void:
    for seat in seats:
        if seat != null:
            seat.current_bet = 0
            seat.has_acted = false
    current_bet = 0
    min_raise = BIG_BLIND
    match betting_round:
        BettingRound.PREFLOP:
            community_cards.append(deck.draw_card())
            community_cards.append(deck.draw_card())
            community_cards.append(deck.draw_card())
            betting_round = BettingRound.FLOP
        BettingRound.FLOP:
            community_cards.append(deck.draw_card())
            betting_round = BettingRound.TURN
        BettingRound.TURN:
            community_cards.append(deck.draw_card())
            betting_round = BettingRound.RIVER
        BettingRound.RIVER:
            betting_round = BettingRound.SHOWDOWN
            _resolve_showdown()
            return
    active_seat_index = _next_active_seat_index(dealer_button_index)

func _award_pot_uncontested() -> void:
    var winner_index := -1
    for i in range(SEAT_COUNT):
        var seat = seats[i]
        if seat != null and not seat.folded:
            winner_index = i
            break
    if winner_index != -1:
        seats[winner_index].ledger.payout(pot)
        last_winner_seats = [winner_index]
    pot = 0
    hand_active = false

func _resolve_showdown() -> void:
    var best_hand = null
    var winners: Array = []
    for i in range(SEAT_COUNT):
        var seat = seats[i]
        if seat == null or seat.folded:
            continue
        var seven: Array[Card] = seat.hole_cards + community_cards
        var hand = PokerHandEvaluator.best_hand(seven)
        if best_hand == null or PokerHandEvaluator.compare(hand, best_hand) > 0:
            best_hand = hand
            winners = [i]
        elif PokerHandEvaluator.compare(hand, best_hand) == 0:
            winners.append(i)
    _split_pot(winners)
    last_winner_seats = winners
    hand_active = false

func _split_pot(winners: Array) -> void:
    var share := pot / winners.size()
    var remainder := pot % winners.size()
    for idx in range(winners.size()):
        var amount := share
        if idx == 0:
            amount += remainder
        seats[winners[idx]].ledger.payout(amount)
    pot = 0

func to_dict(viewer_player_id: int) -> Dictionary:
    var seats_data := []
    for seat in seats:
        if seat == null:
            seats_data.append(null)
            continue
        var reveal: bool = seat.player_id == viewer_player_id or (betting_round == BettingRound.SHOWDOWN and not seat.folded)
        var hole_data := []
        if reveal:
            for card in seat.hole_cards:
                hole_data.append({"rank": card.rank, "suit": card.suit})
        seats_data.append({
            "player_id": seat.player_id,
            "balance": seat.ledger.balance,
            "current_bet": seat.current_bet,
            "folded": seat.folded,
            "hole_cards": hole_data,
        })
    var community_data := []
    for card in community_cards:
        community_data.append({"rank": card.rank, "suit": card.suit})
    return {
        "seats": seats_data,
        "community_cards": community_data,
        "pot": pot,
        "current_bet": current_bet,
        "active_seat_index": active_seat_index,
        "betting_round": betting_round,
        "hand_active": hand_active,
        "dealer_button_index": dealer_button_index,
        "last_winner_seats": last_winner_seats,
    }

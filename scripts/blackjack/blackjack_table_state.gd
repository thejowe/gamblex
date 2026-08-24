class_name BlackjackTableState
extends RefCounted

signal chips_won(player_id: int, amount: int)

const SEAT_COUNT := 4

class Seat:
    var player_id: int = 0
    var ledger: ChipLedger
    var hand: Hand
    var current_bet: int = 0
    var has_acted: bool = false

var seats: Array = []
var dealer_hand: Hand
var deck: Deck
var active_seat_index: int = -1
var round_active: bool = false

func _init(p_deck: Deck = null) -> void:
    if p_deck:
        deck = p_deck
    else:
        deck = Deck.new()
        var rng := RandomNumberGenerator.new()
        rng.randomize()
        deck.shuffle_deck(rng)
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
    seat.ledger = ChipLedger.new(500)
    seats[seat_index] = seat
    return true

func place_bet(seat_index: int, player_id: int, amount: int) -> bool:
    var seat = _seat_for(seat_index, player_id)
    if seat == null or round_active:
        return false
    if not seat.ledger.place_bet(amount):
        return false
    seat.current_bet = amount
    if _all_seated_players_have_bet():
        _start_round()
    return true

func _seat_for(seat_index: int, player_id: int):
    if seat_index < 0 or seat_index >= SEAT_COUNT:
        return null
    var seat = seats[seat_index]
    if seat == null or seat.player_id != player_id:
        return null
    return seat

func _all_seated_players_have_bet() -> bool:
    var any_seated := false
    for seat in seats:
        if seat == null:
            continue
        any_seated = true
        if seat.current_bet == 0:
            return false
    return any_seated

func _start_round() -> void:
    round_active = true
    dealer_hand = Hand.new()
    for seat in seats:
        if seat == null:
            continue
        seat.hand = Hand.new()
        seat.has_acted = false
    for seat in seats:
        if seat == null:
            continue
        seat.hand.add_card(deck.draw_card())
    dealer_hand.add_card(deck.draw_card())
    for seat in seats:
        if seat == null:
            continue
        seat.hand.add_card(deck.draw_card())
    dealer_hand.add_card(deck.draw_card())
    active_seat_index = _first_seated_index()
    if active_seat_index == -1:
        round_active = false

func _first_seated_index() -> int:
    for i in range(SEAT_COUNT):
        if seats[i] != null:
            return i
    return -1

func hit(seat_index: int, player_id: int) -> bool:
    var seat = _seat_for(seat_index, player_id)
    if seat == null or not round_active or active_seat_index != seat_index:
        return false
    seat.hand.add_card(deck.draw_card())
    if seat.hand.is_bust():
        seat.has_acted = true
        _advance_turn()
    return true

func stand(seat_index: int, player_id: int) -> bool:
    var seat = _seat_for(seat_index, player_id)
    if seat == null or not round_active or active_seat_index != seat_index:
        return false
    seat.has_acted = true
    _advance_turn()
    return true

func _advance_turn() -> void:
    var next := active_seat_index + 1
    while next < SEAT_COUNT and seats[next] == null:
        next += 1
    if next < SEAT_COUNT:
        active_seat_index = next
    else:
        active_seat_index = -1
        _resolve_round()

func _resolve_round() -> void:
    var any_seat_not_bust := false
    for seat in seats:
        if seat != null and not seat.hand.is_bust():
            any_seat_not_bust = true
            break
    if any_seat_not_bust:
        while dealer_hand.value() < 17:
            dealer_hand.add_card(deck.draw_card())
    for seat in seats:
        if seat == null:
            continue
        _resolve_seat_payout(seat)
        seat.current_bet = 0
    round_active = false

func _resolve_seat_payout(seat) -> void:
    if seat.hand.is_bust():
        return
    if dealer_hand.is_bust():
        seat.ledger.payout(seat.current_bet * 2)
        chips_won.emit(seat.player_id, seat.current_bet)
        return
    if seat.hand.value() > dealer_hand.value():
        seat.ledger.payout(seat.current_bet * 2)
        chips_won.emit(seat.player_id, seat.current_bet)
    elif seat.hand.value() == dealer_hand.value():
        seat.ledger.payout(seat.current_bet)

func to_dict() -> Dictionary:
    var seats_data := []
    for seat in seats:
        if seat == null:
            seats_data.append(null)
        else:
            seats_data.append({
                "player_id": seat.player_id,
                "balance": seat.ledger.balance,
                "bet": seat.current_bet,
                "hand_value": seat.hand.value() if seat.hand else 0,
                "hand": _cards_to_dicts(seat.hand.cards) if seat.hand else [],
            })
    return {
        "seats": seats_data,
        "dealer_value": dealer_hand.value() if dealer_hand else 0,
        "dealer_hand": _dealer_hand_to_dicts(),
        "active_seat_index": active_seat_index,
        "round_active": round_active,
    }

func _cards_to_dicts(cards: Array) -> Array:
    var result := []
    for card in cards:
        result.append({"rank": card.rank, "suit": card.suit})
    return result

func _dealer_hand_to_dicts() -> Array:
    if dealer_hand == null:
        return []
    var cards := dealer_hand.cards
    var result := []
    for i in range(cards.size()):
        if i == 1 and round_active:
            result.append({"hidden": true})
        else:
            result.append({"rank": cards[i].rank, "suit": cards[i].suit})
    return result

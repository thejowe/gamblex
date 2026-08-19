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

class_name BlackjackTableState
extends RefCounted

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
    deck = p_deck if p_deck else Deck.new()
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

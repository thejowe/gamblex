class_name RouletteTableState
extends RefCounted

const SEAT_COUNT := 4
const NUMBER_COUNT := 37 # 0-36

enum BetType { STRAIGHT, RED, BLACK, EVEN, ODD, DOZEN_1, DOZEN_2, DOZEN_3 }

class Bet:
    var type: int
    var number: int
    var amount: int

class Seat:
    var player_id: int = 0
    var ledger: ChipLedger
    var bets: Array = []

var seats: Array = []
var wheel: RouletteWheel
var last_result: int = -1

func _init(p_wheel: RouletteWheel = null) -> void:
    wheel = p_wheel if p_wheel else RouletteWheel.new()
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

func place_bet(seat_index: int, player_id: int, bet_type: int, number: int, amount: int) -> bool:
    var seat = _seat_for(seat_index, player_id)
    if seat == null:
        return false
    if not _is_valid_bet_type(bet_type):
        return false
    if bet_type == BetType.STRAIGHT and (number < 0 or number >= NUMBER_COUNT):
        return false
    if not seat.ledger.place_bet(amount):
        return false
    var bet := Bet.new()
    bet.type = bet_type
    bet.number = number if bet_type == BetType.STRAIGHT else -1
    bet.amount = amount
    seat.bets.append(bet)
    return true

func _is_valid_bet_type(bet_type: int) -> bool:
    return bet_type >= BetType.STRAIGHT and bet_type <= BetType.DOZEN_3

func _seat_for(seat_index: int, player_id: int):
    if seat_index < 0 or seat_index >= SEAT_COUNT:
        return null
    var seat = seats[seat_index]
    if seat == null or seat.player_id != player_id:
        return null
    return seat

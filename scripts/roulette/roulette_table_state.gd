class_name RouletteTableState
extends RefCounted

const SEAT_COUNT := 4
const NUMBER_COUNT := 37 # 0-36
const RED_NUMBERS: Array[int] = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]

# Ronda compartida por temporizador: todos los sentados apuestan libremente
# mientras phase == BETTING; al agotarse el tiempo la mesa gira sola y
# resuelve las apuestas de todos a la vez (no hace falta que nadie pulse
# "girar" ni que se turnen). RESULT_DURATION_SEC deja tiempo para que la
# animación de la bola (2s en roulette_wheel_display.gd) termine y el
# resultado se vea antes de que abra la siguiente ronda.
const ROUND_DURATION_SEC := 20.0
const RESULT_DURATION_SEC := 5.0

enum Phase { BETTING, RESULT }
enum BetType { STRAIGHT, RED, BLACK, EVEN, ODD, DOZEN_1, DOZEN_2, DOZEN_3, COLUMN_1, COLUMN_2, COLUMN_3, LOW, HIGH }

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
var phase: int = Phase.BETTING
var phase_time_remaining: float = ROUND_DURATION_SEC

func _init(p_wheel: RouletteWheel = null) -> void:
	wheel = p_wheel if p_wheel else RouletteWheel.new()
	for i in range(SEAT_COUNT):
		seats.append(null)

func sit(seat_index: int, player_id: int, external_ledger: ChipLedger = null) -> bool:
	if seat_index < 0 or seat_index >= SEAT_COUNT:
		return false
	if seats[seat_index] != null:
		return false
	for s in seats:
		if s != null and s.player_id == player_id:
			return false
	var seat := Seat.new()
	seat.player_id = player_id
	seat.ledger = external_ledger if external_ledger != null else ChipLedger.new(500)
	seats[seat_index] = seat
	return true

func place_bet(seat_index: int, player_id: int, bet_type: int, number: int, amount: int) -> bool:
	if phase != Phase.BETTING:
		return false
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
	return bet_type >= BetType.STRAIGHT and bet_type <= BetType.HIGH

func _seat_for(seat_index: int, player_id: int):
	if seat_index < 0 or seat_index >= SEAT_COUNT:
		return null
	var seat = seats[seat_index]
	if seat == null or seat.player_id != player_id:
		return null
	return seat

# Llamar cada frame desde el host (RouletteTableController._process). Solo
# hace algo (y solo entonces devuelve true, para que el controller sepa
# cuándo retransmitir) cuando el temporizador de la fase actual llega a
# cero: BETTING -> gira y resuelve -> RESULT -> reabre una ronda nueva.
func advance_time(delta: float) -> bool:
	phase_time_remaining -= delta
	if phase_time_remaining > 0.0:
		return false
	match phase:
		Phase.BETTING:
			_resolve_round()
			phase = Phase.RESULT
			phase_time_remaining = RESULT_DURATION_SEC
		Phase.RESULT:
			phase = Phase.BETTING
			phase_time_remaining = ROUND_DURATION_SEC
	return true

func _resolve_round() -> void:
	var result := wheel.spin()
	last_result = result
	for s in seats:
		if s == null:
			continue
		for bet in s.bets:
			_resolve_bet(s, bet, result)
		s.bets.clear()

func _resolve_bet(seat, bet, result: int) -> void:
	if _bet_wins(bet, result):
		seat.ledger.payout(bet.amount * (_payout_multiplier(bet.type) + 1))
	seat.ledger.resolve_bet(bet.amount)

func _bet_wins(bet, result: int) -> bool:
	match bet.type:
		BetType.STRAIGHT:
			return bet.number == result
		BetType.RED:
			return result != 0 and result in RED_NUMBERS
		BetType.BLACK:
			return result != 0 and not (result in RED_NUMBERS)
		BetType.EVEN:
			return result != 0 and result % 2 == 0
		BetType.ODD:
			return result != 0 and result % 2 == 1
		BetType.DOZEN_1:
			return result >= 1 and result <= 12
		BetType.DOZEN_2:
			return result >= 13 and result <= 24
		BetType.DOZEN_3:
			return result >= 25 and result <= 36
		BetType.COLUMN_1:
			return result != 0 and result % 3 == 1
		BetType.COLUMN_2:
			return result != 0 and result % 3 == 2
		BetType.COLUMN_3:
			return result != 0 and result % 3 == 0
		BetType.LOW:
			return result >= 1 and result <= 18
		BetType.HIGH:
			return result >= 19 and result <= 36
	return false

func _payout_multiplier(bet_type: int) -> int:
	match bet_type:
		BetType.STRAIGHT:
			return 35
		BetType.RED, BetType.BLACK, BetType.EVEN, BetType.ODD, BetType.LOW, BetType.HIGH:
			return 1
		BetType.DOZEN_1, BetType.DOZEN_2, BetType.DOZEN_3, BetType.COLUMN_1, BetType.COLUMN_2, BetType.COLUMN_3:
			return 2
	return 0

func to_dict() -> Dictionary:
	var seats_data := []
	for seat in seats:
		if seat == null:
			seats_data.append(null)
		else:
			var bets_data := []
			for bet in seat.bets:
				bets_data.append({"type": bet.type, "number": bet.number, "amount": bet.amount})
			seats_data.append({
				"player_id": seat.player_id,
				"balance": seat.ledger.balance,
				"bets": bets_data,
			})
	return {
		"seats": seats_data,
		"last_result": last_result,
		"phase": phase,
		"phase_time_remaining": maxf(phase_time_remaining, 0.0),
	}

class_name CrashTableState
extends RefCounted

signal chips_won(player_id: int, amount: int)

const STARTING_BALANCE := 500
# multiplicador(t) = 1 + GROWTH_RATE * t^2. En t=7.07s (mediana del punto de
# explosión, r=0.5 -> 1.98x) el multiplicador llega a ~2.00x, en medio del
# rango de 3-15s pedido por la spec para una ronda "típica". Ver plan
# docs/superpowers/plans/2026-08-20-crash.md para el resto de la cuenta.
const GROWTH_RATE := 0.02

class Player:
	var player_id: int = 0
	var ledger: ChipLedger
	var bet_amount: int = 0
	var crash_point: float = 0.0
	var elapsed: float = 0.0
	var is_active: bool = false
	var last_round: Dictionary = {}

var players: Dictionary = {}
var roller: CrashRoller

func _init(p_roller: CrashRoller = null) -> void:
	roller = p_roller if p_roller else CrashRoller.new()

static func multiplier_at(t: float) -> float:
	return 1.0 + GROWTH_RATE * t * t

func _player_for(player_id: int) -> Player:
	if not players.has(player_id):
		var player := Player.new()
		player.player_id = player_id
		player.ledger = ChipLedger.new(STARTING_BALANCE)
		players[player_id] = player
	return players[player_id]

func place_bet(player_id: int, amount: int) -> bool:
	var player := _player_for(player_id)
	if player.is_active:
		return false
	if not player.ledger.place_bet(amount):
		return false
	player.bet_amount = amount
	player.crash_point = roller.roll()
	player.elapsed = 0.0
	player.is_active = true
	return true

func cash_out(player_id: int) -> bool:
	if not players.has(player_id):
		return false
	var player: Player = players[player_id]
	if not player.is_active:
		return false
	var current := multiplier_at(player.elapsed)
	if current >= player.crash_point:
		return false
	var payout := int(player.bet_amount * current)
	player.ledger.payout(payout)
	chips_won.emit(player_id, payout - player.bet_amount)
	player.last_round = {
		"bet_amount": player.bet_amount,
		"crash_point": player.crash_point,
		"cashed_out_at": current,
		"win": true,
		"payout": payout,
	}
	player.is_active = false
	return true

# Llamar cada frame desde el host (CrashTableController._process). Devuelve
# los player_id cuya ronda acaba de explotar en esta llamada, para que el
# controller sepa cuándo retransmitir el estado sin tener que hacerlo cada
# frame para todo el mundo.
func advance_time(delta: float) -> Array:
	var crashed: Array = []
	for player_id in players:
		var player: Player = players[player_id]
		if not player.is_active:
			continue
		player.elapsed += delta
		if multiplier_at(player.elapsed) >= player.crash_point:
			player.last_round = {
				"bet_amount": player.bet_amount,
				"crash_point": player.crash_point,
				"cashed_out_at": -1.0,
				"win": false,
				"payout": 0,
			}
			player.is_active = false
			crashed.append(player_id)
	return crashed

func to_dict() -> Dictionary:
	var players_data := {}
	for player_id in players:
		var player: Player = players[player_id]
		players_data[player_id] = {
			"player_id": player.player_id,
			"balance": player.ledger.balance,
			"is_active": player.is_active,
			"elapsed": player.elapsed,
			"last_round": player.last_round,
		}
	return {"players": players_data}

class_name PlinkoTableState
extends RefCounted

signal chips_won(player_id: int, amount: int)

const STARTING_BALANCE := 500
const MIN_ROWS := 8
const MAX_ROWS := 16
const DEFAULT_ROWS := 12

class Player:
	var player_id: int = 0
	var ledger: ChipLedger
	var last_round: Dictionary = {}

var players: Dictionary = {}
var roller: PlinkoRoller

func _init(p_roller: PlinkoRoller = null) -> void:
	roller = p_roller if p_roller else PlinkoRoller.new()

static func _comb(n: int, k: int) -> int:
	if k < 0 or k > n:
		return 0
	k = min(k, n - k)
	var result := 1
	for i in range(k):
		result = result * (n - i) / (i + 1)
	return result

static func slot_multiplier(rows: int, slot: int) -> float:
	var c: float = 0.99 * pow(2.0, rows) / (rows + 1)
	return c / _comb(rows, slot)

func _player_for(player_id: int) -> Player:
	if not players.has(player_id):
		var player := Player.new()
		player.player_id = player_id
		player.ledger = ChipLedger.new(STARTING_BALANCE)
		players[player_id] = player
	return players[player_id]

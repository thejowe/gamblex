class_name MinesTableState
extends RefCounted

signal chips_won(player_id: int, amount: int)

const STARTING_BALANCE := 500

class Player:
	var player_id: int = 0
	var ledger: ChipLedger
	var last_round: Dictionary = {}
	var active_round: Dictionary = {}

var players: Dictionary = {}
var roller: MinesRoller

func _init(p_roller: MinesRoller = null) -> void:
	roller = p_roller if p_roller else MinesRoller.new()

static func multiplier(total_cells: int, mine_count: int, revealed_count: int) -> float:
	var result := 1.0
	for i in range(revealed_count):
		result *= float(total_cells - i) / float(total_cells - mine_count - i)
	return 0.99 * result

func _player_for(player_id: int) -> Player:
	if not players.has(player_id):
		var player := Player.new()
		player.player_id = player_id
		player.ledger = ChipLedger.new(STARTING_BALANCE)
		players[player_id] = player
	return players[player_id]

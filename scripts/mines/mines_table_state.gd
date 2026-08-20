class_name MinesTableState
extends RefCounted

signal chips_won(player_id: int, amount: int)

const STARTING_BALANCE := 500
const MAX_CELLS := 100

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

func start_round(player_id: int, total_cells: int, mine_count: int, amount: int) -> bool:
	if total_cells < 2 or total_cells > MAX_CELLS:
		return false
	if mine_count < 1 or mine_count >= total_cells:
		return false
	var player := _player_for(player_id)
	if not player.active_round.is_empty():
		return false
	if not player.ledger.place_bet(amount):
		return false
	player.active_round = {
		"total_cells": total_cells,
		"mine_count": mine_count,
		"mines": roller.roll(total_cells, mine_count),
		"revealed": [],
		"amount": amount,
		"multiplier": 1.0,
	}
	return true

func reveal(player_id: int, index: int) -> bool:
	if not players.has(player_id):
		return false
	var player: Player = players[player_id]
	if player.active_round.is_empty():
		return false
	var round_data: Dictionary = player.active_round
	if index < 0 or index >= round_data["total_cells"]:
		return false
	if round_data["revealed"].has(index):
		return false
	if round_data["mines"].has(index):
		_end_round(player, round_data, false, 0)
		return true
	round_data["revealed"].append(index)
	round_data["multiplier"] = multiplier(round_data["total_cells"], round_data["mine_count"], round_data["revealed"].size())
	var safe_cells: int = round_data["total_cells"] - round_data["mine_count"]
	if round_data["revealed"].size() == safe_cells:
		var payout := int(round_data["amount"] * round_data["multiplier"])
		player.ledger.payout(payout)
		var amount: int = round_data["amount"]
		_end_round(player, round_data, true, payout)
		chips_won.emit(player_id, payout - amount)
	return true

func cash_out(player_id: int) -> bool:
	if not players.has(player_id):
		return false
	var player: Player = players[player_id]
	if player.active_round.is_empty():
		return false
	var round_data: Dictionary = player.active_round
	if round_data["revealed"].is_empty():
		return false
	var payout := int(round_data["amount"] * round_data["multiplier"])
	player.ledger.payout(payout)
	var amount: int = round_data["amount"]
	_end_round(player, round_data, true, payout)
	chips_won.emit(player_id, payout - amount)
	return true

func _end_round(player: Player, round_data: Dictionary, win: bool, payout: int) -> void:
	player.last_round = {
		"total_cells": round_data["total_cells"],
		"mine_count": round_data["mine_count"],
		"mines": round_data["mines"],
		"revealed": round_data["revealed"],
		"amount": round_data["amount"],
		"win": win,
		"payout": payout,
	}
	player.active_round = {}

func to_dict() -> Dictionary:
	var players_data := {}
	for player_id in players:
		var player: Player = players[player_id]
		var public_active := {}
		if not player.active_round.is_empty():
			public_active = player.active_round.duplicate()
			public_active.erase("mines")
		players_data[player_id] = {
			"player_id": player.player_id,
			"balance": player.ledger.balance,
			"active_round": public_active,
			"last_round": player.last_round,
		}
	return {"players": players_data}

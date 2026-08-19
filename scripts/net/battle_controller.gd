class_name BattleController
extends Node

signal teams_changed(teams: Array)
signal match_state_changed(state: Dictionary)

var assignment: TeamAssignment
var pools: Array = []
var rules: MatchRules

# Igual que TableController (Plan 3): el host no puede rpc_id(1, ...) sobre sí
# mismo con call_remote, así que join() aplica directo en el host en vez de
# auto-llamarse por RPC. start_match y apply_bet/apply_payout solo los llama
# el host de todas formas (son la autoridad del partido), sin pasar por RPC.
func start_match(match_type: int, goal_balance: int, time_limit_sec: float, starting_balance: int) -> void:
	if not multiplayer.is_server():
		return
	assignment = TeamAssignment.new(match_type)
	pools = [TeamChipPool.new(0, starting_balance), TeamChipPool.new(1, starting_balance)]
	rules = MatchRules.new(pools, goal_balance, time_limit_sec)
	rules.match_finished.connect(func(_team, _reason): _broadcast_match_state())

func join(player_id: int) -> void:
	if multiplayer.is_server():
		_apply_join(player_id)
	else:
		request_join.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func request_join() -> void:
	if not multiplayer.is_server():
		return
	_apply_join(multiplayer.get_remote_sender_id())

func _apply_join(player_id: int) -> void:
	assignment.join(player_id)
	_broadcast_teams()

func apply_bet(team_id: int, amount: int) -> bool:
	if not multiplayer.is_server():
		return false
	var ok: bool = pools[team_id].place_bet(amount)
	if ok:
		rules.on_balance_changed()
		_broadcast_match_state()
	return ok

func apply_payout(team_id: int, amount: int) -> void:
	if not multiplayer.is_server():
		return
	pools[team_id].payout(amount)
	rules.on_balance_changed()
	_broadcast_match_state()

func _process(delta: float) -> void:
	if multiplayer.is_server() and rules != null and not rules.finished:
		if rules.advance_time(delta):
			_broadcast_match_state()

func _broadcast_teams() -> void:
	_receive_teams.rpc(assignment.teams)

@rpc("authority", "call_local", "reliable")
func _receive_teams(teams: Array) -> void:
	teams_changed.emit(teams)

func _broadcast_match_state() -> void:
	_receive_match_state.rpc(_state_dict())

func _state_dict() -> Dictionary:
	return {
		"pool_balances": [pools[0].balance(), pools[1].balance()],
		"finished": rules.finished,
		"winning_team": rules.winning_team,
		"reason": rules.reason,
	}

@rpc("authority", "call_local", "reliable")
func _receive_match_state(state: Dictionary) -> void:
	match_state_changed.emit(state)

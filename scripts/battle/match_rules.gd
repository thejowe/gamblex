class_name MatchRules
extends RefCounted

signal match_finished(winning_team: int, reason: String)

var pools: Array
var goal_balance: int
var time_limit_sec: float
var elapsed_sec: float = 0.0
var finished: bool = false
var winning_team: int = -1
var reason: String = ""

func _init(p_pools: Array, p_goal_balance: int, p_time_limit_sec: float) -> void:
	pools = p_pools
	goal_balance = p_goal_balance
	time_limit_sec = p_time_limit_sec

# Llamar tras cualquier apuesta o pago que cambie el saldo de un pozo.
# Revisa bancarrota primero: la spec exige que decida "de inmediato, sin
# esperar a las otras condiciones", así que tiene prioridad incluso si el
# mismo cambio de saldo hace que otro equipo llegue a la meta a la vez.
func on_balance_changed() -> bool:
	if finished:
		return false
	if _check_bankruptcy():
		return true
	return _check_goal()

func advance_time(delta: float) -> bool:
	if finished:
		return false
	elapsed_sec += delta
	if elapsed_sec < time_limit_sec:
		return false
	_finish_by_timeout()
	return true

func _check_bankruptcy() -> bool:
	for pool in pools:
		if pool.is_bankrupt():
			_finish(1 - pool.team_id, "bankruptcy")
			return true
	return false

func _check_goal() -> bool:
	for pool in pools:
		if pool.balance() >= goal_balance:
			_finish(pool.team_id, "goal_reached")
			return true
	return false

func _finish_by_timeout() -> void:
	if pools[0].balance() > pools[1].balance():
		_finish(pools[0].team_id, "timeout_highest_balance")
	elif pools[1].balance() > pools[0].balance():
		_finish(pools[1].team_id, "timeout_highest_balance")
	else:
		_finish(-1, "timeout_draw")

func _finish(team: int, p_reason: String) -> void:
	finished = true
	winning_team = team
	reason = p_reason
	match_finished.emit(team, p_reason)

extends Node2D

const GOAL_TARGET := 1000
const BATTLE_GOAL_BALANCE := 2000
const BATTLE_TIME_LIMIT_SEC := 600.0
const BATTLE_STARTING_BALANCE := 500

@onready var goal_label: Label = $GoalLabel
@onready var unlocked_banner: Label = $UnlockedBanner
@onready var battle_controller: BattleController = $BattleController
@onready var battle_status_label: Label = $BattleStatusLabel

var goal: CollectiveGoal
var _is_battle_mode: bool
var _teams_line: String = ""
var _state_line: String = ""

func _ready() -> void:
	_is_battle_mode = SteamManager.chosen_match_type != -1
	goal_label.visible = not _is_battle_mode
	unlocked_banner.visible = false
	battle_status_label.visible = _is_battle_mode
	if _is_battle_mode:
		battle_controller.teams_changed.connect(_on_teams_changed)
		battle_controller.match_state_changed.connect(_on_match_state_changed)
	if multiplayer.is_server():
		if _is_battle_mode:
			battle_controller.start_match(SteamManager.chosen_match_type, BATTLE_GOAL_BALANCE, BATTLE_TIME_LIMIT_SEC, BATTLE_STARTING_BALANCE)
			battle_controller.join(multiplayer.get_unique_id())
		else:
			goal = CollectiveGoal.new(GOAL_TARGET)
			for controller in find_children("*", "TableController", true, false):
				controller.chips_won.connect(_on_chips_won)
			for controller in find_children("*", "DiceTableController", true, false):
				controller.chips_won.connect(_on_chips_won)
			for controller in find_children("*", "MinesTableController", true, false):
				controller.chips_won.connect(_on_chips_won)
			_broadcast_goal_state()
	else:
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			multiplayer.connected_to_server.connect(_on_connected_to_server)
		else:
			_on_connected_to_server()

func _on_connected_to_server() -> void:
	if _is_battle_mode:
		battle_controller.join(multiplayer.get_unique_id())
		battle_controller.request_state()
	else:
		request_goal_state()

# ---- modo libre: meta colectiva ----

func _on_chips_won(_player_id: int, amount: int) -> void:
	goal.add_chips(amount)
	_broadcast_goal_state()

# Un cliente que entra a CasinoFloor después de que ya hubo ganancias no
# recibe nada por su cuenta: el host solo retransmite _receive_goal_state
# cuando el contador cambia, nunca al conectar (mismo gotcha que
# TableController.request_state en Plan 3). Sin este pedido explícito el
# cliente se queda con el contador en 0 para siempre.
func request_goal_state() -> void:
	if multiplayer.is_server():
		return
	_request_goal_state.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_goal_state() -> void:
	if not multiplayer.is_server():
		return
	_receive_goal_state.rpc_id(multiplayer.get_remote_sender_id(), goal.to_dict())

func _broadcast_goal_state() -> void:
	_receive_goal_state.rpc(goal.to_dict())

@rpc("authority", "call_local", "reliable")
func _receive_goal_state(state: Dictionary) -> void:
	goal_label.text = "Meta colectiva: %d / %d fichas" % [state["total"], state["target"]]
	unlocked_banner.visible = state["unlocked"]

# ---- modo batalla ----

func _on_teams_changed(teams: Array) -> void:
	_teams_line = "Equipo A: %s | Equipo B: %s" % [str(teams[0]), str(teams[1])]
	_refresh_battle_label()

func _on_match_state_changed(state: Dictionary) -> void:
	var msg := "Pozo A: %d | Pozo B: %d" % [state["pool_balances"][0], state["pool_balances"][1]]
	if state["finished"]:
		msg += " — FIN (equipo %d, %s)" % [state["winning_team"], state["reason"]]
	_state_line = msg
	_refresh_battle_label()

func _refresh_battle_label() -> void:
	battle_status_label.text = _teams_line + "\n" + _state_line

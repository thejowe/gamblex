extends Node2D

const GOAL_BALANCE := 2000
const TIME_LIMIT_SEC := 600.0
const STARTING_BALANCE := 500

@onready var battle_controller: BattleController = $BattleController
@onready var battle_status_label: Label = $BattleStatusLabel

func _ready() -> void:
	battle_controller.teams_changed.connect(_on_teams_changed)
	battle_controller.match_state_changed.connect(_on_match_state_changed)
	if multiplayer.is_server():
		battle_controller.start_match(SteamManager.chosen_match_type, GOAL_BALANCE, TIME_LIMIT_SEC, STARTING_BALANCE)
	battle_controller.join(multiplayer.get_unique_id())

func _on_teams_changed(teams: Array) -> void:
	battle_status_label.text = "Equipo A: %s | Equipo B: %s" % [str(teams[0]), str(teams[1])]

func _on_match_state_changed(state: Dictionary) -> void:
	var msg := "Pozo A: %d | Pozo B: %d" % [state["pool_balances"][0], state["pool_balances"][1]]
	if state["finished"]:
		msg += " — FIN (equipo %d, %s)" % [state["winning_team"], state["reason"]]
	battle_status_label.text = msg

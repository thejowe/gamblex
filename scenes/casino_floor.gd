extends Node2D

const GOAL_BALANCE := 2000
const TIME_LIMIT_SEC := 600.0
const STARTING_BALANCE := 500

@onready var battle_controller: BattleController = $BattleController
@onready var battle_status_label: Label = $BattleStatusLabel

var _teams_line: String = ""
var _state_line: String = ""

func _ready() -> void:
	battle_controller.teams_changed.connect(_on_teams_changed)
	battle_controller.match_state_changed.connect(_on_match_state_changed)
	if multiplayer.is_server():
		battle_controller.start_match(SteamManager.chosen_match_type, GOAL_BALANCE, TIME_LIMIT_SEC, STARTING_BALANCE)
		battle_controller.join(multiplayer.get_unique_id())
	else:
		# Un cliente puede llegar a CasinoFloor antes de que su
		# SteamMultiplayerPeer termine de conectar (create_client() es async) —
		# join()/request_state() por RPC fallarían en silencio sobre un peer
		# que todavía está CONNECTION_CONNECTING. Mismo patrón que
		# blackjack_table_net.gd para el botón Sentarse, adaptado para
		# disparar solo, sin esperar una acción de UI.
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			multiplayer.connected_to_server.connect(func():
				battle_controller.join(multiplayer.get_unique_id())
				battle_controller.request_state()
			)
		else:
			battle_controller.join(multiplayer.get_unique_id())
			battle_controller.request_state()

func _on_teams_changed(teams: Array) -> void:
	_teams_line = "Equipo A: %s | Equipo B: %s" % [str(teams[0]), str(teams[1])]
	_refresh_label()

func _on_match_state_changed(state: Dictionary) -> void:
	var msg := "Pozo A: %d | Pozo B: %d" % [state["pool_balances"][0], state["pool_balances"][1]]
	if state["finished"]:
		msg += " — FIN (equipo %d, %s)" % [state["winning_team"], state["reason"]]
	_state_line = msg
	_refresh_label()

func _refresh_label() -> void:
	battle_status_label.text = _teams_line + "\n" + _state_line

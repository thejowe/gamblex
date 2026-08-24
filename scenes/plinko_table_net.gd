extends Control

@onready var table_controller: PlinkoTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var rows_label: Label = $RowsLabel
@onready var rows_minus_button: Button = $RowsMinusButton
@onready var rows_plus_button: Button = $RowsPlusButton
@onready var board: PlinkoBoard = $PlinkoBoard
@onready var players_label: Label = $PlayersLabel

var _last_players: Dictionary = {}

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	table_controller.state_changed.connect(_on_state_changed)
	NetworkManager.identities_changed.connect(_refresh_players_label)
	# Mismo gotcha que dice_table_net.gd/roulette_table_net.gd: un cliente
	# recién llegado a esta escena puede que aún no tenga el
	# SteamMultiplayerPeer en CONNECTED — bloquear la apuesta hasta entonces
	# evita el rpc_id() fallido.
	if not multiplayer.is_server():
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			multiplayer.connected_to_server.connect(func():
				table_controller.request_state()
			)
		else:
			table_controller.request_state()

func _on_state_changed(state: Dictionary) -> void:
	_last_players = state["players"]
	_refresh_players_label()

func _refresh_players_label() -> void:
	if _last_players.is_empty():
		players_label.text = "Nadie ha soltado la bola todavía."
		return
	var lines: Array[String] = []
	for player_id in _last_players:
		var player = _last_players[player_id]
		var line := "%s — fichas %d" % [_display_name(player["player_id"]), player["balance"]]
		var last_round = player["last_round"]
		if not last_round.is_empty():
			var outcome_text := "ganó" if last_round["win"] else "perdió"
			line += " — última bola: slot %d/%d, x%.2f, %s" % [
				last_round["slot"], last_round["rows"], last_round["multiplier"], outcome_text
			]
		lines.append(line)
	players_label.text = "\n".join(lines)

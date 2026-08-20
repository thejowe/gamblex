extends Control

@onready var table_controller: PlinkoTableController = $TableController
@onready var players_label: Label = $PlayersLabel
@onready var rows_spinbox: SpinBox = $RowsSpinBox
@onready var amount_spinbox: SpinBox = $AmountSpinBox
@onready var drop_button: Button = $DropButton

var _last_players: Dictionary = {}

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	rows_spinbox.min_value = PlinkoTableState.MIN_ROWS
	rows_spinbox.max_value = PlinkoTableState.MAX_ROWS
	rows_spinbox.value = PlinkoTableState.DEFAULT_ROWS
	table_controller.state_changed.connect(_on_state_changed)
	drop_button.pressed.connect(_drop)
	NetworkManager.identities_changed.connect(_refresh_players_label)
	# Mismo gotcha que dice_table_net.gd/roulette_table_net.gd: un cliente
	# recién llegado a esta escena puede que aún no tenga el
	# SteamMultiplayerPeer en CONNECTED — bloquear la apuesta hasta entonces
	# evita el rpc_id() fallido.
	if not multiplayer.is_server():
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			drop_button.disabled = true
			multiplayer.connected_to_server.connect(func():
				drop_button.disabled = false
				table_controller.request_state()
			)
		else:
			table_controller.request_state()

func _drop() -> void:
	table_controller.roll(int(rows_spinbox.value), int(amount_spinbox.value))

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

extends Control

@onready var table_controller: DiceTableController = $TableController
@onready var players_label: Label = $PlayersLabel
@onready var threshold_spinbox: SpinBox = $ThresholdSpinBox
@onready var amount_spinbox: SpinBox = $AmountSpinBox
@onready var bet_over_button: Button = $BetOverButton
@onready var bet_under_button: Button = $BetUnderButton

var _last_players: Dictionary = {}

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	table_controller.state_changed.connect(_on_state_changed)
	bet_over_button.pressed.connect(func(): _roll(DiceTableState.Direction.OVER))
	bet_under_button.pressed.connect(func(): _roll(DiceTableState.Direction.UNDER))
	NetworkManager.identities_changed.connect(_refresh_players_label)
	# Mismo gotcha que blackjack_table_net.gd/roulette_table_net.gd: un cliente
	# recién llegado a esta escena puede que aún no tenga el
	# SteamMultiplayerPeer en CONNECTED — bloquear las apuestas hasta entonces
	# evita el rpc_id() fallido.
	if not multiplayer.is_server():
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			bet_over_button.disabled = true
			bet_under_button.disabled = true
			multiplayer.connected_to_server.connect(func():
				bet_over_button.disabled = false
				bet_under_button.disabled = false
				table_controller.request_state()
			)
		else:
			table_controller.request_state()

func _roll(direction: int) -> void:
	table_controller.roll(int(threshold_spinbox.value), direction, int(amount_spinbox.value))

func _on_state_changed(state: Dictionary) -> void:
	_last_players = state["players"]
	_refresh_players_label()

func _refresh_players_label() -> void:
	if _last_players.is_empty():
		players_label.text = "Nadie ha tirado todavía."
		return
	var lines: Array[String] = []
	for player_id in _last_players:
		var player = _last_players[player_id]
		var line := "%s — fichas %d" % [_display_name(player["player_id"]), player["balance"]]
		var last_round = player["last_round"]
		if not last_round.is_empty():
			var direction_text := "mayor que" if last_round["direction"] == DiceTableState.Direction.OVER else "menor que"
			var outcome_text := "ganó" if last_round["win"] else "perdió"
			line += " — última tirada %.2f (umbral %d %s, %s)" % [
				last_round["result"], last_round["threshold"], direction_text, outcome_text
			]
		lines.append(line)
	players_label.text = "\n".join(lines)

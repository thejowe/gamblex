extends Control

@onready var table_controller: MinesTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var size_option: OptionButton = $SizeOption
@onready var mine_count_edit: LineEdit = $MineCountEdit
@onready var mine_density_label: Label = $MineDensityLabel
@onready var cash_out_button: Button = $CashOutButton
@onready var grid: GridContainer = $MinesGrid
@onready var result_flash: ColorRect = $ResultFlash
@onready var status_label: Label = $StatusLabel

var _last_players: Dictionary = {}

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	table_controller.state_changed.connect(_on_state_changed)
	cash_out_button.pressed.connect(_on_cash_out_pressed)
	NetworkManager.identities_changed.connect(_refresh_status_label)
	# Mismo gotcha que dice_table_net.gd/roulette_table_net.gd: un cliente
	# recién llegado a esta escena puede que aún no tenga el
	# SteamMultiplayerPeer en CONNECTED — bloquear el botón de empezar hasta
	# entonces evita el rpc_id() fallido.
	if not multiplayer.is_server():
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			multiplayer.connected_to_server.connect(func():
				table_controller.request_state()
			)
		else:
			table_controller.request_state()

func _on_cell_pressed(index: int) -> void:
	table_controller.reveal(index)

func _on_cash_out_pressed() -> void:
	table_controller.cash_out()

func _on_state_changed(state: Dictionary) -> void:
	_last_players = state["players"]
	_refresh_status_label()

func _refresh_status_label() -> void:
	if _last_players.is_empty():
		status_label.text = "Nadie ha jugado todavía."
		return
	var lines: Array[String] = []
	for player_id in _last_players:
		var player = _last_players[player_id]
		var line := "%s — fichas %d" % [_display_name(player["player_id"]), player["balance"]]
		var active_round = player["active_round"]
		if not active_round.is_empty():
			line += " — ronda en curso (%d reveladas, x%.2f)" % [active_round["revealed"].size(), active_round["multiplier"]]
		elif not player["last_round"].is_empty():
			var last_round = player["last_round"]
			var outcome_text := "ganó" if last_round["win"] else "perdió"
			line += " — última ronda %s (%d minas, %d reveladas)" % [outcome_text, last_round["mine_count"], last_round["revealed"].size()]
		lines.append(line)
	status_label.text = "\n".join(lines)

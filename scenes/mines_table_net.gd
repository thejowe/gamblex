extends Control

const TOTAL_CELLS := 25

@onready var table_controller: MinesTableController = $TableController
@onready var status_label: Label = $StatusLabel
@onready var mine_count_spinbox: SpinBox = $MineCountSpinBox
@onready var amount_spinbox: SpinBox = $AmountSpinBox
@onready var start_button: Button = $StartButton
@onready var cash_out_button: Button = $CashOutButton
@onready var grid: GridContainer = $MinesGrid

var _cell_buttons: Array[Button] = []
var _last_players: Dictionary = {}

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	for child in grid.get_children():
		if child is Button:
			_cell_buttons.append(child)
	for i in range(_cell_buttons.size()):
		_cell_buttons[i].pressed.connect(_on_cell_pressed.bind(i))
	table_controller.state_changed.connect(_on_state_changed)
	start_button.pressed.connect(_on_start_pressed)
	cash_out_button.pressed.connect(_on_cash_out_pressed)
	NetworkManager.identities_changed.connect(_refresh_status_label)
	_set_round_ui_active(false)
	# Mismo gotcha que dice_table_net.gd/roulette_table_net.gd: un cliente
	# recién llegado a esta escena puede que aún no tenga el
	# SteamMultiplayerPeer en CONNECTED — bloquear el botón de empezar hasta
	# entonces evita el rpc_id() fallido.
	if not multiplayer.is_server():
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			start_button.disabled = true
			multiplayer.connected_to_server.connect(func():
				start_button.disabled = false
				table_controller.request_state()
			)
		else:
			table_controller.request_state()

func _on_start_pressed() -> void:
	table_controller.start_round(TOTAL_CELLS, int(mine_count_spinbox.value), int(amount_spinbox.value))

func _on_cell_pressed(index: int) -> void:
	table_controller.reveal(index)

func _on_cash_out_pressed() -> void:
	table_controller.cash_out()

func _set_round_ui_active(active: bool) -> void:
	start_button.disabled = active
	cash_out_button.disabled = not active
	mine_count_spinbox.editable = not active
	amount_spinbox.editable = not active
	for button in _cell_buttons:
		button.disabled = not active

func _on_state_changed(state: Dictionary) -> void:
	_last_players = state["players"]
	var my_id := multiplayer.get_unique_id()
	if _last_players.has(my_id):
		var my_data = _last_players[my_id]
		var active_round = my_data["active_round"]
		_set_round_ui_active(not active_round.is_empty())
		for i in range(_cell_buttons.size()):
			if not active_round.is_empty() and active_round["revealed"].has(i):
				_cell_buttons[i].text = "X"
				_cell_buttons[i].disabled = true
			else:
				_cell_buttons[i].text = ""
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

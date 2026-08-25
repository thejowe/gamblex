extends Control

@onready var table_controller: PlinkoTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var rows_label: Label = $RowsLabel
@onready var rows_minus_button: Button = $RowsMinusButton
@onready var rows_plus_button: Button = $RowsPlusButton
@onready var board: PlinkoBoard = $PlinkoBoard
@onready var players_label: Label = $PlayersLabel

var _last_players: Dictionary = {}
var _rows: int = PlinkoTableState.DEFAULT_ROWS

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	table_controller.state_changed.connect(_on_state_changed)
	bet_sidebar.bet_pressed.connect(_on_bet_pressed)
	rows_minus_button.pressed.connect(func(): _set_rows(_rows - 1))
	rows_plus_button.pressed.connect(func(): _set_rows(_rows + 1))
	NetworkManager.identities_changed.connect(_refresh_players_label)
	_set_rows(PlinkoTableState.DEFAULT_ROWS)
	if not multiplayer.is_server():
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			bet_sidebar.bet_button.disabled = true
			multiplayer.connected_to_server.connect(func():
				bet_sidebar.bet_button.disabled = false
				table_controller.request_state()
			)
		else:
			table_controller.request_state()

func _set_rows(value: int) -> void:
	_rows = clampi(value, PlinkoTableState.MIN_ROWS, PlinkoTableState.MAX_ROWS)
	board.rows = _rows
	rows_label.text = "Filas: %d" % _rows

func _on_bet_pressed(amount: int) -> void:
	table_controller.roll(_rows, amount)

func _on_state_changed(state: Dictionary) -> void:
	var previous := _last_players
	_last_players = state["players"]
	_refresh_players_label()
	_maybe_drop_ball(previous)

func _maybe_drop_ball(previous: Dictionary) -> void:
	var my_id := multiplayer.get_unique_id()
	if not _last_players.has(my_id):
		return
	var last_round: Dictionary = _last_players[my_id]["last_round"]
	if last_round.is_empty():
		return
	var previous_round: Dictionary = previous[my_id]["last_round"] if previous.has(my_id) else {}
	if previous_round == last_round:
		return
	board.drop_ball(last_round["bounces"])

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

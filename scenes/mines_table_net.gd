extends Control

const SIZE_OPTIONS := [
	{"label": "5 x 5", "total_cells": 25, "columns": 5},
	{"label": "8 x 8", "total_cells": 64, "columns": 8},
	{"label": "10 x 10", "total_cells": 100, "columns": 10},
]
const MinesCellScene := preload("res://scenes/ui/casino/mines_cell.tscn")
const RULES_TEXT := "Mines: elige tamano de grid (5x5, 8x8 o 10x10) y cuantas minas ocultas quieres. Cada casilla segura que destapas sube el multiplicador de tu apuesta — puedes retirar en cualquier momento para cobrar. Si destapas una mina pierdes la apuesta entera. Mas minas o mas casillas destapadas = multiplicador mas alto, pero mas riesgo."

@onready var table_controller: MinesTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var size_option: OptionButton = $SizeOption
@onready var mine_count_edit: LineEdit = $MineCountEdit
@onready var mine_density_label: Label = $MineDensityLabel
@onready var cash_out_button: Button = $CashOutButton
@onready var grid: GridContainer = $MinesGrid
@onready var result_flash: ColorRect = $ResultFlash
@onready var status_label: Label = $StatusLabel
@onready var help_button: CasinoButton = $HelpButton
@onready var help_overlay: HelpOverlay = $HelpOverlay

var _last_players: Dictionary = {}
var _last_round_seen: Dictionary = {}
var _cash_out_pulse: Tween = null
var _cash_out_was_pulsing: bool = false

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	CasinoTheme.style_option_button(size_option)
	CasinoTheme.style_line_edit(mine_count_edit)
	for option in SIZE_OPTIONS:
		size_option.add_item(option["label"])
	size_option.item_selected.connect(func(_i): _rebuild_grid(); _refresh_density_label())
	mine_count_edit.text_changed.connect(func(_t): _refresh_density_label())
	table_controller.state_changed.connect(_on_state_changed)
	bet_sidebar.bet_pressed.connect(_on_bet_pressed)
	cash_out_button.pressed.connect(func(): table_controller.cash_out())
	help_button.pressed.connect(func(): help_overlay.set_rules_text(RULES_TEXT); help_overlay.open())
	NetworkManager.identities_changed.connect(_refresh_status_label)
	_rebuild_grid()
	_refresh_density_label()
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

func _selected_total_cells() -> int:
	return SIZE_OPTIONS[size_option.selected]["total_cells"]

func _selected_columns() -> int:
	return SIZE_OPTIONS[size_option.selected]["columns"]

func _rebuild_grid() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.free()
	grid.columns = _selected_columns()
	for i in range(_selected_total_cells()):
		var cell: MinesCell = MinesCellScene.instantiate()
		cell.index = i
		cell.cell_pressed.connect(_on_cell_pressed)
		grid.add_child(cell)

func _refresh_density_label() -> void:
	var mine_count := int(mine_count_edit.text) if mine_count_edit.text.is_valid_int() else 0
	var total := _selected_total_cells()
	var density := (float(mine_count) / float(total)) * 100.0 if total > 0 else 0.0
	mine_density_label.text = "%.2f%%" % density
	# Más densidad de minas = más riesgo por casilla — sin esto 5% y 50% se
	# veían igual de neutros pese a ser un riesgo radicalmente distinto.
	mine_density_label.add_theme_color_override("font_color", CasinoTheme.TEXT_LIGHT.lerp(CasinoTheme.ACCENT_RED, clampf(density / 50.0, 0.0, 1.0)))

func _on_bet_pressed(amount: int) -> void:
	var mine_count := int(mine_count_edit.text) if mine_count_edit.text.is_valid_int() else 1
	table_controller.start_round(_selected_total_cells(), mine_count, amount)

func _on_cell_pressed(index: int) -> void:
	table_controller.reveal(index)

func _on_state_changed(state: Dictionary) -> void:
	_render_state(state)

func _render_state(state: Dictionary) -> void:
	_last_players = state["players"]
	var my_id := multiplayer.get_unique_id()
	if _last_players.has(my_id):
		var my_data = _last_players[my_id]
		var active_round: Dictionary = my_data["active_round"]
		var last_round: Dictionary = my_data["last_round"]
		var is_active := not active_round.is_empty()
		if is_active and active_round["revealed"].size() == 5:
			SteamManager.unlock_achievement("MINES_SURVIVOR")
		cash_out_button.disabled = not is_active
		bet_sidebar.bet_button.disabled = is_active
		size_option.disabled = is_active
		mine_count_edit.editable = not is_active
		var can_cash_out: bool = is_active and not active_round.get("revealed", []).is_empty()
		if can_cash_out != _cash_out_was_pulsing:
			_cash_out_was_pulsing = can_cash_out
			_set_cash_out_pulsing(can_cash_out)
		var round_data: Dictionary = active_round if is_active else last_round
		if not round_data.is_empty():
			var cell_states: Array = MinesCell.compute_cell_states(round_data, is_active)
			for i in range(min(cell_states.size(), grid.get_child_count())):
				var cell: MinesCell = grid.get_child(i)
				cell.state = cell_states[i]
				cell.interactive = is_active
		_maybe_flash_result(my_id, last_round)
	_refresh_status_label()

# Igual que en Crash: mientras hay algo real que cobrar, el botón de retirar
# no comunicaba ninguna urgencia — se veía igual habilitado con 1 casilla
# segura destapada que con 20.
func _set_cash_out_pulsing(pulsing: bool) -> void:
	if _cash_out_pulse != null and _cash_out_pulse.is_valid():
		_cash_out_pulse.kill()
	cash_out_button.modulate = Color.WHITE
	if not pulsing:
		return
	_cash_out_pulse = create_tween().set_loops()
	_cash_out_pulse.tween_property(cash_out_button, "modulate", CasinoTheme.GOLD_ACCENT, 0.5)
	_cash_out_pulse.tween_property(cash_out_button, "modulate", Color.WHITE, 0.5)

func _maybe_flash_result(my_id: int, last_round: Dictionary) -> void:
	if last_round.is_empty():
		return
	if _last_round_seen.get(my_id, {}) == last_round:
		return
	_last_round_seen[my_id] = last_round
	AudioManager.play_win_sfx(last_round["win"], last_round.get("payout", 0), last_round.get("amount", 0))
	var flash_color: Color = CasinoTheme.ACCENT_GREEN if last_round["win"] else CasinoTheme.ACCENT_RED
	var tween := create_tween()
	result_flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.3)
	tween.tween_property(result_flash, "color:a", 0.0, 0.6)

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

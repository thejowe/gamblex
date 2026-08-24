# Reskin Visual de Mines — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reconstruir la mesa de Mines sobre la fundación de casino oscuro de Plan 16 — grid de casillas dibujadas por código con tamaño configurable, `BetSidebarPanel` reutilizado para la apuesta, flash de resultado.

**Architecture:** `MinesCell` (nuevo, `scripts/ui/casino/`) es un `Control` presentacional con 4 estados visuales y una función estática pura (`compute_cell_states`) que traduce el diccionario de ronda del backend a estados de celda — separada de la escena para poder testearla sin instanciar nada. `scenes/mines_table_net.gd` reconstruye el `GridContainer` dinámicamente según el tamaño elegido. Cero cambios en `scripts/mines/`.

**Tech Stack:** Godot 4.7 / GDScript, GUT.

**Spec:** `docs/superpowers/specs/2026-08-24-mines-visual-design.md` (léela completa antes de empezar).

## Global Constraints

- No tocar `scripts/mines/mines_table_state.gd`, `scripts/mines/mines_roller.gd`, `scripts/net/mines_table_controller.gd` — la interfaz ya expone todo lo necesario (`start_round`, `reveal`, `cash_out`, `to_dict()`).
- No tocar `scripts/ui/casino/casino_theme.gd` salvo que falte algún color (no debería — Plan 16 ya cubre `PANEL_NAVY_*`/`ACCENT_*`/`TEXT_*`), ni `bet_sidebar_panel.gd`/`casino_button.gd` — reutilízalos tal cual.
- No tocar Blackjack, Dice, Ruleta, Póker, Crash, Plinko, Modo Batalla.
- Cero archivos de imagen — todo `_draw()`/`StyleBoxFlat`.
- Trabaja en worktree aislado, rama `feature/mines-visual`.
- Godot: `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`. Reconstruye caché de clases antes de confiar en GUT; revisa `git status` después por reformateo espacios/tabs.

---

## Task 1: `MinesCell` — casilla dibujada por código + traductor de estado puro

**Files:**
- Create: `scripts/ui/casino/mines_cell.gd`
- Create: `scenes/ui/casino/mines_cell.tscn`
- Test: `tests/unit/test_mines_cell.gd`

**Interfaces:**
- Consumes: `CasinoTheme.PANEL_NAVY_MID/PANEL_NAVY_LIGHT/ACCENT_GREEN/ACCENT_RED` (Plan 16).
- Produces: `class_name MinesCell extends Control`, `enum State { HIDDEN, SAFE, MINE, MINE_DIM }`, propiedades `state: State`, `interactive: bool`, señal `cell_pressed(index: int)`, propiedad `index: int` (la asigna quien la instancia), y `static func compute_cell_states(round_data: Dictionary, is_active: bool) -> Array` — la Tarea 3 la usa para poblar el grid a partir de `active_round`/`last_round`.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_mines_cell.gd
extends GutTest

func _make_cell() -> MinesCell:
	var cell: MinesCell = load("res://scenes/ui/casino/mines_cell.tscn").instantiate()
	add_child_autofree(cell)
	return cell

func test_default_state_is_hidden_and_interactive():
	var cell := _make_cell()
	assert_eq(cell.state, MinesCell.State.HIDDEN)
	assert_true(cell.interactive)

func test_pressing_hidden_interactive_cell_emits_cell_pressed():
	var cell := _make_cell()
	cell.index = 7
	watch_signals(cell)
	cell._on_gui_pressed()
	assert_signal_emitted_with_parameters(cell, "cell_pressed", [7])

func test_pressing_revealed_cell_does_not_emit():
	var cell := _make_cell()
	cell.state = MinesCell.State.SAFE
	watch_signals(cell)
	cell._on_gui_pressed()
	assert_signal_not_emitted(cell, "cell_pressed")

func test_pressing_non_interactive_cell_does_not_emit():
	var cell := _make_cell()
	cell.interactive = false
	watch_signals(cell)
	cell._on_gui_pressed()
	assert_signal_not_emitted(cell, "cell_pressed")

func test_compute_cell_states_active_round_marks_revealed_as_safe():
	var round_data := {"total_cells": 9, "revealed": [0, 4]}
	var states := MinesCell.compute_cell_states(round_data, true)
	assert_eq(states.size(), 9)
	assert_eq(states[0], MinesCell.State.SAFE)
	assert_eq(states[4], MinesCell.State.SAFE)
	assert_eq(states[1], MinesCell.State.HIDDEN)

func test_compute_cell_states_lost_round_marks_one_exploded_mine_and_dims_rest():
	var round_data := {
		"total_cells": 9, "revealed": [0, 1], "mines": [2, 5, 8], "win": false,
	}
	var states := MinesCell.compute_cell_states(round_data, false)
	assert_eq(states[0], MinesCell.State.SAFE)
	assert_eq(states[1], MinesCell.State.SAFE)
	var exploded_count := 0
	var dim_count := 0
	for s in [states[2], states[5], states[8]]:
		if s == MinesCell.State.MINE:
			exploded_count += 1
		elif s == MinesCell.State.MINE_DIM:
			dim_count += 1
	assert_eq(exploded_count, 1)
	assert_eq(dim_count, 2)

func test_compute_cell_states_won_round_dims_all_mines_none_exploded():
	var round_data := {
		"total_cells": 9, "revealed": [0, 1, 3], "mines": [2, 5, 8], "win": true,
	}
	var states := MinesCell.compute_cell_states(round_data, false)
	for i in [2, 5, 8]:
		assert_eq(states[i], MinesCell.State.MINE_DIM)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_mines_cell.gd -gexit`
Expected: FAIL — la escena no existe todavía.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/mines_cell.gd
class_name MinesCell
extends Control

enum State { HIDDEN, SAFE, MINE, MINE_DIM }

signal cell_pressed(index: int)

@export var index: int = -1
@export var interactive: bool = true
@export var state: State = State.HIDDEN:
	set(value):
		var was_safe := state == State.SAFE
		state = value
		queue_redraw()
		if state == State.SAFE and not was_safe and is_inside_tree():
			_animate_reveal()

func _init() -> void:
	custom_minimum_size = Vector2(48, 48)
	pivot_offset = Vector2(24, 24)

func _animate_reveal() -> void:
	scale = Vector2(0.8, 0.8)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_gui_pressed()

func _on_gui_pressed() -> void:
	if state == State.HIDDEN and interactive:
		cell_pressed.emit(index)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	match state:
		State.HIDDEN:
			draw_rect(rect, CasinoTheme.PANEL_NAVY_MID)
			draw_rect(rect, CasinoTheme.PANEL_NAVY_LIGHT, false, 1.5)
		State.SAFE:
			draw_rect(rect, CasinoTheme.PANEL_NAVY_MID)
			_draw_diamond(CasinoTheme.ACCENT_GREEN, 1.0)
		State.MINE:
			draw_rect(rect, CasinoTheme.PANEL_NAVY_MID)
			draw_circle(size / 2.0, size.x * 0.28, CasinoTheme.ACCENT_RED)
		State.MINE_DIM:
			draw_rect(rect, CasinoTheme.PANEL_NAVY_MID)
			draw_circle(size / 2.0, size.x * 0.28, Color(CasinoTheme.ACCENT_RED, 0.4))

func _draw_diamond(color: Color, alpha: float) -> void:
	var c := size / 2.0
	var r := size.x * 0.32
	var points := PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0),
	])
	draw_colored_polygon(points, Color(color, alpha))

static func compute_cell_states(round_data: Dictionary, is_active: bool) -> Array:
	var total_cells: int = round_data.get("total_cells", 0)
	var result := []
	for i in range(total_cells):
		result.append(State.HIDDEN)
	var revealed: Array = round_data.get("revealed", [])
	for i in revealed:
		result[i] = State.SAFE
	if is_active:
		return result
	var mines: Array = round_data.get("mines", [])
	var win: bool = round_data.get("win", true)
	var exploded_marked := false
	for m in mines:
		if revealed.has(m):
			continue
		if not win and not exploded_marked:
			result[m] = State.MINE
			exploded_marked = true
		else:
			result[m] = State.MINE_DIM
	return result
```

```gdscript
# scenes/ui/casino/mines_cell.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/mines_cell.gd" id="1"]

[node name="MinesCell" type="Control"]
script = ExtResource("1")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_mines_cell.gd -gexit`
Expected: PASS, 7/7.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/mines_cell.gd scenes/ui/casino/mines_cell.tscn tests/unit/test_mines_cell.gd
git commit -m "feat(ui): add MinesCell component with pure round-state translator"
```

---

## Task 2: Reconstruye `scenes/mines_table_net.tscn`

**Files:**
- Modify: `scenes/mines_table_net.tscn` (reescritura completa del árbol)
- Test: `tests/unit/test_mines_table_scene_structure.gd`

**Interfaces:**
- Consumes: `BetSidebarPanel` (Plan 16), `CasinoButton` (Plan 14/16).
- Produces: árbol de nodos con los paths que consume la Tarea 3: `$BetSidebarPanel`, `$SizeOption`, `$MineCountEdit`, `$MineDensityLabel`, `$CashOutButton`, `$MinesGrid`, `$ResultFlash`, `$StatusLabel`, `$TableController`.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_mines_table_scene_structure.gd
extends GutTest

func test_scene_has_expected_node_paths():
	var scene := load("res://scenes/mines_table_net.tscn")
	var root := scene.instantiate()
	add_child_autofree(root)
	for path in [
		"BetSidebarPanel", "SizeOption", "MineCountEdit", "MineDensityLabel",
		"CashOutButton", "MinesGrid", "ResultFlash", "StatusLabel", "TableController",
	]:
		assert_not_null(root.get_node_or_null(path), "falta el nodo %s" % path)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_mines_table_scene_structure.gd -gexit`
Expected: FAIL — la escena actual no tiene esos nodos.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/mines_table_net.tscn`:

```gdscript
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scenes/mines_table_net.gd" id="1"]
[ext_resource type="Script" path="res://scripts/net/mines_table_controller.gd" id="2"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/bet_sidebar_panel.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/casino_button.tscn" id="4"]

[node name="MinesTableNet" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="TableController" type="Node" parent="."]
script = ExtResource("2")

[node name="BetSidebarPanel" parent="." instance=ExtResource("3")]
layout_mode = 0
offset_left = 20.0
offset_top = 20.0
offset_right = 300.0
offset_bottom = 260.0

[node name="SizeOption" type="OptionButton" parent="."]
layout_mode = 0
offset_left = 20.0
offset_top = 280.0
offset_right = 300.0
offset_bottom = 316.0

[node name="MineCountEdit" type="LineEdit" parent="."]
layout_mode = 0
offset_left = 20.0
offset_top = 336.0
offset_right = 220.0
offset_bottom = 372.0
text = "5"

[node name="MineDensityLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 230.0
offset_top = 336.0
offset_right = 300.0
offset_bottom = 372.0
text = "7.81%"

[node name="CashOutButton" parent="." instance=ExtResource("4")]
layout_mode = 0
offset_left = 20.0
offset_top = 392.0
offset_right = 300.0
offset_bottom = 436.0
text = "Retirar"
variant = 1
disabled = true

[node name="MinesGrid" type="GridContainer" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 20.0
offset_right = 880.0
offset_bottom = 560.0
columns = 5

[node name="ResultFlash" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 20.0
offset_right = 880.0
offset_bottom = 560.0
color = Color(1, 1, 1, 0)
mouse_filter = 2

[node name="StatusLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 580.0
offset_right = 880.0
offset_bottom = 780.0
text = "Nadie ha jugado todavía."
```

Actualiza solo el bloque de `@onready var` al principio de
`scenes/mines_table_net.gd` (deja el resto tal cual, la Tarea 3 lo
reescribe entero):

```gdscript
@onready var table_controller: MinesTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var size_option: OptionButton = $SizeOption
@onready var mine_count_edit: LineEdit = $MineCountEdit
@onready var mine_density_label: Label = $MineDensityLabel
@onready var cash_out_button: Button = $CashOutButton
@onready var grid: GridContainer = $MinesGrid
@onready var result_flash: ColorRect = $ResultFlash
@onready var status_label: Label = $StatusLabel
```

Si el script deja de compilar por referencias a `$MineCountSpinBox`/
`$AmountSpinBox`/`$StartButton` que ya no existen, elimínalas de este
mismo paso — la Tarea 3 reescribe toda la lógica de todas formas.

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_mines_table_scene_structure.gd -gexit`
Expected: PASS, 1/1.

- [ ] **Step 5: Commit**

```bash
git add scenes/mines_table_net.tscn scenes/mines_table_net.gd tests/unit/test_mines_table_scene_structure.gd
git commit -m "feat(mines): rebuild table scene on dark casino panel components"
```

---

## Task 3: Reescribe `mines_table_net.gd` — grid dinámico, densidad en vivo, flash de resultado

**Files:**
- Modify: `scenes/mines_table_net.gd` (reescritura completa)
- Test: `tests/unit/test_mines_table_view.gd`

**Interfaces:**
- Consumes: `BetSidebarPanel.bet_pressed(amount)` (Plan 16); `MinesCell.compute_cell_states()`/`MinesCell.State` (Task 1); `TableController.state_changed(state)` (ya existente, sin cambios).
- Produces: método público `_rebuild_grid() -> void`, `_selected_total_cells() -> int`, `_selected_columns() -> int`, `_render_state(state: Dictionary) -> void` — usados por el test de esta tarea sin pasar por RPCs reales.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_mines_table_view.gd
extends GutTest

func _make_view():
	var scene := load("res://scenes/mines_table_net.tscn")
	var view = scene.instantiate()
	add_child_autofree(view)
	return view

func test_rebuild_grid_creates_one_cell_per_selected_size():
	var view = _make_view()
	view.size_option.select(0) # 5x5 = 25
	view._rebuild_grid()
	assert_eq(view.grid.get_child_count(), 25)
	assert_eq(view.grid.columns, 5)

func test_rebuild_grid_second_size_creates_sixty_four_cells():
	var view = _make_view()
	view.size_option.select(1) # 8x8 = 64
	view._rebuild_grid()
	assert_eq(view.grid.get_child_count(), 64)
	assert_eq(view.grid.columns, 8)

func test_render_state_marks_revealed_cells_safe_for_active_round():
	var view = _make_view()
	view.size_option.select(0)
	view._rebuild_grid()
	var state := {
		"players": {
			multiplayer.get_unique_id(): {
				"player_id": multiplayer.get_unique_id(),
				"balance": 400,
				"active_round": {"total_cells": 25, "mine_count": 3, "revealed": [0, 1], "amount": 50, "multiplier": 1.2},
				"last_round": {},
			},
		},
	}
	view._render_state(state)
	assert_eq(view.grid.get_child(0).state, MinesCell.State.SAFE)
	assert_eq(view.grid.get_child(2).state, MinesCell.State.HIDDEN)

func test_bet_sidebar_press_starts_round_with_selected_size_and_mines():
	var view = _make_view()
	view.table_controller.table_state = MinesTableState.new()
	view.size_option.select(0) # 25 celdas
	view._rebuild_grid()
	view.mine_count_edit.text = "4"
	view.bet_sidebar.amount = 50
	view.bet_sidebar.bet_pressed.emit(50)
	var my_id := multiplayer.get_unique_id()
	assert_true(view.table_controller.table_state.players.has(my_id))
	assert_eq(view.table_controller.table_state.players[my_id].active_round["mine_count"], 4)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_mines_table_view.gd -gexit`
Expected: FAIL — `_rebuild_grid`/`_render_state` no existen todavía.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/mines_table_net.gd`:

```gdscript
extends Control

const SIZE_OPTIONS := [
	{"label": "5 x 5", "total_cells": 25, "columns": 5},
	{"label": "8 x 8", "total_cells": 64, "columns": 8},
	{"label": "10 x 10", "total_cells": 100, "columns": 10},
]
const MinesCellScene := preload("res://scenes/ui/casino/mines_cell.tscn")

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
var _last_round_seen: Dictionary = {}

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	for option in SIZE_OPTIONS:
		size_option.add_item(option["label"])
	size_option.item_selected.connect(func(_i): _rebuild_grid(); _refresh_density_label())
	mine_count_edit.text_changed.connect(func(_t): _refresh_density_label())
	table_controller.state_changed.connect(_on_state_changed)
	bet_sidebar.bet_pressed.connect(_on_bet_pressed)
	cash_out_button.pressed.connect(func(): table_controller.cash_out())
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
		child.queue_free()
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
		cash_out_button.disabled = active_round.is_empty()
		bet_sidebar.bet_button.disabled = not active_round.is_empty()
		var round_data: Dictionary = active_round if not active_round.is_empty() else last_round
		var is_active := not active_round.is_empty()
		if not round_data.is_empty():
			var cell_states: Array = MinesCell.compute_cell_states(round_data, is_active)
			for i in range(min(cell_states.size(), grid.get_child_count())):
				var cell: MinesCell = grid.get_child(i)
				cell.state = cell_states[i]
				cell.interactive = is_active
		_maybe_flash_result(my_id, last_round)
	_refresh_status_label()

func _maybe_flash_result(my_id: int, last_round: Dictionary) -> void:
	if last_round.is_empty():
		return
	if _last_round_seen.get(my_id, {}) == last_round:
		return
	_last_round_seen[my_id] = last_round
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
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_mines_table_view.gd -gexit`
Expected: PASS, 4/4.

- [ ] **Step 5: Commit**

```bash
git add scenes/mines_table_net.gd tests/unit/test_mines_table_view.gd
git commit -m "feat(mines): wire dynamic grid, live mine density and result flash to dark panel UI"
```

---

## Task 4: Suite completa + verificación visual manual

**Files:** ninguno nuevo — solo verificación.

- [ ] **Step 1: Reconstruye la caché de clases**

Run: `godot --headless --editor --quit --path .`. Revisa `git status` después — descarta con `git checkout -- <archivo>` cualquier reformateo de espacios/tabs en archivos que no tocaste.

- [ ] **Step 2: Corre la suite completa de GUT**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests en verde, incluidos los nuevos de este plan, sin romper Blackjack/Dice/Modo Batalla.

- [ ] **Step 3: Verificación visual manual**

Con Steam corriendo, lanza el proyecto, entra a Mines. Confirma:
- Panel lateral oscuro con monto, 1/2 · x2 · Máx, botón "Hacer apuesta".
- Selector de tamaño (5x5/8x8/10x10) reconstruye el grid correctamente al cambiarlo.
- Campo de minas actualiza el porcentaje de densidad en vivo.
- Al apostar, arranca la ronda: casillas clicables, cada clic revela con animación (diamante verde apareciendo).
- Pisar una mina termina la ronda: esa casilla en rojo, el resto de minas atenuadas, flash rojo.
- Retirar a mitad de ronda paga y muestra flash verde, minas atenuadas visibles.
- El texto de estado por jugador sigue viéndose debajo.

No cierres esta fase sin que el usuario confirme el punto anterior en vivo.

- [ ] **Step 4: Commit final (si algo quedó sin commitear)**

```bash
git status
git add -A
git commit -m "chore: verify Mines visual reskin end to end" --allow-empty
```

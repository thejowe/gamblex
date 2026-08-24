# Reskin Visual de Plinko — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir `PlinkoBoard` (tablero de clavijas con bola animada y fila de multiplicadores) y reconstruir `scenes/plinko_table_net.tscn`/`.gd` sobre `BetSidebarPanel` (Plan 16) y `PlinkoBoard`.

**Architecture:** `PlinkoBoard` es presentacional puro (`scripts/ui/casino/`), no toca `scripts/plinko/`, que ya expone todo (`slot_multiplier`, `MIN_ROWS`/`MAX_ROWS`/`DEFAULT_ROWS`, `to_dict()` con `bounces`/`slot`/`multiplier`). `BetSidebarPanel`/`CasinoButton`/`CasinoTheme` (Plan 16, ya en `main`) se reutilizan sin editar.

**Tech Stack:** Godot 4.7 / GDScript, GUT.

**Spec:** `docs/superpowers/specs/2026-08-24-plinko-visual-design.md` (léela completa antes de empezar).

## Global Constraints

- No tocar `scripts/plinko/plinko_table_state.gd`, `scripts/plinko/plinko_roller.gd`, `scripts/net/plinko_table_controller.gd` — este plan es 100% visual.
- No tocar `scripts/ui/casino/casino_theme.gd`, `bet_sidebar_panel.gd`, `casino_button.gd`, `dice_threshold_slider.gd` (Plan 16) ni nada de Blackjack (`felt_table_panel.gd`, `playing_card.gd`, `casino_chip.gd`, Plan 14) — reutilízalos, no los edites.
- No construir un selector de "Riesgo" — no tiene equivalente real en `PlinkoTableState`.
- Cero archivos de imagen — todo `_draw()`/`Tween`.
- Trabaja en worktree aislado, rama `feature/plinko-visual`.
- Godot: `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`. Reconstruye caché de clases antes de confiar en GUT; revisa `git status` después por reformateo espacios/tabs.

---

## Task 1: `PlinkoBoard` — tablero de clavijas, multiplicadores y bola animada

**Files:**
- Create: `scripts/ui/casino/plinko_board.gd`
- Create: `scenes/ui/casino/plinko_board.tscn`
- Test: `tests/unit/test_plinko_board.gd`

**Interfaces:**
- Consumes: `CasinoTheme.PANEL_NAVY_LIGHT/ACCENT_GREEN/TEXT_MUTED/TEXT_LIGHT` (Plan 16); `PlinkoTableState.slot_multiplier(rows, slot)`, `MIN_ROWS`, `MAX_ROWS`, `DEFAULT_ROWS` (ya existentes, `scripts/plinko/plinko_table_state.gd`, sin cambios).
- Produces: `class_name PlinkoBoard extends Control`, propiedad `rows: int`, métodos `peg_position(row: int, index_in_row: int) -> Vector2`, `drop_ball(bounces: Array) -> void`, `static func slot_from_bounces(bounces: Array) -> int`, señal `ball_landed(slot: int)`. La Tarea 3 lo instancia e invoca `drop_ball()` cuando llega un `last_round` nuevo.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_plinko_board.gd
extends GutTest

func _make_board() -> PlinkoBoard:
	var board: PlinkoBoard = load("res://scenes/ui/casino/plinko_board.tscn").instantiate()
	add_child_autofree(board)
	board.size = Vector2(800, 360)
	return board

func test_default_rows_matches_table_state_default():
	var board := _make_board()
	assert_eq(board.rows, PlinkoTableState.DEFAULT_ROWS)

func test_rows_setter_clamps_to_valid_range():
	var board := _make_board()
	board.rows = 3
	assert_eq(board.rows, PlinkoTableState.MIN_ROWS)
	board.rows = 99
	assert_eq(board.rows, PlinkoTableState.MAX_ROWS)

func test_slot_from_bounces_counts_right_bounces():
	assert_eq(PlinkoBoard.slot_from_bounces([true, false, true, true]), 3)
	assert_eq(PlinkoBoard.slot_from_bounces([false, false, false]), 0)
	assert_eq(PlinkoBoard.slot_from_bounces([]), 0)

func test_peg_position_last_row_spans_left_to_right():
	var board := _make_board()
	board.rows = 8
	var left := board.peg_position(7, 0)
	var right := board.peg_position(7, 7)
	assert_true(right.x > left.x)

func test_drop_ball_emits_ball_landed_with_correct_slot():
	var board := _make_board()
	board.rows = 4
	watch_signals(board)
	board.drop_ball([true, true, false, true])
	await wait_seconds(0.7)
	assert_signal_emitted_with_parameters(board, "ball_landed", [3])
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_plinko_board.gd -gexit`
Expected: FAIL — la escena no existe todavía.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/plinko_board.gd
class_name PlinkoBoard
extends Control

signal ball_landed(slot: int)

const PEG_RADIUS := 3.0
const BALL_RADIUS := 7.0
const TOP_MARGIN := 20.0
const BOTTOM_MARGIN := 44.0
const STEP_DURATION := 0.12

@export var rows: int = PlinkoTableState.DEFAULT_ROWS:
	set(value):
		rows = clampi(value, PlinkoTableState.MIN_ROWS, PlinkoTableState.MAX_ROWS)
		queue_redraw()

var _ball_visible: bool = false
var _ball_position: Vector2 = Vector2.ZERO

func _init() -> void:
	custom_minimum_size = Vector2(0, 360)

static func slot_from_bounces(bounces: Array) -> int:
	var slot := 0
	for bounced_right in bounces:
		if bounced_right:
			slot += 1
	return slot

func _row_step() -> float:
	return size.x / float(rows + 2)

func peg_position(row: int, index_in_row: int) -> Vector2:
	var step := _row_step()
	var center_x := size.x / 2.0
	var row_width := float(row) * step
	var x := center_x - row_width / 2.0 + float(index_in_row) * step
	var usable_height := size.y - TOP_MARGIN - BOTTOM_MARGIN
	var y := TOP_MARGIN + (float(row) / float(max(rows - 1, 1))) * usable_height
	return Vector2(x, y)

func _draw() -> void:
	for row in range(rows):
		for i in range(row + 1):
			draw_circle(peg_position(row, i), PEG_RADIUS, CasinoTheme.TEXT_MUTED)
	_draw_multiplier_row()
	if _ball_visible:
		draw_circle(_ball_position, BALL_RADIUS, CasinoTheme.TEXT_LIGHT)

func _draw_multiplier_row() -> void:
	var step := _row_step()
	var center_x := size.x / 2.0
	var slot_count := rows + 1
	var row_width := float(rows) * step
	var y := size.y - BOTTOM_MARGIN / 2.0
	var max_mult: float = PlinkoTableState.slot_multiplier(rows, 0)
	var min_mult: float = PlinkoTableState.slot_multiplier(rows, rows / 2)
	var font := ThemeDB.fallback_font
	for slot in range(slot_count):
		var mult: float = PlinkoTableState.slot_multiplier(rows, slot)
		var x := center_x - row_width / 2.0 + float(slot) * step
		var t: float = clampf(inverse_lerp(min_mult, max_mult, mult), 0.0, 1.0)
		var color: Color = CasinoTheme.PANEL_NAVY_LIGHT.lerp(CasinoTheme.ACCENT_GREEN, t)
		draw_rect(Rect2(x - step / 2.0 + 2.0, y - 12.0, step - 4.0, 24.0), color)
		var text := "%.2f" % mult
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
		draw_string(font, Vector2(x - text_size.x / 2.0, y + 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, CasinoTheme.TEXT_LIGHT)

func drop_ball(bounces: Array) -> void:
	var step := _row_step()
	var center_x := size.x / 2.0
	var usable_height := size.y - TOP_MARGIN - BOTTOM_MARGIN
	_ball_visible = true
	_ball_position = Vector2(center_x, TOP_MARGIN)
	queue_redraw()
	var tween := create_tween()
	var rights := 0
	var current_pos := Vector2(center_x, TOP_MARGIN)
	for row in range(bounces.size()):
		if bounces[row]:
			rights += 1
		var lefts := row + 1 - rights
		var x_offset := (float(rights) - float(lefts)) * step / 2.0
		var target := Vector2(center_x + x_offset, TOP_MARGIN + (float(row + 1) / float(max(rows, 1))) * usable_height)
		tween.tween_method(_set_ball_position, current_pos, target, STEP_DURATION)
		current_pos = target
	tween.finished.connect(func():
		ball_landed.emit(slot_from_bounces(bounces))
	)

func _set_ball_position(pos: Vector2) -> void:
	_ball_position = pos
	queue_redraw()
```

```gdscript
# scenes/ui/casino/plinko_board.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/plinko_board.gd" id="1"]

[node name="PlinkoBoard" type="Control"]
layout_mode = 3
script = ExtResource("1")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_plinko_board.gd -gexit`
Expected: PASS, 5/5.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/plinko_board.gd scenes/ui/casino/plinko_board.tscn tests/unit/test_plinko_board.gd
git commit -m "feat(ui): add PlinkoBoard component with animated ball drop"
```

---

## Task 2: Reconstruye `scenes/plinko_table_net.tscn`

**Files:**
- Modify: `scenes/plinko_table_net.tscn` (reescritura completa del árbol)
- Test: `tests/unit/test_plinko_table_scene_structure.gd`

**Interfaces:**
- Consumes: `BetSidebarPanel` (Plan 16), `PlinkoBoard` (Task 1), `CasinoButton` (Plan 14/16).
- Produces: árbol de nodos con los paths que consume la Tarea 3: `$BetSidebarPanel`, `$RowsLabel`, `$RowsMinusButton`, `$RowsPlusButton`, `$PlinkoBoard`, `$PlayersLabel`, `$TableController`.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_plinko_table_scene_structure.gd
extends GutTest

func test_scene_has_expected_node_paths():
	var scene := load("res://scenes/plinko_table_net.tscn")
	var root := scene.instantiate()
	add_child_autofree(root)
	for path in [
		"BetSidebarPanel", "RowsLabel", "RowsMinusButton", "RowsPlusButton",
		"PlinkoBoard", "PlayersLabel", "TableController",
	]:
		assert_not_null(root.get_node_or_null(path), "falta el nodo %s" % path)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_plinko_table_scene_structure.gd -gexit`
Expected: FAIL — la escena actual no tiene esos nodos.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/plinko_table_net.tscn`:

```gdscript
[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://scenes/plinko_table_net.gd" id="1"]
[ext_resource type="Script" path="res://scripts/net/plinko_table_controller.gd" id="2"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/bet_sidebar_panel.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/casino_button.tscn" id="4"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/plinko_board.tscn" id="5"]

[node name="PlinkoTableNet" type="Control"]
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

[node name="RowsLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 20.0
offset_right = 480.0
offset_bottom = 50.0
text = "Filas: 12"

[node name="RowsMinusButton" parent="." instance=ExtResource("4")]
layout_mode = 0
offset_left = 490.0
offset_top = 16.0
offset_right = 530.0
offset_bottom = 52.0
text = "-"

[node name="RowsPlusButton" parent="." instance=ExtResource("4")]
layout_mode = 0
offset_left = 540.0
offset_top = 16.0
offset_right = 580.0
offset_bottom = 52.0
text = "+"

[node name="PlinkoBoard" parent="." instance=ExtResource("5")]
layout_mode = 0
offset_left = 340.0
offset_top = 70.0
offset_right = 880.0
offset_bottom = 430.0

[node name="PlayersLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 450.0
offset_right = 900.0
offset_bottom = 650.0
text = "Nadie ha soltado la bola todavía."
```

Actualiza solo el bloque de `@onready var` al principio de
`scenes/plinko_table_net.gd` (deja el resto tal cual, la Tarea 3 lo
reescribe entero):

```gdscript
@onready var table_controller: PlinkoTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var rows_label: Label = $RowsLabel
@onready var rows_minus_button: Button = $RowsMinusButton
@onready var rows_plus_button: Button = $RowsPlusButton
@onready var board: PlinkoBoard = $PlinkoBoard
@onready var players_label: Label = $PlayersLabel
```

Si el script deja de compilar por referencias a `$RowsSpinBox`/
`$AmountSpinBox`/`$DropButton` que ya no existen, elimínalas de este
mismo paso — la Tarea 3 reescribe toda la lógica.

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_plinko_table_scene_structure.gd -gexit`
Expected: PASS, 1/1.

- [ ] **Step 5: Commit**

```bash
git add scenes/plinko_table_net.tscn scenes/plinko_table_net.gd tests/unit/test_plinko_table_scene_structure.gd
git commit -m "feat(plinko): rebuild table scene on dark casino panel components"
```

---

## Task 3: Reescribe `plinko_table_net.gd` — filas, apuesta y bola animada

**Files:**
- Modify: `scenes/plinko_table_net.gd` (reescritura completa)
- Test: `tests/unit/test_plinko_table_view.gd`

**Interfaces:**
- Consumes: `BetSidebarPanel.bet_pressed(amount)` (Plan 16); `PlinkoBoard.rows`/`drop_ball()` (Task 1); `TableController.state_changed(state)` (ya existente, sin cambios).
- Produces: método público `_set_rows(value: int) -> void`, usado por el test de esta tarea.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_plinko_table_view.gd
extends GutTest

func _make_view():
	var scene := load("res://scenes/plinko_table_net.tscn")
	var view = scene.instantiate()
	add_child_autofree(view)
	return view

func test_set_rows_clamps_and_updates_board_and_label():
	var view = _make_view()
	view._set_rows(999)
	assert_eq(view.board.rows, PlinkoTableState.MAX_ROWS)
	assert_true(view.rows_label.text.contains(str(PlinkoTableState.MAX_ROWS)))
	view._set_rows(1)
	assert_eq(view.board.rows, PlinkoTableState.MIN_ROWS)

func test_bet_sidebar_press_calls_roll_with_current_rows():
	var view = _make_view()
	view.table_controller.table_state = PlinkoTableState.new()
	view._set_rows(10)
	view.bet_sidebar.amount = 25
	view.bet_sidebar.bet_pressed.emit(25)
	assert_true(view.table_controller.table_state.players.has(multiplayer.get_unique_id()))
	assert_eq(view.table_controller.table_state.players[multiplayer.get_unique_id()].last_round["rows"], 10)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_plinko_table_view.gd -gexit`
Expected: FAIL — `_set_rows` no existe todavía.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/plinko_table_net.gd`:

```gdscript
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
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_plinko_table_view.gd -gexit`
Expected: PASS, 2/2.

- [ ] **Step 5: Commit**

```bash
git add scenes/plinko_table_net.gd tests/unit/test_plinko_table_view.gd
git commit -m "feat(plinko): wire row selector, bet sidebar and animated ball drop"
```

---

## Task 4: Suite completa + verificación visual manual

**Files:** ninguno nuevo — solo verificación.

- [ ] **Step 1: Reconstruye la caché de clases**

Run: `godot --headless --editor --quit --path .`. Revisa `git status` después — descarta con `git checkout -- <archivo>` cualquier reformateo de espacios/tabs en archivos que no tocaste.

- [ ] **Step 2: Corre la suite completa de GUT**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests en verde, incluidos los nuevos de este plan, y que ningún test de Blackjack/Dice/Modo Batalla se haya roto.

- [ ] **Step 3: Verificación visual manual**

Con Steam corriendo, lanza el proyecto, entra a la mesa de Plinko. Confirma:
- Panel lateral oscuro con monto de apuesta, botones 1/2 · x2 · Máx, botón verde "Hacer apuesta".
- Botones -/+ de filas cambian el número de filas del tablero en vivo (8-16).
- El tablero muestra clavijas en triángulo y la fila de multiplicadores abajo, más verde en los extremos.
- Al pulsar "Hacer apuesta" la bola cae animada, rebotando fila a fila, y termina en un slot coherente con el resultado.
- El listado de jugadores/tiradas recientes sigue viéndose debajo.

No cierres esta fase sin que el usuario confirme el punto anterior en vivo.

- [ ] **Step 4: Commit final (si algo quedó sin commitear)**

```bash
git status
git add -A
git commit -m "chore: verify Plinko visual reskin end to end" --allow-empty
```

# Reskin Visual de Ruleta — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reskin completo de la mesa de Ruleta: rueda animada, grid de números clicable, historial de resultados, reutilizando `BetSidebarPanel`/`CasinoTheme` de la fundación de casino oscuro (Plan 16).

**Architecture:** 3 componentes nuevos y específicos de Ruleta (`RouletteResultBadge`, `RouletteWheelDisplay`, `RouletteBettingGrid`) en `scripts/ui/casino/`, presentacionales puros. `RouletteBettingGrid` solo *selecciona* un tipo de apuesta (no apuesta); `BetSidebarPanel.bet_pressed(amount)` combina esa selección con el monto y dispara la apuesta real. Cero cambios en `scripts/roulette/`.

**Tech Stack:** Godot 4.7 / GDScript, GUT.

**Spec:** `docs/superpowers/specs/2026-08-24-roulette-visual-design.md` (léela completa antes de empezar).

## Global Constraints

- No tocar `scripts/roulette/roulette_table_state.gd`, `roulette_wheel.gd`, `scripts/net/roulette_table_controller.gd`.
- No añadir tipos de apuesta nuevos al enum `BetType` (ver "Límite real" en el spec — Alta/Baja quedan fuera).
- No tocar `CasinoTheme` — ya tiene todo lo necesario (`CARD_RED`/`CARD_BLACK`/`ACCENT_GREEN`/`PANEL_NAVY_*`/`TEXT_*`).
- No tocar Blackjack, Dice, Modo Batalla.
- Cero archivos de imagen.
- Trabaja en worktree aislado, rama `feature/roulette-visual`.
- Godot: `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`. Reconstruye caché de clases antes de confiar en GUT; revisa `git status` después por reformateo espacios/tabs.

---

## Task 1: `RouletteResultBadge` — insignia circular de resultado

**Files:**
- Create: `scripts/ui/casino/roulette_result_badge.gd`
- Create: `scenes/ui/casino/roulette_result_badge.tscn`
- Test: `tests/unit/test_roulette_result_badge.gd`

**Interfaces:**
- Consumes: `CasinoTheme.CARD_RED/CARD_BLACK/ACCENT_GREEN/TEXT_LIGHT`; `RouletteTableState.RED_NUMBERS` (ya existente).
- Produces: `class_name RouletteResultBadge extends Control`, propiedad `number: int`. La Tarea 5 instancia `preload("res://scenes/ui/casino/roulette_result_badge.tscn")` una vez por resultado del historial.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_roulette_result_badge.gd
extends GutTest

func test_default_size_is_diameter_of_radius():
	var badge: RouletteResultBadge = RouletteResultBadge.new()
	assert_eq(badge.custom_minimum_size, Vector2(RouletteResultBadge.RADIUS * 2, RouletteResultBadge.RADIUS * 2))
	badge.free()

func test_setting_number_does_not_error():
	var badge: RouletteResultBadge = RouletteResultBadge.new()
	add_child_autofree(badge)
	badge.number = 32
	assert_eq(badge.number, 32)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_result_badge.gd -gexit`
Expected: FAIL — `RouletteResultBadge` no existe todavía.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/roulette_result_badge.gd
class_name RouletteResultBadge
extends Control

const RADIUS := 16.0

@export var number: int = 0:
	set(value):
		number = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2, RADIUS * 2)

func _color_for_number() -> Color:
	if number == 0:
		return CasinoTheme.ACCENT_GREEN
	if number in RouletteTableState.RED_NUMBERS:
		return CasinoTheme.CARD_RED
	return CasinoTheme.CARD_BLACK

func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, RADIUS, _color_for_number())
	draw_arc(center, RADIUS, 0, TAU, 24, CasinoTheme.TEXT_LIGHT, 1.5)
	var font := ThemeDB.fallback_font
	var text := str(number)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	draw_string(font, center - text_size / 2.0 + Vector2(0, text_size.y * 0.3), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, CasinoTheme.TEXT_LIGHT)
```

```gdscript
# scenes/ui/casino/roulette_result_badge.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/roulette_result_badge.gd" id="1"]

[node name="RouletteResultBadge" type="Control"]
script = ExtResource("1")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_result_badge.gd -gexit`
Expected: PASS, 2/2.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/roulette_result_badge.gd scenes/ui/casino/roulette_result_badge.tscn tests/unit/test_roulette_result_badge.gd
git commit -m "feat(ui): add RouletteResultBadge component"
```

---

## Task 2: `RouletteWheelDisplay` — rueda animada

**Files:**
- Create: `scripts/ui/casino/roulette_wheel_display.gd`
- Create: `scenes/ui/casino/roulette_wheel_display.tscn`
- Test: `tests/unit/test_roulette_wheel_display.gd`

**Interfaces:**
- Consumes: `CasinoTheme.CARD_RED/CARD_BLACK/ACCENT_GREEN/TEXT_LIGHT`; `RouletteTableState.RED_NUMBERS`.
- Produces: `class_name RouletteWheelDisplay extends Control`, propiedad `last_result: int`, método `angle_for_result(result: int) -> float` (cálculo puro, testeable), método `spin_to(result: int) -> void` (anima y al terminar fija `last_result`), señal `spin_finished`.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_roulette_wheel_display.gd
extends GutTest

func _make_wheel() -> RouletteWheelDisplay:
	var wheel: RouletteWheelDisplay = load("res://scenes/ui/casino/roulette_wheel_display.tscn").instantiate()
	add_child_autofree(wheel)
	return wheel

func test_angle_for_result_zero_is_zero_plus_half_slice():
	var wheel := _make_wheel()
	var slice := TAU / RouletteWheelDisplay.WHEEL_ORDER.size()
	assert_almost_eq(wheel.angle_for_result(0), slice / 2.0, 0.0001)

func test_angle_for_result_is_within_full_circle():
	var wheel := _make_wheel()
	for result in [1, 17, 36]:
		var angle := wheel.angle_for_result(result)
		assert_true(angle >= 0.0 and angle < TAU)

func test_spin_to_eventually_sets_last_result():
	var wheel := _make_wheel()
	wheel.spin_to(23)
	await wheel.spin_finished
	assert_eq(wheel.last_result, 23)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_wheel_display.gd -gexit`
Expected: FAIL — la escena no existe todavía.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/roulette_wheel_display.gd
class_name RouletteWheelDisplay
extends Control

signal spin_finished

const RADIUS := 130.0
const WHEEL_ORDER := [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]

@export var last_result: int = -1:
	set(value):
		last_result = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2, RADIUS * 2)

func _color_for_number(n: int) -> Color:
	if n == 0:
		return CasinoTheme.ACCENT_GREEN
	if n in RouletteTableState.RED_NUMBERS:
		return CasinoTheme.CARD_RED
	return CasinoTheme.CARD_BLACK

func _draw() -> void:
	var center := size / 2.0
	var slice_angle := TAU / WHEEL_ORDER.size()
	for i in range(WHEEL_ORDER.size()):
		var n: int = WHEEL_ORDER[i]
		var start_angle := i * slice_angle
		var points := PackedVector2Array()
		points.append(center)
		var steps := 6
		for s in range(steps + 1):
			var a := start_angle + slice_angle * float(s) / float(steps)
			points.append(center + Vector2(cos(a), sin(a)) * RADIUS)
		draw_colored_polygon(points, _color_for_number(n))
	draw_arc(center, RADIUS, 0, TAU, 64, CasinoTheme.TEXT_LIGHT, 2.0)

func angle_for_result(result: int) -> float:
	var index := WHEEL_ORDER.find(result)
	var slice_angle := TAU / WHEEL_ORDER.size()
	return index * slice_angle + slice_angle / 2.0

func spin_to(result: int) -> void:
	var target_angle := -angle_for_result(result) + TAU * 4.0
	var tween := create_tween()
	tween.tween_property(self, "rotation", target_angle, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		last_result = result
		rotation = wrapf(rotation, 0.0, TAU)
		spin_finished.emit()
	)
```

```gdscript
# scenes/ui/casino/roulette_wheel_display.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/roulette_wheel_display.gd" id="1"]

[node name="RouletteWheelDisplay" type="Control"]
script = ExtResource("1")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_wheel_display.gd -gexit`
Expected: PASS, 3/3 (el tercero tarda ~2s reales por el tween, es esperado).

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/roulette_wheel_display.gd scenes/ui/casino/roulette_wheel_display.tscn tests/unit/test_roulette_wheel_display.gd
git commit -m "feat(ui): add RouletteWheelDisplay component with spin animation"
```

---

## Task 3: `RouletteBettingGrid` — selector de apuesta

**Files:**
- Create: `scripts/ui/casino/roulette_betting_grid.gd`
- Create: `scenes/ui/casino/roulette_betting_grid.tscn`
- Test: `tests/unit/test_roulette_betting_grid.gd`

**Interfaces:**
- Consumes: `CasinoTheme.CARD_RED/CARD_BLACK/ACCENT_GREEN`; `RouletteTableState.BetType`/`RED_NUMBERS`; `CasinoButton` (Plan 14, para las apuestas de fuera).
- Produces: `class_name RouletteBettingGrid extends GridContainer`, señal `bet_selected(bet_type: int, number: int)`. La Tarea 5 la conecta directo a `_on_bet_selected`, guardando la última selección hasta que se pulse "Hacer apuesta".

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_roulette_betting_grid.gd
extends GutTest

func _make_grid() -> RouletteBettingGrid:
	var grid: RouletteBettingGrid = load("res://scenes/ui/casino/roulette_betting_grid.tscn").instantiate()
	add_child_autofree(grid)
	return grid

func test_grid_creates_37_number_buttons():
	var grid := _make_grid()
	var count := 0
	for child in grid.get_children():
		if child is Button and child.text.is_valid_int():
			count += 1
	assert_eq(count, 37)

func test_number_press_emits_straight_bet_selected():
	var grid := _make_grid()
	watch_signals(grid)
	var fake_button := Button.new()
	grid.add_child(fake_button)
	grid._on_number_pressed(fake_button, 7)
	assert_signal_emitted_with_parameters(grid, "bet_selected", [RouletteTableState.BetType.STRAIGHT, 7])
	fake_button.queue_free()

func test_outside_bet_press_emits_bet_selected_with_no_number():
	var grid := _make_grid()
	watch_signals(grid)
	var fake_button := Button.new()
	grid.add_child(fake_button)
	grid._on_outside_bet_pressed(fake_button, RouletteTableState.BetType.RED, -1)
	assert_signal_emitted_with_parameters(grid, "bet_selected", [RouletteTableState.BetType.RED, -1])
	fake_button.queue_free()
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_betting_grid.gd -gexit`
Expected: FAIL — la escena no existe todavía.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/roulette_betting_grid.gd
class_name RouletteBettingGrid
extends GridContainer

signal bet_selected(bet_type: int, number: int)

const CasinoButtonScene := preload("res://scenes/ui/casino/casino_button.tscn")

var _selected_button: Control = null

func _ready() -> void:
	columns = 12
	for number in range(37):
		var button := Button.new()
		button.text = str(number)
		button.custom_minimum_size = Vector2(48, 36)
		add_child(button)
		_style_number_button(button, number)
		button.pressed.connect(_on_number_pressed.bind(button, number))
	_add_outside_bet_button("Rojo", RouletteTableState.BetType.RED)
	_add_outside_bet_button("Negro", RouletteTableState.BetType.BLACK)
	_add_outside_bet_button("Par", RouletteTableState.BetType.EVEN)
	_add_outside_bet_button("Impar", RouletteTableState.BetType.ODD)
	_add_outside_bet_button("1 a 12", RouletteTableState.BetType.DOZEN_1)
	_add_outside_bet_button("13 a 24", RouletteTableState.BetType.DOZEN_2)
	_add_outside_bet_button("25 a 36", RouletteTableState.BetType.DOZEN_3)

func _style_number_button(button: Button, number: int) -> void:
	var color := CasinoTheme.ACCENT_GREEN
	if number != 0:
		color = CasinoTheme.CARD_RED if number in RouletteTableState.RED_NUMBERS else CasinoTheme.CARD_BLACK
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = 4
	box.corner_radius_top_right = 4
	box.corner_radius_bottom_left = 4
	box.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_color_override("font_color", CasinoTheme.TEXT_LIGHT)

func _add_outside_bet_button(label: String, bet_type: int) -> void:
	var button: CasinoButton = CasinoButtonScene.instantiate()
	button.text = label
	button.custom_minimum_size = Vector2(90, 36)
	add_child(button)
	button.pressed.connect(_on_outside_bet_pressed.bind(button, bet_type, -1))

func _on_number_pressed(button: Control, number: int) -> void:
	_select(button)
	bet_selected.emit(RouletteTableState.BetType.STRAIGHT, number)

func _on_outside_bet_pressed(button: Control, bet_type: int, number: int) -> void:
	_select(button)
	bet_selected.emit(bet_type, number)

func _select(button: Control) -> void:
	if _selected_button != null and is_instance_valid(_selected_button):
		_selected_button.modulate = Color.WHITE
	_selected_button = button
	button.modulate = Color(1.3, 1.3, 0.7)
```

Nota: `_style_number_button` se llama **después** de `add_child(button)` — importante para los botones numerados (son `Button` planos, no `CasinoButton`, así que aquí no aplica, pero mantén el orden por consistencia; para `_add_outside_bet_button`, que sí instancia `CasinoButton`, el `add_child` también va antes de conectar la señal por la misma razón: `CasinoButton._ready()` debe correr antes de que cualquier otro código dependa de sus overrides de estilo).

```gdscript
# scenes/ui/casino/roulette_betting_grid.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/roulette_betting_grid.gd" id="1"]

[node name="RouletteBettingGrid" type="GridContainer"]
script = ExtResource("1")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_betting_grid.gd -gexit`
Expected: PASS, 3/3.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/roulette_betting_grid.gd scenes/ui/casino/roulette_betting_grid.tscn tests/unit/test_roulette_betting_grid.gd
git commit -m "feat(ui): add RouletteBettingGrid bet-selection component"
```

---

## Task 4: Reconstruye `scenes/roulette_table_net.tscn`

**Files:**
- Modify: `scenes/roulette_table_net.tscn` (reescritura completa)
- Test: `tests/unit/test_roulette_table_scene_structure.gd`

**Interfaces:**
- Consumes: `BetSidebarPanel`, `RouletteWheelDisplay` (Task 2), `RouletteBettingGrid` (Task 3), `CasinoButton`.
- Produces: árbol con paths `$BetSidebarPanel`, `$RouletteWheelDisplay`, `$RouletteBettingGrid`, `$ResultsHistory`, `$SpinButton`, `$SitButton`, `$SeatsLabel`, `$TableController`, consumidos por la Tarea 5.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_roulette_table_scene_structure.gd
extends GutTest

func test_scene_has_expected_node_paths():
	var scene := load("res://scenes/roulette_table_net.tscn")
	var root := scene.instantiate()
	add_child_autofree(root)
	for path in [
		"BetSidebarPanel", "RouletteWheelDisplay", "RouletteBettingGrid",
		"ResultsHistory", "SpinButton", "SitButton", "SeatsLabel", "TableController",
	]:
		assert_not_null(root.get_node_or_null(path), "falta el nodo %s" % path)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_table_scene_structure.gd -gexit`
Expected: FAIL — la escena actual no tiene esos nodos.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/roulette_table_net.tscn`:

```gdscript
[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://scenes/roulette_table_net.gd" id="1"]
[ext_resource type="Script" path="res://scripts/net/roulette_table_controller.gd" id="2"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/bet_sidebar_panel.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/roulette_wheel_display.tscn" id="4"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/roulette_betting_grid.tscn" id="5"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/casino_button.tscn" id="6"]

[node name="RouletteTableNet" type="Control"]
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

[node name="RouletteWheelDisplay" parent="." instance=ExtResource("4")]
layout_mode = 0
offset_left = 400.0
offset_top = 20.0
offset_right = 660.0
offset_bottom = 280.0

[node name="ResultsHistory" type="HBoxContainer" parent="."]
layout_mode = 0
offset_left = 680.0
offset_top = 20.0
offset_right = 900.0
offset_bottom = 60.0
theme_override_constants/separation = 6

[node name="SitButton" parent="." instance=ExtResource("6")]
layout_mode = 0
offset_left = 340.0
offset_top = 300.0
offset_right = 460.0
offset_bottom = 336.0
text = "Sentarse"

[node name="SpinButton" parent="." instance=ExtResource("6")]
layout_mode = 0
offset_left = 480.0
offset_top = 300.0
offset_right = 600.0
offset_bottom = 336.0
text = "Girar"
variant = 1

[node name="RouletteBettingGrid" parent="." instance=ExtResource("5")]
layout_mode = 0
offset_left = 20.0
offset_top = 360.0
offset_right = 880.0
offset_bottom = 520.0

[node name="SeatsLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 20.0
offset_top = 540.0
offset_right = 880.0
offset_bottom = 700.0
```

Actualiza solo el bloque de `@onready var` al principio de
`scenes/roulette_table_net.gd` (deja el resto tal cual, la Tarea 5 lo
reescribe entero):

```gdscript
@onready var table_controller: RouletteTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var wheel: RouletteWheelDisplay = $RouletteWheelDisplay
@onready var betting_grid: RouletteBettingGrid = $RouletteBettingGrid
@onready var results_history: HBoxContainer = $ResultsHistory
@onready var spin_button: Button = $SpinButton
@onready var sit_button: Button = $SitButton
@onready var seats_label: Label = $SeatsLabel
```

Si el script deja de compilar por referencias a los botones fijos que ya
no existen (`$BetRedButton`, etc.), elimínalas en este mismo paso.

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_table_scene_structure.gd -gexit`
Expected: PASS, 1/1.

- [ ] **Step 5: Commit**

```bash
git add scenes/roulette_table_net.tscn scenes/roulette_table_net.gd tests/unit/test_roulette_table_scene_structure.gd
git commit -m "feat(roulette): rebuild table scene on dark casino panel components"
```

---

## Task 5: Reescribe `roulette_table_net.gd` — selección de apuesta, giro animado, historial

**Files:**
- Modify: `scenes/roulette_table_net.gd` (reescritura completa)
- Test: `tests/unit/test_roulette_table_view.gd`

**Interfaces:**
- Consumes: `BetSidebarPanel.bet_pressed(amount)`; `RouletteBettingGrid.bet_selected(bet_type, number)`; `RouletteWheelDisplay.spin_to(result)`; `TableController.state_changed(state)` (sin cambios).
- Produces: métodos públicos `_on_bet_selected(bet_type, number)` y `_push_history(result)`, usados por el test de esta tarea.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_roulette_table_view.gd
extends GutTest

func _make_view():
	var scene := load("res://scenes/roulette_table_net.tscn")
	var view = scene.instantiate()
	add_child_autofree(view)
	return view

func test_bet_selected_updates_pending_selection():
	var view = _make_view()
	view._on_bet_selected(RouletteTableState.BetType.BLACK, -1)
	assert_eq(view._selected_bet_type, RouletteTableState.BetType.BLACK)
	assert_eq(view._selected_number, -1)

func test_push_history_keeps_at_most_max_history_badges():
	var view = _make_view()
	for i in range(9):
		view._push_history(i % 37)
	assert_true(view.results_history.get_child_count() <= 8)

func test_bet_pressed_calls_place_bet_with_selected_type_and_number():
	var view = _make_view()
	view.table_controller.table_state = RouletteTableState.new()
	view.table_controller.table_state.sit(0, multiplayer.get_unique_id())
	view.my_seat_index = 0
	view._on_bet_selected(RouletteTableState.BetType.STRAIGHT, 7)
	view.bet_sidebar.amount = 100
	view.bet_sidebar.bet_pressed.emit(100)
	assert_eq(view.table_controller.table_state.seats[0].bets.size(), 1)
	assert_eq(view.table_controller.table_state.seats[0].bets[0].number, 7)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_table_view.gd -gexit`
Expected: FAIL — `_on_bet_selected`/`_push_history`/`_selected_bet_type` no existen todavía.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/roulette_table_net.gd`:

```gdscript
extends Control

const RouletteResultBadgeScene := preload("res://scenes/ui/casino/roulette_result_badge.tscn")
const MAX_HISTORY := 8

@onready var table_controller: RouletteTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var wheel: RouletteWheelDisplay = $RouletteWheelDisplay
@onready var betting_grid: RouletteBettingGrid = $RouletteBettingGrid
@onready var results_history: HBoxContainer = $ResultsHistory
@onready var spin_button: Button = $SpinButton
@onready var sit_button: Button = $SitButton
@onready var seats_label: Label = $SeatsLabel

var my_seat_index: int = -1
var _last_seats: Array = []
var _selected_bet_type: int = RouletteTableState.BetType.RED
var _selected_number: int = -1
var _history: Array = []

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	table_controller.state_changed.connect(_on_state_changed)
	bet_sidebar.bet_pressed.connect(_on_bet_pressed)
	betting_grid.bet_selected.connect(_on_bet_selected)
	sit_button.pressed.connect(_on_sit_pressed)
	spin_button.pressed.connect(_on_spin_pressed)
	NetworkManager.identities_changed.connect(_refresh_seats_label)
	if not multiplayer.is_server():
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			sit_button.disabled = true
			multiplayer.connected_to_server.connect(func():
				sit_button.disabled = false
				table_controller.request_state()
			)
		else:
			table_controller.request_state()

func _on_sit_pressed() -> void:
	var seat_index := 0
	for i in range(_last_seats.size()):
		if _last_seats[i] == null:
			seat_index = i
			break
	table_controller.sit(seat_index)
	my_seat_index = seat_index

func _on_bet_selected(bet_type: int, number: int) -> void:
	_selected_bet_type = bet_type
	_selected_number = number

func _on_bet_pressed(amount: int) -> void:
	table_controller.place_bet(my_seat_index, _selected_bet_type, _selected_number, amount)

func _on_spin_pressed() -> void:
	table_controller.spin(my_seat_index)

func _on_state_changed(state: Dictionary) -> void:
	_last_seats = state["seats"]
	_refresh_seats_label()
	var new_result: int = state["last_result"]
	if new_result != -1 and (_history.is_empty() or _history[0] != new_result):
		_push_history(new_result)
		wheel.spin_to(new_result)

func _push_history(result: int) -> void:
	_history.push_front(result)
	if _history.size() > MAX_HISTORY:
		_history.resize(MAX_HISTORY)
	for child in results_history.get_children():
		child.queue_free()
	for n in _history:
		var badge: RouletteResultBadge = RouletteResultBadgeScene.instantiate()
		results_history.add_child(badge)
		badge.number = n

func _refresh_seats_label() -> void:
	var lines: Array[String] = []
	for i in range(_last_seats.size()):
		var seat = _last_seats[i]
		if seat == null:
			lines.append("Asiento %d: libre" % i)
		else:
			lines.append("Asiento %d: %s — fichas %d — apuestas activas %d" % [
				i, _display_name(seat["player_id"]), seat["balance"], seat["bets"].size()
			])
	seats_label.text = "\n".join(lines)
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_table_view.gd -gexit`
Expected: PASS, 3/3.

- [ ] **Step 5: Commit**

```bash
git add scenes/roulette_table_net.gd tests/unit/test_roulette_table_view.gd
git commit -m "feat(roulette): wire bet selection, animated spin and result history to dark panel UI"
```

---

## Task 6: Suite completa + verificación visual manual

**Files:** ninguno nuevo — solo verificación.

- [ ] **Step 1: Reconstruye la caché de clases**

Run: `godot --headless --editor --quit --path .`. Revisa `git status` después — descarta con `git checkout -- <archivo>` cualquier reformateo de espacios/tabs en archivos que no tocaste.

- [ ] **Step 2: Corre la suite completa de GUT**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests en verde, incluidos los nuevos de este plan y los de Dice/Blackjack/Modo Batalla sin romperse.

- [ ] **Step 3: Verificación visual manual**

Con Steam corriendo, lanza el proyecto, entra a la mesa de Ruleta.
Confirma:
- Panel lateral oscuro reutilizado (idéntico a Dice).
- Rueda dibujada con sectores rojo/negro/verde correctos.
- Grid de 37 números clicable, coloreado, con Rojo/Negro/Par/Impar/Docenas debajo.
- Clicar una celda la resalta; solo se apuesta al pulsar "Hacer apuesta".
- Al pulsar "Girar", la rueda gira animada y se detiene en el número real que devolvió el backend.
- El historial de resultados recientes se actualiza con la insignia de color correcto.

No cierres esta fase sin que el usuario confirme el punto anterior en vivo.

- [ ] **Step 4: Commit final (si algo quedó sin commitear)**

```bash
git status
git add -A
git commit -m "chore: verify roulette visual reskin end to end" --allow-empty
```

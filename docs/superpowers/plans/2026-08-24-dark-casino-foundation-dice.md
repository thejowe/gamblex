# Fundación de Casino Oscuro + Reskin de Dice — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir el panel lateral de apuesta reutilizable (monto + 1/2/x2/Máx + botón de apostar) que comparten las 5 referencias de estilo "casino oscuro" (Ruleta, Dice, Crash, Mines, Plinko), y aplicar la estética completa a Dice — slider de umbral arrastrable, cajas de multiplicador/probabilidad, flash de resultado.

**Architecture:** `BetSidebarPanel` (`scripts/ui/casino/`) es la única pieza pensada para las 5 mesas; `DiceThresholdSlider` es específico de Dice. Ambos son presentacionales puros — no tocan `scripts/dice/`, que ya expone todo lo necesario (`win_chance`, `multiplier`, `to_dict()`). `CasinoTheme` (Plan 14) gana constantes de color nuevas, no se duplica.

**Tech Stack:** Godot 4.7 / GDScript, GUT.

**Spec:** `docs/superpowers/specs/2026-08-24-dark-casino-foundation-dice-design.md` (léela completa antes de empezar).

## Global Constraints

- No tocar `scripts/dice/dice_roller.gd`, `scripts/dice/dice_table_state.gd`, `scripts/net/dice_table_controller.gd` — la lógica ya es correcta y suficiente, este plan es 100% visual.
- No tocar `scripts/ui/casino/felt_table_panel.gd`, `playing_card.gd`, `casino_chip.gd` (Blackjack, lenguaje visual distinto) — solo se extiende `casino_theme.gd` con constantes nuevas.
- `CasinoButton`/`CasinoHudBar` (Plan 14) sí se reutilizan tal cual, ya son genéricos.
- Cero archivos de imagen — todo `_draw()`/`StyleBoxFlat`, igual que Plan 14.
- Trabaja en worktree aislado, rama `feature/dark-casino-foundation-dice`.
- Godot: `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`. Reconstruye caché de clases antes de confiar en GUT; revisa `git status` después por reformateo espacios/tabs.

---

## Task 1: `CasinoTheme` — paleta de panel oscuro

**Files:**
- Modify: `scripts/ui/casino/casino_theme.gd`
- Test: `tests/unit/test_casino_theme.gd` (añade al final)

**Interfaces:**
- Produces: 7 constantes `Color` nuevas (`PANEL_NAVY_DARK`, `PANEL_NAVY_MID`, `PANEL_NAVY_LIGHT`, `ACCENT_GREEN`, `ACCENT_RED`, `TEXT_LIGHT`, `TEXT_MUTED`). Las Tareas 2-5 las consumen.

- [ ] **Step 1: Escribe el test que falla**

Añade al final de `tests/unit/test_casino_theme.gd`:

```gdscript
func test_dark_panel_palette_constants_are_colors():
	assert_true(CasinoTheme.PANEL_NAVY_DARK is Color)
	assert_true(CasinoTheme.PANEL_NAVY_MID is Color)
	assert_true(CasinoTheme.PANEL_NAVY_LIGHT is Color)
	assert_true(CasinoTheme.ACCENT_GREEN is Color)
	assert_true(CasinoTheme.ACCENT_RED is Color)
	assert_true(CasinoTheme.TEXT_LIGHT is Color)
	assert_true(CasinoTheme.TEXT_MUTED is Color)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_theme.gd -gexit`
Expected: FAIL — las constantes no existen todavía.

- [ ] **Step 3: Implementa**

Añade al final de `scripts/ui/casino/casino_theme.gd` (después de `chip_color`):

```gdscript
const PANEL_NAVY_DARK := Color("131b26")
const PANEL_NAVY_MID := Color("1c2733")
const PANEL_NAVY_LIGHT := Color("28374a")
const ACCENT_GREEN := Color("4caf6e")
const ACCENT_RED := Color("d9534f")
const TEXT_LIGHT := Color("e8edf2")
const TEXT_MUTED := Color("7c8a9a")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_theme.gd -gexit`
Expected: PASS, todos los tests del archivo.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/casino_theme.gd tests/unit/test_casino_theme.gd
git commit -m "feat(ui): add dark casino panel palette to CasinoTheme"
```

---

## Task 2: `BetSidebarPanel` — panel de apuesta compartido

**Files:**
- Create: `scripts/ui/casino/bet_sidebar_panel.gd`
- Create: `scenes/ui/casino/bet_sidebar_panel.tscn`
- Test: `tests/unit/test_bet_sidebar_panel.gd`

**Interfaces:**
- Consumes: `CasinoTheme.PANEL_NAVY_MID/TEXT_LIGHT` (Task 1); `CasinoButton` (Plan 14, `scenes/ui/casino/casino_button.tscn`).
- Produces: `class_name BetSidebarPanel extends PanelContainer`, propiedades `amount: int`, `max_amount: int`, señal `bet_pressed(amount: int)`, método `set_max_amount(value: int) -> void`. Las Tareas 4-5 (Dice) y los Planes 17-20 (Ruleta/Crash/Mines/Plinko) lo instancian igual.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_bet_sidebar_panel.gd
extends GutTest

func _make_panel() -> BetSidebarPanel:
	var panel: BetSidebarPanel = load("res://scenes/ui/casino/bet_sidebar_panel.tscn").instantiate()
	add_child_autofree(panel)
	return panel

func test_default_amount_is_ten():
	var panel := _make_panel()
	assert_eq(panel.amount, 10)

func test_amount_setter_clamps_to_at_least_one():
	var panel := _make_panel()
	panel.amount = -5
	assert_eq(panel.amount, 1)

func test_amount_setter_clamps_to_max_amount():
	var panel := _make_panel()
	panel.max_amount = 200
	panel.amount = 9999
	assert_eq(panel.amount, 200)

func test_half_button_halves_amount_with_minimum_one():
	var panel := _make_panel()
	panel.amount = 10
	panel._on_half_pressed()
	assert_eq(panel.amount, 5)
	panel.amount = 1
	panel._on_half_pressed()
	assert_eq(panel.amount, 1)

func test_double_button_doubles_amount_clamped_to_max():
	var panel := _make_panel()
	panel.max_amount = 100
	panel.amount = 60
	panel._on_double_pressed()
	assert_eq(panel.amount, 100) # 120 clamped a max_amount

func test_max_button_sets_amount_to_max_amount():
	var panel := _make_panel()
	panel.max_amount = 300
	panel._on_max_pressed()
	assert_eq(panel.amount, 300)

func test_bet_button_emits_bet_pressed_with_current_amount():
	var panel := _make_panel()
	panel.amount = 42
	watch_signals(panel)
	panel._on_bet_pressed()
	assert_signal_emitted_with_parameters(panel, "bet_pressed", [42])
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_bet_sidebar_panel.gd -gexit`
Expected: FAIL — la escena no existe todavía.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/bet_sidebar_panel.gd
class_name BetSidebarPanel
extends PanelContainer

signal bet_pressed(amount: int)

@onready var amount_edit: LineEdit = $Margin/VBox/AmountRow/AmountEdit
@onready var bet_button: CasinoButton = $Margin/VBox/BetButton

@export var max_amount: int = 500

@export var amount: int = 10:
	set(value):
		amount = clampi(value, 1, max_amount)
		if is_inside_tree():
			amount_edit.text = str(amount)

func _ready() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = CasinoTheme.PANEL_NAVY_MID
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", box)
	amount_edit.text = str(amount)
	amount_edit.text_submitted.connect(func(new_text: String): amount = int(new_text))
	bet_button.pressed.connect(_on_bet_pressed)

func set_max_amount(value: int) -> void:
	max_amount = value
	amount = amount # re-clamp contra el nuevo tope

func _on_half_pressed() -> void:
	amount = amount / 2

func _on_double_pressed() -> void:
	amount = amount * 2

func _on_max_pressed() -> void:
	amount = max_amount

func _on_bet_pressed() -> void:
	bet_pressed.emit(amount)
```

```gdscript
# scenes/ui/casino/bet_sidebar_panel.tscn
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/bet_sidebar_panel.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/casino_button.tscn" id="2"]

[node name="BetSidebarPanel" type="PanelContainer"]
custom_minimum_size = Vector2(280, 0)
script = ExtResource("1")

[node name="Margin" type="MarginContainer" parent="."]
layout_mode = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 16
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 16

[node name="VBox" type="VBoxContainer" parent="Margin"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="AmountLabel" type="Label" parent="Margin/VBox"]
layout_mode = 2
text = "Monto de la apuesta"

[node name="AmountRow" type="HBoxContainer" parent="Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="AmountEdit" type="LineEdit" parent="Margin/VBox/AmountRow"]
layout_mode = 2
size_flags_horizontal = 3
text = "10"

[node name="HalfButton" parent="Margin/VBox/AmountRow" instance=ExtResource("2")]
layout_mode = 2
custom_minimum_size = Vector2(48, 0)
text = "1/2"

[node name="DoubleButton" parent="Margin/VBox/AmountRow" instance=ExtResource("2")]
layout_mode = 2
custom_minimum_size = Vector2(48, 0)
text = "x2"

[node name="MaxButton" parent="Margin/VBox/AmountRow" instance=ExtResource("2")]
layout_mode = 2
custom_minimum_size = Vector2(52, 0)
text = "Máx"

[node name="BetButton" parent="Margin/VBox" instance=ExtResource("2")]
layout_mode = 2
custom_minimum_size = Vector2(0, 48)
text = "Hacer apuesta"
variant = 1
```

Conecta los tres botones de la fila a sus handlers — añade al final de
`_ready()` en `bet_sidebar_panel.gd` (después de `bet_button.pressed.connect(...)`):

```gdscript
	$Margin/VBox/AmountRow/HalfButton.pressed.connect(_on_half_pressed)
	$Margin/VBox/AmountRow/DoubleButton.pressed.connect(_on_double_pressed)
	$Margin/VBox/AmountRow/MaxButton.pressed.connect(_on_max_pressed)
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_bet_sidebar_panel.gd -gexit`
Expected: PASS, 7/7.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/bet_sidebar_panel.gd scenes/ui/casino/bet_sidebar_panel.tscn tests/unit/test_bet_sidebar_panel.gd
git commit -m "feat(ui): add shared BetSidebarPanel component"
```

---

## Task 3: `DiceThresholdSlider` — slider de umbral arrastrable

**Files:**
- Create: `scripts/ui/casino/dice_threshold_slider.gd`
- Create: `scenes/ui/casino/dice_threshold_slider.tscn`
- Test: `tests/unit/test_dice_threshold_slider.gd`

**Interfaces:**
- Consumes: `CasinoTheme.ACCENT_GREEN/ACCENT_RED/PANEL_NAVY_LIGHT` (Task 1); `DiceTableState.Direction` (ya existente, `scripts/dice/dice_table_state.gd`).
- Produces: `class_name DiceThresholdSlider extends Control`, propiedades `threshold: int`, `direction: int`, señal `threshold_changed(value: int)`, método `set_threshold_from_x(local_x: float) -> void` (usado internamente por `_gui_input` y directamente por el test para simular un drag sin necesitar eventos de ratón reales).

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_dice_threshold_slider.gd
extends GutTest

func _make_slider() -> DiceThresholdSlider:
	var slider: DiceThresholdSlider = load("res://scenes/ui/casino/dice_threshold_slider.tscn").instantiate()
	add_child_autofree(slider)
	slider.size = Vector2(600, 40)
	return slider

func test_default_threshold_is_fifty():
	var slider := _make_slider()
	assert_eq(slider.threshold, 50)

func test_set_threshold_from_x_clamps_to_one_and_ninety_nine():
	var slider := _make_slider()
	slider.set_threshold_from_x(-100.0)
	assert_eq(slider.threshold, 1)
	slider.set_threshold_from_x(10000.0)
	assert_eq(slider.threshold, 99)

func test_set_threshold_from_x_maps_middle_to_fifty():
	var slider := _make_slider()
	slider.set_threshold_from_x(300.0) # mitad de 600px de ancho
	assert_eq(slider.threshold, 50)

func test_set_threshold_from_x_emits_threshold_changed():
	var slider := _make_slider()
	watch_signals(slider)
	slider.set_threshold_from_x(0.0)
	assert_signal_emitted_with_parameters(slider, "threshold_changed", [1])
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_dice_threshold_slider.gd -gexit`
Expected: FAIL — la escena no existe todavía.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/dice_threshold_slider.gd
class_name DiceThresholdSlider
extends Control

signal threshold_changed(value: int)

const HANDLE_RADIUS := 12.0
const TRACK_HEIGHT := 10.0

@export var threshold: int = 50:
	set(value):
		threshold = clampi(value, 1, 99)
		queue_redraw()
# DiceTableState.Direction.UNDER (el enum es { OVER, UNDER }, así que
# UNDER = 1) — se pone aquí como valor literal porque los componentes de
# `scripts/ui/casino/` no dependen de clases de un juego concreto salvo
# donde es inevitable (aquí sí lo es, `DiceThresholdSlider` es específico
# de Dice); el valor 1 y `DiceTableState.Direction.UNDER` son
# intercambiables, usa el enum con nombre en cualquier código nuevo que
# escribas para evitar el número mágico.
@export var direction: int = DiceTableState.Direction.UNDER:
	set(value):
		direction = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(0, 40)

func set_threshold_from_x(local_x: float) -> void:
	var ratio: float = clampf(local_x / size.x, 0.0, 1.0)
	threshold = clampi(roundi(1.0 + ratio * 98.0), 1, 99)
	threshold_changed.emit(threshold)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		set_threshold_from_x(event.position.x)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		set_threshold_from_x(event.position.x)

func _draw() -> void:
	var track_y := size.y / 2.0
	var handle_x := (float(threshold - 1) / 98.0) * size.x
	# UNDER gana tirando por debajo del umbral -> la zona ganadora (verde)
	# es la izquierda del tirador; OVER gana por encima -> verde a la derecha.
	var win_is_left := direction == DiceTableState.Direction.UNDER
	var left_color := CasinoTheme.ACCENT_GREEN if win_is_left else CasinoTheme.ACCENT_RED
	var right_color := CasinoTheme.ACCENT_RED if win_is_left else CasinoTheme.ACCENT_GREEN
	draw_rect(Rect2(0, track_y - TRACK_HEIGHT / 2.0, handle_x, TRACK_HEIGHT), left_color)
	draw_rect(Rect2(handle_x, track_y - TRACK_HEIGHT / 2.0, size.x - handle_x, TRACK_HEIGHT), right_color)
	draw_circle(Vector2(handle_x, track_y), HANDLE_RADIUS, CasinoTheme.TEXT_LIGHT)
	draw_arc(Vector2(handle_x, track_y), HANDLE_RADIUS, 0, TAU, 24, CasinoTheme.PANEL_NAVY_LIGHT, 2.0)
```

```gdscript
# scenes/ui/casino/dice_threshold_slider.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/dice_threshold_slider.gd" id="1"]

[node name="DiceThresholdSlider" type="Control"]
layout_mode = 3
script = ExtResource("1")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_dice_threshold_slider.gd -gexit`
Expected: PASS, 4/4.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/dice_threshold_slider.gd scenes/ui/casino/dice_threshold_slider.tscn tests/unit/test_dice_threshold_slider.gd
git commit -m "feat(ui): add DiceThresholdSlider component"
```

---

## Task 4: Reconstruye `scenes/dice_table_net.tscn`

**Files:**
- Modify: `scenes/dice_table_net.tscn` (reescritura completa del árbol)
- Test: `tests/unit/test_dice_table_scene_structure.gd`

**Interfaces:**
- Consumes: `BetSidebarPanel` (Task 2), `DiceThresholdSlider` (Task 3), `CasinoButton` (Plan 14).
- Produces: árbol de nodos con los paths que consume la Tarea 5: `$BetSidebarPanel`, `$OverButton`, `$UnderButton`, `$MultiplierLabel`, `$ProbabilityLabel`, `$ThresholdSlider`, `$ResultFlash`, `$PlayersLabel`, `$TableController`.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_dice_table_scene_structure.gd
extends GutTest

func test_scene_has_expected_node_paths():
	var scene := load("res://scenes/dice_table_net.tscn")
	var root := scene.instantiate()
	add_child_autofree(root)
	for path in [
		"BetSidebarPanel", "OverButton", "UnderButton", "MultiplierLabel",
		"ProbabilityLabel", "ThresholdSlider", "ResultFlash", "PlayersLabel",
		"TableController",
	]:
		assert_not_null(root.get_node_or_null(path), "falta el nodo %s" % path)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_dice_table_scene_structure.gd -gexit`
Expected: FAIL — la escena actual no tiene esos nodos.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/dice_table_net.tscn`:

```gdscript
[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://scenes/dice_table_net.gd" id="1"]
[ext_resource type="Script" path="res://scripts/net/dice_table_controller.gd" id="2"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/bet_sidebar_panel.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/casino_button.tscn" id="4"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/dice_threshold_slider.tscn" id="5"]

[node name="DiceTableNet" type="Control"]
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

[node name="OverButton" parent="." instance=ExtResource("4")]
layout_mode = 0
offset_left = 340.0
offset_top = 20.0
offset_right = 500.0
offset_bottom = 56.0
text = "Mayor que"

[node name="UnderButton" parent="." instance=ExtResource("4")]
layout_mode = 0
offset_left = 520.0
offset_top = 20.0
offset_right = 680.0
offset_bottom = 56.0
text = "Menor que"
variant = 1

[node name="MultiplierLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 80.0
offset_right = 560.0
offset_bottom = 110.0
text = "Multiplicador: 1.98x"

[node name="ProbabilityLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 116.0
offset_right = 560.0
offset_bottom = 146.0
text = "Probabilidad: 50.00%"

[node name="ThresholdSlider" parent="." instance=ExtResource("5")]
layout_mode = 0
offset_left = 340.0
offset_top = 200.0
offset_right = 900.0
offset_bottom = 240.0

[node name="ResultFlash" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 60.0
offset_right = 900.0
offset_bottom = 260.0
color = Color(1, 1, 1, 0)
mouse_filter = 2

[node name="PlayersLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 300.0
offset_right = 900.0
offset_bottom = 500.0
text = "Nadie ha tirado todavía."
```

Actualiza solo el bloque de `@onready var` al principio de
`scenes/dice_table_net.gd` (deja el resto del script tal cual por ahora,
la Tarea 5 lo reescribe entero):

```gdscript
@onready var table_controller: DiceTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var over_button: Button = $OverButton
@onready var under_button: Button = $UnderButton
@onready var multiplier_label: Label = $MultiplierLabel
@onready var probability_label: Label = $ProbabilityLabel
@onready var threshold_slider: DiceThresholdSlider = $ThresholdSlider
@onready var result_flash: ColorRect = $ResultFlash
@onready var players_label: Label = $PlayersLabel
```

Si el script deja de compilar por referencias a `$ThresholdSpinBox`/
`$AmountSpinBox`/`$BetOverButton`/`$BetUnderButton` que ya no existen,
elimínalas de este mismo paso (no son parte de la interfaz que otras
tareas consumen) — la Tarea 5 reescribe toda la lógica de todas formas.

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_dice_table_scene_structure.gd -gexit`
Expected: PASS, 1/1.

- [ ] **Step 5: Commit**

```bash
git add scenes/dice_table_net.tscn scenes/dice_table_net.gd tests/unit/test_dice_table_scene_structure.gd
git commit -m "feat(dice): rebuild table scene on dark casino panel components"
```

---

## Task 5: Reescribe `dice_table_net.gd` — dirección, stats en vivo, flash de resultado

**Files:**
- Modify: `scenes/dice_table_net.gd` (reescritura completa)
- Test: `tests/unit/test_dice_table_view.gd`

**Interfaces:**
- Consumes: `BetSidebarPanel.bet_pressed(amount)` (Task 2); `DiceThresholdSlider.threshold`/`direction`/`threshold_changed` (Task 3); `DiceTableState.win_chance()`/`multiplier()` (ya existentes); `TableController.state_changed(state)` (ya existente, sin cambios).
- Produces: método público `_refresh_stats() -> void` y `_apply_direction(new_direction: int) -> void`, usados por el test de esta tarea para verificar la lógica sin pasar por RPCs reales.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_dice_table_view.gd
extends GutTest

func _make_view():
	var scene := load("res://scenes/dice_table_net.tscn")
	var view = scene.instantiate()
	add_child_autofree(view)
	return view

func test_refresh_stats_shows_multiplier_and_probability_for_current_threshold():
	var view = _make_view()
	view.threshold_slider.threshold = 40
	view.threshold_slider.direction = DiceTableState.Direction.OVER
	view._refresh_stats()
	var expected_mult := DiceTableState.multiplier(40, DiceTableState.Direction.OVER)
	assert_true(view.multiplier_label.text.contains("%.2f" % expected_mult))
	var expected_chance := DiceTableState.win_chance(40, DiceTableState.Direction.OVER)
	assert_true(view.probability_label.text.contains("%.2f" % expected_chance))

func test_apply_direction_updates_slider_and_refreshes_stats():
	var view = _make_view()
	view._apply_direction(DiceTableState.Direction.OVER)
	assert_eq(view.threshold_slider.direction, DiceTableState.Direction.OVER)
	assert_true(view.multiplier_label.text.length() > 0)

func test_bet_sidebar_press_calls_roll_with_slider_threshold_and_direction():
	var view = _make_view()
	view.table_controller.table_state = DiceTableState.new()
	view.threshold_slider.threshold = 30
	view._apply_direction(DiceTableState.Direction.UNDER)
	view.bet_sidebar.amount = 25
	view.bet_sidebar.bet_pressed.emit(25)
	assert_true(view.table_controller.table_state.players.has(multiplayer.get_unique_id()))
```

(El tercer test asume que `TableController._apply_roll`/`table_state.roll`
se invoca directo, sin `.rpc()`, cuando se es servidor — igual que ya
verifican los tests de `table_controller.gd` de Plan 15, ver
`multiplayer.is_server()` por defecto en `true` sin peer configurado.)

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_dice_table_view.gd -gexit`
Expected: FAIL — `_refresh_stats`/`_apply_direction` no existen todavía.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/dice_table_net.gd`:

```gdscript
extends Control

@onready var table_controller: DiceTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var over_button: Button = $OverButton
@onready var under_button: Button = $UnderButton
@onready var multiplier_label: Label = $MultiplierLabel
@onready var probability_label: Label = $ProbabilityLabel
@onready var threshold_slider: DiceThresholdSlider = $ThresholdSlider
@onready var result_flash: ColorRect = $ResultFlash
@onready var players_label: Label = $PlayersLabel

var _last_players: Dictionary = {}
var _last_round_seen: Dictionary = {}

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	table_controller.state_changed.connect(_on_state_changed)
	bet_sidebar.bet_pressed.connect(_on_bet_pressed)
	threshold_slider.threshold_changed.connect(func(_value): _refresh_stats())
	over_button.pressed.connect(func(): _apply_direction(DiceTableState.Direction.OVER))
	under_button.pressed.connect(func(): _apply_direction(DiceTableState.Direction.UNDER))
	NetworkManager.identities_changed.connect(_refresh_players_label)
	_apply_direction(DiceTableState.Direction.UNDER)
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

func _apply_direction(new_direction: int) -> void:
	threshold_slider.direction = new_direction
	over_button.variant = CasinoButton.Variant.POSITIVE if new_direction == DiceTableState.Direction.OVER else CasinoButton.Variant.NEUTRAL
	under_button.variant = CasinoButton.Variant.POSITIVE if new_direction == DiceTableState.Direction.UNDER else CasinoButton.Variant.NEUTRAL
	_refresh_stats()

func _refresh_stats() -> void:
	var threshold := threshold_slider.threshold
	var direction := threshold_slider.direction
	var mult := DiceTableState.multiplier(threshold, direction)
	var chance := DiceTableState.win_chance(threshold, direction)
	multiplier_label.text = "Multiplicador: %.2fx" % mult
	probability_label.text = "Probabilidad: %.2f%%" % chance

func _on_bet_pressed(amount: int) -> void:
	table_controller.roll(threshold_slider.threshold, threshold_slider.direction, amount)

func _on_state_changed(state: Dictionary) -> void:
	_last_players = state["players"]
	_refresh_players_label()
	_maybe_flash_result()

func _maybe_flash_result() -> void:
	var my_id := multiplayer.get_unique_id()
	if not _last_players.has(my_id):
		return
	var last_round: Dictionary = _last_players[my_id]["last_round"]
	if last_round.is_empty():
		return
	if _last_round_seen.get(my_id, {}) == last_round:
		return
	_last_round_seen[my_id] = last_round
	var flash_color: Color = CasinoTheme.ACCENT_GREEN if last_round["win"] else CasinoTheme.ACCENT_RED
	var tween := create_tween()
	result_flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.35)
	tween.tween_property(result_flash, "color:a", 0.0, 0.6)

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
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_dice_table_view.gd -gexit`
Expected: PASS, 3/3.

- [ ] **Step 5: Commit**

```bash
git add scenes/dice_table_net.gd tests/unit/test_dice_table_view.gd
git commit -m "feat(dice): wire direction toggle, live stats and result flash to dark panel UI"
```

---

## Task 6: Suite completa + verificación visual manual

**Files:** ninguno nuevo — solo verificación.

- [ ] **Step 1: Reconstruye la caché de clases**

Run: `godot --headless --editor --quit --path .`. Revisa `git status` después — descarta con `git checkout -- <archivo>` cualquier reformateo de espacios/tabs en archivos que no tocaste.

- [ ] **Step 2: Corre la suite completa de GUT**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests en verde, incluidos los nuevos de este plan, y que ningún test de Blackjack/Modo Batalla se haya roto.

- [ ] **Step 3: Verificación visual manual**

Con Steam corriendo, lanza el proyecto, entra a la mesa de Dice. Confirma:
- Panel lateral oscuro con monto de apuesta, botones 1/2 · x2 · Máx, botón verde "Hacer apuesta".
- Botones "Mayor que"/"Menor que" resaltan el activo (verde) sin lanzar la tirada por sí solos.
- El slider se puede arrastrar, cambia el umbral, y el multiplicador/probabilidad se actualizan en vivo mientras arrastras.
- El lado verde/rojo del slider coincide con la dirección elegida.
- Al pulsar "Hacer apuesta" se lanza la tirada y aparece un flash verde (gana) o rojo (pierde) breve.
- El listado de jugadores/tiradas recientes sigue viéndose debajo.

No cierres esta fase sin que el usuario confirme el punto anterior en vivo.

- [ ] **Step 4: Commit final (si algo quedó sin commitear)**

```bash
git status
git add -A
git commit -m "chore: verify dark casino foundation + Dice reskin end to end" --allow-empty
```

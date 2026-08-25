# Fix: Grid de Ruleta se Sale de la Ventana — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Arreglar el grid de 37 números de Ruleta, que hoy corta los números de la derecha de cada fila (11, 23, 35...) fuera de la ventana porque comparte `GridContainer`/columnas con los 7 botones de apuesta de fuera, más anchos.

**Architecture:** `RouletteBettingGrid` pasa de `extends GridContainer` a `extends VBoxContainer` con dos `GridContainer` hijos independientes — uno solo para los 37 números (`columns = 12`), otro solo para las 7 apuestas de fuera (`columns = 7`) — así ninguno contamina el ancho de columna del otro. Interfaz pública sin cambios.

**Tech Stack:** Godot 4.7 / GDScript, GUT.

**Spec:** `docs/superpowers/specs/2026-08-24-roulette-grid-overflow-fix-design.md` (léela completa antes de empezar).

## Global Constraints

- Modificas **solo** `scripts/ui/casino/roulette_betting_grid.gd`, `scenes/ui/casino/roulette_betting_grid.tscn` y `tests/unit/test_roulette_betting_grid.gd`. Ningún otro archivo — ni `roulette_table_net.gd`/`.tscn`, ni ninguna otra mesa.
- No cambies el comportamiento de apostar-al-clic (confirmado y aceptado por el usuario en Plan 17) — este plan es un fix de layout puro.
- No cambies la señal pública `bet_selected` ni las firmas de `_on_number_pressed`/`_on_outside_bet_pressed` — otros archivos ya los usan tal cual.
- Trabaja en worktree aislado, rama `feature/roulette-grid-overflow-fix`.
- Godot: `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`. Reconstruye caché de clases antes de confiar en GUT; revisa `git status` después por reformateo espacios/tabs.

---

## Task 1: Separa números y apuestas de fuera en dos `GridContainer` independientes

**Files:**
- Modify: `scripts/ui/casino/roulette_betting_grid.gd` (reescritura completa)
- Modify: `scenes/ui/casino/roulette_betting_grid.tscn`
- Modify: `tests/unit/test_roulette_betting_grid.gd`

**Interfaces:**
- Consumes: `CasinoButton` (Plan 14, sin cambios); `RouletteTableState.BetType`/`RED_NUMBERS` (sin cambios).
- Produces: `class_name RouletteBettingGrid extends VBoxContainer` (antes `extends GridContainer`), con `_number_grid: GridContainer` y `_outside_bets_row: GridContainer` como propiedades internas. La señal `bet_selected(bet_type, number)` y los métodos `_on_number_pressed`/`_on_outside_bet_pressed` mantienen exactamente la misma firma — `roulette_table_net.gd` no necesita ningún cambio.

- [ ] **Step 1: Escribe los tests que fallan**

Reemplaza el contenido completo de `tests/unit/test_roulette_betting_grid.gd`:

```gdscript
extends GutTest

func _make_grid() -> RouletteBettingGrid:
	var grid: RouletteBettingGrid = load("res://scenes/ui/casino/roulette_betting_grid.tscn").instantiate()
	add_child_autofree(grid)
	return grid

func test_grid_creates_37_number_buttons():
	var grid := _make_grid()
	assert_eq(grid._number_grid.get_child_count(), 37)

func test_number_buttons_and_outside_bets_are_in_separate_containers():
	var grid := _make_grid()
	assert_eq(grid._outside_bets_row.get_child_count(), 7)
	for child in grid._number_grid.get_children():
		assert_true(child.text.is_valid_int(), "un botón de apuesta de fuera se coló en el grid de números")
	for child in grid._outside_bets_row.get_children():
		assert_false(child.text.is_valid_int(), "un botón de número se coló en la fila de apuestas de fuera")

func test_number_grid_and_outside_bets_row_fit_within_design_width():
	var grid := _make_grid()
	const DESIGN_WIDTH := 860.0 # ancho real del contenedor en roulette_table_net.tscn (880-20)
	var number_grid_width: float = grid._number_grid.columns * 48.0
	var outside_bets_width: float = grid._outside_bets_row.columns * 96.0
	assert_true(number_grid_width <= DESIGN_WIDTH, "el grid de números por sí solo ya no cabe")
	assert_true(outside_bets_width <= DESIGN_WIDTH, "la fila de apuestas de fuera por sí sola ya no cabe")

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

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_betting_grid.gd -gexit`
Expected: FAIL — `grid._number_grid`/`grid._outside_bets_row` no existen todavía (el `RouletteBettingGrid` actual mete todo en `self`).

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scripts/ui/casino/roulette_betting_grid.gd`:

```gdscript
class_name RouletteBettingGrid
extends VBoxContainer

signal bet_selected(bet_type: int, number: int)

const CasinoButtonScene := preload("res://scenes/ui/casino/casino_button.tscn")
const NUMBER_CELL_SIZE := Vector2(48, 36)
const OUTSIDE_BET_CELL_SIZE := Vector2(96, 36)

var _selected_button: Control = null
var _number_grid: GridContainer
var _outside_bets_row: GridContainer

func _ready() -> void:
	_number_grid = GridContainer.new()
	_number_grid.columns = 12
	add_child(_number_grid)
	for number in range(37):
		var button := Button.new()
		button.text = str(number)
		button.custom_minimum_size = NUMBER_CELL_SIZE
		_number_grid.add_child(button)
		_style_number_button(button, number)
		button.pressed.connect(_on_number_pressed.bind(button, number))

	_outside_bets_row = GridContainer.new()
	_outside_bets_row.columns = 7
	add_child(_outside_bets_row)
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
	button.custom_minimum_size = OUTSIDE_BET_CELL_SIZE
	_outside_bets_row.add_child(button)
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

Reemplaza `scenes/ui/casino/roulette_betting_grid.tscn` (solo cambia el
`type` del nodo raíz de `GridContainer` a `VBoxContainer`):

```gdscript
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/roulette_betting_grid.gd" id="1"]

[node name="RouletteBettingGrid" type="VBoxContainer"]
script = ExtResource("1")
```

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_roulette_betting_grid.gd -gexit`
Expected: PASS, 5/5.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/roulette_betting_grid.gd scenes/ui/casino/roulette_betting_grid.tscn tests/unit/test_roulette_betting_grid.gd
git commit -m "fix(roulette): separate number grid and outside-bet row into independent GridContainers"
```

---

## Task 2: Suite completa + verificación visual manual

**Files:** ninguno nuevo — solo verificación.

- [ ] **Step 1: Reconstruye la caché de clases**

Run: `godot --headless --editor --quit --path .`. Revisa `git status` después — descarta con `git checkout -- <archivo>` cualquier reformateo de espacios/tabs en archivos que no tocaste.

- [ ] **Step 2: Corre la suite completa de GUT**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests en verde, sin romper nada de Ruleta ni de ninguna otra mesa.

- [ ] **Step 3: Verificación visual manual**

Con Steam corriendo, lanza el proyecto, entra a la mesa de Ruleta.
Confirma:
- Los 37 números (0-36) son visibles completos, ninguno cortado por el
  borde derecho de la ventana.
- La fila de apuestas de fuera (Rojo/Negro/Par/Impar/Docenas) se ve
  completa debajo del grid de números, con texto legible.
- Clicar cualquier número o apuesta de fuera sigue apostando al instante
  (comportamiento de Plan 17, sin cambios).

No cierres esta fase sin que el usuario confirme el punto anterior en vivo.

- [ ] **Step 4: Commit final (si algo quedó sin commitear)**

```bash
git status
git add -A
git commit -m "chore: verify roulette grid overflow fix end to end" --allow-empty
```

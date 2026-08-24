# Reskin Visual de Crash — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aplicar la estética de casino oscuro (Plan 16) a la mesa de Crash — panel lateral de apuesta compartido + gráfico de multiplicador creciente en tiempo real con flash de resultado.

**Architecture:** `CrashGraph` (`scripts/ui/casino/`) es el único componente nuevo, específico de Crash — el resto (`BetSidebarPanel`, `CasinoButton`, paleta) ya existe en `main` desde Plan 16 y se instancia sin tocarlo. Presentacional puro: no toca `scripts/crash/` ni `scripts/net/crash_table_controller.gd`, que ya exponen todo lo necesario (`multiplier_at`, `to_dict()`).

**Tech Stack:** Godot 4.7 / GDScript, GUT.

**Spec:** `docs/superpowers/specs/2026-08-24-crash-visual-design.md` (léela completa antes de empezar).

## Global Constraints

- No tocar `scripts/crash/crash_table_state.gd`, `scripts/crash/crash_roller.gd`, `scripts/net/crash_table_controller.gd` — este plan es 100% visual.
- No tocar `scripts/ui/casino/casino_theme.gd`, `bet_sidebar_panel.gd`, `casino_button.gd` (Plan 16/14) — ya son suficientes, solo se instancian.
- No tocar Blackjack, Dice, Ruleta, Póker, Mines, Plinko, Modo Batalla.
- Cero archivos de imagen — todo `_draw()`, igual que Planes 14/16.
- **Nunca expongas `crash_point` a la vista** — la vista solo puede leer `elapsed`/`is_active`/`last_round` de `to_dict()`, calcular el multiplicador con `CrashTableState.multiplier_at(t)`. Si algún test o código de este plan necesita el punto de explosión exacto antes de que la ronda termine, es una señal de que algo se ha diseñado mal — para.
- Trabaja en worktree aislado, rama `feature/crash-visual`.
- Godot: `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`. Reconstruye caché de clases antes de confiar en GUT; revisa `git status` después por reformateo espacios/tabs.

---

## Task 1: `CrashGraph` — curva de multiplicador

**Files:**
- Create: `scripts/ui/casino/crash_graph.gd`
- Create: `scenes/ui/casino/crash_graph.tscn`
- Test: `tests/unit/test_crash_graph.gd`

**Interfaces:**
- Consumes: `CasinoTheme.ACCENT_GREEN/ACCENT_RED/PANEL_NAVY_LIGHT` (Plan 16, ya en `main`); `CrashTableState.multiplier_at(t: float) -> float` (ya existente, `scripts/crash/crash_table_state.gd`).
- Produces: `class_name CrashGraph extends Control`, `enum State { IDLE, RISING, CRASHED, CASHED_OUT }`, propiedades `elapsed: float`, `state: int`, `const TIME_WINDOW_SEC := 12.0`, método estático `curve_points(elapsed_time: float, sample_count: int = 40) -> PackedVector2Array`, método `current_multiplier() -> float`. La Tarea 3 (vista de Crash) los consume.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_crash_graph.gd
extends GutTest

func test_curve_points_first_sample_is_approximately_one():
	var points := CrashGraph.curve_points(6.0, 10)
	assert_almost_eq(points[0].y, 1.0, 0.01)

func test_curve_points_is_monotonically_increasing():
	var points := CrashGraph.curve_points(6.0, 10)
	assert_true(points[points.size() - 1].y > points[0].y)

func test_curve_points_last_sample_matches_multiplier_at_elapsed():
	var points := CrashGraph.curve_points(4.0, 20)
	var expected := CrashTableState.multiplier_at(4.0)
	assert_almost_eq(points[points.size() - 1].y, expected, 0.001)

func test_curve_points_clamps_elapsed_to_time_window():
	var points := CrashGraph.curve_points(999.0, 10)
	assert_almost_eq(points[points.size() - 1].x, CrashGraph.TIME_WINDOW_SEC, 0.001)

func test_current_multiplier_matches_static_formula():
	var graph: CrashGraph = load("res://scenes/ui/casino/crash_graph.tscn").instantiate()
	add_child_autofree(graph)
	graph.elapsed = 3.0
	assert_almost_eq(graph.current_multiplier(), CrashTableState.multiplier_at(3.0), 0.001)

func test_default_state_is_idle():
	var graph: CrashGraph = load("res://scenes/ui/casino/crash_graph.tscn").instantiate()
	add_child_autofree(graph)
	assert_eq(graph.state, CrashGraph.State.IDLE)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_crash_graph.gd -gexit`
Expected: FAIL — la escena no existe todavía.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/crash_graph.gd
class_name CrashGraph
extends Control

enum State { IDLE, RISING, CRASHED, CASHED_OUT }

const TIME_WINDOW_SEC := 12.0
const MULTIPLIER_CEIL := 3.0

@export var elapsed: float = 0.0:
	set(value):
		elapsed = value
		queue_redraw()
@export var state: int = State.IDLE:
	set(value):
		state = value
		queue_redraw()

static func curve_points(elapsed_time: float, sample_count: int = 40) -> PackedVector2Array:
	var points := PackedVector2Array()
	var capped := clampf(elapsed_time, 0.0, TIME_WINDOW_SEC)
	for i in range(sample_count + 1):
		var t: float = capped * float(i) / float(sample_count)
		points.append(Vector2(t, CrashTableState.multiplier_at(t)))
	return points

func current_multiplier() -> float:
	return CrashTableState.multiplier_at(elapsed)

func _to_screen(p: Vector2) -> Vector2:
	var x := (p.x / TIME_WINDOW_SEC) * size.x
	var normalized := (clampf(p.y, 1.0, MULTIPLIER_CEIL) - 1.0) / (MULTIPLIER_CEIL - 1.0)
	var y := size.y - normalized * size.y
	return Vector2(x, y)

func _draw() -> void:
	draw_line(Vector2(0, size.y), Vector2(size.x, size.y), CasinoTheme.PANEL_NAVY_LIGHT, 1.0)
	draw_line(Vector2(0, 0), Vector2(0, size.y), CasinoTheme.PANEL_NAVY_LIGHT, 1.0)
	var raw_points := curve_points(elapsed)
	var line_color := CasinoTheme.ACCENT_RED if state == State.CRASHED else CasinoTheme.ACCENT_GREEN
	if elapsed > 0.0:
		var screen_points := PackedVector2Array()
		for p in raw_points:
			screen_points.append(_to_screen(p))
		draw_polyline(screen_points, line_color, 3.0, true)
		draw_circle(screen_points[screen_points.size() - 1], 6.0, line_color)
	var font := ThemeDB.fallback_font
	var text := "%.2fx" % current_multiplier()
	var font_size := 48
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, size / 2.0 - text_size / 2.0, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, line_color)
```

```gdscript
# scenes/ui/casino/crash_graph.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/crash_graph.gd" id="1"]

[node name="CrashGraph" type="Control"]
layout_mode = 3
script = ExtResource("1")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_crash_graph.gd -gexit`
Expected: PASS, 6/6.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/crash_graph.gd scenes/ui/casino/crash_graph.tscn tests/unit/test_crash_graph.gd
git commit -m "feat(ui): add CrashGraph component"
```

---

## Task 2: Reconstruye `scenes/crash_table_net.tscn`

**Files:**
- Modify: `scenes/crash_table_net.tscn` (reescritura completa del árbol)
- Test: `tests/unit/test_crash_table_scene_structure.gd`

**Interfaces:**
- Consumes: `BetSidebarPanel` (Plan 16), `CasinoButton` (Plan 14), `CrashGraph` (Task 1).
- Produces: árbol de nodos con los paths que consume la Tarea 3: `$BetSidebarPanel`, `$CashOutButton`, `$CrashGraph`, `$PlayersLabel`, `$TableController`.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_crash_table_scene_structure.gd
extends GutTest

func test_scene_has_expected_node_paths():
	var scene := load("res://scenes/crash_table_net.tscn")
	var root := scene.instantiate()
	add_child_autofree(root)
	for path in ["BetSidebarPanel", "CashOutButton", "CrashGraph", "PlayersLabel", "TableController"]:
		assert_not_null(root.get_node_or_null(path), "falta el nodo %s" % path)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_crash_table_scene_structure.gd -gexit`
Expected: FAIL — la escena actual no tiene esos nodos.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/crash_table_net.tscn`:

```gdscript
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scenes/crash_table_net.gd" id="1"]
[ext_resource type="Script" path="res://scripts/net/crash_table_controller.gd" id="2"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/bet_sidebar_panel.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/casino_button.tscn" id="4"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/crash_graph.tscn" id="5"]

[node name="CrashTableNet" type="Control"]
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

[node name="CashOutButton" parent="." instance=ExtResource("4")]
layout_mode = 0
offset_left = 340.0
offset_top = 20.0
offset_right = 520.0
offset_bottom = 60.0
text = "Retirar"
variant = 1
disabled = true

[node name="CrashGraph" parent="." instance=ExtResource("5")]
layout_mode = 0
offset_left = 340.0
offset_top = 80.0
offset_right = 880.0
offset_bottom = 460.0

[node name="PlayersLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 340.0
offset_top = 480.0
offset_right = 900.0
offset_bottom = 680.0
text = "Nadie ha apostado todavía."
```

Actualiza solo el bloque de `@onready var` al principio de
`scenes/crash_table_net.gd` (deja el resto tal cual, la Tarea 3 lo
reescribe entero):

```gdscript
@onready var table_controller: CrashTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var cash_out_button: CasinoButton = $CashOutButton
@onready var crash_graph: CrashGraph = $CrashGraph
@onready var players_label: Label = $PlayersLabel
```

Si el script deja de compilar por referencias a `$AmountSpinBox`/
`$BetButton` que ya no existen, elimínalas de este mismo paso.

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_crash_table_scene_structure.gd -gexit`
Expected: PASS, 1/1.

- [ ] **Step 5: Commit**

```bash
git add scenes/crash_table_net.tscn scenes/crash_table_net.gd tests/unit/test_crash_table_scene_structure.gd
git commit -m "feat(crash): rebuild table scene on dark casino panel components"
```

---

## Task 3: Reescribe `crash_table_net.gd` — apuesta, retiro, gráfico en vivo

**Files:**
- Modify: `scenes/crash_table_net.gd` (reescritura completa)
- Test: `tests/unit/test_crash_table_view.gd`

**Interfaces:**
- Consumes: `BetSidebarPanel.bet_pressed(amount)`; `CrashGraph.elapsed`/`state`/`current_multiplier()` (Task 1); `TableController.state_changed(state)` (ya existente, sin cambios).
- Produces: método público `_refresh_graph() -> void`, usado por el test de esta tarea para verificar la lógica sin pasar por RPCs reales.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_crash_table_view.gd
extends GutTest

func _make_view():
	var scene := load("res://scenes/crash_table_net.tscn")
	var view = scene.instantiate()
	add_child_autofree(view)
	return view

func test_refresh_graph_idle_when_no_round_for_local_player():
	var view = _make_view()
	view._last_players = {}
	view._refresh_graph()
	assert_eq(view.crash_graph.state, CrashGraph.State.IDLE)
	assert_eq(view.crash_graph.elapsed, 0.0)

func test_refresh_graph_rising_while_round_active():
	var view = _make_view()
	var my_id := multiplayer.get_unique_id()
	view._last_players = {my_id: {"player_id": my_id, "balance": 400, "is_active": true, "elapsed": 2.5, "last_round": {}}}
	view._local_elapsed = {my_id: 2.5}
	view._refresh_graph()
	assert_eq(view.crash_graph.state, CrashGraph.State.RISING)
	assert_almost_eq(view.crash_graph.elapsed, 2.5, 0.001)

func test_bet_sidebar_press_calls_place_bet_with_amount():
	var view = _make_view()
	view.table_controller.table_state = CrashTableState.new()
	view.bet_sidebar.amount = 30
	view.bet_sidebar.bet_pressed.emit(30)
	assert_true(view.table_controller.table_state.players.has(multiplayer.get_unique_id()))
	assert_eq(view.table_controller.table_state.players[multiplayer.get_unique_id()].bet_amount, 30)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_crash_table_view.gd -gexit`
Expected: FAIL — `_refresh_graph` no existe todavía.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/crash_table_net.gd`:

```gdscript
extends Control

@onready var table_controller: CrashTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var cash_out_button: CasinoButton = $CashOutButton
@onready var crash_graph: CrashGraph = $CrashGraph
@onready var players_label: Label = $PlayersLabel

var _last_players: Dictionary = {}
var _local_elapsed: Dictionary = {}
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
	cash_out_button.pressed.connect(func(): table_controller.cash_out())
	NetworkManager.identities_changed.connect(_refresh_players_label)
	cash_out_button.disabled = true
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

func _on_bet_pressed(amount: int) -> void:
	table_controller.place_bet(amount)

func _process(delta: float) -> void:
	var any_active := false
	for player_id in _last_players:
		if _last_players[player_id]["is_active"]:
			_local_elapsed[player_id] = _local_elapsed.get(player_id, 0.0) + delta
			any_active = true
	if any_active:
		_refresh_players_label()
		_refresh_graph()

func _on_state_changed(state: Dictionary) -> void:
	_last_players = state["players"]
	for player_id in _last_players:
		_local_elapsed[player_id] = _last_players[player_id]["elapsed"]
	var my_id := multiplayer.get_unique_id()
	var mine: Dictionary = _last_players.get(my_id, {})
	var mine_active: bool = mine.get("is_active", false)
	cash_out_button.disabled = not mine_active
	if not (not multiplayer.is_server() and multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED):
		bet_sidebar.bet_button.disabled = mine_active
	_refresh_players_label()
	_refresh_graph()
	_maybe_flash_result(mine)

func _refresh_graph() -> void:
	var my_id := multiplayer.get_unique_id()
	var mine: Dictionary = _last_players.get(my_id, {})
	if mine.is_empty():
		crash_graph.state = CrashGraph.State.IDLE
		crash_graph.elapsed = 0.0
		return
	crash_graph.elapsed = _local_elapsed.get(my_id, mine["elapsed"])
	if mine["is_active"]:
		crash_graph.state = CrashGraph.State.RISING

func _maybe_flash_result(mine: Dictionary) -> void:
	if mine.is_empty():
		return
	var last_round: Dictionary = mine["last_round"]
	if last_round.is_empty():
		return
	var my_id := multiplayer.get_unique_id()
	if _last_round_seen.get(my_id, {}) == last_round:
		return
	_last_round_seen[my_id] = last_round
	crash_graph.state = CrashGraph.State.CASHED_OUT if last_round["win"] else CrashGraph.State.CRASHED

func _refresh_players_label() -> void:
	if _last_players.is_empty():
		players_label.text = "Nadie ha apostado todavía."
		return
	var lines: Array[String] = []
	for player_id in _last_players:
		var player = _last_players[player_id]
		var line := "%s — fichas %d" % [_display_name(player["player_id"]), player["balance"]]
		if player["is_active"]:
			var t: float = _local_elapsed.get(player_id, player["elapsed"])
			var current := CrashTableState.multiplier_at(t)
			line += " — en juego, multiplicador %.2fx" % current
		else:
			var last_round = player["last_round"]
			if not last_round.is_empty():
				if last_round["win"]:
					line += " — última ronda: retiró en %.2fx" % last_round["cashed_out_at"]
				else:
					line += " — última ronda: explotó en %.2fx" % last_round["crash_point"]
		lines.append(line)
	players_label.text = "\n".join(lines)
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_crash_table_view.gd -gexit`
Expected: PASS, 3/3.

- [ ] **Step 5: Commit**

```bash
git add scenes/crash_table_net.gd tests/unit/test_crash_table_view.gd
git commit -m "feat(crash): wire bet sidebar, cash out and live graph to dark panel UI"
```

---

## Task 4: Suite completa + verificación visual manual

**Files:** ninguno nuevo — solo verificación.

- [ ] **Step 1: Reconstruye la caché de clases**

Run: `godot --headless --editor --quit --path .`. Revisa `git status` — descarta con `git checkout -- <archivo>` cualquier reformateo de espacios/tabs en archivos que no tocaste.

- [ ] **Step 2: Corre la suite completa de GUT**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests en verde, incluidos los nuevos de este plan, y que ningún test de otra mesa se haya roto.

- [ ] **Step 3: Verificación visual manual**

Con Steam corriendo, lanza el proyecto, entra a la mesa de Crash. Confirma:
- Panel lateral oscuro con monto, 1/2 · x2 · Máx, "Hacer apuesta".
- Botón "Retirar" deshabilitado hasta que hay una ronda activa propia.
- Al apostar, el multiplicador gigante y la curva verde suben en tiempo real.
- Al pulsar "Retirar" a tiempo, la curva/número quedan en verde (ganó); si explota antes, pasan a rojo.
- El listado de jugadores sigue viéndose debajo.

No cierres esta fase sin que el usuario confirme el punto anterior en vivo.

- [ ] **Step 4: Commit final (si algo quedó sin commitear)**

```bash
git status
git add -A
git commit -m "chore: verify Crash visual reskin end to end" --allow-empty
```

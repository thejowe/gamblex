# Pozo Compartido Real en Modo Libre — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar la meta colectiva acumulativa (`CollectiveGoal`, solo suma ganancias) por un pozo `ChipLedger` compartido de verdad en Modo Libre — empieza en 500, sube y baja con cada apuesta/pago en cualquiera de las 7 mesas, meta 1000 — reutilizando la tubería `shared_ledger_provider`/`on_shared_ledger_changed` que Plan 15 ya construyó para Modo Batalla. Añade una pantalla de derrota si el pozo llega a 0.

**Architecture:** `CasinoFloor` es el único archivo que cambia. `_ledger_for_player()` deja de devolver `null` fuera de batalla — devuelve el mismo `ChipLedger` compartido para cualquier jugador. `_inject_shared_ledger_providers()` (ya iterando las 7 clases de controller) asigna el notificador correcto según el modo. Cero cambios en `scripts/roulette/`, `scripts/poker/`, `scripts/dice/`, `scripts/crash/`, `scripts/mines/`, `scripts/plinko/`, `scripts/blackjack/`, `scripts/net/*_table_controller.gd`, `scripts/battle/`, `scripts/net/battle_controller.gd` — todos ya exponen y usan `shared_ledger_provider`/`on_shared_ledger_changed` desde Plan 15, no hace falta tocarlos.

**Tech Stack:** Godot 4.7 / GDScript, GUT.

**Spec:** `docs/superpowers/specs/2026-08-24-free-mode-shared-pool-design.md` (léela completa antes de empezar).

## Global Constraints

- Modificas **solo** `scripts/net/casino_floor.gd` y `scenes/casino_floor.tscn` (más borrar `scripts/free_mode/collective_goal.gd` y `tests/unit/test_collective_goal.gd`). Ningún otro archivo.
- No tocar Modo Batalla (`battle_controller.gd`, `match_rules.gd`, `team_chip_pool.gd`, `team_assignment.gd`) — ya funciona, confirmado en Plan 15.
- No tocar ninguna función de reglas de apuesta/turno/pago de ninguno de los 7 juegos.
- Ningún test nuevo llama a `.rpc()` — construye/verifica el estado directo, mismo patrón que `tests/unit/test_casino_floor_ledger_wiring.gd` (Plan 15).
- Antes de borrar `collective_goal.gd`/su test, confirma con `grep -rl "CollectiveGoal" --include="*.gd" .` (excluyendo `.claude/worktrees/`) que solo aparecen esos dos archivos — si algo más lo referencia, para y avisa, no borres a ciegas.
- Trabaja en worktree aislado, rama `feature/free-mode-shared-pool`.
- Godot: `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`. Reconstruye caché de clases antes de confiar en GUT; revisa `git status` después por reformateo espacios/tabs.

---

## Task 1: `CasinoFloor` — pozo compartido reemplaza `CollectiveGoal`

**Files:**
- Modify: `scripts/net/casino_floor.gd`
- Test: `tests/unit/test_casino_floor_ledger_wiring.gd` (añade al final del archivo que ya existe desde Plan 15)

**Interfaces:**
- Consumes: `ChipLedger` (ya existente).
- Produces: `_ledger_for_player(player_id) -> ChipLedger` (cambia de comportamiento: ya no devuelve `null` fuera de batalla), `_goal_state_dict() -> Dictionary`, `_notify_free_mode_balance_changed() -> void`. La Tarea 2 conecta el resultado al HUD.

- [ ] **Step 1: Escribe los tests que fallan**

Añade al final de `tests/unit/test_casino_floor_ledger_wiring.gd`:

```gdscript
func test_ledger_for_player_returns_shared_pool_in_free_mode_for_any_player():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor._is_battle_mode = false
	casino_floor.shared_pool_ledger = ChipLedger.new(500)
	assert_eq(casino_floor._ledger_for_player(111), casino_floor.shared_pool_ledger)
	assert_eq(casino_floor._ledger_for_player(222), casino_floor.shared_pool_ledger)

func test_goal_state_dict_reflects_shared_pool_balance_and_target():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor.shared_pool_ledger = ChipLedger.new(500)
	casino_floor.shared_pool_ledger.payout(300)
	var state := casino_floor._goal_state_dict()
	assert_eq(state["balance"], 800)
	assert_eq(state["target"], 1000) # CasinoFloor.GOAL_TARGET, sin cambios en este plan
	assert_eq(state["unlocked"], false)
	assert_eq(state["bankrupt"], false)

func test_notify_free_mode_balance_changed_sets_unlocked_flag_at_target():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor._is_battle_mode = false
	casino_floor.shared_pool_ledger = ChipLedger.new(500)
	casino_floor.shared_pool_ledger.payout(600) # 1100, por encima de la meta de 1000
	casino_floor._pool_unlocked = false
	casino_floor._set_pool_unlocked_if_reached_goal()
	assert_true(casino_floor._pool_unlocked)

func test_goal_state_dict_reports_bankrupt_at_zero_balance():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor.shared_pool_ledger = ChipLedger.new(500)
	casino_floor.shared_pool_ledger.place_bet(500)
	var state := casino_floor._goal_state_dict()
	assert_true(state["bankrupt"])
```

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_floor_ledger_wiring.gd -gexit`
Expected: FAIL — `shared_pool_ledger`/`_goal_state_dict`/`_notify_free_mode_balance_changed`/`_set_pool_unlocked_if_reached_goal`/`_pool_unlocked` no existen todavía.

- [ ] **Step 3: Implementa**

En `scripts/net/casino_floor.gd`:

1. Reemplaza la línea `const GOAL_TARGET := 1000` por (añade la nueva
   constante justo debajo, no la reemplaces):

```gdscript
const GOAL_TARGET := 1000
const FREE_MODE_STARTING_BALANCE := 500
```

2. Reemplaza `var goal: CollectiveGoal` por:

```gdscript
var shared_pool_ledger: ChipLedger
var _pool_unlocked: bool = false
```

3. En `_ready()`, reemplaza el bloque completo de la rama `else:` dentro
   de `if multiplayer.is_server():` (el que hoy crea `goal =
   CollectiveGoal.new(GOAL_TARGET)` y conecta 5 veces `chips_won`) por:

```gdscript
		else:
			shared_pool_ledger = ChipLedger.new(FREE_MODE_STARTING_BALANCE)
			_broadcast_goal_state()
```

4. Reemplaza `_ledger_for_player`:

```gdscript
func _ledger_for_player(player_id: int) -> ChipLedger:
	if _is_battle_mode:
		var team_id := battle_controller.team_for(player_id)
		if team_id == -1:
			return null
		return battle_controller.ledger_for_team(team_id)
	return shared_pool_ledger
```

5. Reemplaza `_inject_shared_ledger_providers`:

```gdscript
func _inject_shared_ledger_providers() -> void:
	for controller_class in CONTROLLER_CLASS_NAMES:
		for controller in find_children("*", controller_class, true, false):
			controller.shared_ledger_provider = _ledger_for_player
			if _is_battle_mode:
				controller.on_shared_ledger_changed = battle_controller.notify_balance_possibly_changed
			else:
				controller.on_shared_ledger_changed = _notify_free_mode_balance_changed
```

6. Elimina por completo la función `_on_chips_won` (ya nadie la conecta,
   queda muerta).

7. Reemplaza el bloque de `request_goal_state`/`_request_goal_state`/
   `_broadcast_goal_state`/`_receive_goal_state` (sección "modo libre:
   meta colectiva") por:

```gdscript
func _set_pool_unlocked_if_reached_goal() -> void:
	if shared_pool_ledger.balance >= GOAL_TARGET:
		_pool_unlocked = true

func _notify_free_mode_balance_changed() -> void:
	_set_pool_unlocked_if_reached_goal()
	_broadcast_goal_state()

func _goal_state_dict() -> Dictionary:
	return {
		"balance": shared_pool_ledger.balance,
		"target": GOAL_TARGET,
		"unlocked": _pool_unlocked,
		"bankrupt": shared_pool_ledger.is_bankrupt(),
	}

# Un cliente que entra a CasinoFloor después de que ya hubo apuestas no
# recibe nada por su cuenta: el host solo retransmite _receive_goal_state
# cuando el pozo cambia, nunca al conectar (mismo gotcha que
# TableController.request_state en Plan 3). Sin este pedido explícito el
# cliente se queda con el pozo en el balance inicial para siempre.
func request_goal_state() -> void:
	if multiplayer.is_server():
		return
	_request_goal_state.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_goal_state() -> void:
	if not multiplayer.is_server():
		return
	_receive_goal_state.rpc_id(multiplayer.get_remote_sender_id(), _goal_state_dict())

func _broadcast_goal_state() -> void:
	_receive_goal_state.rpc(_goal_state_dict())

@rpc("authority", "call_local", "reliable")
func _receive_goal_state(state: Dictionary) -> void:
	goal_label.text = "Meta colectiva: %d / %d fichas" % [state["balance"], state["target"]]
	unlocked_banner.visible = state["unlocked"]
	defeat_overlay.visible = state["bankrupt"]
```

(`defeat_overlay` se declara en la Tarea 2 — este paso deja el script
referenciándolo; si ejecutas los tests de esta tarea antes de terminar la
Tarea 2, instanciar la escena completa fallará por el `@onready` que
falta. Los tests de esta tarea instancian el **script suelto**
(`load(...).new()`), no la escena completa, así que no dependen de
`defeat_overlay` — pasan igual sin la Tarea 2 hecha todavía.)

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_floor_ledger_wiring.gd -gexit`
Expected: PASS, todos los tests del archivo (los de Plan 15 + los 4 nuevos).

- [ ] **Step 5: Commit**

```bash
git add scripts/net/casino_floor.gd tests/unit/test_casino_floor_ledger_wiring.gd
git commit -m "feat(casino-floor): replace cumulative CollectiveGoal with a real shared pool ledger in free mode"
```

---

## Task 2: Pantalla de derrota (`DefeatOverlay`)

**Files:**
- Modify: `scenes/casino_floor.tscn`
- Modify: `scripts/net/casino_floor.gd` (solo añadir el `@onready var`)
- Test: `tests/unit/test_casino_floor_scene_structure.gd` (nuevo)

**Interfaces:**
- Produces: nodo `$Hud/DefeatOverlay` (`ColorRect`, `visible = false` por defecto), consumido por `_receive_goal_state` (Task 1, ya escrito para referenciarlo).

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_casino_floor_scene_structure.gd
extends GutTest

func test_scene_has_defeat_overlay_node_hidden_by_default():
	var scene := load("res://scenes/casino_floor.tscn")
	var root := scene.instantiate()
	add_child_autofree(root)
	var overlay := root.get_node_or_null("Hud/DefeatOverlay")
	assert_not_null(overlay, "falta el nodo Hud/DefeatOverlay")
	assert_false(overlay.visible)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_floor_scene_structure.gd -gexit`
Expected: FAIL — el nodo no existe todavía.

- [ ] **Step 3: Implementa**

En `scenes/casino_floor.tscn`, añade dentro de `[node name="Hud" type="CanvasLayer" parent="."]` (después del bloque de `BackButton`, al final del archivo):

```gdscript
[node name="DefeatOverlay" type="ColorRect" parent="Hud"]
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.05, 0.02, 0.02, 0.85)
mouse_filter = 0
visible = false

[node name="DefeatLabel" type="Label" parent="Hud/DefeatOverlay"]
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_font_sizes/font_size = 40
theme_override_colors/font_color = Color(1, 1, 1, 1)
horizontal_alignment = 1
vertical_alignment = 1
text = "PERDISTE — el pozo compartido se agotó"
```

En `scripts/net/casino_floor.gd`, añade junto a los demás `@onready var`
del bloque inicial (junto a `unlocked_banner`):

```gdscript
@onready var defeat_overlay: Control = $Hud/DefeatOverlay
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_floor_scene_structure.gd -gexit`
Expected: PASS, 1/1.

- [ ] **Step 5: Commit**

```bash
git add scenes/casino_floor.tscn scripts/net/casino_floor.gd tests/unit/test_casino_floor_scene_structure.gd
git commit -m "feat(casino-floor): add full-screen defeat overlay for free-mode pool bankruptcy"
```

---

## Task 3: Elimina `CollectiveGoal` (código muerto)

**Files:**
- Delete: `scripts/free_mode/collective_goal.gd`
- Delete: `tests/unit/test_collective_goal.gd` (y su `.uid` si existe)

**Interfaces:** ninguna — limpieza pura, nadie más lo usa.

- [ ] **Step 1: Confirma que nada más lo referencia**

Run: `grep -rl "CollectiveGoal" --include="*.gd" . | grep -v worktrees`
Expected: cero resultados (ya quitaste las dos únicas referencias en
`scripts/net/casino_floor.gd` en la Tarea 1; `collective_goal.gd` y
`test_collective_goal.gd` se auto-referencian por nombre de clase pero
eso no cuenta). Si aparece algo más, **para** y avisa a la sesión pilar
antes de borrar nada.

- [ ] **Step 2: Borra los archivos**

```bash
git rm scripts/free_mode/collective_goal.gd scripts/free_mode/collective_goal.gd.uid tests/unit/test_collective_goal.gd tests/unit/test_collective_goal.gd.uid
```

(Si algún `.uid` no existe, `git rm` de ese archivo fallará — quita solo
ese nombre del comando y sigue con el resto, no es un error real.)

- [ ] **Step 3: Corre la suite completa, confirma que nada se rompe**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests en verde, sin ningún fallo por referencia a
`CollectiveGoal` (si aparece un error de clase no encontrada, algo se te
escapó en el Step 1 — investiga antes de seguir).

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: remove unused CollectiveGoal, replaced by shared pool ledger"
```

---

## Task 4: Suite completa + verificación visual manual

**Files:** ninguno nuevo — solo verificación.

- [ ] **Step 1: Reconstruye la caché de clases**

Run: `godot --headless --editor --quit --path .`. Revisa `git status` después — descarta con `git checkout -- <archivo>` cualquier reformateo de espacios/tabs en archivos que no tocaste.

- [ ] **Step 2: Corre la suite completa de GUT**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests en verde.

- [ ] **Step 3: Verificación visual manual (necesita 2 clientes Steam en Modo Libre)**

Con Steam corriendo y dos cuentas, entra en Modo Libre (sin elegir tipo
de partida). Confirma:
- El HUD muestra "Meta colectiva: 500 / 1000 fichas" al entrar.
- Un jugador apuesta en cualquier mesa (ej. Dice) y pierde — el otro
  jugador, en otra mesa distinta, ve el número bajar también.
- Un jugador gana — el balance sube para los dos.
- Si el pozo llega a 0 (fuerza pérdidas seguidas para probarlo), aparece
  la pantalla "PERDISTE — el pozo compartido se agotó" cubriendo toda la
  pantalla, y ya no se puede interactuar con nada.
- Si el pozo llega a 1000 (en otra partida, sin llegar a 0 antes), aparece
  el banner de desbloqueo y la partida sigue jugándose con normalidad.

No cierres esta fase sin que el usuario confirme el punto anterior en
vivo — necesita 2 cuentas Steam, no disponible en la sesión del agente.

- [ ] **Step 4: Commit final (si algo quedó sin commitear)**

```bash
git status
git add -A
git commit -m "chore: verify free-mode shared pool fix end to end" --allow-empty
```

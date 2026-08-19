# Modo Libre — Meta Colectiva de Grupo (Plan 7) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** En modo libre, todos los jugadores presentes en el `CasinoFloor` contribuyen a un contador compartido de fichas ganadas; al alcanzar la meta se desbloquea un anuncio visible para todos.

**Architecture:** `BlackjackTableState` emite una señal `chips_won(player_id, amount)` cada vez que un asiento gana fichas netas en una ronda. `TableController` la reenvía hacia arriba. `CasinoFloor` (nuevo script, autoridad en el host) acumula esas ganancias en un `CollectiveGoal` (lógica pura, sin red) y retransmite el estado por RPC a todos los presentes — mismo patrón broadcast/request que ya usa `TableController` para el estado de mesa, incluyendo la sincronización a clientes que entran tarde.

**Tech Stack:** Godot 4 GDScript, GUT (tests unitarios headless), Steamworks/GodotSteam multiplayer (RPC vía `MultiplayerAPI`).

**Spec:** `docs/superpowers/specs/2026-08-17-casino-multiplayer-design.md` (sección "Modo libre")

## Global Constraints

- Modo libre: "meta colectiva de grupo: un objetivo compartido (ej. acumular X fichas entre todos los presentes) que al cumplirse desbloquea algo (nueva mesa, cosmético, etc.)".
- Suma lo que gana cada jugador, sin importar en qué mesa juegue (hoy solo existe blackjack; el hook debe vivir en el nivel de `TableController`/`CasinoFloor`, no atado a blackjack específicamente donde sea evitable).
- Sin alcance extra: nada de misiones ni logros individuales — solo el contador compartido y su desbloqueo.
- Host es la autoridad (modelo listen-server ya establecido en Plan 3); los clientes solo reciben estado.
- Test de lógica de juego: módulos GDScript aislados sin red (GUT). Prueba manual multijugador con varias instancias para la parte de red, como ya se hace en Plan 3.
- Comando de test headless: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`

---

### Task 1: `CollectiveGoal` — lógica pura del contador compartido

**Files:**
- Create: `scripts/free_mode/collective_goal.gd`
- Test: `tests/unit/test_collective_goal.gd`

**Interfaces:**
- Produces: `class_name CollectiveGoal extends RefCounted`
  - `_init(p_target: int) -> void`
  - `var target: int`, `var total: int`, `var unlocked: bool`
  - `func add_chips(amount: int) -> bool` — suma `amount` a `total` si es positivo; devuelve `true` solo en el tick donde `total` cruza `target` por primera vez (transición a `unlocked`), `false` en cualquier otro caso (incluye `amount <= 0`).
  - `func to_dict() -> Dictionary` — `{"total": int, "target": int, "unlocked": bool}`

- [ ] **Step 1: Escribe los tests (deben fallar, la clase no existe aún)**

```gdscript
extends GutTest

func test_starts_at_zero_and_locked():
    var goal = CollectiveGoal.new(1000)
    assert_eq(goal.total, 0)
    assert_false(goal.unlocked)

func test_add_chips_accumulates_total():
    var goal = CollectiveGoal.new(1000)
    goal.add_chips(300)
    goal.add_chips(250)
    assert_eq(goal.total, 550)

func test_unlocks_when_target_reached():
    var goal = CollectiveGoal.new(500)
    goal.add_chips(500)
    assert_true(goal.unlocked)

func test_unlocks_when_target_exceeded():
    var goal = CollectiveGoal.new(500)
    goal.add_chips(700)
    assert_true(goal.unlocked)

func test_add_chips_returns_true_only_on_unlock_transition():
    var goal = CollectiveGoal.new(500)
    var before = goal.add_chips(300)
    assert_false(before)
    var at_unlock = goal.add_chips(200)
    assert_true(at_unlock)
    var after = goal.add_chips(100)
    assert_false(after)
    assert_true(goal.unlocked)

func test_ignores_non_positive_amounts():
    var goal = CollectiveGoal.new(500)
    var ok = goal.add_chips(0)
    assert_false(ok)
    assert_eq(goal.total, 0)
    var ok2 = goal.add_chips(-50)
    assert_false(ok2)
    assert_eq(goal.total, 0)

func test_multiple_players_contribute_to_shared_total():
    var goal = CollectiveGoal.new(300)
    goal.add_chips(100) # jugador A gana
    goal.add_chips(150) # jugador B gana
    assert_eq(goal.total, 250)
    assert_false(goal.unlocked)
    goal.add_chips(60) # jugador C gana, se cumple la meta
    assert_true(goal.unlocked)

func test_to_dict_reflects_state():
    var goal = CollectiveGoal.new(500)
    goal.add_chips(500)
    var data = goal.to_dict()
    assert_eq(data["total"], 500)
    assert_eq(data["target"], 500)
    assert_eq(data["unlocked"], true)
```

- [ ] **Step 2: Ejecuta los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `Could not find type "CollectiveGoal"` (o equivalente, la clase aún no existe).

- [ ] **Step 3: Implementa `CollectiveGoal`**

```gdscript
class_name CollectiveGoal
extends RefCounted

var target: int
var total: int = 0
var unlocked: bool = false

func _init(p_target: int) -> void:
    target = p_target

func add_chips(amount: int) -> bool:
    if amount <= 0:
        return false
    total += amount
    if not unlocked and total >= target:
        unlocked = true
        return true
    return false

func to_dict() -> Dictionary:
    return {
        "total": total,
        "target": target,
        "unlocked": unlocked,
    }
```

- [ ] **Step 4: Ejecuta los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: PASS — 8 tests nuevos en verde.

- [ ] **Step 5: Commit**

```bash
git add scripts/free_mode/collective_goal.gd tests/unit/test_collective_goal.gd
git commit -m "feat: add CollectiveGoal for free-mode shared chip counter"
```

---

### Task 2: `BlackjackTableState` emite `chips_won` en ganancias netas

**Files:**
- Modify: `scripts/blackjack/blackjack_table_state.gd:1-3` (declarar señal), `scripts/blackjack/blackjack_table_state.gd:139-148` (`_resolve_seat_payout`)
- Test: `tests/unit/test_blackjack_table_state.gd`

**Interfaces:**
- Consumes: nada nuevo (usa `Seat.player_id`, `Seat.current_bet` ya existentes).
- Produces: `signal chips_won(player_id: int, amount: int)` en `BlackjackTableState` — se emite solo cuando el asiento gana fichas por encima de lo apostado (paga 2x por victoria; nunca en empate ni en bust). `amount` es la ganancia neta (igual a `current_bet`, no al pago bruto de `current_bet * 2`).

- [ ] **Step 1: Añade los tests (deben fallar — la señal no existe)**

Añade al final de `tests/unit/test_blackjack_table_state.gd`:

```gdscript
func test_chips_won_emitted_only_for_winning_seat():
    var deck = _stub_deck([
        Card.new(10, Card.Suit.HEARTS),   # seat0 card1
        Card.new(10, Card.Suit.DIAMONDS), # seat1 card1
        Card.new(9, Card.Suit.HEARTS),    # dealer card1
        Card.new(10, Card.Suit.SPADES),   # seat0 card2 -> seat0 = 20
        Card.new(9, Card.Suit.SPADES),    # seat1 card2 -> seat1 = 19
        Card.new(8, Card.Suit.SPADES),    # dealer card2 -> dealer = 17
        Card.new(5, Card.Suit.CLUBS),     # seat1 hit -> 24 bust
    ])
    var table = BlackjackTableState.new(deck)
    table.sit(0, 111)
    table.sit(1, 222)
    table.place_bet(0, 111, 100)
    table.place_bet(1, 222, 50)
    watch_signals(table)

    table.stand(0, 111)
    table.hit(1, 222) # bust, resuelve la ronda

    assert_signal_emitted_with_parameters(table, "chips_won", [111, 100])
    assert_signal_emit_count(table, "chips_won", 1) # seat1 quebró, no emite

func test_chips_won_not_emitted_on_tie():
    var deck = _stub_deck([
        Card.new(10, Card.Suit.HEARTS), # seat0 card1
        Card.new(9, Card.Suit.HEARTS),  # dealer card1
        Card.new(7, Card.Suit.SPADES),  # seat0 card2 -> 17
        Card.new(8, Card.Suit.SPADES),  # dealer card2 -> 17 (empate)
    ])
    var table = BlackjackTableState.new(deck)
    table.sit(0, 111)
    table.place_bet(0, 111, 100)
    watch_signals(table)

    table.stand(0, 111) # única silla ocupada, resuelve la ronda

    assert_signal_not_emitted(table, "chips_won")
    assert_eq(table.seats[0].ledger.balance, 500) # -100 + 100 (empate, ganancia neta 0)
```

- [ ] **Step 2: Ejecuta los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `chips_won` no existe en `BlackjackTableState`.

- [ ] **Step 3: Añade la señal y emítela en las ramas ganadoras**

En `scripts/blackjack/blackjack_table_state.gd`, añade tras `class_name BlackjackTableState` / `extends RefCounted`:

```gdscript
signal chips_won(player_id: int, amount: int)
```

Reemplaza `_resolve_seat_payout`:

```gdscript
func _resolve_seat_payout(seat) -> void:
    if seat.hand.is_bust():
        return
    if dealer_hand.is_bust():
        seat.ledger.payout(seat.current_bet * 2)
        chips_won.emit(seat.player_id, seat.current_bet)
        return
    if seat.hand.value() > dealer_hand.value():
        seat.ledger.payout(seat.current_bet * 2)
        chips_won.emit(seat.player_id, seat.current_bet)
    elif seat.hand.value() == dealer_hand.value():
        seat.ledger.payout(seat.current_bet)
```

- [ ] **Step 4: Ejecuta los tests, confirma que pasan (incluye la suite completa, no rompiste nada existente)**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: PASS — todos los tests, incluidos los 2 nuevos y `test_full_round_multiple_seats_resolve_independientemente` (balances sin cambios).

- [ ] **Step 5: Commit**

```bash
git add scripts/blackjack/blackjack_table_state.gd tests/unit/test_blackjack_table_state.gd
git commit -m "feat: emit chips_won signal on net round winnings"
```

---

### Task 3: `TableController` reenvía `chips_won` hacia el nivel de `CasinoFloor`

**Files:**
- Modify: `scripts/net/table_controller.gd:1-10` (declarar señal y conectar en `_ready`)

**Interfaces:**
- Consumes: `BlackjackTableState.chips_won(player_id: int, amount: int)` (Task 2), solo conectada cuando `multiplayer.is_server()` es `true` (igual que la creación de `table_state`, ya que en clientes `table_state` es `null`).
- Produces: `signal chips_won(player_id: int, amount: int)` en `TableController` — reenvío 1:1, mismo nombre y firma, para que `CasinoFloor` (Task 4) no necesite tocar `table_state` directamente.

No hay test unitario para este paso: `TableController` depende de `multiplayer`/RPC y ya se verifica manualmente en este repo (ningún test existente lo cubre — ver `tests/unit/`). Se verifica en la Task 4 con la prueba manual multijugador.

- [ ] **Step 1: Añade la señal y la conexión**

En `scripts/net/table_controller.gd`, añade tras `signal state_changed(state: Dictionary)`:

```gdscript
signal chips_won(player_id: int, amount: int)
```

Reemplaza `_ready`:

```gdscript
func _ready() -> void:
    if multiplayer.is_server():
        table_state = BlackjackTableState.new()
        table_state.chips_won.connect(_on_table_chips_won)
```

Añade el método de reenvío (al final del archivo):

```gdscript
func _on_table_chips_won(player_id: int, amount: int) -> void:
    chips_won.emit(player_id, amount)
```

- [ ] **Step 2: Ejecuta la suite completa de tests, confirma que sigue en verde (no debería haber cambiado nada, es una red de guarda)**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: PASS — mismos tests que antes, `TableController` no tiene tests propios pero no debe romper la carga del proyecto (ausencia de errores de parseo).

- [ ] **Step 3: Commit**

```bash
git add scripts/net/table_controller.gd
git commit -m "feat: forward chips_won signal from TableController"
```

---

### Task 4: `CasinoFloor` — autoridad del contador compartido, broadcast y desbloqueo

**Files:**
- Create: `scripts/net/casino_floor.gd`
- Modify: `scenes/casino_floor.tscn`

**Interfaces:**
- Consumes: `TableController.chips_won(player_id: int, amount: int)` (Task 3, vía `$BlackjackTableNet/TableController`), `CollectiveGoal` (Task 1).
- Produces: nodo raíz `CasinoFloor` con script — ninguna otra escena depende de sus símbolos internos, es la cima de la jerarquía de escena.

- [ ] **Step 1: Escribe `scripts/net/casino_floor.gd`**

```gdscript
extends Node2D

const GOAL_TARGET := 1000

@onready var table_controller: TableController = $BlackjackTableNet/TableController
@onready var goal_label: Label = $GoalLabel
@onready var unlocked_banner: Label = $UnlockedBanner

var goal: CollectiveGoal

func _ready() -> void:
    unlocked_banner.visible = false
    if multiplayer.is_server():
        goal = CollectiveGoal.new(GOAL_TARGET)
        table_controller.chips_won.connect(_on_chips_won)
        _broadcast_goal_state()
    else:
        var peer := multiplayer.multiplayer_peer
        if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
            multiplayer.connected_to_server.connect(func(): request_goal_state())
        else:
            request_goal_state()

func _on_chips_won(_player_id: int, amount: int) -> void:
    goal.add_chips(amount)
    _broadcast_goal_state()

# Un cliente que entra a CasinoFloor después de que ya hubo ganancias no
# recibe nada por su cuenta: el host solo retransmite _receive_goal_state
# cuando el contador cambia, nunca al conectar (mismo gotcha que
# TableController.request_state en Plan 3). Sin este pedido explícito el
# cliente se queda con el contador en 0 para siempre.
func request_goal_state() -> void:
    if multiplayer.is_server():
        return
    _request_goal_state.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_goal_state() -> void:
    if not multiplayer.is_server():
        return
    _receive_goal_state.rpc_id(multiplayer.get_remote_sender_id(), goal.to_dict())

func _broadcast_goal_state() -> void:
    _receive_goal_state.rpc(goal.to_dict())

@rpc("authority", "call_local", "reliable")
func _receive_goal_state(state: Dictionary) -> void:
    goal_label.text = "Meta colectiva: %d / %d fichas" % [state["total"], state["target"]]
    unlocked_banner.visible = state["unlocked"]
```

- [ ] **Step 2: Modifica `scenes/casino_floor.tscn`** para adjuntar el script y añadir los nodos de UI

Contenido completo del archivo:

```
[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene" path="res://scenes/blackjack_table_net.tscn" id="1"]
[ext_resource type="Script" path="res://scripts/net/casino_floor.gd" id="2"]

[node name="CasinoFloor" type="Node2D"]
script = ExtResource("2")

[node name="BlackjackTableNet" parent="." instance=ExtResource("1")]

[node name="GoalLabel" type="Label" parent="."]
offset_left = 650.0
offset_top = 20.0
offset_right = 1000.0
offset_bottom = 44.0
text = "Meta colectiva: 0 / 1000 fichas"

[node name="UnlockedBanner" type="Label" parent="."]
offset_left = 650.0
offset_top = 56.0
offset_right = 1000.0
offset_bottom = 90.0
text = "¡Meta colectiva alcanzada! Nueva mesa desbloqueada."
visible = false
```

- [ ] **Step 3: Ejecuta la suite completa de tests, confirma que sigue en verde**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: PASS — todos los tests (unitarios, sin red) siguen pasando; este cambio es capa de escena/red, no tocado por GUT.

- [ ] **Step 4: Verificación manual multijugador (2+ instancias locales, como en Plan 3)**

1. Lanza 2 instancias del proyecto en local, host + cliente, entra a `CasinoFloor` (misma ruta manual que Plan 3 usa para probar la mesa).
2. Ambos jugadores se sientan y apuestan hasta ganar rondas de blackjack; confirma que `GoalLabel` sube en **ambas** instancias tras cada ronda ganada por cualquiera de los dos jugadores (no solo el que jugó esa mesa).
3. Sigue jugando hasta que el total acumulado alcance `GOAL_TARGET` (1000); confirma que `UnlockedBanner` se hace visible en ambas instancias en el mismo momento.
4. Cierra el cliente, vuelve a entrar (reconexión tardía) después de que el host ya acumuló progreso: confirma que el cliente que entra tarde recibe el `GoalLabel`/`UnlockedBanner` correctos al conectar, no un contador en 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/net/casino_floor.gd scenes/casino_floor.tscn
git commit -m "feat: add CasinoFloor collective goal broadcast and unlock banner"
```

---

## Self-Review

**Cobertura de spec:**
- "meta colectiva de grupo... acumular X fichas entre todos los presentes" → Task 1 (`CollectiveGoal`) + Task 4 (`GOAL_TARGET = 1000`, host acumula de todos los jugadores).
- "sumando lo que gana cada uno independientemente de en qué mesa juegue" → Task 2/3 propagan `chips_won` desde la mesa hasta `CasinoFloor`, que es el nivel compartido (no atado a una mesa concreta).
- "desbloquea algo (nueva mesa, cosmético, etc.)" → Task 4, `UnlockedBanner` visible para todos vía broadcast.
- Sincronización a clientes que entran tarde (mismo patrón que Plan 3 ya tuvo que arreglar) → Task 4, `request_goal_state`/`_request_goal_state`.
- Fuera de alcance respetado: sin misiones, sin logros individuales, sin nuevas mesas de verdad (el desbloqueo es un anuncio, no un juego nuevo — eso pertenece a Plans 5/6).

**Placeholders:** ninguno — todo el código de cada step es completo y ejecutable.

**Consistencia de tipos:** `chips_won(player_id: int, amount: int)` idéntico en `BlackjackTableState` (Task 2) y `TableController` (Task 3). `CollectiveGoal.add_chips(amount: int) -> bool` y `.to_dict()` usados igual en Task 1 y Task 4. `GOAL_TARGET` es la única constante mágica nueva, documentada en el propio archivo.

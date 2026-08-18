# CasinoFloor Compartido + Blackjack Multijugador Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convertir el Blackjack en solitario (Plan 1) en el primer slice multijugador jugable: varios jugadores sentados a la misma mesa de Blackjack, con el host como autoridad, y el estado de la mesa visible en tiempo real para todos los presentes en el `CasinoFloor` (estén sentados o no).

**Architecture:** Una nueva clase de lógica pura `BlackjackTableState` (multi-asiento, reutiliza `Card`/`Hand`/`Deck`/`ChipLedger` de Plan 1 sin tocarlos) vive solo en el host. `TableController` es el envoltorio de red: recibe acciones de los clientes por RPC (`request_sit`, `request_bet`, `request_hit`, `request_stand`), las valida contra `BlackjackTableState`, y retransmite el estado resultante a todos por RPC. La escena `CasinoFloor` aloja la mesa; `LobbyMenu` (de Plan 2) pasa a ella en cuanto el lobby está listo.

**Tech Stack:** Godot 4.4+, GDScript, GUT (lógica de `BlackjackTableState`), `MultiplayerAPI`/RPCs nativos de Godot sobre el `SteamMultiplayerPeer` que deja listo Plan 2.

**Spec:** `docs/superpowers/specs/2026-08-17-casino-multiplayer-design.md`

## Global Constraints

- No se toca `scripts/blackjack/blackjack_game.gd` ni `scenes/blackjack_table.*` de Plan 1 — siguen siendo la mesa en solitario. Este plan añade una clase y unas escenas nuevas para el caso multijugador, no reemplaza las de Plan 1.
- Servidor autoritativo: toda decisión de juego (repartir, validar apuesta, resolver pago) ocurre solo en el host (`multiplayer.is_server()`); los clientes solo envían intención y reciben estado.
- El servidor tiene siempre `unique_id == 1` en el `MultiplayerAPI` de Godot (así lo garantiza el protocolo, independientemente del transporte) — los clientes dirigen sus RPCs de acción con `rpc_id(1, ...)`.
- Mesa con 4 asientos fijos (`SEAT_COUNT = 4`) — suficiente para 1v1/2v2 alrededor de una mesa; ampliar el número es un cambio de una constante, no de arquitectura, si hiciera falta más adelante.
- Sin persistencia entre partidas — el estado de la mesa vive solo en memoria del host mientras dura la sesión.

## Nota sobre testing en este plan

`BlackjackTableState` es lógica pura (Task 1 y 2) y se testea con GUT igual que
en Plan 1, sin red de por medio. `TableController` y las escenas (Task 3 y 4)
sí dependen de una sesión multijugador real ya establecida (Plan 2) y se
verifican manualmente con dos instancias — mismo criterio que Plan 2.

---

## Task 1: BlackjackTableState — asientos y apuestas

**Files:**
- Create: `scripts/blackjack/blackjack_table_state.gd`
- Test: `tests/unit/test_blackjack_table_state.gd`

**Interfaces:**
- Consume: `ChipLedger` (Plan 1, `scripts/chip_ledger.gd`), `Deck`/`Card`/`Hand` (Plan 1, `scripts/blackjack/`).
- Produce: `BlackjackTableState.new(deck: Deck = null)`, constante `SEAT_COUNT = 4`, propiedad `seats: Array` (tamaño 4, cada elemento `null` o un objeto `Seat` con `player_id: int`, `ledger: ChipLedger`, `hand: Hand`, `current_bet: int`), propiedades `round_active: bool`, `active_seat_index: int`, método `sit(seat_index: int, player_id: int) -> bool`, `place_bet(seat_index: int, player_id: int, amount: int) -> bool`. Usado por Task 2 (mismo archivo, añade `hit`/`stand`/resolución) y por `TableController` (Task 3).

- [ ] **Step 1: Escribir los tests**

```gdscript
extends GutTest

func test_sit_occupies_empty_seat():
    var table = BlackjackTableState.new()
    var ok = table.sit(0, 111)
    assert_true(ok)
    assert_eq(table.seats[0].player_id, 111)

func test_sit_fails_on_occupied_seat():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    var ok = table.sit(0, 222)
    assert_false(ok)

func test_sit_fails_if_player_already_seated_elsewhere():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    var ok = table.sit(1, 111)
    assert_false(ok)

func test_sit_fails_on_out_of_range_seat():
    var table = BlackjackTableState.new()
    var ok = table.sit(4, 111)
    assert_false(ok)

func test_round_does_not_start_until_all_seated_players_bet():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.place_bet(0, 111, 100)
    assert_false(table.round_active)
    table.place_bet(1, 222, 100)
    assert_true(table.round_active)

func test_place_bet_fails_for_unseated_or_wrong_player():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    var ok = table.place_bet(0, 999, 100)
    assert_false(ok)
    assert_false(table.round_active)
```

Guardar en `tests/unit/test_blackjack_table_state.gd`.

- [ ] **Step 2: Ejecutar y verificar que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `Identifier "BlackjackTableState" not declared`.

- [ ] **Step 3: Implementar BlackjackTableState (parte 1: asientos y apuestas)**

```gdscript
class_name BlackjackTableState
extends RefCounted

const SEAT_COUNT := 4

class Seat:
    var player_id: int = 0
    var ledger: ChipLedger
    var hand: Hand
    var current_bet: int = 0
    var has_acted: bool = false

var seats: Array = []
var dealer_hand: Hand
var deck: Deck
var active_seat_index: int = -1
var round_active: bool = false

func _init(p_deck: Deck = null) -> void:
    deck = p_deck if p_deck else Deck.new()
    for i in range(SEAT_COUNT):
        seats.append(null)

func sit(seat_index: int, player_id: int) -> bool:
    if seat_index < 0 or seat_index >= SEAT_COUNT:
        return false
    if seats[seat_index] != null:
        return false
    for s in seats:
        if s != null and s.player_id == player_id:
            return false
    var seat := Seat.new()
    seat.player_id = player_id
    seat.ledger = ChipLedger.new(500)
    seats[seat_index] = seat
    return true

func place_bet(seat_index: int, player_id: int, amount: int) -> bool:
    var seat = _seat_for(seat_index, player_id)
    if seat == null or round_active:
        return false
    if not seat.ledger.place_bet(amount):
        return false
    seat.current_bet = amount
    if _all_seated_players_have_bet():
        _start_round()
    return true

func _seat_for(seat_index: int, player_id: int):
    if seat_index < 0 or seat_index >= SEAT_COUNT:
        return null
    var seat = seats[seat_index]
    if seat == null or seat.player_id != player_id:
        return null
    return seat

func _all_seated_players_have_bet() -> bool:
    var any_seated := false
    for seat in seats:
        if seat == null:
            continue
        any_seated = true
        if seat.current_bet == 0:
            return false
    return any_seated

func _start_round() -> void:
    round_active = true
    dealer_hand = Hand.new()
    for seat in seats:
        if seat == null:
            continue
        seat.hand = Hand.new()
        seat.has_acted = false
    for seat in seats:
        if seat == null:
            continue
        seat.hand.add_card(deck.draw_card())
    dealer_hand.add_card(deck.draw_card())
    for seat in seats:
        if seat == null:
            continue
        seat.hand.add_card(deck.draw_card())
    dealer_hand.add_card(deck.draw_card())
    active_seat_index = _first_seated_index()
    if active_seat_index == -1:
        round_active = false

func _first_seated_index() -> int:
    for i in range(SEAT_COUNT):
        if seats[i] != null:
            return i
    return -1
```

Guardar en `scripts/blackjack/blackjack_table_state.gd`. `hit`/`stand`/resolución de pagos se añaden en Task 2 — con esto ya deberían pasar los tests de Task 1 (el reparto deja `round_active = true` y `active_seat_index` en el primer asiento ocupado, pero nada más consume esas cartas todavía).

- [ ] **Step 4: Ejecutar y verificar que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests de `test_blackjack_table_state.gd` en verde, `0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/blackjack/blackjack_table_state.gd tests/unit/test_blackjack_table_state.gd
git commit -m "feat: add BlackjackTableState multi-seat seating and betting gate"
```

---

## Task 2: BlackjackTableState — turnos y resolución de pagos

**Files:**
- Modify: `scripts/blackjack/blackjack_table_state.gd`
- Modify: `tests/unit/test_blackjack_table_state.gd`

**Interfaces:**
- Produce (añadido a `BlackjackTableState`): `hit(seat_index: int, player_id: int) -> bool`, `stand(seat_index: int, player_id: int) -> bool`, `to_dict() -> Dictionary`.

- [ ] **Step 1: Añadir los tests de turnos y resolución**

Añadir al final de `tests/unit/test_blackjack_table_state.gd`:

```gdscript
func _stub_deck(draw_order: Array) -> Deck:
    var deck = Deck.new()
    deck.cards = draw_order.duplicate()
    deck.cards.reverse()
    return deck

func test_full_round_multiple_seats_resolve_independently():
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
    assert_true(table.round_active)
    assert_eq(table.active_seat_index, 0)

    assert_true(table.stand(0, 111))
    assert_eq(table.active_seat_index, 1)

    assert_true(table.hit(1, 222))
    assert_false(table.round_active) # los dos asientos se resolvieron, ronda cerrada

    assert_eq(table.seats[0].ledger.balance, 600) # 500 - 100 + 200 (gana 20 vs 17)
    assert_eq(table.seats[1].ledger.balance, 450) # 500 - 50, bust, sin pago

func test_actions_rejected_when_not_your_turn_or_not_your_seat():
    var deck = _stub_deck([
        Card.new(10, Card.Suit.HEARTS),
        Card.new(6, Card.Suit.SPADES),
        Card.new(9, Card.Suit.HEARTS),
        Card.new(9, Card.Suit.SPADES),
        Card.new(7, Card.Suit.SPADES),
        Card.new(8, Card.Suit.SPADES),
    ])
    var table = BlackjackTableState.new(deck)
    table.sit(0, 111)
    table.sit(1, 222)
    table.place_bet(0, 111, 100)
    table.place_bet(1, 222, 100)
    # el turno activo es el asiento 0 (jugador 111); el asiento 1 intenta jugar fuera de turno
    var ok = table.hit(1, 222)
    assert_false(ok)
    assert_eq(table.active_seat_index, 0)
    # alguien que no ocupa el asiento 0 intenta actuar en su nombre
    var ok2 = table.stand(0, 999)
    assert_false(ok2)
    assert_eq(table.active_seat_index, 0)

func test_to_dict_reflects_seat_and_dealer_state():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    var data = table.to_dict()
    assert_eq(data["seats"][0]["player_id"], 111)
    assert_eq(data["seats"][1], null)
    assert_eq(data["round_active"], false)
```

- [ ] **Step 2: Ejecutar y verificar que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `Invalid call. Nonexistent function 'hit'/'stand'/'to_dict'`.

- [ ] **Step 3: Implementar hit/stand/resolución/to_dict**

Añadir dentro de `scripts/blackjack/blackjack_table_state.gd`:

```gdscript
func hit(seat_index: int, player_id: int) -> bool:
    var seat = _seat_for(seat_index, player_id)
    if seat == null or not round_active or active_seat_index != seat_index:
        return false
    seat.hand.add_card(deck.draw_card())
    if seat.hand.is_bust():
        seat.has_acted = true
        _advance_turn()
    return true

func stand(seat_index: int, player_id: int) -> bool:
    var seat = _seat_for(seat_index, player_id)
    if seat == null or not round_active or active_seat_index != seat_index:
        return false
    seat.has_acted = true
    _advance_turn()
    return true

func _advance_turn() -> void:
    var next := active_seat_index + 1
    while next < SEAT_COUNT and seats[next] == null:
        next += 1
    if next < SEAT_COUNT:
        active_seat_index = next
    else:
        active_seat_index = -1
        _resolve_round()

func _resolve_round() -> void:
    var any_seat_not_bust := false
    for seat in seats:
        if seat != null and not seat.hand.is_bust():
            any_seat_not_bust = true
            break
    if any_seat_not_bust:
        while dealer_hand.value() < 17:
            dealer_hand.add_card(deck.draw_card())
    for seat in seats:
        if seat == null:
            continue
        _resolve_seat_payout(seat)
        seat.current_bet = 0
    round_active = false

func _resolve_seat_payout(seat) -> void:
    if seat.hand.is_bust():
        return
    if dealer_hand.is_bust():
        seat.ledger.payout(seat.current_bet * 2)
        return
    if seat.hand.value() > dealer_hand.value():
        seat.ledger.payout(seat.current_bet * 2)
    elif seat.hand.value() == dealer_hand.value():
        seat.ledger.payout(seat.current_bet)

func to_dict() -> Dictionary:
    var seats_data := []
    for seat in seats:
        if seat == null:
            seats_data.append(null)
        else:
            seats_data.append({
                "player_id": seat.player_id,
                "balance": seat.ledger.balance,
                "bet": seat.current_bet,
                "hand_value": seat.hand.value() if seat.hand else 0,
            })
    return {
        "seats": seats_data,
        "dealer_value": dealer_hand.value() if dealer_hand else 0,
        "active_seat_index": active_seat_index,
        "round_active": round_active,
    }
```

- [ ] **Step 4: Ejecutar y verificar que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests en verde, `0 failed`, incluidos los de Task 1.

- [ ] **Step 5: Commit**

```bash
git add scripts/blackjack/blackjack_table_state.gd tests/unit/test_blackjack_table_state.gd
git commit -m "feat: add turn actions and per-seat payout resolution to BlackjackTableState"
```

---

## Task 3: TableController — puente de red sobre BlackjackTableState

**Files:**
- Create: `scripts/net/table_controller.gd`

**Interfaces:**
- Consume: `BlackjackTableState` (Task 1/2 completo), `multiplayer.is_server()`, `multiplayer.get_remote_sender_id()` (API estándar de Godot).
- Produce: nodo `TableController` con señal `state_changed(state: Dictionary)`, RPCs `request_sit(seat_index: int)`, `request_bet(seat_index: int, amount: int)`, `request_hit(seat_index: int)`, `request_stand(seat_index: int)` — invocados por el cliente vía `rpc_id(1, ...)`. Usado por `BlackjackTableNet` (Task 4).

- [ ] **Step 1: Implementar TableController**

```gdscript
class_name TableController
extends Node

signal state_changed(state: Dictionary)

var table_state: BlackjackTableState

func _ready() -> void:
    if multiplayer.is_server():
        table_state = BlackjackTableState.new()

@rpc("any_peer", "call_remote", "reliable")
func request_sit(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    var player_id := multiplayer.get_remote_sender_id()
    if table_state.sit(seat_index, player_id):
        _broadcast_state()

@rpc("any_peer", "call_remote", "reliable")
func request_bet(seat_index: int, amount: int) -> void:
    if not multiplayer.is_server():
        return
    var player_id := multiplayer.get_remote_sender_id()
    if table_state.place_bet(seat_index, player_id, amount):
        _broadcast_state()

@rpc("any_peer", "call_remote", "reliable")
func request_hit(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    var player_id := multiplayer.get_remote_sender_id()
    if table_state.hit(seat_index, player_id):
        _broadcast_state()

@rpc("any_peer", "call_remote", "reliable")
func request_stand(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    var player_id := multiplayer.get_remote_sender_id()
    if table_state.stand(seat_index, player_id):
        _broadcast_state()

func _broadcast_state() -> void:
    _receive_state.rpc(table_state.to_dict())

@rpc("authority", "call_local", "reliable")
func _receive_state(state: Dictionary) -> void:
    state_changed.emit(state)
```

Guardar en `scripts/net/table_controller.gd`. Nota: en el host, `_ready()` crea `table_state`; en los clientes queda `null` a propósito — los clientes nunca ejecutan lógica de juego, solo reciben `state_changed` y piden acciones por RPC.

- [ ] **Step 2: Verificación manual con dos cuentas**

Reutilizando el flujo de lobby de Plan 2 (una instancia crea partida, la otra se une), añade temporalmente un `TableController` como nodo hijo de la escena principal en ambas instancias y conecta:

```gdscript
$TableController.state_changed.connect(func(state): print("Estado mesa: %s" % state))
```

Desde la instancia cliente, llama `$TableController.request_sit.rpc_id(1, 0)` y luego `$TableController.request_bet.rpc_id(1, 0, 100)`. Confirma que **ambas** instancias imprimen el mismo `Estado mesa` tras cada acción (la del host porque es la fuente, la del cliente porque le llegó por `_receive_state`). Repite sentando también al host en el asiento 1 y completando una ronda con `request_hit`/`request_stand` para confirmar que el flujo completo de turnos funciona en red.

- [ ] **Step 3: Commit**

```bash
git add scripts/net/table_controller.gd
git commit -m "feat: add TableController RPC bridge for BlackjackTableState"
```

---

## Task 4: Escena CasinoFloor + mesa de Blackjack multijugador jugable

**Files:**
- Create: `scenes/casino_floor.tscn`
- Create: `scenes/blackjack_table_net.tscn`
- Create: `scenes/blackjack_table_net.gd`
- Modify: `scenes/lobby_menu.gd` (de Plan 2 — añadir el cambio de escena al `CasinoFloor`)

**Interfaces:**
- Consume: `TableController` (Task 3), `SteamManager.lobby_ready` (Plan 2).

- [ ] **Step 1: Escribir el script de la mesa jugable**

```gdscript
extends Control

@onready var table_controller: TableController = $TableController
@onready var seats_label: Label = $SeatsLabel
@onready var dealer_label: Label = $DealerLabel
@onready var sit_button: Button = $SitButton
@onready var bet_button: Button = $BetButton
@onready var hit_button: Button = $HitButton
@onready var stand_button: Button = $StandButton

var my_seat_index: int = -1

func _ready() -> void:
    table_controller.state_changed.connect(_on_state_changed)
    sit_button.pressed.connect(_on_sit_pressed)
    bet_button.pressed.connect(_on_bet_pressed)
    hit_button.pressed.connect(_on_hit_pressed)
    stand_button.pressed.connect(_on_stand_pressed)

func _on_sit_pressed() -> void:
    # Sentarse siempre en el primer asiento libre visible en pantalla; suficiente para
    # la verificación manual de este plan — un selector de asiento por UI queda fuera
    # de alcance aquí.
    table_controller.request_sit.rpc_id(1, 0)
    my_seat_index = 0

func _on_bet_pressed() -> void:
    table_controller.request_bet.rpc_id(1, my_seat_index, 50)

func _on_hit_pressed() -> void:
    table_controller.request_hit.rpc_id(1, my_seat_index)

func _on_stand_pressed() -> void:
    table_controller.request_stand.rpc_id(1, my_seat_index)

func _on_state_changed(state: Dictionary) -> void:
    dealer_label.text = "Banca: %d" % state["dealer_value"]
    var lines: Array[String] = []
    for i in range(state["seats"].size()):
        var seat = state["seats"][i]
        if seat == null:
            lines.append("Asiento %d: libre" % i)
        else:
            lines.append("Asiento %d: jugador %d — fichas %d — apuesta %d — mano %d" % [
                i, seat["player_id"], seat["balance"], seat["bet"], seat["hand_value"]
            ])
    seats_label.text = "\n".join(lines)
```

Guardar en `scenes/blackjack_table_net.gd`.

- [ ] **Step 2: Crear las escenas en el editor de Godot**

`scenes/blackjack_table_net.tscn`: raíz `Control`, hijos `TableController` (nodo `Node` con el script de Task 3), `Label` `SeatsLabel`, `Label` `DealerLabel`, `Button` `SitButton` ("Sentarse"), `Button` `BetButton` ("Apostar 50"), `Button` `HitButton` ("Pedir"), `Button` `StandButton` ("Plantarse"). Adjuntar `scenes/blackjack_table_net.gd` a la raíz.

`scenes/casino_floor.tscn`: raíz `Node2D` (o `Control`), con `scenes/blackjack_table_net.tscn` instanciada como hijo. Sin script propio por ahora — solo aloja la mesa.

- [ ] **Step 3: Conectar el paso de LobbyMenu a CasinoFloor**

En `scenes/lobby_menu.gd` (creado en Plan 2), dentro de `_on_lobby_ready`, añadir la transición de escena:

```gdscript
func _on_lobby_ready(_lobby_id: int, _is_owner: bool) -> void:
    invite_button.disabled = false
    _refresh_members()
    get_tree().change_scene_to_file("res://scenes/casino_floor.tscn")
```

(Sustituye por completo el cuerpo anterior de la función — añade la línea de cambio de escena al final, conservando las dos líneas ya existentes.)

- [ ] **Step 4: Verificación manual con dos cuentas (flujo completo)**

Repite el flujo de invitación de Plan 2 (A crea partida, invita a B, B acepta) hasta llegar a `CasinoFloor` en ambas instancias. En A: pulsar "Sentarse", luego "Apostar 50". En B: pulsar "Sentarse" (asiento distinto — si `SitButton` siempre pide el asiento 0 y ya está ocupado, `request_sit` fallará silenciosamente; para esta verificación manual, edita temporalmente el índice en `_on_sit_pressed` de la instancia B a `1` antes de probar), luego "Apostar 50". Confirmar que en **ambas** pantallas aparecen los dos asientos ocupados con sus apuestas, que el turno pasa de uno a otro con "Pedir"/"Plantarse", y que al resolverse la ronda el campo "fichas" de cada asiento cambia según ganó/perdió — visible igual en las dos instancias.

- [ ] **Step 5: Commit**

```bash
git add scenes/casino_floor.tscn scenes/blackjack_table_net.tscn scenes/blackjack_table_net.gd scenes/lobby_menu.gd
git commit -m "feat: add CasinoFloor scene with playable multiplayer Blackjack table"
```

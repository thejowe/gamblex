# Conectar el Pozo Compartido de Modo Batalla a las 7 Mesas — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hacer que, en Modo Batalla, cada apuesta o pago en cualquiera de las 7 mesas mute el `ChipLedger` compartido del equipo (no un `ChipLedger` individual por asiento), y que `MatchRules` se entere de cada cambio para decidir meta alcanzada / bancarrota en vivo.

**Architecture:** `CasinoFloor` inyecta, en cada `TableController`, un `Callable` que resuelve `player_id -> ChipLedger` del equipo (o `null` fuera de modo batalla) y otro `Callable` que avisa a `BattleController` tras cualquier mutación. Cada uno de los 7 `*_table_state.gd` acepta ese ledger externo en su único punto de creación de asiento/jugador. `TeamChipPool`/`MatchRules`/`BattleController` (Plan 4) no cambian su lógica, solo ganan los 3 métodos de conexión que faltaban.

**Tech Stack:** Godot 4.7 / GDScript, GUT para tests unitarios (sin tocar `.rpc()`/multiplayer real en ningún test de este plan).

**Spec:** `docs/superpowers/specs/2026-08-24-battle-pool-wiring-design.md` (léelo completo antes de empezar).

## Global Constraints

- No tocar Modo Libre (`CollectiveGoal`, la rama `else:` de `_ready()` en `casino_floor.gd`).
- No tocar ninguna función de reglas de apuesta/turno/evaluación de manos/pago de ninguno de los 7 juegos — solo el origen del `ChipLedger` en su punto de creación.
- No tocar `TeamChipPool`, `MatchRules`, `TeamAssignment` — ya están completos y probados (Plan 4).
- Ningún test nuevo llama a `.rpc()` ni depende de un `MultiplayerPeer` real — construye los objetos directamente (mismo patrón que `test_match_rules.gd`/`test_team_chip_pool.gd`), igual que el resto de este repo.
- Trabaja en worktree aislado, rama `feature/battle-pool-wiring` — nunca en el checkout compartido de pilar.
- Godot para tests/verificación: `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`. Reconstruye la caché de clases (`godot --headless --editor --quit --path .`) antes de confiar en un run de GUT, y revisa `git status` después por si el editor reformateó espacios/tabs en archivos que no tocaste.

---

## Task 1: `BattleController` — métodos de conexión

**Files:**
- Modify: `scripts/net/battle_controller.gd`
- Test: `tests/unit/test_battle_controller.gd` (nuevo)

**Interfaces:**
- Consumes: `assignment.team_for(player_id) -> int` (ya existe, `scripts/battle/team_assignment.gd`); `pools[i].ledger: ChipLedger` (ya existe, `scripts/battle/team_chip_pool.gd`); `rules.on_balance_changed() -> bool` (ya existe, `scripts/battle/match_rules.gd`).
- Produces: `team_for(player_id: int) -> int`, `ledger_for_team(team_id: int) -> ChipLedger`, `notify_balance_possibly_changed() -> void`. Las Tareas 2-9 llaman a los tres.

- [ ] **Step 1: Escribe los tests que fallan**

```gdscript
# tests/unit/test_battle_controller.gd
extends GutTest

func test_team_for_returns_minus_one_before_match_starts():
	var controller := BattleController.new()
	assert_eq(controller.team_for(999), -1)

func test_team_for_resolves_after_manual_assignment_setup():
	var controller := BattleController.new()
	controller.assignment = TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	controller.assignment.join(111)
	controller.assignment.join(222)
	assert_eq(controller.team_for(111), 0)
	assert_eq(controller.team_for(222), 1)
	assert_eq(controller.team_for(999), -1)

func test_ledger_for_team_returns_the_pool_ledger_object():
	var controller := BattleController.new()
	controller.pools = [TeamChipPool.new(0, 500), TeamChipPool.new(1, 500)]
	assert_eq(controller.ledger_for_team(0), controller.pools[0].ledger)
	assert_eq(controller.ledger_for_team(0).balance, 500)
```

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_battle_controller.gd -gexit`
Expected: FAIL — `team_for`/`ledger_for_team` no existen todavía.

- [ ] **Step 3: Implementa**

Añade al final de `scripts/net/battle_controller.gd` (después de `apply_payout`, antes de `_process`):

```gdscript
func team_for(player_id: int) -> int:
	if assignment == null:
		return -1
	return assignment.team_for(player_id)

func ledger_for_team(team_id: int) -> ChipLedger:
	return pools[team_id].ledger

# Las apuestas/pagos reales de cada mesa mutan directamente el ChipLedger
# compartido (inyectado vía TableController.shared_ledger_provider, Tareas
# 2-9), no pasan por apply_bet()/apply_payout() — así que MatchRules nunca
# se entera del cambio de saldo a menos que alguien se lo diga. Este método
# es ese aviso: cada TableController lo llama tras cualquier
# _broadcast_state() suyo mientras el partido está en marcha.
func notify_balance_possibly_changed() -> void:
	if rules == null or rules.finished:
		return
	if rules.on_balance_changed():
		_broadcast_match_state()
```

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_battle_controller.gd -gexit`
Expected: PASS, 3/3.

- [ ] **Step 5: Commit**

```bash
git add scripts/net/battle_controller.gd tests/unit/test_battle_controller.gd
git commit -m "feat(battle): add team_for/ledger_for_team/notify_balance_possibly_changed"
```

---

## Task 2: `CasinoFloor` — inyecta el ledger compartido en las 7 mesas

**Files:**
- Modify: `scripts/net/casino_floor.gd`
- Test: `tests/unit/test_casino_floor_ledger_wiring.gd` (nuevo)

**Interfaces:**
- Consumes: `battle_controller.team_for(player_id)`, `battle_controller.ledger_for_team(team_id)` (Task 1).
- Produces: `_ledger_for_player(player_id: int) -> ChipLedger`, `_inject_shared_ledger_providers() -> void`. Se llama una vez al final de `_ready()` cuando `multiplayer.is_server()`.

- [ ] **Step 1: Escribe los tests que fallan**

```gdscript
# tests/unit/test_casino_floor_ledger_wiring.gd
extends GutTest

func test_ledger_for_player_returns_null_outside_battle_mode():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor._is_battle_mode = false
	assert_eq(casino_floor._ledger_for_player(111), null)

func test_ledger_for_player_returns_team_pool_ledger_in_battle_mode():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor._is_battle_mode = true
	casino_floor.battle_controller = BattleController.new()
	casino_floor.battle_controller.assignment = TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	casino_floor.battle_controller.assignment.join(111)
	casino_floor.battle_controller.pools = [TeamChipPool.new(0, 500), TeamChipPool.new(1, 500)]
	var ledger := casino_floor._ledger_for_player(111)
	assert_eq(ledger, casino_floor.battle_controller.pools[0].ledger)

func test_ledger_for_player_returns_null_for_unassigned_player():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor._is_battle_mode = true
	casino_floor.battle_controller = BattleController.new()
	casino_floor.battle_controller.assignment = TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	assert_eq(casino_floor._ledger_for_player(999), null)
```

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_floor_ledger_wiring.gd -gexit`
Expected: FAIL — `_ledger_for_player` no existe todavía.

- [ ] **Step 3: Implementa**

En `scripts/net/casino_floor.gd`, añade tras `_refresh_battle_label()` (final del archivo):

```gdscript
func _ledger_for_player(player_id: int) -> ChipLedger:
	if not _is_battle_mode:
		return null
	var team_id := battle_controller.team_for(player_id)
	if team_id == -1:
		return null
	return battle_controller.ledger_for_team(team_id)

const CONTROLLER_CLASS_NAMES := [
	"TableController", "RouletteTableController", "PokerTableController",
	"DiceTableController", "CrashTableController", "MinesTableController",
	"PlinkoTableController",
]

func _inject_shared_ledger_providers() -> void:
	for controller_class in CONTROLLER_CLASS_NAMES:
		for controller in find_children("*", controller_class, true, false):
			controller.shared_ledger_provider = _ledger_for_player
			if _is_battle_mode:
				controller.on_shared_ledger_changed = battle_controller.notify_balance_possibly_changed
```

Y modifica `_ready()` para llamarlo — el bloque `if multiplayer.is_server():` queda así (añade la última línea, no toques nada anterior):

```gdscript
	if multiplayer.is_server():
		if _is_battle_mode:
			battle_controller.start_match(SteamManager.chosen_match_type, BATTLE_GOAL_BALANCE, BATTLE_TIME_LIMIT_SEC, BATTLE_STARTING_BALANCE)
			battle_controller.join(multiplayer.get_unique_id())
		else:
			goal = CollectiveGoal.new(GOAL_TARGET)
			for controller in find_children("*", "TableController", true, false):
				controller.chips_won.connect(_on_chips_won)
			for controller in find_children("*", "DiceTableController", true, false):
				controller.chips_won.connect(_on_chips_won)
			for controller in find_children("*", "CrashTableController", true, false):
				controller.chips_won.connect(_on_chips_won)
			for controller in find_children("*", "MinesTableController", true, false):
				controller.chips_won.connect(_on_chips_won)
			for controller in find_children("*", "PlinkoTableController", true, false):
				controller.chips_won.connect(_on_chips_won)
			_broadcast_goal_state()
		_inject_shared_ledger_providers()
```

(`_inject_shared_ledger_providers()` va **después** del `if/else`, al mismo nivel de indentación, para que en modo batalla `battle_controller.pools`/`rules` ya existan — los crea `start_match()` justo arriba — antes de que algo intente leerlos.)

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_floor_ledger_wiring.gd -gexit`
Expected: PASS, 3/3.

- [ ] **Step 5: Commit**

```bash
git add scripts/net/casino_floor.gd tests/unit/test_casino_floor_ledger_wiring.gd
git commit -m "feat(casino-floor): inject shared team ledger provider into every table controller"
```

---

## Task 3: Blackjack — usa el ledger compartido al sentarse

**Files:**
- Modify: `scripts/blackjack/blackjack_table_state.gd:26-38` (función `sit`)
- Modify: `scripts/net/table_controller.gd`
- Test: `tests/unit/test_blackjack_table_state.gd` (añade al final)

**Interfaces:**
- Consumes: nada nuevo de otras tareas.
- Produces: `BlackjackTableState.sit(seat_index, player_id, external_ledger: ChipLedger = null)`; `TableController.shared_ledger_provider`/`on_shared_ledger_changed` (mismos nombres que consumirá Task 2 vía `_inject_shared_ledger_providers`).

- [ ] **Step 1: Escribe los tests que fallan**

Añade al final de `tests/unit/test_blackjack_table_state.gd`:

```gdscript
func test_sit_uses_external_ledger_when_provided():
	var table = BlackjackTableState.new()
	var shared := ChipLedger.new(500)
	table.sit(0, 111, shared)
	assert_eq(table.seats[0].ledger, shared)

func test_sit_creates_individual_ledger_when_no_external_ledger_given():
	var table = BlackjackTableState.new()
	table.sit(0, 111)
	assert_eq(table.seats[0].ledger.balance, 500)

func test_shared_ledger_bet_is_visible_to_both_seats_on_the_same_team():
	var table = BlackjackTableState.new()
	var shared := ChipLedger.new(500)
	table.sit(0, 111, shared)
	table.sit(1, 222, shared)
	table.place_bet(0, 111, 100)
	assert_eq(shared.balance, 400)
	assert_eq(table.seats[1].ledger.balance, 400)
```

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_blackjack_table_state.gd -gexit`
Expected: FAIL en los 3 tests nuevos — `sit()` no acepta un tercer argumento todavía.

- [ ] **Step 3: Implementa**

Reemplaza `sit()` en `scripts/blackjack/blackjack_table_state.gd` (líneas 26-38):

```gdscript
func sit(seat_index: int, player_id: int, external_ledger: ChipLedger = null) -> bool:
	if seat_index < 0 or seat_index >= SEAT_COUNT:
		return false
	if seats[seat_index] != null:
		return false
	for s in seats:
		if s != null and s.player_id == player_id:
			return false
	var seat := Seat.new()
	seat.player_id = player_id
	seat.ledger = external_ledger if external_ledger != null else ChipLedger.new(500)
	seats[seat_index] = seat
	return true
```

En `scripts/net/table_controller.gd`, añade dos variables tras `var table_state: BlackjackTableState`:

```gdscript
var shared_ledger_provider: Callable = Callable()
var on_shared_ledger_changed: Callable = Callable()
```

Reemplaza `_apply_sit`:

```gdscript
func _apply_sit(seat_index: int, player_id: int) -> void:
    var external_ledger: ChipLedger = shared_ledger_provider.call(player_id) if shared_ledger_provider.is_valid() else null
    if table_state.sit(seat_index, player_id, external_ledger):
        _broadcast_state()
```

Reemplaza `_broadcast_state`:

```gdscript
func _broadcast_state() -> void:
    _receive_state.rpc(table_state.to_dict())
    if on_shared_ledger_changed.is_valid():
        on_shared_ledger_changed.call()
```

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_blackjack_table_state.gd -gexit`
Expected: PASS, todos los tests del archivo.

- [ ] **Step 5: Commit**

```bash
git add scripts/blackjack/blackjack_table_state.gd scripts/net/table_controller.gd tests/unit/test_blackjack_table_state.gd
git commit -m "feat(blackjack): accept shared team ledger on sit"
```

---

## Task 4: Ruleta — mismo patrón

**Files:**
- Modify: `scripts/roulette/roulette_table_state.gd:29-41` (función `sit`)
- Modify: `scripts/net/roulette_table_controller.gd`
- Test: `tests/unit/test_roulette_table_state.gd` (añade al final; si el archivo no existe con ese nombre exacto, créalo siguiendo el mismo `extends GutTest` que el resto)

**Interfaces:**
- Produces: `RouletteTableState.sit(seat_index, player_id, external_ledger: ChipLedger = null)`; `RouletteTableController.shared_ledger_provider`/`on_shared_ledger_changed`.

- [ ] **Step 1: Escribe los tests que fallan**

```gdscript
func test_sit_uses_external_ledger_when_provided():
	var table = RouletteTableState.new()
	var shared := ChipLedger.new(500)
	table.sit(0, 111, shared)
	assert_eq(table.seats[0].ledger, shared)

func test_sit_creates_individual_ledger_when_no_external_ledger_given():
	var table = RouletteTableState.new()
	table.sit(0, 111)
	assert_eq(table.seats[0].ledger.balance, 500)
```

(Añádelos al archivo de test existente de Ruleta — localízalo con `ls tests/unit | grep -i roulette` antes de escribir, para no duplicar un archivo con otro nombre.)

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=<archivo_de_test_de_ruleta> -gexit`
Expected: FAIL — `sit()` no acepta un tercer argumento todavía.

- [ ] **Step 3: Implementa**

Reemplaza `sit()` en `scripts/roulette/roulette_table_state.gd` (líneas 29-41):

```gdscript
func sit(seat_index: int, player_id: int, external_ledger: ChipLedger = null) -> bool:
    if seat_index < 0 or seat_index >= SEAT_COUNT:
        return false
    if seats[seat_index] != null:
        return false
    for s in seats:
        if s != null and s.player_id == player_id:
            return false
    var seat := Seat.new()
    seat.player_id = player_id
    seat.ledger = external_ledger if external_ledger != null else ChipLedger.new(500)
    seats[seat_index] = seat
    return true
```

En `scripts/net/roulette_table_controller.gd`, añade tras `var table_state: RouletteTableState`:

```gdscript
var shared_ledger_provider: Callable = Callable()
var on_shared_ledger_changed: Callable = Callable()
```

Reemplaza `_apply_sit`:

```gdscript
func _apply_sit(seat_index: int, player_id: int) -> void:
    var external_ledger: ChipLedger = shared_ledger_provider.call(player_id) if shared_ledger_provider.is_valid() else null
    if table_state.sit(seat_index, player_id, external_ledger):
        _broadcast_state()
```

Reemplaza `_broadcast_state`:

```gdscript
func _broadcast_state() -> void:
    _receive_state.rpc(table_state.to_dict())
    if on_shared_ledger_changed.is_valid():
        on_shared_ledger_changed.call()
```

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=<archivo_de_test_de_ruleta> -gexit`
Expected: PASS, todos los tests del archivo.

- [ ] **Step 5: Commit**

```bash
git add scripts/roulette/roulette_table_state.gd scripts/net/roulette_table_controller.gd tests/unit/
git commit -m "feat(roulette): accept shared team ledger on sit"
```

---

## Task 5: Póker — mismo patrón

**Files:**
- Modify: `scripts/poker/poker_table_state.gd:37-51` (función `sit`)
- Modify: `scripts/net/poker_table_controller.gd`
- Test: `tests/unit/test_poker_table_state.gd` (añade al final; localiza el nombre exacto con `ls tests/unit | grep -i poker`)

**Interfaces:**
- Produces: `PokerTableState.sit(seat_index, player_id, external_ledger: ChipLedger = null)`; `PokerTableController.shared_ledger_provider`/`on_shared_ledger_changed`.

- [ ] **Step 1: Escribe los tests que fallan**

```gdscript
func test_sit_uses_external_ledger_when_provided():
	var table = PokerTableState.new()
	var shared := ChipLedger.new(500)
	table.sit(0, 111, shared)
	assert_eq(table.seats[0].ledger, shared)

func test_sit_creates_individual_ledger_when_no_external_ledger_given():
	var table = PokerTableState.new()
	table.sit(0, 111)
	assert_eq(table.seats[0].ledger.balance, 500)
```

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=<archivo_de_test_de_poker> -gexit`
Expected: FAIL — `sit()` no acepta un tercer argumento todavía.

- [ ] **Step 3: Implementa**

Reemplaza `sit()` en `scripts/poker/poker_table_state.gd` (líneas 37-51):

```gdscript
func sit(seat_index: int, player_id: int, external_ledger: ChipLedger = null) -> bool:
	if hand_active:
		return false
	if seat_index < 0 or seat_index >= SEAT_COUNT:
		return false
	if seats[seat_index] != null:
		return false
	for s in seats:
		if s != null and s.player_id == player_id:
			return false
	var seat := Seat.new()
	seat.player_id = player_id
	seat.ledger = external_ledger if external_ledger != null else ChipLedger.new(STARTING_BALANCE)
	seats[seat_index] = seat
	return true
```

En `scripts/net/poker_table_controller.gd`, añade tras `var table_state: PokerTableState`:

```gdscript
var shared_ledger_provider: Callable = Callable()
var on_shared_ledger_changed: Callable = Callable()
```

Reemplaza `_apply_sit`:

```gdscript
func _apply_sit(seat_index: int, player_id: int) -> void:
    var external_ledger: ChipLedger = shared_ledger_provider.call(player_id) if shared_ledger_provider.is_valid() else null
    if table_state.sit(seat_index, player_id, external_ledger):
        _broadcast_state()
```

Reemplaza `_broadcast_state` (Póker retransmite un dict distinto por jugador, no toques esa parte — solo añade la línea final):

```gdscript
func _broadcast_state() -> void:
    state_changed.emit(table_state.to_dict(multiplayer.get_unique_id()))
    for peer_id in multiplayer.get_peers():
        _receive_state.rpc_id(peer_id, table_state.to_dict(peer_id))
    if on_shared_ledger_changed.is_valid():
        on_shared_ledger_changed.call()
```

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=<archivo_de_test_de_poker> -gexit`
Expected: PASS, todos los tests del archivo.

- [ ] **Step 5: Commit**

```bash
git add scripts/poker/poker_table_state.gd scripts/net/poker_table_controller.gd tests/unit/
git commit -m "feat(poker): accept shared team ledger on sit"
```

---

## Task 6: Dice — mismo patrón, familia de ronda independiente

**Files:**
- Modify: `scripts/dice/dice_table_state.gd` (funciones `_player_for` y `roll`)
- Modify: `scripts/net/dice_table_controller.gd`
- Test: `tests/unit/test_dice_table_state.gd` (añade al final)

**Interfaces:**
- Produces: `DiceTableState.roll(player_id, threshold, direction, amount, external_ledger: ChipLedger = null)`; `DiceTableController.shared_ledger_provider`/`on_shared_ledger_changed`.

- [ ] **Step 1: Escribe los tests que fallan**

Las tres pruebas comprueban identidad de objeto, no aritmética de saldo —
`roll()` paga inmediatamente según un resultado aleatorio, así que
cualquier assert sobre el número exacto de fichas sería inestable; el
hecho de que el `Player` termine apuntando al mismo objeto `ChipLedger`
compartido es lo único que este cambio necesita garantizar, y `place_bet`
siempre puede permitirse 100 fichas contra un saldo inicial de 500
independientemente del resultado de la tirada.

```gdscript
func test_roll_uses_external_ledger_for_new_player():
	var table = DiceTableState.new()
	var shared := ChipLedger.new(500)
	table.roll(111, 40, DiceTableState.Direction.OVER, 100, shared)
	assert_eq(table.players[111].ledger, shared)

func test_roll_creates_individual_ledger_when_no_external_ledger_given():
	var table = DiceTableState.new()
	table.roll(111, 40, DiceTableState.Direction.OVER, 100)
	assert_true(table.players.has(111))
	assert_ne(table.players[111].ledger, null)

func test_shared_ledger_persists_after_first_roll_ignoring_later_argument():
	var table = DiceTableState.new()
	var shared := ChipLedger.new(500)
	table.roll(111, 40, DiceTableState.Direction.OVER, 100, shared)
	table.roll(111, 40, DiceTableState.Direction.OVER, 50) # sin external_ledger la 2a vez
	assert_eq(table.players[111].ledger, shared)
```

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_dice_table_state.gd -gexit`
Expected: FAIL — `roll()` no acepta un quinto argumento todavía.

- [ ] **Step 3: Implementa**

En `scripts/dice/dice_table_state.gd`, reemplaza `_player_for` y la firma/cuerpo de `roll` (deja el resto de `roll` — cálculo de resultado, payout, `last_round` — intacto, solo cambia cómo se obtiene `player`):

```gdscript
func _player_for(player_id: int, external_ledger: ChipLedger = null) -> Player:
    if not players.has(player_id):
        var player := Player.new()
        player.player_id = player_id
        player.ledger = external_ledger if external_ledger != null else ChipLedger.new(STARTING_BALANCE)
        players[player_id] = player
    return players[player_id]

func roll(player_id: int, threshold: int, direction: int, amount: int, external_ledger: ChipLedger = null) -> bool:
    if threshold < 1 or threshold > 99:
        return false
    if direction != Direction.OVER and direction != Direction.UNDER:
        return false
    var player := _player_for(player_id, external_ledger)
    if not player.ledger.place_bet(amount):
        return false
```

(El resto de la función, desde `var result := roller.roll()` en adelante, no cambia — no lo reescribas, solo reemplaza las líneas de arriba en su sitio.)

En `scripts/net/dice_table_controller.gd`, añade tras `var table_state: DiceTableState`:

```gdscript
var shared_ledger_provider: Callable = Callable()
var on_shared_ledger_changed: Callable = Callable()
```

Reemplaza `_apply_roll`:

```gdscript
func _apply_roll(threshold: int, direction: int, amount: int, player_id: int) -> void:
    var external_ledger: ChipLedger = shared_ledger_provider.call(player_id) if shared_ledger_provider.is_valid() else null
    if table_state.roll(player_id, threshold, direction, amount, external_ledger):
        _broadcast_state()
```

Reemplaza `_broadcast_state`:

```gdscript
func _broadcast_state() -> void:
    _receive_state.rpc(table_state.to_dict())
    if on_shared_ledger_changed.is_valid():
        on_shared_ledger_changed.call()
```

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_dice_table_state.gd -gexit`
Expected: PASS, todos los tests del archivo.

- [ ] **Step 5: Commit**

```bash
git add scripts/dice/dice_table_state.gd scripts/net/dice_table_controller.gd tests/unit/test_dice_table_state.gd
git commit -m "feat(dice): accept shared team ledger on first roll"
```

---

## Task 7: Crash — mismo patrón, familia de ronda independiente

**Files:**
- Modify: `scripts/crash/crash_table_state.gd` (funciones `_player_for` y `place_bet`)
- Modify: `scripts/net/crash_table_controller.gd`
- Test: `tests/unit/test_crash_table_state.gd` (añade al final)

**Interfaces:**
- Produces: `CrashTableState.place_bet(player_id, amount, external_ledger: ChipLedger = null)`; `CrashTableController.shared_ledger_provider`/`on_shared_ledger_changed`.

- [ ] **Step 1: Escribe los tests que fallan**

```gdscript
func test_place_bet_uses_external_ledger_for_new_player():
	var table = CrashTableState.new()
	var shared := ChipLedger.new(500)
	table.place_bet(111, 100, shared)
	assert_eq(shared.balance, 400)

func test_place_bet_creates_individual_ledger_when_no_external_ledger_given():
	var table = CrashTableState.new()
	table.place_bet(111, 100)
	assert_eq(table.players[111].ledger.balance, 400)
```

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_crash_table_state.gd -gexit`
Expected: FAIL — `place_bet()` no acepta un tercer argumento todavía.

- [ ] **Step 3: Implementa**

En `scripts/crash/crash_table_state.gd`, reemplaza `_player_for` y la firma/cuerpo de `place_bet` (deja el resto — `crash_point`, `elapsed`, `is_active` — intacto):

```gdscript
func _player_for(player_id: int, external_ledger: ChipLedger = null) -> Player:
	if not players.has(player_id):
		var player := Player.new()
		player.player_id = player_id
		player.ledger = external_ledger if external_ledger != null else ChipLedger.new(STARTING_BALANCE)
		players[player_id] = player
	return players[player_id]

func place_bet(player_id: int, amount: int, external_ledger: ChipLedger = null) -> bool:
	var player := _player_for(player_id, external_ledger)
	if player.is_active:
		return false
	if not player.ledger.place_bet(amount):
		return false
	player.bet_amount = amount
	player.crash_point = roller.roll()
	player.elapsed = 0.0
	player.is_active = true
	return true
```

En `scripts/net/crash_table_controller.gd`, añade tras `var table_state: CrashTableState`:

```gdscript
var shared_ledger_provider: Callable = Callable()
var on_shared_ledger_changed: Callable = Callable()
```

Reemplaza `_apply_place_bet`:

```gdscript
func _apply_place_bet(amount: int, player_id: int) -> void:
	var external_ledger: ChipLedger = shared_ledger_provider.call(player_id) if shared_ledger_provider.is_valid() else null
	if table_state.place_bet(player_id, amount, external_ledger):
		_broadcast_state()
```

Reemplaza `_broadcast_state`:

```gdscript
func _broadcast_state() -> void:
	_receive_state.rpc(table_state.to_dict())
	if on_shared_ledger_changed.is_valid():
		on_shared_ledger_changed.call()
```

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_crash_table_state.gd -gexit`
Expected: PASS, todos los tests del archivo.

- [ ] **Step 5: Commit**

```bash
git add scripts/crash/crash_table_state.gd scripts/net/crash_table_controller.gd tests/unit/test_crash_table_state.gd
git commit -m "feat(crash): accept shared team ledger on first bet"
```

---

## Task 8: Mines — mismo patrón, familia de ronda independiente

**Files:**
- Modify: `scripts/mines/mines_table_state.gd` (funciones `_player_for` y `start_round`)
- Modify: `scripts/net/mines_table_controller.gd`
- Test: `tests/unit/test_mines_table_state.gd` (añade al final)

**Interfaces:**
- Produces: `MinesTableState.start_round(player_id, total_cells, mine_count, amount, external_ledger: ChipLedger = null)`; `MinesTableController.shared_ledger_provider`/`on_shared_ledger_changed`.

- [ ] **Step 1: Escribe los tests que fallan**

```gdscript
func test_start_round_uses_external_ledger_for_new_player():
	var table = MinesTableState.new()
	var shared := ChipLedger.new(500)
	table.start_round(111, 25, 3, 100, shared)
	assert_eq(shared.balance, 400)

func test_start_round_creates_individual_ledger_when_no_external_ledger_given():
	var table = MinesTableState.new()
	table.start_round(111, 25, 3, 100)
	assert_eq(table.players[111].ledger.balance, 400)
```

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_mines_table_state.gd -gexit`
Expected: FAIL — `start_round()` no acepta un quinto argumento todavía.

- [ ] **Step 3: Implementa**

En `scripts/mines/mines_table_state.gd`, reemplaza `_player_for` y la firma/cuerpo de `start_round` (deja `active_round`/`mines`/`revealed` intactos):

```gdscript
func _player_for(player_id: int, external_ledger: ChipLedger = null) -> Player:
	if not players.has(player_id):
		var player := Player.new()
		player.player_id = player_id
		player.ledger = external_ledger if external_ledger != null else ChipLedger.new(STARTING_BALANCE)
		players[player_id] = player
	return players[player_id]

func start_round(player_id: int, total_cells: int, mine_count: int, amount: int, external_ledger: ChipLedger = null) -> bool:
	if total_cells < 2 or total_cells > MAX_CELLS:
		return false
	if mine_count < 1 or mine_count >= total_cells:
		return false
	var player := _player_for(player_id, external_ledger)
	if not player.active_round.is_empty():
		return false
	if not player.ledger.place_bet(amount):
		return false
```

(El resto de la función, desde `player.active_round = {` en adelante, no cambia — solo reemplaza las líneas de arriba en su sitio.)

En `scripts/net/mines_table_controller.gd`, añade tras `var table_state: MinesTableState`:

```gdscript
var shared_ledger_provider: Callable = Callable()
var on_shared_ledger_changed: Callable = Callable()
```

Reemplaza `_apply_start_round`:

```gdscript
func _apply_start_round(total_cells: int, mine_count: int, amount: int, player_id: int) -> void:
	var external_ledger: ChipLedger = shared_ledger_provider.call(player_id) if shared_ledger_provider.is_valid() else null
	if table_state.start_round(player_id, total_cells, mine_count, amount, external_ledger):
		_broadcast_state()
```

Reemplaza `_broadcast_state`:

```gdscript
func _broadcast_state() -> void:
	_receive_state.rpc(table_state.to_dict())
	if on_shared_ledger_changed.is_valid():
		on_shared_ledger_changed.call()
```

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_mines_table_state.gd -gexit`
Expected: PASS, todos los tests del archivo.

- [ ] **Step 5: Commit**

```bash
git add scripts/mines/mines_table_state.gd scripts/net/mines_table_controller.gd tests/unit/test_mines_table_state.gd
git commit -m "feat(mines): accept shared team ledger on round start"
```

---

## Task 9: Plinko — mismo patrón, familia de ronda independiente

**Files:**
- Modify: `scripts/plinko/plinko_table_state.gd` (funciones `_player_for` y `roll`)
- Modify: `scripts/net/plinko_table_controller.gd`
- Test: `tests/unit/test_plinko_table_state.gd` (añade al final)

**Interfaces:**
- Produces: `PlinkoTableState.roll(player_id, rows, amount, external_ledger: ChipLedger = null)`; `PlinkoTableController.shared_ledger_provider`/`on_shared_ledger_changed`.

- [ ] **Step 1: Escribe los tests que fallan**

Igual que en Dice (Task 6), `roll()` paga de inmediato según un resultado
aleatorio de rebotes, así que las pruebas comprueban identidad de objeto,
no el saldo exacto — `place_bet` siempre puede permitirse 100 fichas
contra un saldo inicial de 500 sin importar el resultado.

```gdscript
func test_roll_uses_external_ledger_for_new_player():
	var table = PlinkoTableState.new()
	var shared := ChipLedger.new(500)
	table.roll(111, 12, 100, shared)
	assert_eq(table.players[111].ledger, shared)

func test_roll_creates_individual_ledger_when_no_external_ledger_given():
	var table = PlinkoTableState.new()
	table.roll(111, 12, 100)
	assert_true(table.players.has(111))
	assert_ne(table.players[111].ledger, null)
```

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_plinko_table_state.gd -gexit`
Expected: FAIL — `roll()` no acepta un cuarto argumento todavía.

- [ ] **Step 3: Implementa**

En `scripts/plinko/plinko_table_state.gd`, reemplaza `_player_for` y la firma/cuerpo de `roll` (deja `bounces`/cálculo de slot intacto):

```gdscript
func _player_for(player_id: int, external_ledger: ChipLedger = null) -> Player:
	if not players.has(player_id):
		var player := Player.new()
		player.player_id = player_id
		player.ledger = external_ledger if external_ledger != null else ChipLedger.new(STARTING_BALANCE)
		players[player_id] = player
	return players[player_id]

func roll(player_id: int, rows: int, amount: int, external_ledger: ChipLedger = null) -> bool:
	if rows < MIN_ROWS or rows > MAX_ROWS:
		return false
	var player := _player_for(player_id, external_ledger)
	if not player.ledger.place_bet(amount):
		return false
```

(El resto de la función, desde `var bounces: Array = roller.roll(rows)` en adelante, no cambia.)

En `scripts/net/plinko_table_controller.gd`, añade tras `var table_state: PlinkoTableState`:

```gdscript
var shared_ledger_provider: Callable = Callable()
var on_shared_ledger_changed: Callable = Callable()
```

Reemplaza `_apply_roll`:

```gdscript
func _apply_roll(rows: int, amount: int, player_id: int) -> void:
	var external_ledger: ChipLedger = shared_ledger_provider.call(player_id) if shared_ledger_provider.is_valid() else null
	if table_state.roll(player_id, rows, amount, external_ledger):
		_broadcast_state()
```

Reemplaza `_broadcast_state`:

```gdscript
func _broadcast_state() -> void:
	_receive_state.rpc(table_state.to_dict())
	if on_shared_ledger_changed.is_valid():
		on_shared_ledger_changed.call()
```

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_plinko_table_state.gd -gexit`
Expected: PASS, todos los tests del archivo.

- [ ] **Step 5: Commit**

```bash
git add scripts/plinko/plinko_table_state.gd scripts/net/plinko_table_controller.gd tests/unit/test_plinko_table_state.gd
git commit -m "feat(plinko): accept shared team ledger on first roll"
```

---

## Task 10: Suite completa + verificación manual de batalla en vivo

**Files:** ninguno nuevo — solo verificación.

- [ ] **Step 1: Reconstruye la caché de clases**

Run: `godot --headless --editor --quit --path .` (binario `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`). Revisa `git status` después — descarta con `git checkout -- <archivo>` cualquier reformateo de espacios/tabs en archivos que no tocaste en este plan.

- [ ] **Step 2: Corre la suite completa de GUT**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit`
Expected: todos los tests en verde, incluidos los ~9 archivos nuevos/modificados de este plan, y que ningún test de Modo Libre (`test_match_rules.gd` sigue siendo el único que toca `MatchRules`, nada de `CollectiveGoal` debería haber cambiado) se haya roto.

- [ ] **Step 3: Verificación manual con 2 clientes Steam en Modo Batalla**

Con Steam corriendo y dos cuentas, crea una partida 1v1 (o 2v2 si hay 4 cuentas disponibles). Confirma:
- Ambos jugadores del mismo equipo ven el mismo balance al sentarse en cualquier mesa (o el mismo `BALANCE` si Plan 14 ya está mergeado y el HUD lo muestra).
- Si un jugador apuesta y pierde, el balance del compañero baja igual, aunque esté en otra mesa distinta.
- Si un jugador gana, el balance del compañero sube igual.
- `battle_status_label` (o el HUD que corresponda) refleja el pozo moviéndose en vivo, no se queda fijo en 500.
- Al llegar el pozo del equipo a `BATTLE_GOAL_BALANCE` (2000), la partida marca "FIN" con ese equipo como ganador.
- Si el pozo del equipo llega a 0, la partida marca "FIN" con el otro equipo como ganador.

No cierres esta fase sin que el usuario confirme el punto anterior en vivo — mismo patrón usado para cerrar el bug de Plan 13 (necesita 2 cuentas Steam, no disponible en la sesión del agente).

- [ ] **Step 4: Commit final (si algo quedó sin commitear)**

```bash
git status
git add -A
git commit -m "chore: verify battle-mode shared pool wiring end to end" --allow-empty
```

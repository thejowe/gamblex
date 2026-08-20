# Modo Batalla (1v1 / 2v2 / 4v4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir el modo batalla al casino compartido: selección de tipo de partida (1v1/2v2/4v4) con asignación de equipos equilibrada, un pozo de fichas compartido por equipo (`ChipLedger` pooled), y `MatchRules` como árbitro que decide la victoria por meta de fichas, timeout o bancarrota inmediata.

**Architecture:** Tres clases de lógica pura sin red (`TeamAssignment`, `TeamChipPool`, `MatchRules`), testeadas con GUT igual que Plan 1/3. `BattleController` (nodo, solo host tiene estado real) es el puente de red que las conecta, siguiendo el mismo patrón que `TableController` (Plan 3): el host aplica sus propias acciones directo, los clientes piden por `rpc_id(1, ...)`. `LobbyMenu` gana un selector de tipo de partida que fija cuántos jugadores caben en el lobby de Steam; `CasinoFloor` instancia `BattleController` y muestra el estado del pozo/equipos.

**Tech Stack:** Godot 4.4+, GDScript, GUT (lógica pura), `MultiplayerAPI`/RPCs nativos sobre el `SteamMultiplayerPeer` que deja listo Plan 2, reutilizando `ChipLedger` de Plan 1.

**Spec:** `docs/superpowers/specs/2026-08-17-casino-multiplayer-design.md` (sección "Modo batalla (1v1 / 2v2 / 4v4)")

## Global Constraints

- Servidor autoritativo: toda decisión de equipos/pozo/victoria ocurre solo en el host (`multiplayer.is_server()`); los clientes solo envían intención y reciben estado — mismo criterio que Plan 3.
- El servidor tiene siempre `unique_id == 1` en el `MultiplayerAPI` de Godot — los clientes dirigen sus RPCs de acción con `rpc_id(1, ...)`.
- Gotcha ya encontrado en Plan 3: `rpc_id(1, ...)` con modo `call_remote` falla si quien llama ya es el peer 1 (el host actuando sobre su propio estado). `BattleController` sigue el mismo patrón que `TableController`: métodos wrapper (`join`, `start_match`) que en el host aplican directo en vez de auto-llamarse por RPC.
- Saldo por equipo: en partidas con más de un jugador por bando, el saldo de fichas es un pozo único compartido (`TeamChipPool`), no individual — un solo `ChipLedger` por equipo, no uno por asiento.
- Condición de victoria (en este orden de prioridad cuando coinciden): (1) bancarrota de un equipo decide de inmediato, sin esperar a las otras condiciones; (2) si nadie está en bancarrota, el primer equipo en llegar a la meta de fichas gana; (3) si se agota el tiempo sin bancarrota ni meta alcanzada, gana el equipo con más fichas (empate = sin ganador).
- Sin persistencia entre partidas — todo el estado de `BattleController` vive en memoria del host mientras dura la sesión.
- No mergees a `main` — trabajas en `feature/battle-mode`, en paralelo con los Agentes 5/6/7 sobre el mismo punto de partida. Avisa a la sesión pilar cuando el plan esté completo y verificado.

## Nota sobre alcance

Este plan conecta el pozo de equipo y el árbitro a la red (`BattleController`), pero **no** modifica `BlackjackTableState` ni ningún `GameLogic` para que las apuestas reales de una mesa alimenten el pozo de equipo — eso es integración cruzada entre planes (Blackjack ya cerrado en Plan 3; Ruleta/Póker en curso en Agentes 5/6) y la decide la sesión pilar al fusionar ramas. La verificación manual de este plan mueve el pozo con llamadas directas a `apply_bet`/`apply_payout` (igual que Plan 3 verificó `TableController` con llamadas RPC manuales antes de tener UI completa), no con una partida de blackjack real.

## Nota sobre testing en este plan

`TeamAssignment`, `TeamChipPool` y `MatchRules` son lógica pura (Tasks 1-3) y se testean con GUT sin red, igual que Plan 1. `BattleController` y la integración con `LobbyMenu`/`CasinoFloor` (Tasks 4-5) dependen de una sesión multijugador real ya establecida (Plan 2) y se verifican manualmente con dos instancias — mismo criterio que Plan 3.

---

## Task 1: TeamAssignment — selección de modo y equilibrio de equipos

**Files:**
- Create: `scripts/battle/team_assignment.gd`
- Test: `tests/unit/test_team_assignment.gd`

**Interfaces:**
- Consume: nada (lógica pura).
- Produce: `class_name TeamAssignment`, `enum MatchType { ONE_V_ONE, TWO_V_TWO, FOUR_V_FOUR }`, `TeamAssignment.new(match_type: int)`, `static func team_size_for(match_type: int) -> int`, propiedad `teams: Array` (`[Array[int], Array[int]]`), método `join(player_id: int) -> int` (devuelve índice de equipo 0/1, o -1 si ya está sentado o no cabe), `team_for(player_id: int) -> int`, `team_size() -> int`, `max_players() -> int`, `is_full() -> bool`. Usado por `BattleController` (Task 4) y por `LobbyMenu` (Task 5, vía `team_size_for` para fijar el tamaño del lobby de Steam).

- [ ] **Step 1: Escribir los tests**

```gdscript
extends GutTest

func test_one_v_one_assigns_first_two_players_to_opposite_teams():
	var a := TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	assert_eq(a.join(111), 0)
	assert_eq(a.join(222), 1)
	assert_eq(a.team_for(111), 0)
	assert_eq(a.team_for(222), 1)

func test_one_v_one_rejects_third_player():
	var a := TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	a.join(111)
	a.join(222)
	assert_eq(a.join(333), -1)
	assert_true(a.is_full())

func test_two_v_two_balances_teams_as_players_join():
	var a := TeamAssignment.new(TeamAssignment.MatchType.TWO_V_TWO)
	assert_eq(a.join(1), 0)
	assert_eq(a.join(2), 1)
	assert_eq(a.join(3), 0)
	assert_eq(a.join(4), 1)
	assert_eq(a.join(5), -1)
	assert_true(a.is_full())
	assert_eq(a.teams[0], [1, 3])
	assert_eq(a.teams[1], [2, 4])

func test_four_v_four_team_size_and_max_players():
	var a := TeamAssignment.new(TeamAssignment.MatchType.FOUR_V_FOUR)
	assert_eq(a.team_size(), 4)
	assert_eq(a.max_players(), 8)

func test_join_is_idempotent_for_already_seated_player():
	var a := TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	a.join(111)
	assert_eq(a.join(111), -1)
	assert_eq(a.teams[0], [111])

func test_team_size_for_is_a_static_lookup():
	assert_eq(TeamAssignment.team_size_for(TeamAssignment.MatchType.TWO_V_TWO), 2)
```

Guardar en `tests/unit/test_team_assignment.gd`.

- [ ] **Step 2: Ejecutar y verificar que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `Identifier "TeamAssignment" not declared`.

- [ ] **Step 3: Implementar TeamAssignment**

```gdscript
class_name TeamAssignment
extends RefCounted

enum MatchType { ONE_V_ONE, TWO_V_TWO, FOUR_V_FOUR }

const TEAM_SIZE_BY_MATCH_TYPE := {
	MatchType.ONE_V_ONE: 1,
	MatchType.TWO_V_TWO: 2,
	MatchType.FOUR_V_FOUR: 4,
}

var match_type: int
var teams: Array = [[], []]

func _init(p_match_type: int) -> void:
	match_type = p_match_type

static func team_size_for(p_match_type: int) -> int:
	return TEAM_SIZE_BY_MATCH_TYPE[p_match_type]

func team_size() -> int:
	return TeamAssignment.team_size_for(match_type)

func max_players() -> int:
	return team_size() * 2

func join(player_id: int) -> int:
	if team_for(player_id) != -1:
		return -1
	var size := team_size()
	if teams[0].size() <= teams[1].size() and teams[0].size() < size:
		teams[0].append(player_id)
		return 0
	if teams[1].size() < size:
		teams[1].append(player_id)
		return 1
	return -1

func team_for(player_id: int) -> int:
	for i in range(2):
		if teams[i].has(player_id):
			return i
	return -1

func is_full() -> bool:
	return teams[0].size() == team_size() and teams[1].size() == team_size()
```

Guardar en `scripts/battle/team_assignment.gd`.

- [ ] **Step 4: Ejecutar y verificar que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests de `test_team_assignment.gd` en verde, `0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/team_assignment.gd tests/unit/test_team_assignment.gd
git commit -m "feat: add TeamAssignment for balanced 1v1/2v2/4v4 team assignment"
```

---

## Task 2: TeamChipPool — pozo de fichas compartido por equipo

**Files:**
- Create: `scripts/battle/team_chip_pool.gd`
- Test: `tests/unit/test_team_chip_pool.gd`

**Interfaces:**
- Consume: `ChipLedger` (Plan 1, `scripts/chip_ledger.gd`) sin modificarlo.
- Produce: `class_name TeamChipPool`, `TeamChipPool.new(team_id: int, starting_balance: int)`, propiedades `team_id: int`, `ledger: ChipLedger`, métodos `balance() -> int`, `can_afford(amount: int) -> bool`, `place_bet(amount: int) -> bool`, `payout(amount: int) -> void`, `is_bankrupt() -> bool`. Usado por `MatchRules` (Task 3) y `BattleController` (Task 4).

- [ ] **Step 1: Escribir los tests**

```gdscript
extends GutTest

func test_starting_balance_matches_constructor_argument():
	var pool := TeamChipPool.new(0, 500)
	assert_eq(pool.balance(), 500)
	assert_eq(pool.team_id, 0)

func test_bet_from_one_member_reduces_shared_balance_for_whole_team():
	var pool := TeamChipPool.new(0, 500)
	assert_true(pool.place_bet(200)) # miembro A apuesta
	assert_eq(pool.balance(), 300)
	assert_true(pool.place_bet(300)) # miembro B apuesta contra el mismo pozo
	assert_eq(pool.balance(), 0)

func test_bet_fails_when_pool_cannot_afford_it():
	var pool := TeamChipPool.new(0, 100)
	assert_false(pool.place_bet(200))
	assert_eq(pool.balance(), 100)

func test_payout_credits_shared_pool_regardless_of_which_member_won():
	var pool := TeamChipPool.new(1, 500)
	pool.place_bet(200)
	pool.payout(400) # el miembro que jugó gana, pero el pago va al pozo del equipo
	assert_eq(pool.balance(), 700)

func test_is_bankrupt_reflects_shared_balance():
	var pool := TeamChipPool.new(0, 100)
	pool.place_bet(100)
	assert_true(pool.is_bankrupt())
```

Guardar en `tests/unit/test_team_chip_pool.gd`.

- [ ] **Step 2: Ejecutar y verificar que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `Identifier "TeamChipPool" not declared`.

- [ ] **Step 3: Implementar TeamChipPool**

```gdscript
class_name TeamChipPool
extends RefCounted

var team_id: int
var ledger: ChipLedger

func _init(p_team_id: int, starting_balance: int) -> void:
	team_id = p_team_id
	ledger = ChipLedger.new(starting_balance)

func balance() -> int:
	return ledger.balance

func can_afford(amount: int) -> bool:
	return ledger.can_afford(amount)

func place_bet(amount: int) -> bool:
	return ledger.place_bet(amount)

func payout(amount: int) -> void:
	ledger.payout(amount)

func is_bankrupt() -> bool:
	return ledger.is_bankrupt()
```

Guardar en `scripts/battle/team_chip_pool.gd`.

- [ ] **Step 4: Ejecutar y verificar que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests de `test_team_chip_pool.gd` en verde, `0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/team_chip_pool.gd tests/unit/test_team_chip_pool.gd
git commit -m "feat: add TeamChipPool for shared per-team chip balance"
```

---

## Task 3: MatchRules — árbitro de meta, timeout y bancarrota

**Files:**
- Create: `scripts/battle/match_rules.gd`
- Test: `tests/unit/test_match_rules.gd`

**Interfaces:**
- Consume: `TeamChipPool` (Task 2) — `pool.team_id`, `pool.balance()`, `pool.is_bankrupt()`.
- Produce: `class_name MatchRules`, señal `match_finished(winning_team: int, reason: String)`, `MatchRules.new(pools: Array, goal_balance: int, time_limit_sec: float)`, propiedades `finished: bool`, `winning_team: int` (-1 = empate/sin definir), `reason: String`, `elapsed_sec: float`, métodos `on_balance_changed() -> bool` (llamar tras cada apuesta/pago), `advance_time(delta: float) -> bool`. Usado por `BattleController` (Task 4).

- [ ] **Step 1: Escribir los tests**

```gdscript
extends GutTest

func test_first_team_to_reach_goal_wins_immediately():
	var pools := [TeamChipPool.new(0, 900), TeamChipPool.new(1, 500)]
	var rules := MatchRules.new(pools, 1000, 600.0)
	pools[0].payout(150) # equipo 0 llega a 1050, por encima de la meta
	assert_true(rules.on_balance_changed())
	assert_true(rules.finished)
	assert_eq(rules.winning_team, 0)
	assert_eq(rules.reason, "goal_reached")

func test_timeout_without_goal_awards_highest_balance():
	var pools := [TeamChipPool.new(0, 700), TeamChipPool.new(1, 400)]
	var rules := MatchRules.new(pools, 2000, 60.0)
	assert_false(rules.advance_time(59.0))
	assert_true(rules.advance_time(1.0))
	assert_true(rules.finished)
	assert_eq(rules.winning_team, 0)
	assert_eq(rules.reason, "timeout_highest_balance")

func test_timeout_tie_is_a_draw():
	var pools := [TeamChipPool.new(0, 500), TeamChipPool.new(1, 500)]
	var rules := MatchRules.new(pools, 2000, 60.0)
	rules.advance_time(60.0)
	assert_eq(rules.winning_team, -1)
	assert_eq(rules.reason, "timeout_draw")

func test_bankruptcy_ends_match_immediately_for_the_other_team():
	var pools := [TeamChipPool.new(0, 500), TeamChipPool.new(1, 200)]
	var rules := MatchRules.new(pools, 2000, 600.0)
	pools[1].place_bet(200) # equipo 1 se queda a 0, bancarrota
	assert_true(rules.on_balance_changed())
	assert_eq(rules.winning_team, 0)
	assert_eq(rules.reason, "bankruptcy")

func test_bankruptcy_takes_priority_over_simultaneous_goal():
	# Mismo cambio de saldo: equipo 1 llega a la meta, pero equipo 0 se queda
	# sin fichas en el mismo instante — la spec exige que la bancarrota decida
	# de inmediato, sin esperar a la condición de meta.
	var pools := [TeamChipPool.new(0, 0), TeamChipPool.new(1, 1000)]
	var rules := MatchRules.new(pools, 1000, 600.0)
	assert_true(rules.on_balance_changed())
	assert_eq(rules.winning_team, 1)
	assert_eq(rules.reason, "bankruptcy")

func test_no_ops_once_finished():
	var pools := [TeamChipPool.new(0, 1000), TeamChipPool.new(1, 500)]
	var rules := MatchRules.new(pools, 1000, 60.0)
	rules.on_balance_changed() # equipo 0 ya arranca en la meta, termina el partido
	var reason_before := rules.reason
	pools[1].payout(9999)
	assert_false(rules.on_balance_changed())
	assert_false(rules.advance_time(1000.0))
	assert_eq(rules.reason, reason_before)
```

Guardar en `tests/unit/test_match_rules.gd`.

- [ ] **Step 2: Ejecutar y verificar que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `Identifier "MatchRules" not declared`.

- [ ] **Step 3: Implementar MatchRules**

```gdscript
class_name MatchRules
extends RefCounted

signal match_finished(winning_team: int, reason: String)

var pools: Array
var goal_balance: int
var time_limit_sec: float
var elapsed_sec: float = 0.0
var finished: bool = false
var winning_team: int = -1
var reason: String = ""

func _init(p_pools: Array, p_goal_balance: int, p_time_limit_sec: float) -> void:
	pools = p_pools
	goal_balance = p_goal_balance
	time_limit_sec = p_time_limit_sec

# Llamar tras cualquier apuesta o pago que cambie el saldo de un pozo.
# Revisa bancarrota primero: la spec exige que decida "de inmediato, sin
# esperar a las otras condiciones", así que tiene prioridad incluso si el
# mismo cambio de saldo hace que otro equipo llegue a la meta a la vez.
func on_balance_changed() -> bool:
	if finished:
		return false
	if _check_bankruptcy():
		return true
	return _check_goal()

func advance_time(delta: float) -> bool:
	if finished:
		return false
	elapsed_sec += delta
	if elapsed_sec < time_limit_sec:
		return false
	_finish_by_timeout()
	return true

func _check_bankruptcy() -> bool:
	for pool in pools:
		if pool.is_bankrupt():
			_finish(1 - pool.team_id, "bankruptcy")
			return true
	return false

func _check_goal() -> bool:
	for pool in pools:
		if pool.balance() >= goal_balance:
			_finish(pool.team_id, "goal_reached")
			return true
	return false

func _finish_by_timeout() -> void:
	if pools[0].balance() > pools[1].balance():
		_finish(pools[0].team_id, "timeout_highest_balance")
	elif pools[1].balance() > pools[0].balance():
		_finish(pools[1].team_id, "timeout_highest_balance")
	else:
		_finish(-1, "timeout_draw")

func _finish(team: int, p_reason: String) -> void:
	finished = true
	winning_team = team
	reason = p_reason
	match_finished.emit(team, p_reason)
```

Guardar en `scripts/battle/match_rules.gd`. Nota: `1 - pool.team_id` asume exactamente 2 equipos (0/1) — correcto para 1v1/2v2/4v4, que siempre enfrentan dos bandos aunque cambie cuánta gente hay en cada uno.

- [ ] **Step 4: Ejecutar y verificar que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests de `test_match_rules.gd` en verde, `0 failed`, incluidos los de Tasks 1-2.

- [ ] **Step 5: Commit**

```bash
git add scripts/battle/match_rules.gd tests/unit/test_match_rules.gd
git commit -m "feat: add MatchRules arbiter for goal/timeout/bankruptcy victory conditions"
```

---

## Task 4: BattleController — puente de red sobre TeamAssignment/TeamChipPool/MatchRules

**Files:**
- Create: `scripts/net/battle_controller.gd`

**Interfaces:**
- Consume: `TeamAssignment` (Task 1), `TeamChipPool` (Task 2), `MatchRules` (Task 3), `multiplayer.is_server()`, `multiplayer.get_remote_sender_id()`, `multiplayer.get_unique_id()` (API estándar de Godot, mismo patrón que `TableController` de Plan 3).
- Produce: nodo `class_name BattleController`, señales `teams_changed(teams: Array)`, `match_state_changed(state: Dictionary)`, métodos `start_match(match_type: int, goal_balance: int, time_limit_sec: float, starting_balance: int) -> void`, `join(player_id: int) -> void`, `apply_bet(team_id: int, amount: int) -> bool`, `apply_payout(team_id: int, amount: int) -> void`. Usado por `CasinoFloor` (Task 5).

- [ ] **Step 1: Implementar BattleController**

```gdscript
class_name BattleController
extends Node

signal teams_changed(teams: Array)
signal match_state_changed(state: Dictionary)

var assignment: TeamAssignment
var pools: Array = []
var rules: MatchRules

# Igual que TableController (Plan 3): el host no puede rpc_id(1, ...) sobre sí
# mismo con call_remote, así que join() aplica directo en el host en vez de
# auto-llamarse por RPC. start_match y apply_bet/apply_payout solo los llama
# el host de todas formas (son la autoridad del partido), sin pasar por RPC.
func start_match(match_type: int, goal_balance: int, time_limit_sec: float, starting_balance: int) -> void:
	if not multiplayer.is_server():
		return
	assignment = TeamAssignment.new(match_type)
	pools = [TeamChipPool.new(0, starting_balance), TeamChipPool.new(1, starting_balance)]
	rules = MatchRules.new(pools, goal_balance, time_limit_sec)
	rules.match_finished.connect(func(_team, _reason): _broadcast_match_state())

func join(player_id: int) -> void:
	if multiplayer.is_server():
		_apply_join(player_id)
	else:
		request_join.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func request_join() -> void:
	if not multiplayer.is_server():
		return
	_apply_join(multiplayer.get_remote_sender_id())

func _apply_join(player_id: int) -> void:
	assignment.join(player_id)
	_broadcast_teams()

func apply_bet(team_id: int, amount: int) -> bool:
	if not multiplayer.is_server():
		return false
	var ok: bool = pools[team_id].place_bet(amount)
	if ok:
		rules.on_balance_changed()
		_broadcast_match_state()
	return ok

func apply_payout(team_id: int, amount: int) -> void:
	if not multiplayer.is_server():
		return
	pools[team_id].payout(amount)
	rules.on_balance_changed()
	_broadcast_match_state()

func _process(delta: float) -> void:
	if multiplayer.is_server() and rules != null and not rules.finished:
		if rules.advance_time(delta):
			_broadcast_match_state()

func _broadcast_teams() -> void:
	_receive_teams.rpc(assignment.teams)

@rpc("authority", "call_local", "reliable")
func _receive_teams(teams: Array) -> void:
	teams_changed.emit(teams)

func _broadcast_match_state() -> void:
	_receive_match_state.rpc(_state_dict())

func _state_dict() -> Dictionary:
	return {
		"pool_balances": [pools[0].balance(), pools[1].balance()],
		"finished": rules.finished,
		"winning_team": rules.winning_team,
		"reason": rules.reason,
	}

@rpc("authority", "call_local", "reliable")
func _receive_match_state(state: Dictionary) -> void:
	match_state_changed.emit(state)
```

Guardar en `scripts/net/battle_controller.gd`. Nota: en el host, `pools`/`rules`/`assignment` quedan poblados tras `start_match`; en los clientes quedan `null`/vacíos a propósito — los clientes nunca deciden equipos ni resultado, solo reciben `teams_changed`/`match_state_changed` y piden acciones por RPC.

- [ ] **Step 2: Verificación manual con dos cuentas**

Reutilizando el flujo de lobby de Plan 2/3 (una instancia crea partida, la otra se une), añade temporalmente un `BattleController` como nodo hijo de la escena principal en ambas instancias y conecta:

```gdscript
$BattleController.teams_changed.connect(func(teams): print("Equipos: %s" % [teams]))
$BattleController.match_state_changed.connect(func(state): print("Estado partido: %s" % state))
```

En la instancia host: `$BattleController.start_match(TeamAssignment.MatchType.ONE_V_ONE, 1000, 60.0, 500)`, luego `$BattleController.join(multiplayer.get_unique_id())`. Desde la instancia cliente: `$BattleController.join(multiplayer.get_unique_id())`. Confirma que **ambas** instancias imprimen `Equipos: [[<id_host>], [<id_cliente>]]`.

Luego, solo desde el host (es quien tiene `pools`/`rules`): `$BattleController.apply_bet(0, 200)` y `$BattleController.apply_payout(0, 900)` para llevar al equipo 0 a superar la meta de 1000; confirma que ambas instancias imprimen el mismo `Estado partido` con `finished = true`, `winning_team = 0`, `reason = "goal_reached"`. Repite el experimento en una sesión nueva forzando bancarrota (`apply_bet(1, 500)` sobre un pozo de 500) y confirma `reason = "bankruptcy"` con `winning_team` el equipo contrario.

- [ ] **Step 3: Commit**

```bash
git add scripts/net/battle_controller.gd
git commit -m "feat: add BattleController RPC bridge for team assignment and match rules"
```

---

## Task 5: Selección de tipo de partida en LobbyMenu + estado de batalla en CasinoFloor

**Files:**
- Modify: `scenes/lobby_menu.gd`, `scenes/lobby_menu.tscn`
- Modify: `autoloads/steam_manager.gd`
- Modify: `scenes/casino_floor.tscn`
- Create: `scenes/casino_floor.gd`

**Interfaces:**
- Consume: `TeamAssignment` (Task 1), `BattleController` (Task 4), `SteamManager.create_lobby(max_members: int)` (Plan 2), `SteamManager.lobby_ready` (Plan 2).
- Produce: `SteamManager.chosen_match_type: int` (nueva propiedad).

- [ ] **Step 1: Añadir el selector de tipo de partida a LobbyMenu**

Editar `scenes/lobby_menu.tscn` — añadir un `OptionButton` entre `CreateButton` y `InviteButton`:

```
[node name="MatchTypeOption" type="OptionButton" parent="."]
layout_mode = 0
offset_left = 20.0
offset_top = 62.0
offset_right = 200.0
offset_bottom = 98.0
```

(Desplaza `InviteButton` y `MembersLabel` 40px hacia abajo en `offset_top`/`offset_bottom` para que no se solapen con el nuevo control.)

- [ ] **Step 2: Actualizar lobby_menu.gd para leer el tipo de partida elegido**

Reemplazar el contenido de `scenes/lobby_menu.gd`:

```gdscript
extends Control

@onready var create_button: Button = $CreateButton
@onready var invite_button: Button = $InviteButton
@onready var members_label: Label = $MembersLabel
@onready var match_type_option: OptionButton = $MatchTypeOption

var _transitioned: bool = false

func _ready() -> void:
	match_type_option.add_item("1v1", TeamAssignment.MatchType.ONE_V_ONE)
	match_type_option.add_item("2v2", TeamAssignment.MatchType.TWO_V_TWO)
	match_type_option.add_item("4v4", TeamAssignment.MatchType.FOUR_V_FOUR)
	create_button.pressed.connect(_on_create_pressed)
	invite_button.pressed.connect(_on_invite_pressed)
	invite_button.disabled = true
	SteamManager.lobby_ready.connect(_on_lobby_ready)
	SteamManager.lobby_join_failed.connect(_on_lobby_join_failed)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)

func _on_create_pressed() -> void:
	create_button.disabled = true
	var match_type: int = match_type_option.get_selected_id()
	SteamManager.chosen_match_type = match_type
	SteamManager.create_lobby(TeamAssignment.team_size_for(match_type) * 2)

func _on_invite_pressed() -> void:
	Steam.activateGameOverlayInviteDialog(SteamManager.current_lobby_id)

func _on_lobby_ready(lobby_id: int, is_owner: bool) -> void:
	invite_button.disabled = false
	_refresh_members()
	print("LobbyMenu: lobby lista, id %d (compártelo si el overlay de invitar no sirve)" % lobby_id)
	if not is_owner:
		# El invitado ya llega acompañado del host, pasa directo a la mesa.
		_go_to_casino_floor()

func _on_lobby_join_failed(reason: String) -> void:
	push_error("LobbyMenu: %s" % reason)

func _on_lobby_chat_update(_lobby_id: int, _change_id: int, _making_change_id: int, _chat_state: int) -> void:
	_refresh_members()
	# El host espera aquí (con el botón de invitar visible) hasta que se llene el equipo.
	var max_members: int = TeamAssignment.team_size_for(SteamManager.chosen_match_type) * 2
	if Steam.getNumLobbyMembers(SteamManager.current_lobby_id) >= max_members:
		_go_to_casino_floor()

func _go_to_casino_floor() -> void:
	if _transitioned:
		return
	_transitioned = true
	get_tree().change_scene_to_file("res://scenes/casino_floor.tscn")

func _refresh_members() -> void:
	var lobby_id := SteamManager.current_lobby_id
	var names: Array[String] = []
	var count: int = Steam.getNumLobbyMembers(lobby_id)
	for i in range(count):
		var member_id: int = Steam.getLobbyMemberByIndex(lobby_id, i)
		names.append(Steam.getFriendPersonaName(member_id))
	members_label.text = "Jugadores: %s" % ", ".join(names)
```

Nota: esto cambia el criterio para pasar a `CasinoFloor` de "≥2 miembros" (fijo, Plan 3) a "lobby lleno según el tipo de partida elegido" — 2/4/8 según 1v1/2v2/4v4. El invitado (`is_owner == false`) sigue pasando directo como antes; es el host quien ahora espera al aforo completo en vez de a 2 jugadores fijos.

- [ ] **Step 3: Añadir `chosen_match_type` a SteamManager**

En `autoloads/steam_manager.gd`, añadir tras `var current_lobby_id: int = 0`:

```gdscript
var chosen_match_type: int = TeamAssignment.MatchType.ONE_V_ONE
```

- [ ] **Step 4: Instanciar BattleController en CasinoFloor y mostrar su estado**

Primero crear `scenes/casino_floor.gd` (el `.tscn` de abajo ya referencia este archivo):

```gdscript
extends Node2D

const GOAL_BALANCE := 2000
const TIME_LIMIT_SEC := 600.0
const STARTING_BALANCE := 500

@onready var battle_controller: BattleController = $BattleController
@onready var battle_status_label: Label = $BattleStatusLabel

func _ready() -> void:
	battle_controller.teams_changed.connect(_on_teams_changed)
	battle_controller.match_state_changed.connect(_on_match_state_changed)
	if multiplayer.is_server():
		battle_controller.start_match(SteamManager.chosen_match_type, GOAL_BALANCE, TIME_LIMIT_SEC, STARTING_BALANCE)
	battle_controller.join(multiplayer.get_unique_id())

func _on_teams_changed(teams: Array) -> void:
	battle_status_label.text = "Equipo A: %s | Equipo B: %s" % [str(teams[0]), str(teams[1])]

func _on_match_state_changed(state: Dictionary) -> void:
	var msg := "Pozo A: %d | Pozo B: %d" % [state["pool_balances"][0], state["pool_balances"][1]]
	if state["finished"]:
		msg += " — FIN (equipo %d, %s)" % [state["winning_team"], state["reason"]]
	battle_status_label.text = msg
```

Guardar en `scenes/casino_floor.gd`. Ahora sí, sobreescribir `scenes/casino_floor.tscn` completo:

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scenes/casino_floor.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/blackjack_table_net.tscn" id="2"]
[ext_resource type="Script" path="res://scripts/net/battle_controller.gd" id="3"]

[node name="CasinoFloor" type="Node2D"]
script = ExtResource("1")

[node name="BattleController" type="Node" parent="."]
script = ExtResource("3")

[node name="BattleStatusLabel" type="Label" parent="."]
offset_left = 20.0
offset_top = 320.0
offset_right = 700.0
offset_bottom = 420.0
text = "Equipos: —"

[node name="BlackjackTableNet" parent="." instance=ExtResource("2")]
```

- [ ] **Step 5: Verificación manual con dos cuentas (flujo completo)**

Con dos instancias del juego: en la instancia A (host), en `LobbyMenu` selecciona "1v1" en el desplegable y pulsa "Crear partida"; invita a B. Confirma que **ambas** instancias llegan a `CasinoFloor` (el host ya no pasa automáticamente por tener solo 2 miembros con un tipo fijo — ahora depende del tipo elegido) y que `BattleStatusLabel` muestra `Equipo A: [<id_A>] | Equipo B: [<id_B>]` en ambas pantallas. Repite la prueba eligiendo "2v2" con solo 2 jugadores conectados y confirma que el host **no** transiciona a `CasinoFloor` hasta que se unan 4 (usa el `print` de `_refresh_members` o el contador de `Steam.getNumLobbyMembers` para confirmarlo sin necesitar 4 cuentas reales, o reduce temporalmente el umbral para la prueba).

Con ambas instancias ya en `CasinoFloor`, usa la consola de depuración remota de Godot (o botones temporales, igual que Task 4) para llamar en el host `$BattleController.apply_bet(0, 200)` y `$BattleController.apply_payout(0, 1900)`; confirma que `BattleStatusLabel` se actualiza en ambas pantallas y termina mostrando `— FIN (equipo 0, goal_reached)`.

- [ ] **Step 6: Commit**

```bash
git add scenes/lobby_menu.gd scenes/lobby_menu.tscn autoloads/steam_manager.gd scenes/casino_floor.tscn scenes/casino_floor.gd
git commit -m "feat: add match type selection and battle status display to CasinoFloor"
```

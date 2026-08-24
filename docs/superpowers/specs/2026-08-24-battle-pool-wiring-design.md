# Fix: conectar el pozo compartido de Modo Batalla a las 7 mesas

**Fecha:** 2026-08-24
**Estado:** aprobado por el usuario, listo para plan de implementación

## Contexto

El usuario pidió que, en partida por equipos, todo el equipo comparta un
único balance (ej. empiezan en 500, tienen que convertirlo en un objetivo)
de forma que la ficha que gasta o gana un compañero afecte a los dos por
igual, en cualquier mesa. Investigando el código, esto **ya está construido
desde el Plan 4** (`TeamChipPool`, `MatchRules`, `BattleController`) y
completamente probado en aislamiento (`test_team_chip_pool.gd`,
`test_match_rules.gd`, `test_team_assignment.gd`) — meta alcanzada gana el
equipo, bancarrota pierde el equipo, empate por timeout. El problema real
es que **nunca se conectó a las mesas**: `BattleController.apply_bet()` /
`apply_payout()` no los llama nadie en todo el repo (confirmado por
`grep`). Hoy, en modo batalla, cada jugador sigue apostando desde su propio
`ChipLedger.new(500)` individual creado por cada una de las 7
`*_table_state.gd` al sentarse/jugar — el HUD del pozo de equipo
(`battle_status_label`) nunca se mueve porque nada escribe en él.

Este documento describe la conexión que falta, no un rediseño. No toca
Modo Libre.

## Diseño

### Principio

En vez de sincronizar dos balances (individual + pozo de equipo) después de
cada acción, el asiento/jugador de cada mesa usa **directamente el mismo
objeto `ChipLedger`** que ya envuelve `TeamChipPool` cuando la partida es de
equipos. Cero riesgo de desincronización porque no hay dos números que
mantener iguales — hay uno solo, referenciado desde dos sitios.

### `BattleController` — 3 métodos nuevos, nada existente cambia

```gdscript
func team_for(player_id: int) -> int:
	if assignment == null:
		return -1
	return assignment.team_for(player_id)

func ledger_for_team(team_id: int) -> ChipLedger:
	return pools[team_id].ledger

# Cualquier apuesta/pago real ocurre dentro de cada TableState (vía el
# ChipLedger compartido inyectado, ver más abajo), no a través de
# apply_bet()/apply_payout() — así que MatchRules nunca se entera de que el
# saldo cambió a menos que alguien se lo diga. Este método es ese aviso:
# se llama tras CUALQUIER _broadcast_state() de CUALQUIER mesa mientras
# dura el partido.
func notify_balance_possibly_changed() -> void:
	if rules == null or rules.finished:
		return
	if rules.on_balance_changed():
		_broadcast_match_state()
```

`apply_bet()`/`apply_payout()` quedan como están (no las usa nadie tras
este fix tampoco — la vía real es el `ChipLedger` compartido; se dejan por
si alguna mesa futura las necesita, no es objeto de este plan tocarlas).

### `CasinoFloor` — inyecta el ledger compartido en cada mesa

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

Se llama una vez al final de `_ready()`, dentro del bloque
`if multiplayer.is_server():` (mismo sitio donde hoy se decide entre modo
libre/batalla), **después** de que `battle_controller.start_match(...)` ya
haya creado `pools`/`rules` en modo batalla — el orden importa, si se
inyecta antes `ledger_for_team()` fallaría contra un `pools` vacío.
`find_children("*", "<ClassName>", true, false)` es el mismo patrón que
`_ready()` ya usa hoy para conectar `chips_won` a la meta colectiva —
busca por clase del script, no por nombre de nodo (necesario porque el
nodo controlador de Póker se llama `PokerTableController`, no
`TableController`, a diferencia de las otras 6 mesas).

En modo libre, `_is_battle_mode` es `false`, así que
`_ledger_for_player()` siempre devuelve `null` y cada mesa sigue creando su
propio `ChipLedger` individual exactamente como hoy — cero cambio de
comportamiento fuera de modo batalla.

### Cada uno de los 7 `TableController` — 2 campos nuevos, 1 línea en cada punto de entrada

```gdscript
var shared_ledger_provider: Callable = Callable()
var on_shared_ledger_changed: Callable = Callable()
```

En el único punto de cada controlador donde su `TableState` crea un
asiento/jugador nuevo (`_apply_sit` en las mesas por turnos; el primer
`_apply_*` de apuesta en las mesas de ronda independiente), se calcula el
ledger externo y se pasa al `TableState`:

```gdscript
var external_ledger: ChipLedger = shared_ledger_provider.call(player_id) if shared_ledger_provider.is_valid() else null
```

Y en `_broadcast_state()` (el único sitio por el que pasa **cualquier**
mutación exitosa de cualquier mesa, incluidos los pagos que ocurren como
efecto secundario de una acción — ej. `stand()` en Blackjack puede disparar
el pago de toda la mesa sin que haya una "apuesta" explícita en ese
instante):

```gdscript
if on_shared_ledger_changed.is_valid():
	on_shared_ledger_changed.call()
```

### Cada uno de los 7 `*_table_state.gd` — un parámetro opcional en el punto de creación

Dos familias, mismo principio, dos formas (ya existentes) de crear al
jugador:

- **Mesas por turnos** (Blackjack, Ruleta, Póker): el jugador se crea una
  sola vez, en `sit(seat_index, player_id)`. Gana un tercer parámetro
  opcional `external_ledger: ChipLedger = null`; si no es `null`, se usa en
  vez de `ChipLedger.new(...)`.
- **Mesas de ronda independiente** (Dice, Crash, Mines, Plinko): el jugador
  se crea perezosamente dentro de `_player_for(player_id)`, la primera vez
  que llama a `roll()`/`place_bet()`/`start_round()`. `_player_for` gana el
  mismo parámetro opcional, y el método público de entrada (el único que
  llama a `_player_for`) lo recibe y se lo reenvía.

En ambos casos: si el asiento/jugador **ya existía** (segunda apuesta en
adelante), el parámetro se ignora — el ledger ya asignado la primera vez
seguirá siendo el mismo objeto compartido, no hay nada que hacer.

Ninguna función de reglas de apuesta/turno/pago cambia — solo el origen
del objeto `ChipLedger` que ya usaban.

## Verificación cruzada con las respuestas del usuario

- *"si uno del equipo se gasta 100 se le resta a los dos"* — cierto por
  construcción: es el mismo objeto `ChipLedger`, no una copia sincronizada.
- *"si los gana se le suma a los dos"* — igual, cualquier `payout()` sobre
  el ledger compartido lo ve todo el equipo de inmediato la próxima vez que
  su mesa retransmita estado (cada mesa ya difunde su propio `to_dict()`
  con `balance`/`hand_value`/etc. tras cada acción).
- *"en versus se acaba y gana el bando"* al llegar a la meta — ya
  implementado en `MatchRules._check_goal()`, solo hacía falta que algo
  llamara a `on_balance_changed()` tras una apuesta/pago real; eso es
  `notify_balance_possibly_changed()`.
- *"en versus el equipo pierde"* si el pozo llega a 0 — ya implementado en
  `MatchRules._check_bankruptcy()`, mismo mecanismo de aviso.
- Modo libre — sin cambios, confirmado explícitamente fuera de alcance por
  el usuario ("lo perfeccionaremos luego").

## Fuera de alcance

- Modo Libre / `CollectiveGoal` — no se toca.
- Cualquier regla de apuesta, turno, evaluación de manos o pago de
  cualquiera de los 7 juegos.
- UI/estética — el HUD de batalla (`battle_status_label`) ya muestra
  pozos y estado "FIN" en vivo desde Plan 4, no requiere cambios.
- `apply_bet()`/`apply_payout()` de `BattleController` — quedan sin uso,
  no se eliminan ni se modifican.

## Testing y verificación

Ninguna prueba nueva llama a `.rpc()` directamente ni depende de un
`MultiplayerPeer` real — sigue la misma convención ya establecida en el
repo (`test_*_table_state.gd`, `test_match_rules.gd`,
`test_team_chip_pool.gd`): construir los objetos de lógica pura
directamente y verificar comportamiento sin pasar por la capa de red.
`notify_balance_possibly_changed()` y `_inject_shared_ledger_providers()`
sí tocan `.rpc()`/`find_children()` sobre el árbol de escena real — no se
cubren con GUT (no hay precedente en el repo de testear esa capa
directamente), se verifican en la Task final del plan con un playtest real
de 2 clientes en batalla, igual que se cerró el bug de Plan 13.

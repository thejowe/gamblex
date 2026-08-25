# Fix: pozo compartido real en Modo Libre (reemplaza la meta colectiva acumulativa)

**Fecha:** 2026-08-24
**Estado:** aprobado por el usuario, listo para plan de implementación

## Contexto

El usuario reportó que "la meta colectiva sigue siendo errónea, sigue
acumulando solo los puntos ganados" — quiere que todo el grupo en Modo
Libre comparta un balance real (sube y baja con cada apuesta/victoria en
cualquier mesa), mostrado como `balance/objetivo` (ej. `500/1000`), igual
que ya se arregló para Modo Batalla en Plan 15.

Investigado: `CollectiveGoal` (`scripts/free_mode/collective_goal.gd`)
solo tiene `add_chips()`, que suma y nunca resta — alimentado por la
señal `chips_won` de 5 de los 7 controllers (Roulette y Póker no la
emiten). Es un contador de ganancias brutas acumuladas, no un balance.
Mientras tanto, las 7 mesas en Modo Libre siguen creando un `ChipLedger`
individual por asiento — Plan 15 conectó el pozo compartido de
`shared_ledger_provider`/`on_shared_ledger_changed` solo para Modo
Batalla (`_ledger_for_player()` devuelve `null` fuera de batalla, cada
mesa cae a su ledger propio).

Este fix reutiliza exactamente esa misma tubería, ya construida y
probada, para Modo Libre.

## Diseño

### `CasinoFloor` — pozo único compartido en vez de `CollectiveGoal`

- `var shared_pool_ledger: ChipLedger` reemplaza `var goal: CollectiveGoal`.
- Nueva constante `FREE_MODE_STARTING_BALANCE := 500` (junto a
  `GOAL_TARGET := 1000`, que ya coincide con el ejemplo del usuario).
- En `_ready()`, rama no-batalla: `shared_pool_ledger =
  ChipLedger.new(FREE_MODE_STARTING_BALANCE)` — se elimina la conexión de
  `chips_won` a las 5 mesas (ya no hace falta, el balance fluye solo por
  el ledger compartido, igual que en Plan 15).
- `_ledger_for_player(player_id)`: en vez de devolver `null` fuera de
  batalla, devuelve `shared_pool_ledger` para **cualquier** jugador — no
  hay equipos en modo libre, todos comparten el mismo pozo.
- `_inject_shared_ledger_providers()`: además de `battle_controller.notify_balance_possibly_changed`
  en batalla, asigna `_notify_free_mode_balance_changed` como
  `on_shared_ledger_changed` de las 7 mesas cuando NO es batalla —
  mismo mecanismo, mismo punto de enganche que ya usa Plan 15.
- `_notify_free_mode_balance_changed()`: marca `_pool_unlocked = true` si
  `shared_pool_ledger.balance >= GOAL_TARGET` (bandera de un solo sentido,
  igual que hacía `CollectiveGoal.unlocked`) y retransmite el estado.
- El estado retransmitido pasa de `goal.to_dict()`
  (`total`/`target`/`unlocked`) a `{"balance", "target", "unlocked",
  "bankrupt"}`, con `bankrupt = shared_pool_ledger.is_bankrupt()`.
- `GoalLabel` pasa a mostrar `"Meta colectiva: %d / %d fichas" %
  [balance, target]` — mismo formato, ahora con el balance real.

### Pantalla de derrota (bancarrota del pozo compartido)

El usuario pidió explícitamente que llegar a 0 "termine la partida con
una interfaz de derrota" — no solo bloquear apuestas en silencio. Se
añade `DefeatOverlay` (`ColorRect` a pantalla completa dentro de `Hud`,
`CanvasLayer` ya existente) con un mensaje de derrota, visible cuando
`state["bankrupt"] == true`. Al ser `CanvasLayer`, cubre lobby y
cualquier mesa por igual y bloquea el clic (`mouse_filter = STOP`) — no
hay flujo de "reintentar" en ningún otro sitio del proyecto (Modo
Batalla tampoco lo tiene al terminar), así que esta fase tampoco lo
construye; es una pantalla terminal, igual de "básica pero necesaria"
que el resto del HUD actual.

### Limpieza

`CollectiveGoal` (`scripts/free_mode/collective_goal.gd` +
`tests/unit/test_collective_goal.gd`) queda sin ningún uso tras este fix
(confirmado por `grep`, solo lo referenciaban `casino_floor.gd` y su
propio test) — se borran ambos archivos.

## Fuera de alcance

- Modo Batalla — no se toca, ya funciona (Plan 15).
- "Niveles" al alcanzar la meta — mencionado por el usuario como trabajo
  futuro aparte, no es parte de este fix. Alcanzar la meta sigue
  mostrando el banner de desbloqueo y la partida continúa, igual que
  antes.
- Cualquier flujo de "reiniciar partida" tras la derrota.
- Reglas de apuesta/pago de cualquiera de los 7 juegos.

## Testing

Mismo criterio que Plan 15: la lógica de resolución del ledger
(`_ledger_for_player`) y la construcción del diccionario de estado son
puras y se testean sin `.rpc()`/multiplayer real. `_notify_free_mode_balance_changed`
sí llama a `.rpc()` internamente (vía `_broadcast_goal_state`) — no se
cubre con GUT, mismo motivo que `notify_balance_possibly_changed` en
Plan 15; se verifica con playtest manual.

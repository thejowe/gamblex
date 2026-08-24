# Ampliación v1.4b: reskin visual de Plinko

**Fecha:** 2026-08-24
**Estado:** aprobado, listo para plan de implementación
**Referencia visual:** `docs/superpowers/specs/references/plinko-acebet-reference.png`
— tablero triangular de clavijas, la bola rebota fila a fila, fila de
multiplicadores abajo coloreada más intensa cuanto más alto el valor.

## Contexto

Reutiliza la fundación de Plan 16 (`docs/superpowers/specs/2026-08-24-dark-casino-foundation-dice-design.md`,
ya en `main`): `CasinoTheme` (paleta oscura), `BetSidebarPanel` (panel de
apuesta), `CasinoButton`. No se duplican ni se editan.

Plinko hoy es funcional pero en blanco (`Label` + `SpinBox` × 2 + `Button`,
`scenes/plinko_table_net.tscn`). Toda la lógica que la UI necesita ya
existe: `PlinkoTableState.slot_multiplier(rows, slot)`,
`MIN_ROWS`/`MAX_ROWS`/`DEFAULT_ROWS`, y `to_dict()` ya expone por jugador
`last_round` con `bounces` (array de bool, `true` = rebotó a la derecha),
`slot`, `multiplier`, `payout`, `win`. **Este plan es 100% visual — cero
cambios en `scripts/plinko/` ni `scripts/net/plinko_table_controller.gd`.**

La referencia tiene un selector "Riesgo" que no existe en nuestra lógica
(el juego real de Stake tiene varias tablas de pago por riesgo; el
nuestro no) — **no se construye**, sería un control sin efecto real. El
selector de "Filas" sí tiene equivalente real (`rows`, 8-16) y se
construye como dos botones -/+ fuera del `BetSidebarPanel`.

## Diseño

### `PlinkoBoard` — componente nuevo, específico de Plinko (`scripts/ui/casino/plinko_board.gd` + escena)

`Control` que dibuja el tablero completo:
- **Clavijas**: `rows` filas triangulares, fila `r` (0-indexado) con
  `r + 1` clavijas centradas, calculadas por `peg_position(row, index) ->
  Vector2` (método público, testeable).
- **Fila de multiplicadores**: `rows + 1` casillas bajo el tablero, una
  por slot posible (`0..rows`), valor real de
  `PlinkoTableState.slot_multiplier(rows, slot)`, color interpolado entre
  `CasinoTheme.PANEL_NAVY_LIGHT` (multiplicador bajo) y
  `CasinoTheme.ACCENT_GREEN` (multiplicador alto) — igual criterio que la
  referencia (verde intenso en los extremos, apagado en el centro).
- **Bola animada**: método `drop_ball(bounces: Array) -> void` anima con
  `Tween` un segmento por fila (izquierda/derecha según cada bool de
  `bounces`), señal `ball_landed(slot: int)` al terminar. Función pura
  `static func slot_from_bounces(bounces: Array) -> int` (cuenta los
  `true`) reutilizada tanto por el dibujo como por el test — coincide con
  el mismo cálculo que ya hace `PlinkoTableState.roll()` internamente
  (`slot`), no lo reimplementa con lógica distinta, solo lo repite en el
  lado visual porque `PlinkoBoard` no debe depender de recibir el `slot`
  ya calculado si algún día se anima antes de tener el estado completo.

Propiedad exportada `rows: int` (clamped a `MIN_ROWS`/`MAX_ROWS` de
`PlinkoTableState`).

### Reconstrucción de `scenes/plinko_table_net.tscn` / `.gd`

- `BetSidebarPanel` a la izquierda — sustituye a `AmountSpinBox` y
  `DropButton`. Su `bet_pressed(amount)` dispara
  `table_controller.roll(current_rows, amount)`.
- Selector de filas fuera del sidebar: `Label` "Filas: N" + dos
  `CasinoButton` pequeños (`-`/`+`) que ajustan `_rows` en el script de la
  escena (clamp a `MIN_ROWS`/`MAX_ROWS`) y actualizan `PlinkoBoard.rows`.
  Sustituye a `RowsSpinBox`.
- `PlinkoBoard` centrado, ocupa el resto del espacio.
- Al recibir `state_changed` con un `last_round` nuevo para el jugador
  local (comparado contra el `last_round` anterior, mismo patrón que el
  flash de Dice), llama a `board.drop_ball(last_round["bounces"])` — la
  animación de la bola ES la retroalimentación de resultado, no hace
  falta un flash aparte como en Dice.
- `PlayersLabel` (ya existente, restyleado `TEXT_MUTED`) se conserva
  debajo del tablero.

## Fuera de alcance

- `scripts/plinko/`, `scripts/net/plinko_table_controller.gd` — lógica
  correcta y suficiente.
- Selector de "Riesgo" (sin equivalente real en el backend).
- Cualquier otra mesa. Blackjack / fieltro no se toca.

## Testing

`PlinkoBoard` es dibujo puro — pruebas de humo (instancia sin error,
`rows` clamp, `peg_position` produce coordenadas coherentes) más la
función pura `slot_from_bounces` (aritmética real, sí verificable con
precisión) y un test de `drop_ball` que espera la duración de la
animación (`await wait_seconds`) y confirma que `ball_landed` se emite
con el slot correcto. Verificación visual manual final con el usuario,
mismo patrón que Plan 14/16.

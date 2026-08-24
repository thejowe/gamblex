# Ampliación v1.4b: reskin visual de Crash

**Fecha:** 2026-08-24
**Estado:** listo para plan de implementación
**Referencia visual:** `docs/superpowers/specs/references/crash-acebet-reference.png`
(ACEBET) — panel lateral con monto/1/2/x2/Máx/"Programar apuesta", panel
principal oscuro con multiplicador gigante en el centro ("1.48x"), gráfico
de línea verde ascendente sobre ejes de tiempo/multiplicador, punto en el
extremo de la curva.

## Contexto

Reutiliza la fundación de Plan 16, ya en `main`: `CasinoTheme` (paleta
`PANEL_NAVY_DARK`/`PANEL_NAVY_MID`/`PANEL_NAVY_LIGHT`/`ACCENT_GREEN`/
`ACCENT_RED`/`TEXT_LIGHT`/`TEXT_MUTED`, sin añadir nada nuevo — ya
alcanza), `BetSidebarPanel` (panel de apuesta, se instancia tal cual) y
`CasinoButton` (Plan 14). No hace falta ninguna pieza compartida nueva.

Crash hoy es funcional pero en blanco: `SpinBox` + 2 `Button` + un
`Label` de texto (`scenes/crash_table_net.tscn`). La lógica ya expone
todo lo necesario: `CrashTableState.multiplier_at(t: float) -> float`
(estático, puro) calcula el multiplicador en cualquier instante;
`to_dict()` ya da `is_active`/`elapsed`/`balance`/`last_round` por
jugador — **deliberadamente no expone `crash_point`** (el instante exacto
de explosión), porque revelarlo permitiría a un cliente hacer trampa
retirándose siempre justo a tiempo. La vista solo puede mostrar el
multiplicador creciente en tiempo real, nunca el punto de corte futuro —
esto ya lo respeta `crash_table_net.gd` actual (extrapola localmente
`_local_elapsed` entre broadcasts) y este plan lo conserva igual. **Cero
cambios en `scripts/crash/` ni en `scripts/net/crash_table_controller.gd`.**

## Diseño

### `CrashGraph` — específico de Crash (`scripts/ui/casino/crash_graph.gd` + escena)

`Control` que dibuja el multiplicador gigante centrado + la curva
verde/roja. Toda la geometría de la curva sale de una función estática
pura, testeable sin instanciar ningún nodo:

```gdscript
static func curve_points(elapsed_time: float, sample_count: int = 40) -> PackedVector2Array
```

Devuelve `sample_count + 1` puntos `(t, multiplier_at(t))` desde `t=0`
hasta `min(elapsed_time, TIME_WINDOW_SEC)` — la ventana de tiempo visible
del gráfico (12s, igual que la referencia). `_draw()` mapea esos puntos a
coordenadas de pantalla (X = tiempo / `TIME_WINDOW_SEC`, Y = multiplicador
clamped a `[1.0, MULTIPLIER_CEIL]`) y dibuja la polilínea + un punto en el
extremo + el multiplicador gigante en texto grande centrado.

Propiedades exportadas: `elapsed: float`, `state: int` (`enum State {
IDLE, RISING, CRASHED, CASHED_OUT }`) — verde mientras `RISING`/
`CASHED_OUT`, rojo en `CRASHED`. Método `current_multiplier() -> float`
(atajo de `CrashTableState.multiplier_at(elapsed)`).

### Reconstrucción de `scenes/crash_table_net.tscn` / `.gd`

- `BetSidebarPanel` (izquierda) sustituye al `AmountSpinBox`/`BetButton`
  actuales — su `bet_pressed(amount)` llama a
  `table_controller.place_bet(amount)`.
- Un `CasinoButton` "Retirar" (variante `POSITIVE`) al lado del panel,
  sustituye a `CashOutButton` — **sigue siendo un control aparte**, no se
  fusiona con el botón de apostar: son dos acciones reales distintas
  (apostar empieza la ronda, retirar la corta antes de que explote), la
  referencia no lo muestra porque ese casino usa retiro automático por
  umbral, que esta mesa no implementa (fuera de alcance). Habilitado solo
  mientras la ronda del jugador local está activa — mismo criterio que
  hoy ya aplica `crash_table_net.gd`.
- `CrashGraph` centrado ocupando el grueso del panel principal, alimentado
  cada frame con la extrapolación local de `elapsed` (se conserva el
  patrón actual de `_process`/`_local_elapsed`), y con `state` puesto a
  `CRASHED`/`CASHED_OUT` cuando llega un `last_round` nuevo — mismo
  criterio de "flash de resultado" que Dice (Plan 16), pero aquí el color
  se queda en la curva en vez de un `ColorRect` superpuesto, porque la
  curva ES el elemento central de esta pantalla.
- El listado "quién está jugando y a qué multiplicador" que hoy vive en
  `PlayersLabel` se conserva como `Label` simple debajo del gráfico,
  restyleado (`TEXT_MUTED`) — información real ya existente, no forma
  parte de la referencia pero no hay que perderla.

## Fuera de alcance

- `scripts/crash/`, `scripts/net/crash_table_controller.gd` — lógica ya
  correcta y suficiente.
- Retiro automático por umbral (visible en la referencia) — la mesa no
  tiene esa mecánica, añadirla sería cambiar reglas de juego, no estética.
- Cualquier otra mesa, Blackjack, Modo Batalla.

## Testing

`CrashGraph.curve_points()` es lógica pura, se cubre con tests reales
(primer punto ≈ 1.0x, último punto == `multiplier_at(elapsed)`, clamp a
`TIME_WINDOW_SEC`). El resto del componente (`_draw()`) se cubre con
prueba de humo, igual que `DiceThresholdSlider` en Plan 16. Verificación
visual manual final con el usuario.

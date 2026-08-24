# Ampliación v1.4b: reskin visual de Mines

**Fecha:** 2026-08-24
**Estado:** aprobado por el usuario, listo para plan de implementación
**Referencia visual:** `docs/superpowers/specs/references/mines-acebet-reference.png`
(ACEBET) — panel lateral con tamaño de grid y número de minas, panel
principal con la rejilla de casillas tapadas.

## Contexto

Mines hoy es funcional pero visualmente en blanco: un `Label` de estado y
un `GridContainer` de 25 `Button`s vacíos hardcodeados en la escena
(`scenes/mines_table_net.tscn`), tamaño de grid fijo (`TOTAL_CELLS := 25`
en el script). Toda la lógica ya soporta grid de tamaño variable
(`MinesTableState.start_round(player_id, total_cells, mine_count, amount)`
acepta cualquier `total_cells` entre 2 y `MAX_CELLS = 100`) y ya oculta
correctamente las posiciones de las minas mientras la ronda está activa
(`to_dict()` borra `"mines"` de `active_round`, solo lo expone en
`last_round` una vez la ronda termina). **Este plan es 100% visual — cero
cambios en `scripts/mines/` ni en `scripts/net/mines_table_controller.gd`.**

Reutiliza la fundación de Plan 16, ya en `main`, sin tocarla:
`CasinoTheme` (paleta oscura), `BetSidebarPanel` (monto + 1/2/x2/Máx +
botón de apostar), `CasinoButton`.

## Diseño

### `MinesCell` — componente nuevo (`scripts/ui/casino/mines_cell.gd` + escena)

`Control` cuadrado, dibujado por código, sin imágenes. Estados
(`enum State { HIDDEN, SAFE, MINE, MINE_DIM }`):
- `HIDDEN`: tile `PANEL_NAVY_MID` con borde `PANEL_NAVY_LIGHT` — clicable.
- `SAFE`: fondo `ACCENT_GREEN` con un diamante simple dibujado
  (`draw_colored_polygon` con 4 puntos) — la casilla que el jugador ya
  reveló con seguridad.
- `MINE`: fondo `ACCENT_RED` con un círculo negro central (la mina que
  hizo perder la ronda).
- `MINE_DIM`: como `MINE` pero con `modulate.a = 0.4` — las minas que no
  se llegaron a pisar, mostradas atenuadas al terminar la ronda (perdida
  o retirada), para que el jugador vea dónde estaban sin confundirlas con
  la que sí explotó.

Propiedades exportadas: `state: State = State.HIDDEN`, `interactive: bool
= true`. Señal `cell_pressed(index: int)` — solo se emite si
`state == HIDDEN and interactive`; la escena le asigna el `index` desde
fuera al instanciarla. Animación mínima: al pasar a `SAFE`, un
`create_tween()` que anima `scale` de 0.8 a 1.0 en 0.15s (aparición del
diamante), reutilizando el mismo patrón de tween corto que ya usan
`CasinoButton`/`PlayingCard` de Plan 14/16 — no hace falta partículas.

### Reconstrucción de `scenes/mines_table_net.tscn` / `.gd`

- `BetSidebarPanel` a la izquierda: monto + botón "Hacer apuesta" —
  sustituye a `AmountSpinBox`/`StartButton`. Su `bet_pressed(amount)`
  dispara `start_round(total_cells_actual, mine_count_actual, amount)`.
- Dentro de la barra lateral (debajo del panel, o en un `VBoxContainer`
  propio junto a él — decisión de maquetación libre para el agente,
  la referencia los pone apilados): un `OptionButton` "Tamaño" con 3
  opciones fijas (`5 x 5` → 25 celdas/5 columnas, `8 x 8` → 64
  celdas/8 columnas, `10 x 10` → 100 celdas/10 columnas — cubre de sobra
  el rango que ya soporta `MinesTableState`, no hace falta tamaño
  arbitrario libre) y un `LineEdit`/`SpinBox` "Minas" con una label de
  porcentaje en vivo (`"%.2f%%" % (mine_count / float(total_cells) *
  100.0)`, igual que el "7.81%" de la referencia).
- Grid principal: un `GridContainer` cuyas `columns` y número de hijos
  `MinesCell` se reconstruyen dinámicamente cada vez que cambia el
  `OptionButton` de tamaño (limpia y vuelve a poblar el grid) — nunca
  hardcodear 25 celdas fijas como hoy.
- Botón "Retirar" (`CasinoButton`, variante `POSITIVE`) visible solo
  durante una ronda activa, sobre o junto al grid.
- Estado del grid en cada `state_changed`: si hay `active_round` propio,
  cada índice en `active_round["revealed"]` → celda `SAFE`, resto
  `HIDDEN` e interactivas; si `active_round` está vacío pero hay
  `last_round` reciente sin ver todavía, pinta el resultado final: los
  índices de `last_round["revealed"]` → `SAFE`, el índice de la mina que
  hizo perder (si `last_round["win"] == false`, es el único de
  `last_round["mines"]` que no está en `revealed` y coincide con el
  intento fallido — en la práctica, dado que `reveal()` termina la ronda
  en el primer clic sobre una mina, alguna posición de `mines` no estará
  en `revealed`; usa el primer elemento de `mines` que no esté en
  `revealed` como la mina "explotada" si `win == false`, el resto de
  `mines` como `MINE_DIM`) — si `win == true` (se retiró o completó),
  ninguna casilla es `MINE`, todas las de `mines` quedan `MINE_DIM`.
  Celdas fuera de `revealed`/`mines` quedan `HIDDEN`, no interactivas
  (ronda ya terminada).
- Etiqueta de estado (`StatusLabel` actual) se conserva, restyleada con
  `TEXT_MUTED`, debajo del grid.
- Flash de resultado igual que Dice (Plan 16): `ColorRect` transparente
  superpuesto al grid, `ACCENT_GREEN`/`ACCENT_RED` con tween de alpha a 0
  en 0.6s, disparado cuando `last_round` cambia respecto al anterior
  visto.

## Fuera de alcance

- `scripts/mines/` / `scripts/net/mines_table_controller.gd` — sin
  cambios, la interfaz ya expone todo lo necesario.
- Cualquier otra mesa — Blackjack, Dice, Ruleta, Póker, Crash, Plinko no
  se tocan.
- Modo Batalla / pozo compartido — ya resuelto en Plan 15.

## Testing

`MinesCell` con pruebas de humo (instancia sin error, estado por defecto,
`cell_pressed` se emite solo si `HIDDEN` + `interactive`, no se emite si
`MINE`/`SAFE`/no interactivo). La lógica de "qué celdas pintar a partir
de `active_round`/`last_round`" se extrae a una función pura testeable
(`compute_cell_states(active_round, last_round) -> Array[int]`) que no
toca la escena — mismo criterio que Plan 16 separó `_refresh_stats()` de
la UI real. Verificación visual manual final con el usuario.

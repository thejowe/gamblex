# Fix: grid de números de Ruleta se sale de la ventana

**Fecha:** 2026-08-24
**Estado:** confirmado en vivo por la sesión pilar, listo para plan de implementación

## Contexto

Verificación visual en vivo (Plan 17 mergeado) encontró que el grid de
37 números de `RouletteBettingGrid` corta los números de la derecha de
cada fila (11, 23, 35...) fuera de la ventana — invisibles e imposibles
de pulsar. Captura de pantalla adjunta al usuario en la conversación.

## Causa raíz

`RouletteBettingGrid` (`scripts/ui/casino/roulette_betting_grid.gd`)
extiende `GridContainer` directamente con `columns = 12`, y mete **los
44 botones en el mismo contenedor**: los 37 números (48px de ancho cada
uno) más los 7 botones de apuesta de fuera ("Rojo", "13 a 24", etc.,
96px de ancho). Los 37 números llenan 3 filas completas de 12 columnas
más 1 celda en la fila 4 (columna 0, número "36") — los 7 botones de
fuera empiezan justo después, en las columnas 1 a 7 de esa misma fila 4.

`GridContainer` fija el ancho de cada columna al máximo entre todas las
celdas que caen en esa columna, en cualquier fila. Como las columnas 1-7
tienen una celda ancha (96px) en la fila 4, esas columnas se ensanchan a
96px **en todas las filas**, incluidas las filas 1-3 donde solo hay
números de 48px. El ancho total resultante (≈900-960px con separación)
supera el ancho de diseño del proyecto (900px) y el propio contenedor
(860px), así que la parte derecha de las filas de números queda fuera de
la ventana.

## Diseño del fix

Separar los números y las apuestas de fuera en **dos `GridContainer`
independientes** (uno por cada grupo, sin compartir columnas), dentro de
un `VBoxContainer` como raíz de `RouletteBettingGrid` — así el ancho de
columna de un grupo no puede contaminar al otro:

- `_number_grid` (`GridContainer`, `columns = 12`): solo los 37 números.
  Ancho total ≈ 12 × 48px + separación ≈ 620px, cabe de sobra en 860px.
- `_outside_bets_row` (`GridContainer`, `columns = 7`): solo los 7
  botones de apuesta de fuera, en una sola fila. Ancho total ≈ 7 × 96px +
  separación ≈ 700px, también cabe.

`RouletteBettingGrid` pasa de `extends GridContainer` a `extends
VBoxContainer`, y `columns = 12` deja de fijarse sobre `self` — se fija
sobre `_number_grid`. El resto de la interfaz pública (señal
`bet_selected`, métodos `_on_number_pressed`/`_on_outside_bet_pressed`)
no cambia — nada fuera de este archivo necesita enterarse del cambio
interno.

## Fuera de alcance

- Cualquier otro archivo — es un fix de layout de un solo componente.
- No se cambia el comportamiento de apostar-al-clic (Plan 17,
  confirmado y aceptado por el usuario) — solo el layout.

## Testing

`tests/unit/test_roulette_betting_grid.gd` ya existe (Plan 17) — el test
`test_grid_creates_37_number_buttons` buscaba los botones como hijos
directos de `grid`; con la nueva estructura viven dentro de
`grid._number_grid`, así que ese test se actualiza para mirar ahí. Los
otros dos tests no cambian (llaman a los handlers directo, no dependen
de la jerarquía de nodos). Se añade un test nuevo de ancho total para
que esta regresión no vuelva a colarse sin que un test falle.

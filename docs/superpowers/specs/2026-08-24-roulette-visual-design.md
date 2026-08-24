# Ampliación v1.4b: reskin visual de Ruleta

**Fecha:** 2026-08-24
**Estado:** aprobado por el usuario (parte de "todas las mesas"), listo para plan de implementación
**Referencia visual:** `docs/superpowers/specs/references/roulette-acebet-reference.png`

## Contexto

Segunda mesa del lote de reskin oscuro tras Dice (Plan 16). Reutiliza la
fundación ya en `main`: `CasinoTheme` (paleta), `BetSidebarPanel` (panel
de apuesta), `CasinoButton`. No se toca `scripts/roulette/` ni
`scripts/net/roulette_table_controller.gd` — la lógica ya es correcta y
suficiente, salvo por un límite real explicado abajo.

`scenes/roulette_table_net.tscn` hoy es un `Label` de asientos, un
`Label` de último número y 6 botones sueltos con apuestas fijas
(`Apostar Rojo 50`, `Apostar Pleno 7 (100)`, etc.) — nada dibujado, sin
selección real de número.

## Límite real encontrado (fuera de alcance, no se toca)

La referencia tiene botones "1 a 18" / "19 a 36" (apuesta alta/baja). El
`enum BetType` de `RouletteTableState` no los tiene (`STRAIGHT, RED,
BLACK, EVEN, ODD, DOZEN_1, DOZEN_2, DOZEN_3`) — añadirlos sería tocar
reglas de juego (`_bet_wins`, `_payout_multiplier`), fuera del criterio
"100% visual" que se ha seguido en todo este lote. Esos dos botones **no
se replican** en esta fase; el resto de tipos de apuesta de la referencia
sí tienen equivalente real y se implementan todos.

## Diseño

### Paleta

Ninguna constante nueva — `CasinoTheme.CARD_RED`/`CARD_BLACK` (Plan 14)
se reutilizan para los números rojos/negros de la ruleta,
`CasinoTheme.ACCENT_GREEN` para el 0, `PANEL_NAVY_*`/`TEXT_*` para paneles
y texto, igual que Dice.

### `RouletteResultBadge` (`scripts/ui/casino/roulette_result_badge.gd` + escena)

`Control` pequeño (~32px), dibuja un círculo de color según el número
(`CARD_RED` si está en `RouletteTableState.RED_NUMBERS`, `ACCENT_GREEN`
si es 0, `CARD_BLACK` en el resto) con el número centrado. Propiedad
exportada `number: int`. Se instancia repetidamente para el historial de
resultados recientes (`HBoxContainer` a la derecha del tablero, últimos
8, más nuevo a la izquierda — igual que la columna vertical de la
referencia, adaptada a fila horizontal por simplicidad de layout).

### `RouletteWheelDisplay` (`scripts/ui/casino/roulette_wheel_display.gd` + escena)

`Control` circular (~260px), dibuja 37 sectores alternando rojo/negro
según `RouletteTableState.RED_NUMBERS` (0 en verde), con el número de
cada sector rotado hacia el centro. Propiedad `last_result: int = -1`.
Método `spin_to(result: int) -> void`: calcula el ángulo del sector
ganador, anima `rotation` con `create_tween()` (varias vueltas completas
+ ángulo final, ~2s, `Tween.EASE_OUT`/`TRANS_CUBIC` para que frene como
una ruleta real), emite `spin_finished` al terminar.

### `RouletteBettingGrid` (`scripts/ui/casino/roulette_betting_grid.gd` + escena)

`GridContainer` que instancia 37 `CasinoButton` (0-36) coloreados
(`variant` no alcanza para rojo/negro/verde — usa
`add_theme_stylebox_override` directo con `CasinoTheme.CARD_RED`/
`CARD_BLACK`/`ACCENT_GREEN` como en Task 4 del plan) más una fila de 5
`CasinoButton` para Rojo/Negro/Par/Impar (variant `NEUTRAL`, se resaltan
al seleccionarse) y 3 para las docenas. Señal
`bet_selected(bet_type: int, number: int)` — **no apuesta al pulsar**,
solo marca la selección activa (resaltada visualmente); el botón "Hacer
apuesta" de `BetSidebarPanel` es el que dispara la apuesta real, igual
que se hizo con la dirección en Dice (Plan 16).

### Reconstrucción de `scenes/roulette_table_net.tscn` / `.gd`

- `BetSidebarPanel` a la izquierda — `bet_pressed(amount)` combina con el
  `(bet_type, number)` seleccionado en `RouletteBettingGrid` y llama
  `table_controller.place_bet(my_seat_index, bet_type, number, amount)`.
- `RouletteWheelDisplay` centrada arriba; al recibir `state_changed` con
  un `last_result` distinto al anterior, llama `spin_to(last_result)`.
- `RouletteBettingGrid` debajo de la rueda.
- Historial de `RouletteResultBadge` a la derecha de la rueda.
- Botón "Girar" (`CasinoButton`, variant `POSITIVE`) — se mantiene como
  acción separada de apostar, igual que hoy (`table_controller.spin()`),
  la referencia no lo necesita porque su backend real gira automático,
  el nuestro no.
- `SitButton` restyleado como `CasinoButton`.
- Lista de asientos se conserva como `Label` simple restyleado
  (`TEXT_MUTED`), no está en la referencia pero es información real que
  no hay que perder.

## Fuera de alcance

- Apuestas "1 a 18"/"19 a 36" (ver límite real arriba).
- Cualquier cambio a `scripts/roulette/roulette_table_state.gd`,
  `roulette_wheel.gd`, `scripts/net/roulette_table_controller.gd`.
- Blackjack, Dice, Modo Batalla — no se tocan.

## Testing

Componentes de dibujo puro (`RouletteResultBadge`, `RouletteWheelDisplay`)
con pruebas de humo (instancia sin error, propiedades exportadas,
`spin_to` deja `last_result` actualizado). `RouletteBettingGrid` sí es
testeable con precisión: `bet_selected` se emite con los parámetros
correctos por cada tipo de celda. Verificación visual manual final con
el usuario.

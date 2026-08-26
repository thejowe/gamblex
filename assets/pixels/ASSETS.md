# Lista de assets pixel art — grid base 32px

Sacada del código real (`scripts/ui/casino/*.gd`), no inventada. Nombres de
archivo son sugerencia — respeta la carpeta, el nombre exacto lo ajusta el
agente al importar.

## common/chips/ — fichas (`CasinoTheme.CHIP_COLORS`)

Denominaciones reales usadas en el código: **1, 5, 10, 25, 50, 100**.
Cualquier otra usa un color morado de fallback — si quieres cubrir más
valores dilo y las añado a la paleta.

- chip_1.png / chip_5.png / chip_10.png / chip_25.png / chip_50.png / chip_100.png

## common/cards/ — cartas (Blackjack + Póker)

52 cartas + dorso. Palos: hearts, diamonds, clubs, spades. Rangos: A,2-10,J,Q,K.

- card_back.png
- card_hearts_A.png ... card_hearts_K.png (13)
- card_diamonds_A.png ... card_diamonds_K.png (13)
- card_clubs_A.png ... card_clubs_K.png (13)
- card_spades_A.png ... card_spades_K.png (13)

## common/buttons/ — botón genérico, 3 variantes × 4 estados

Variantes: neutral, positive (verde), negative (rojo).
Estados: normal, hover, pressed, disabled.

- button_neutral_normal.png / _hover.png / _pressed.png / _disabled.png
- button_positive_normal.png / _hover.png / _pressed.png / _disabled.png
- button_negative_normal.png / _hover.png / _pressed.png / _disabled.png

## common/panels/ — fondo panel lateral de apuesta (compartido por 6 mesas)

- bet_sidebar_bg.png (panel navy oscuro, usado por Ruleta/Dice/Crash/Mines/Plinko/Blackjack)
- panel_border.png (opcional, si quieres borde distinto del StyleBox actual)

## blackjack/ — mesa de fieltro (`FeltTablePanel`)

- felt_table_bg.png (tapete verde + riel de madera)
- (usa common/cards/ y common/chips/, no assets propios de carta/ficha)

## roulette/ — rueda (`RouletteWheelDisplay`)

37 casillas en orden real de rueda (0,32,15,19,4,21,2,25,17,34,6,27,13,36,11,30,8,23,10,5,24,16,33,1,20,14,31,9,22,18,29,7,28,12,35,3,26).
Colores: 0 verde, resto rojo/negro según `RouletteTableState.RED_NUMBERS`.

- roulette_wheel.png (rueda completa con los 37 números pintados, o sprite base sin números si prefieres dibujarlos aparte)
- roulette_ball.png
- roulette_grid_cell_red.png / _black.png / _green.png (celdas del grid de apuesta interior, 37 números)

## poker/ — sin reskin todavía, sin referencia tuya

- (pendiente — reutiliza common/cards/ + common/chips/, mesa propia si mandas referencia)

## dice/ — slider de umbral (`DiceThresholdSlider`)

No hay dado físico en el código (es un slider, no un cubo 1-6) — si quieres
un dado de verdad como icono decorativo (ej. en el lobby) dímelo, si no,
solo necesita el track del slider.

- dice_slider_handle.png
- dice_slider_track_win.png / dice_slider_track_lose.png

## crash/ — gráfico de multiplicador (`CrashGraph`)

Actualmente es una línea dibujada por código, sin sprite. Si quieres un
cohete/nave que suba con la línea:

- crash_rocket.png
- crash_line_texture.png (opcional, si no quieres línea sólida)

## mines/ — celdas (`MinesCell`, 4 estados)

- mines_cell_hidden.png
- mines_cell_safe.png (gema/diamante verde)
- mines_cell_mine.png (mina roja, resultado de ronda perdida)
- mines_cell_mine_dim.png (mina no pisada, semitransparente, se muestra al final)

## plinko/ — tablero (`PlinkoBoard`)

- plinko_peg.png
- plinko_ball.png
- plinko_slot_bg.png (fila de multiplicadores inferior, color varía con el valor — puede ser un solo sprite + tint)

## hud/ — barra superior

- icon_pot.png (fichas del pozo, modo libre)
- icon_crown_a.png / icon_crown_b.png (equipos, modo batalla)
- icon_win.png / icon_lose.png (overlay victoria/derrota)

## lobby/ — 7 tarjetas de selección de juego

- card_blackjack.png
- card_roulette.png
- card_poker.png
- card_dice.png
- card_crash.png
- card_mines.png
- card_plinko.png

---

Cuando tengas un lote razonable (aunque sea solo fichas+cartas+botones),
dímelo y armo el plan del primer agente de pixel art.

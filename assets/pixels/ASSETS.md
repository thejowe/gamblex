# Lista de assets pixel art — grid base 32px

Una carpeta por cada asset individual (104 en total) — mete la imagen
dentro de la carpeta que le corresponde, con el mismo nombre que la
carpeta (ej. `common/chips/chip_1/chip_1.png`). Así el agente que los
integre no tiene que adivinar qué archivo es cuál.

## common/chips/ — fichas (`CasinoTheme.CHIP_COLORS`, denominaciones reales)

`chip_1/` `chip_5/` `chip_10/` `chip_25/` `chip_50/` `chip_100/`

## common/cards/ — cartas (Blackjack + Póker), 52 + dorso

`card_back/`

Por palo (`hearts`/`diamonds`/`clubs`/`spades`) × rango
(`A`/`2`.../`10`/`J`/`Q`/`K`): `card_hearts_A/` ... `card_spades_K/`
(52 carpetas).

## common/buttons/ — botón genérico, 3 variantes × 4 estados (12 carpetas)

Variantes: `neutral`/`positive`/`negative`. Estados:
`normal`/`hover`/`pressed`/`disabled`.
`button_neutral_normal/` ... `button_negative_disabled/`

## common/panels/ — fondo del panel lateral de apuesta (compartido por 6 mesas)

`bet_sidebar_bg/` `panel_border/` (este último opcional)

## blackjack/

`felt_table_bg/` (tapete verde + riel de madera; usa `common/cards/` y
`common/chips/` para el resto, no tiene assets propios de carta/ficha)

## roulette/

`roulette_wheel/` `roulette_ball/` `roulette_grid_cell_red/`
`roulette_grid_cell_black/` `roulette_grid_cell_green/`

## poker/

Sin reskin todavía, sin referencia tuya — carpeta vacía a propósito.
Reutiliza `common/cards/` + `common/chips/` cuando le toque.

## dice/

`dice_slider_handle/` `dice_slider_track_win/` `dice_slider_track_lose/`

No hay dado físico en el código (es un slider, no un cubo 1-6).

## crash/

`crash_rocket/` (si quieres un cohete/nave subiendo con la línea)
`crash_line_texture/` (opcional, si no quieres línea sólida)

## mines/

`mines_cell_hidden/` `mines_cell_safe/` `mines_cell_mine/` `mines_cell_mine_dim/`

## plinko/

`plinko_peg/` `plinko_ball/` `plinko_slot_bg/`

## hud/

`icon_pot/` `icon_crown_a/` `icon_crown_b/` `icon_win/` `icon_lose/`

## lobby/ — 7 tarjetas de selección de juego

`card_blackjack/` `card_roulette/` `card_poker/` `card_dice/`
`card_crash/` `card_mines/` `card_plinko/`

---

104 carpetas creadas. Ve rellenando las que puedas — no hace falta
completarlas todas para empezar (fichas+cartas+botones ya es un lote
razonable para el primer agente de pixel art).

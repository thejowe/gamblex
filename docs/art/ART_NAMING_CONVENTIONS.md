# Art Naming Conventions — Casino Pixel

La convención ya existente en `assets/pixels/` (creada por el usuario)
es la convención oficial. No se cambia — se documenta y se extiende a
los masters, que son nuevos.

## Assets finales (ya definidos por la estructura de carpetas)

```text
card_back.png
card_hearts_A.png … card_hearts_K.png
card_diamonds_A.png … card_spades_K.png

chip_1.png chip_5.png chip_10.png chip_25.png chip_50.png chip_100.png

button_neutral_normal.png   button_neutral_hover.png
button_neutral_pressed.png  button_neutral_disabled.png
button_positive_normal.png  … (mismo patrón)
button_negative_normal.png  … (mismo patrón)

bet_sidebar_bg.png  panel_border.png

felt_table_bg.png

roulette_wheel.png  roulette_ball.png
roulette_grid_cell_red.png  roulette_grid_cell_black.png
roulette_grid_cell_green.png

dice_slider_handle.png  dice_slider_track_win.png
dice_slider_track_lose.png

crash_rocket.png  crash_line_texture.png

mines_cell_hidden.png  mines_cell_safe.png
mines_cell_mine.png    mines_cell_mine_dim.png

plinko_peg.png  plinko_ball.png  plinko_slot_bg.png

card_blackjack.png … card_plinko.png   (lobby, 7)

lobby_bg.png  loading_bg.png
victory_bg.png  defeat_bg.png
settings_bg.png  pause_bg.png  credits_bg.png  help_bg.png

icon_pot.png  icon_crown_a.png  icon_crown_b.png
icon_win.png  icon_lose.png
```

Regla: nombre del archivo == nombre de la carpeta que lo contiene
(`assets/pixels/common/chips/chip_1/chip_1.png`). Es lo que ya pide
`ASSETS.md` — no lo rompas.

## Masters (nuevos — no existían antes de este sistema)

Prefijo `_masters/`, sufijo `_MASTER` en mayúsculas para diferenciarlos
de un asset final por accidente:

```text
CARD_MASTER.png            CARD_BACK_MASTER.png
SUIT_HEART.png  SUIT_DIAMOND.png  SUIT_CLUB.png  SUIT_SPADE.png
RANK_A.png … RANK_K.png
CHIP_MASTER.png
BUTTON_MASTER.png
PANEL_MASTER.png
MINES_CELL_MASTER.png
ROULETTE_CELL_MASTER.png
LOBBY_CARD_MASTER.png
ICON_MASTER.png
BACKGROUND_MASTER.png       (si se confirma que aplica)
```

## Animaciones (frames)

Sufijo numérico de 2 dígitos, mismo prefijo:

```text
crash_rocket_idle.png
crash_rocket_launch.png
crash_rocket_flame_01.png  crash_rocket_flame_02.png …
```

Si el motor consume un `SpriteFrames`/`AnimatedTexture` en vez de PNGs
sueltos, el nombre del recurso `.tres` sigue el mismo patrón sin
extensión de frame.

## Prohibido

```text
asset_final_v2_FINAL_REAL.png
chip_1_new.png
button_neutral_normal_v3.png
```

Una sola fuente final por asset. Si hace falta iterar, se sobreescribe
el `DRAFT` en revisión — no se acumulan versiones con sufijos.

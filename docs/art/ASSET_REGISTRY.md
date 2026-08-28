# Asset Registry — Casino Pixel

Estado real de cada asset. `CasinoArtDirector` es el único que edita
este archivo. Estados: `PLANNED` `DRAFT` `REVIEW` `APPROVED` `FINAL`.

Estado tras FASE 2-7 (2026-08-28): **7/9 masters `APPROVED`**, y
**73/112 assets finales `APPROVED`** (52 cartas + card_back, 6 fichas,
12 botones, 2 paneles, 5 iconos HUD, 1 felt_table_bg). Todo FASE 4-7 se
derivó **por código (Pillow) a partir de los masters ya aprobados —
0 generaciones nuevas de PixelLab**, siguiendo la jerarquía de
herramientas de `ART_PIPELINE.md` (regla 2: composición por código para
lo repetitivo/derivado de un master). 10/40 generaciones del trial
siguen siendo las únicas usadas, las de FASE 2.

`MINES_CELL_MASTER` y `ROULETTE_CELL_MASTER` no son de FASE 2 (les toca
en FASE 12/8) — siguen en `PLANNED`. `BACKGROUND_MASTER` confirmado,
pendiente de generarse en FASE 15-17. 39/112 assets finales
(ruleta, póker si aplica, dice, crash, mines, plinko, lobby, home/carga,
victoria/derrota, menús) siguen `PLANNED`.

**Corrección de plan encontrada en FASE 6:** `ART_ASSET_PLAN.md` tenía
mal asignado `PANEL_MASTER` como master de `bet_sidebar_bg`/
`panel_border`. El código real (`scripts/ui/casino/bet_sidebar_panel.gd`)
usa `CasinoTheme.PANEL_NAVY_MID`, familia panel oscuro — no fieltro.
`PANEL_MASTER` (fieltro) se queda reservado para Blackjack/Póker;
`bet_sidebar_bg`/`panel_border` se generaron directamente por código con
los tokens `PANEL_NAVY_DARK/MID/LIGHT`, sin master de por medio (son
geometría simple, no necesitan un master de imagen).

## Masters (9)

| ID | Categoría | Tamaño | Status | Deriva |
|---|---|---|---|---|
| CARD_MASTER | Cartas | 64×96 | APPROVED | 52 cartas |
| CARD_BACK_MASTER | Cartas | 64×96 | APPROVED | card_back |
| CHIP_MASTER | Fichas | 32×32 | APPROVED | 6 fichas |
| BUTTON_MASTER | UI | 96×32 | APPROVED | 12 botones |
| PANEL_MASTER | UI (fieltro) | 256×144 | APPROVED | bet_sidebar_bg, panel_border |
| MINES_CELL_MASTER | Mines | 32×32 | PLANNED | 4 casillas |
| ROULETTE_CELL_MASTER | Ruleta | — | N/A (geometría por código, sin PNG standalone) | 3 celdas |
| LOBBY_CARD_MASTER | Lobby | 192×256 | PLANNED | 7 tarjetas |
| ICON_MASTER | HUD | 32×32 | APPROVED | 5 iconos |
| BACKGROUND_MASTER | Fondos | 225×270 | CONFIRMADO — aplica a los 8 fondos, mismo marco/vignette, motivo central cambia | 8 fondos |

Decisión (usuario, 2026-08-28): los 7 masters de FASE 2 quedan
`APPROVED` tal cual (pip de trébol decorativo en CARD_MASTER y iconos
de palo en `felt_table_bg` aceptados). `BACKGROUND_MASTER` confirmado
como master compartido — se genera al llegar a FASE 15/16/17.

## Detalle de generación — FASE 2 (7 masters, PixelLab MCP `create_image_pixflux`)

| Asset | Tool | Method | Resolution | Palette | Status | Nota |
|---|---|---|---|---|---|---|
| CARD_MASTER | PixelLab pixflux | text2img, opaco sobre fondo oscuro (retry tras fallo transparente) | 64×96 | ivory `#F5F5F0` + borde marrón | REVIEW | Trae un pip de trébol decorativo en la esquina — al derivar las 52 cartas en FASE 4, sustituir ese pip por el rank/suit real vía `inpaint_image`, no reutilizarlo literalmente |
| CARD_BACK_MASTER | PixelLab pixflux | text2img, opaco sobre fondo negro (retry) | 64×96 | `#1C5C3A` + `#E8C468` | REVIEW | — |
| CHIP_MASTER | PixelLab pixflux | text2img, opaco sobre fondo oscuro (retry) | 32×32 | off-white + oro, notches de borde | REVIEW | Falta aplicar color por denominación en FASE 5 (derivar, no regenerar desde cero) |
| BUTTON_MASTER | PixelLab pixflux | text2img, transparente (funcionó a la primera — relleno navy oscuro) | 96×32 | `#1C2733` + `#E8C468` | REVIEW | Solo estado "normal" — hover/pressed/disabled se derivan en FASE 6 |
| PANEL_MASTER | PixelLab pixflux | text2img, opaco | 256×144 | `#5C3A20`/`#8A5A34` madera + `#1C5C3A` fieltro + `#E8C468` | REVIEW | — |
| ICON_MASTER | PixelLab pixflux | text2img, transparente (funcionó a la primera — relleno navy oscuro) | 32×32 | `#131B26` + `#E8C468` | REVIEW | Placeholder de badge — el pictograma interior se añade por icono en FASE 6 |
| felt_table_bg (fragmento FASE 2, no es master de variantes) | PixelLab pixflux | text2img, opaco | 320×180 | `#1C5C3A`/`#2F8F5B` fieltro + `#5C3A20`/`#8A5A34` madera + `#E8C468` | REVIEW | Trae 4 iconos de palo decorativos en el riel superior — evaluar si se conservan en el `felt_table_bg` final de FASE 7 o se piden sin ellos |

Gotcha documentado en `ART_PIPELINE.md`: `no_background=true` con
rellenos claros (ivory/off-white) borra el relleno junto al fondo en
`create_image_pixflux` — CARD_MASTER/CARD_BACK_MASTER/CHIP_MASTER
necesitaron un segundo intento opacos sobre fondo oscuro. 3 generaciones
descartadas (1 fallo original de CARD_MASTER + 2 reintentos), 10
generaciones usadas de 40 en el trial.

Archivos en `assets/pixels/_masters/` (nuevo, creado en esta fase):
`CARD_MASTER.png`, `CARD_BACK_MASTER.png`, `CHIP_MASTER.png`,
`BUTTON_MASTER.png`, `PANEL_MASTER.png`, `ICON_MASTER.png`,
`felt_table_bg_fragment.png`.

## Cartas — `common/cards/` (53) — Master: CARD_MASTER / CARD_BACK_MASTER

| ID | Tamaño | Status | Source |
|---|---|---|---|
| card_back | 52×86 | APPROVED | CARD_BACK_MASTER, fondo neutro eliminado por flood-fill |
| card_hearts_A … card_hearts_K (13) | 52×86 | APPROVED | CARD_MASTER + pip/rango por código (Pillow) |
| card_diamonds_A … card_diamonds_K (13) | 52×86 | APPROVED | ídem |
| card_clubs_A … card_clubs_K (13) | 52×86 | APPROVED | ídem |
| card_spades_A … card_spades_K (13) | 52×86 | APPROVED | ídem |

Método: `CARD_MASTER` limpiado (fondo neutro fuera, pips de trébol
horneados parcheados con el ivory de base, borde negro redibujado a
mano porque el de la IA era demasiado desaturado y se perdía al quitar
el fondo — ver nota en `ART_PIPELINE.md`), escalado a 52×86 (tamaño real
de `CARD_BACK_MASTER` recortado). Palo y rango: matrices de píxel a mano
(4 palos) + fuente bitmap de PIL binarizada a alfa 0/255 (sin
anti-aliasing) para el rango, en la esquina superior izquierda y su
espejo a 180° en la inferior derecha. 0 generaciones PixelLab.

## Fichas — `common/chips/` (6) — Master: CHIP_MASTER

| ID | Tamaño | Status | Color (`CasinoTheme.CHIP_COLORS`) |
|---|---|---|---|
| chip_1 | 22×22 | APPROVED | `#E8E8E8` |
| chip_5 | 22×22 | APPROVED | `#C0392B` |
| chip_10 | 22×22 | APPROVED | `#2E6DA4` |
| chip_25 | 22×22 | APPROVED | `#2F8F5B` |
| chip_50 | 22×22 | APPROVED | `#E07B1F` |
| chip_100 | 22×22 | APPROVED | `#1A1A1A` |

Método: `CHIP_MASTER` limpiado, cuerpo recoloreado por denominación
preservando luminancia (aro dorado y notches oscuros del borde
detectados por hue/brillo y no recoloreados), número compuesto con
fuente bitmap de PIL binarizada. 0 generaciones PixelLab.

## Botones — `common/buttons/` (12) — Master: BUTTON_MASTER

| ID | Tamaño | Status |
|---|---|---|
| button_neutral_normal / hover / pressed / disabled | 93×30 | APPROVED ×4 |
| button_positive_normal / hover / pressed / disabled | 93×30 | APPROVED ×4 |
| button_negative_normal / hover / pressed / disabled | 93×30 | APPROVED ×4 |

Método: `BUTTON_MASTER` limpiado, cuerpo recoloreado por variante
(navy/verde/rojo, borde dorado preservado por hue), 4 estados por
brillo/desaturación (hover +18% brillo, pressed −22%, disabled
desaturado 65% + alfa 75%). 0 generaciones PixelLab.

## Paneles — `common/panels/` (2) — Sin master de imagen (geometría por código)

| ID | Tamaño | Status |
|---|---|---|
| bet_sidebar_bg | 96×144 | APPROVED |
| panel_border | 96×144 | APPROVED |

Método: rect redondeado por código con gradiente vertical
`PANEL_NAVY_LIGHT`→`PANEL_NAVY_DARK` + borde `PANEL_NAVY_LIGHT` 2-3px,
tokens reales de `CasinoTheme` (no `PANEL_MASTER`, ver corrección de
plan arriba). 0 generaciones PixelLab.

## Blackjack (1)

| ID | Tamaño | Status |
|---|---|---|
| felt_table_bg | 320×180 | APPROVED |

Fragmento de FASE 2 (`felt_table_bg_fragment`, PixelLab pixflux)
adoptado tal cual como asset final — aprobado explícitamente por el
usuario con los iconos de palo decorativos incluidos.

## Póker (0 — carpeta vacía a propósito, reutiliza cards/chips/panel)

## Ruleta (5) — FASE 8 completa (2026-08-28)

| ID | Tamaño | Status | Source |
|---|---|---|---|
| roulette_wheel | 124×124 | APPROVED | PixelLab pixflux, transparente a la primera |
| roulette_ball | 9×10 | APPROVED | PixelLab pixen, opaco sobre fondo oscuro (mismo gotcha que fichas/cartas) + 2 pasadas de flood-fill (gris exterior + anillo navy) |
| roulette_grid_cell_red | 40×40 | APPROVED | código (Pillow) |
| roulette_grid_cell_black | 40×40 | APPROVED | código (Pillow) |
| roulette_grid_cell_green | 40×40 | APPROVED | código (Pillow) |

`ROULETTE_CELL_MASTER`: no existe como PNG standalone — las 3 celdas
comparten una función `make_cell()` por código (mismo patrón que
`bet_sidebar_bg`/`panel_border`), no hace falta un master de imagen
para geometría plana. 2 generaciones PixelLab usadas en FASE 8 (12/40
del trial en total).

**Nota de integración (no es tarea de `CasinoArtDirector`):**
`RouletteWheelDisplay._draw()` y `roulette_betting_grid.gd` dibujan hoy
la rueda y la grid enteramente por código (`draw_colored_polygon`,
`StyleBoxFlat`) — ningún script consume todavía estos PNGs. Quedan
listos en la librería para cuando alguien (pilar/agente de código)
decida reemplazar ese dibujo procedural por texturas.

## Dice (3) — FASE 10 completa (2026-08-28)

| ID | Tamaño | Status |
|---|---|---|
| dice_slider_handle | 24×24 | APPROVED |
| dice_slider_track_win | 32×10 | APPROVED |
| dice_slider_track_lose | 32×10 | APPROVED |

Método: código (Pillow), replica exactamente los colores/proporciones
que `DiceThresholdSlider._draw()` ya usa (`TEXT_LIGHT` handle,
`PANEL_NAVY_LIGHT` outline, `ACCENT_GREEN`/`ACCENT_RED` tracks) — mismo
caso que Ruleta: el slider se dibuja hoy por código, estos PNGs quedan
listos para una integración futura. 0 generaciones PixelLab.

## Crash (2)

| ID | Tamaño | Status |
|---|---|---|
| crash_rocket | 32×32 (animado: idle/launch/flame) | PLANNED |
| crash_line_texture | opcional — evaluar si hace falta (ver `crash_graph.gd`) | PLANNED |

## Mines (4) — Master: MINES_CELL_MASTER

| ID | Tamaño | Status |
|---|---|---|
| mines_cell_hidden | 32×32 | PLANNED |
| mines_cell_safe | 32×32 | PLANNED |
| mines_cell_mine | 32×32 | PLANNED |
| mines_cell_mine_dim | 32×32 | PLANNED |

## Plinko (3)

| ID | Tamaño | Status |
|---|---|---|
| plinko_peg | 16×16 | PLANNED |
| plinko_ball | 16×16 | PLANNED |
| plinko_slot_bg | 32×32 | PLANNED |

## Lobby — `lobby/` (7) — Master: LOBBY_CARD_MASTER

| ID | Tamaño | Status |
|---|---|---|
| card_blackjack | 192×256 | PLANNED |
| card_roulette | 192×256 | PLANNED |
| card_poker | 192×256 | PLANNED |
| card_dice | 192×256 | PLANNED |
| card_crash | 192×256 | PLANNED |
| card_mines | 192×256 | PLANNED |
| card_plinko | 192×256 | PLANNED |

## HUD — `hud/` (7) — Iconos: Master ICON_MASTER; fondos: BACKGROUND_MASTER

| ID | Tamaño | Status |
|---|---|---|
| icon_pot | 28×28 | APPROVED |
| icon_crown_a | 28×28 | APPROVED |
| icon_crown_b | 28×28 | APPROVED |
| icon_win | 28×28 | APPROVED |
| icon_lose | 28×28 | APPROVED |
| victory_bg | 225×270→900×1080 | PLANNED |
| defeat_bg | 225×270→900×1080 | PLANNED |

Iconos método: `ICON_MASTER` limpiado + pictograma a mano por código
(Pillow, formas geométricas sin anti-aliasing) — pila de monedas
(pot), corona simple (crown_a), corona con gema roja (crown_b), check
verde (`ACCENT_GREEN`, win), X roja (`ACCENT_RED`, lose). 0
generaciones PixelLab.

## Home / Loading (2)

| ID | Tamaño | Status |
|---|---|---|
| lobby_bg (`inicio/`) | 225×270→900×1080 | PLANNED |
| loading_bg (`carga/`) | 225×270→900×1080 | PLANNED |

## Menús (4)

| ID | Tamaño | Status |
|---|---|---|
| settings_bg | 225×270→900×1080 | PLANNED |
| pause_bg | 225×270→900×1080 | PLANNED |
| credits_bg | 225×270→900×1080 | PLANNED |
| help_bg | 225×270→900×1080 | PLANNED |

---

Total assets finales: 112 (coincide con `assets/pixels/ASSETS.md`).
Total masters: 9. Total filas de trabajo: 121.

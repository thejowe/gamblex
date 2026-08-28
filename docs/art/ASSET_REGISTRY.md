# Asset Registry — Casino Pixel

Estado real de cada asset. `CasinoArtDirector` es el único que edita
este archivo. Estados: `PLANNED` `DRAFT` `REVIEW` `APPROVED` `FINAL`.

Estado tras FASE 2 (2026-08-28): **7/9 masters de FASE 2 en `REVIEW`**
(generados con PixelLab MCP, validados visualmente contra
`ART_DIRECTION.md`, pendientes de tu aprobación explícita antes de
`APPROVED`). `MINES_CELL_MASTER` y `ROULETTE_CELL_MASTER` no son de
FASE 2 (les toca en FASE 12/8) — siguen en `PLANNED`.
`BACKGROUND_MASTER` sigue `PLANNED` (pendiente de que confirmes si
aplica). 105/112 assets finales siguen en `PLANNED` — nada de FASE 4+
se ha generado todavía.

## Masters (9)

| ID | Categoría | Tamaño | Status | Deriva |
|---|---|---|---|---|
| CARD_MASTER | Cartas | 64×96 | APPROVED | 52 cartas |
| CARD_BACK_MASTER | Cartas | 64×96 | APPROVED | card_back |
| CHIP_MASTER | Fichas | 32×32 | APPROVED | 6 fichas |
| BUTTON_MASTER | UI | 96×32 | APPROVED | 12 botones |
| PANEL_MASTER | UI (fieltro) | 256×144 | APPROVED | bet_sidebar_bg, panel_border |
| MINES_CELL_MASTER | Mines | 32×32 | PLANNED | 4 casillas |
| ROULETTE_CELL_MASTER | Ruleta | 32×32 | PLANNED | 3 celdas |
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
| card_back | 64×96 | PLANNED | — |
| card_hearts_A … card_hearts_K (13) | 64×96 | PLANNED | — |
| card_diamonds_A … card_diamonds_K (13) | 64×96 | PLANNED | — |
| card_clubs_A … card_clubs_K (13) | 64×96 | PLANNED | — |
| card_spades_A … card_spades_K (13) | 64×96 | PLANNED | — |

## Fichas — `common/chips/` (6) — Master: CHIP_MASTER

| ID | Tamaño | Status | Color (`CasinoTheme.CHIP_COLORS`) |
|---|---|---|---|
| chip_1 | 32×32 | PLANNED | `#E8E8E8` |
| chip_5 | 32×32 | PLANNED | `#C0392B` |
| chip_10 | 32×32 | PLANNED | `#2E6DA4` |
| chip_25 | 32×32 | PLANNED | `#2F8F5B` |
| chip_50 | 32×32 | PLANNED | `#E07B1F` |
| chip_100 | 32×32 | PLANNED | `#1A1A1A` |

## Botones — `common/buttons/` (12) — Master: BUTTON_MASTER

| ID | Tamaño | Status |
|---|---|---|
| button_neutral_normal / hover / pressed / disabled | 96×32 | PLANNED ×4 |
| button_positive_normal / hover / pressed / disabled | 96×32 | PLANNED ×4 |
| button_negative_normal / hover / pressed / disabled | 96×32 | PLANNED ×4 |

## Paneles — `common/panels/` (2) — Master: PANEL_MASTER

| ID | Tamaño | Status |
|---|---|---|
| bet_sidebar_bg | variable (ver `BetSidebarPanel`) | PLANNED |
| panel_border | variable (opcional) | PLANNED |

## Blackjack (1)

| ID | Tamaño | Status |
|---|---|---|
| felt_table_bg | variable | PLANNED |

## Póker (0 — carpeta vacía a propósito, reutiliza cards/chips/panel)

## Ruleta (5) — Master celdas: ROULETTE_CELL_MASTER

| ID | Tamaño | Status |
|---|---|---|
| roulette_wheel | pendiente de confirmar | PLANNED |
| roulette_ball | pequeño (fracción de celda) | PLANNED |
| roulette_grid_cell_red | 32×32 | PLANNED |
| roulette_grid_cell_black | 32×32 | PLANNED |
| roulette_grid_cell_green | 32×32 | PLANNED |

## Dice (3)

| ID | Tamaño | Status |
|---|---|---|
| dice_slider_handle | 32×32 | PLANNED |
| dice_slider_track_win | variable (ancho de slider) | PLANNED |
| dice_slider_track_lose | variable (ancho de slider) | PLANNED |

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

## HUD — `hud/` (7) — Iconos: Master ICON_MASTER; fondos: BACKGROUND_MASTER?

| ID | Tamaño | Status |
|---|---|---|
| icon_pot | 32×32 | PLANNED |
| icon_crown_a | 32×32 | PLANNED |
| icon_crown_b | 32×32 | PLANNED |
| icon_win | 32×32 | PLANNED |
| icon_lose | 32×32 | PLANNED |
| victory_bg | 225×270→900×1080 | PLANNED |
| defeat_bg | 225×270→900×1080 | PLANNED |

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

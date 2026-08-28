# Asset Registry — Casino Pixel

Estado real de cada asset. `CasinoArtDirector` es el único que edita
este archivo. Estados: `PLANNED` `DRAFT` `REVIEW` `APPROVED` `FINAL`.

Al arrancar esta sesión: **112/112 assets en `PLANNED`, 0 masters
creados.** Ningún PNG existe todavía en `assets/pixels/` (solo
`.gitkeep`). Ver resumen de auditoría en el cierre de esta sesión.

## Masters (9 — a crear en FASE 2, carpeta `_masters/` aún no existe)

| ID | Categoría | Tamaño | Status | Deriva |
|---|---|---|---|---|
| CARD_MASTER | Cartas | 64×96 | PLANNED | 52 cartas |
| CARD_BACK_MASTER | Cartas | 64×96 | PLANNED | card_back |
| CHIP_MASTER | Fichas | 32×32 | PLANNED | 6 fichas |
| BUTTON_MASTER | UI | 96×32 | PLANNED | 12 botones |
| PANEL_MASTER | UI (fieltro) | variable | PLANNED | bet_sidebar_bg, panel_border, felt_table_bg |
| MINES_CELL_MASTER | Mines | 32×32 | PLANNED | 4 casillas |
| ROULETTE_CELL_MASTER | Ruleta | 32×32 | PLANNED | 3 celdas |
| LOBBY_CARD_MASTER | Lobby | 192×256 | PLANNED | 7 tarjetas |
| ICON_MASTER | HUD | 32×32 | PLANNED | 5 iconos |
| BACKGROUND_MASTER | Fondos | 225×270 | PLANNED (pendiente confirmar con usuario) | 8 fondos |

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

# Art Asset Plan — Casino Pixel

Inventario completo + orden de producción obligatorio. Absorbe y
sustituye la lista de `assets/pixels/ASSETS.md` (esa la mantiene el
usuario a mano; esta la mantiene `CasinoArtDirector` con estado
PLANNED/DRAFT/REVIEW/APPROVED/FINAL por asset). No la reescribas sin
comprobar antes `assets/pixels/*/*.gitkeep` — si una carpeta ya tiene
imagen, ese asset no está en `PLANNED`.

Estado detallado y campos completos por asset: `ASSET_REGISTRY.md`. Este
documento es el **orden de fases**, no la tabla de estado.

## Regla master-first

Nunca generar variantes independientes. Antes de cualquier fase con
variantes, el MASTER correspondiente debe estar `APPROVED`:

```text
CARD_MASTER         → 52 cartas + card_back
CHIP_MASTER          → chip_1 … chip_100 (6)
BUTTON_MASTER         → 12 estados (3 variantes × 4 estados)
PANEL_MASTER (fieltro) → felt_table_bg, bet_sidebar_bg, panel_border
MINES_CELL_MASTER    → hidden, safe, mine, mine_dim (4)
ROULETTE_CELL_MASTER  → red, black, green (3)
LOBBY_CARD_MASTER    → 7 tarjetas de juego
ICON_MASTER          → icon_pot, icon_win, icon_lose, icon_crown_a/b (5)
BACKGROUND_MASTER    → 8 fondos de pantalla completa (ver nota abajo)
```

`BACKGROUND_MASTER` es una decisión pendiente de confirmar con el
usuario (ver `ART_DIRECTION.md` § Decisiones que requieren confirmación).
Hasta confirmarse, los 8 fondos quedan en `PLANNED` sin maestro asignado.

## Fases (orden obligatorio — no saltar)

### FASE 1 — Style Bible
`ART_DIRECTION.md`, `ART_PIPELINE.md`, `ART_NAMING_CONVENTIONS.md`,
`ART_VALIDATION.md`, `ASSET_REGISTRY.md`. **Completada** en esta sesión.

### FASE 2 — Master assets
En este orden: `CARD_MASTER` → `card_back` maestro → `CHIP_MASTER` →
`BUTTON_MASTER` → `PANEL_MASTER` (fieltro, para Blackjack/Póker) →
`ICON_MASTER` → fragmento de mesa Blackjack (`felt_table_bg`).

### FASE 3 — Validación visual
`CasinoArtDirector` compara los masters de FASE 2 entre sí (misma luz,
paleta, pixel density). No continuar si no son coherentes entre ellos.

### FASE 4 — Cards
52 cartas + `card_back` derivadas de `CARD_MASTER` + los 4 palos + 13
rangos (carpetas ya existen en `assets/pixels/common/cards/`).

### FASE 5 — Chips
`chip_1`, `chip_5`, `chip_10`, `chip_25`, `chip_50`, `chip_100` derivadas
de `CHIP_MASTER`, color por `CasinoTheme.CHIP_COLORS`.

### FASE 6 — UI system
12 botones (`common/buttons/`), `bet_sidebar_bg` + `panel_border`
(`common/panels/`), 5 iconos HUD (`hud/icon_*`).

### FASE 7 — Blackjack
`felt_table_bg`. Reutiliza cards/chips/panel/botones — sin arte propio
adicional.

### FASE 8 — Ruleta
`ROULETTE_CELL_MASTER` → `roulette_grid_cell_red/black/green`,
`roulette_wheel`, `roulette_ball`.

### FASE 9 — Póker
Carpeta `poker/` vacía a propósito (100% reutiliza cards/chips/panel de
fieltro/botones, Plan 31 ya hizo el reskin de layout en código). Solo
producir arte propio si `felt_table_bg` no encaja en la mesa ovalada
completa de Póker — evaluar tras FASE 7.

### FASE 10 — Dice
`dice_slider_handle`, `dice_slider_track_win`, `dice_slider_track_lose`.

### FASE 11 — Crash
`crash_rocket` (idle/launch/flame — animado), `crash_line_texture`
(opcional, solo si el motor no puede dibujar la línea proceduralmente
mejor — comprobar `scripts/ui/casino/crash_graph.gd` antes de generar).

### FASE 12 — Mines
`MINES_CELL_MASTER` → `mines_cell_hidden/safe/mine/mine_dim`.

### FASE 13 — Plinko
`plinko_peg`, `plinko_ball`, `plinko_slot_bg`.

### FASE 14 — Lobby
`LOBBY_CARD_MASTER` → `card_blackjack/roulette/poker/dice/crash/mines/plinko`
(7, mismo marco/tamaño/luz, cambia solo la ilustración central).

### FASE 15 — Home / Loading
`lobby_bg` (`inicio/`), `loading_bg` (`carga/`).

### FASE 16 — Victoria / Derrota
`victory_bg`, `defeat_bg` (`hud/`).

### FASE 17 — Menús
`settings_bg`, `pause_bg`, `credits_bg`, `help_bg`.

## Mapeo íntegro a `assets/pixels/` (112 carpetas)

| Carpeta | Fase | Master |
|---|---|---|
| `common/cards/card_back` | 4 | CARD_BACK_MASTER |
| `common/cards/card_{hearts,diamonds,clubs,spades}_{A,2..10,J,Q,K}` (52) | 4 | CARD_MASTER |
| `common/chips/chip_{1,5,10,25,50,100}` (6) | 5 | CHIP_MASTER |
| `common/buttons/button_{neutral,positive,negative}_{normal,hover,pressed,disabled}` (12) | 6 | BUTTON_MASTER |
| `common/panels/bet_sidebar_bg`, `panel_border` (2) | 6 | PANEL_MASTER |
| `hud/icon_{pot,crown_a,crown_b,win,lose}` (5) | 6 | ICON_MASTER |
| `blackjack/felt_table_bg` (1) | 7 | — (compone masters) |
| `roulette/roulette_grid_cell_{red,black,green}` (3) | 8 | ROULETTE_CELL_MASTER |
| `roulette/roulette_wheel`, `roulette_ball` (2) | 8 | — (assets únicos) |
| `poker/` (0, vacía a propósito) | 9 | — |
| `dice/dice_slider_handle`, `dice_slider_track_{win,lose}` (3) | 10 | — |
| `crash/crash_rocket`, `crash_line_texture` (2) | 11 | — |
| `mines/mines_cell_{hidden,safe,mine,mine_dim}` (4) | 12 | MINES_CELL_MASTER |
| `plinko/plinko_peg`, `plinko_ball`, `plinko_slot_bg` (3) | 13 | — |
| `lobby/card_{blackjack,roulette,poker,dice,crash,mines,plinko}` (7) | 14 | LOBBY_CARD_MASTER |
| `inicio/lobby_bg` (1) | 15 | BACKGROUND_MASTER? |
| `carga/loading_bg` (1) | 15 | BACKGROUND_MASTER? |
| `hud/victory_bg`, `defeat_bg` (2) | 16 | BACKGROUND_MASTER? |
| `settings/settings_bg`, `pause/pause_bg`, `credits/credits_bg`, `help/help_bg` (4) | 17 | BACKGROUND_MASTER? |

Total: 112 carpetas (coincide con `ASSETS.md`) + 9 masters no incluidos
en esa carpeta (viven como fuente en `assets/pixels/_masters/`, ver
`ART_PIPELINE.md`).

## No producir todavía

Tras esta sesión (auditoría + STEP 1-8), **no se generan assets** hasta
que el usuario dé luz verde explícita a empezar FASE 2. Ver resumen al
final de la sesión.

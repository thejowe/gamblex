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
| MINES_CELL_MASTER | Mines | — | N/A (geometría por código, sin PNG standalone) | 4 casillas |
| ROULETTE_CELL_MASTER | Ruleta | — | N/A (geometría por código, sin PNG standalone) | 3 celdas |
| LOBBY_CARD_MASTER | Lobby | 96×128 | APPROVED | 7 tarjetas |
| ICON_MASTER | HUD | 32×32 | APPROVED | 5 iconos |
| BACKGROUND_MASTER | Fondos | 220×264 | APPROVED — usado tal cual en 5/8 fondos (loading/settings/pause/credits/help); lobby/victory/defeat se ganaron generación propia | 8 fondos |

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
| BUTTON_MASTER | PixelLab pixflux | text2img, transparente (funcionó a la primera — relleno oscuro) | 96×32 | `#140b35` (indigo/violeta, no `#1C2733` navy — ver discrepancia corregida en sección "Botones") + `#E8C468` | REVIEW | Solo estado "normal" — hover/pressed/disabled se derivan en FASE 6 |
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
| card_back | 52×86 | FINAL | CARD_BACK_MASTER, fondo neutro eliminado por flood-fill |
| card_hearts_A … card_hearts_K (13) | 52×86 | FINAL | CARD_MASTER + pip/rango por código (Pillow) |
| card_diamonds_A … card_diamonds_K (13) | 52×86 | FINAL | ídem |
| card_clubs_A … card_clubs_K (13) | 52×86 | FINAL | ídem |
| card_spades_A … card_spades_K (13) | 52×86 | FINAL | ídem |

Validación `artgroup-cards` (2026-08-28): checklist completo de
`ART_VALIDATION.md` corrido contra los 53 archivos reales en
`assets/pixels/common/cards/` (script Pillow ad hoc, no contra memoria
del registro). Técnica: 53/53 tamaño real 52×86 confirmado, modo RGBA,
sin halo de anti-aliasing (partial-alpha <2% en todos), PNG lossless,
`.import` presente en los 53 con `compress/mode=0` y
`mipmaps/generate=false`. Visual: paleta en familia de `CasinoTheme`
(`CARD_WHITE`/`CARD_RED #C0392B`/`CARD_BLACK #1A1A1A` exactos en los
pips de rango/palo; `card_back` en familia `FELT_GREEN_DARK`/
`GOLD_ACCENT` con textura de variación de valor, sin colores fuera de
familia). Gameplay: legibilidad confirmada por contact sheet de los 53
a 2× y comparación 1:1 nativa — `PlayingCard.CARD_SIZE = Vector2(52,86)`
en `scripts/ui/casino/playing_card.gd` dibuja sin reescalado
(`draw_texture_rect` a tamaño nativo) con `texture_filter =
TEXTURE_FILTER_NEAREST` ya fijado en el nodo (código de otro agente,
no tocado aquí) — el checklist de "filtro nearest en el nodo que lo
consume" ya está satisfecho de origen. 0/53 huérfanos o archivos
inesperados en la carpeta. 0 generaciones PixelLab (ninguna hizo
falta) — única corrección aplicada fue de `.import` (ver abajo).

Único fallo encontrado en `.import`: los 53 traían
`process/fix_alpha_border=true` (default del editor de Godot al
importar), contra el `false` que exige `ART_PIPELINE.md` para pixel art
("no difuminar bordes") — corregido en los 53 (mismo criterio aplicado
por `artgroup-roulette` en su sección). Es un default compartido por
los ~121 `.import` de todo `assets/pixels/`; no se toca nada fuera de
`common/cards/`, así que el resto de categorías queda a criterio de
cada `artgroup-*`/`CasinoArtDirector`. No generaba halo visible
(mipmaps desactivados y `texture_filter` nearest ya fijado en el nodo),
pero se alinea con el documento igualmente. Con eso, técnica/visual/
gameplay/import pasan completos → `FINAL`.

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
| chip_1 | 22×22 | FINAL | `#E8E8E8` |
| chip_5 | 22×22 | FINAL | `#C0392B` |
| chip_10 | 22×22 | FINAL | `#2E6DA4` |
| chip_25 | 22×22 | FINAL | `#2F8F5B` |
| chip_50 | 22×22 | FINAL | `#E07B1F` |
| chip_100 | 22×22 | FINAL | `#1A1A1A` |

Método: `CHIP_MASTER` limpiado, cuerpo recoloreado por denominación
preservando luminancia (aro dorado y notches oscuros del borde
detectados por hue/brillo y no recoloreados), número compuesto con
fuente bitmap de PIL binarizada. 0 generaciones PixelLab.

Validación FINAL (`artgroup-chips`, 2026-08-28) — checklist completo de
`ART_VALIDATION.md` corrido contra los 6 archivos reales, todo pasa:
técnica (22×22 confirmado en los 6, alfa binaria 0/255 sin halo de AA,
15-16 colores opacos por ficha — consistente con la paleta discreta de
`CHIP_MASTER`, sin artefactos de resize con blending), color (recolor
por denominación fiel a `CasinoTheme.CHIP_COLORS` real leído del código
— la banda de color más frecuente en cada ficha es ~0.86-0.88× el hex
plano por diseño de preservación de luminancia/sombreado del master, no
un valor plano; el aro/notches quedan sin recolorear tal como documenta
el método), `.import` idéntico en los 6 (`compress/mode=0`,
`mipmaps/generate=false`), implementación (`CasinoChip`
en `scripts/ui/casino/casino_chip.gd` ya carga
`res://assets/pixels/common/chips/chip_%d/chip_%d.png` por denominación
y fija `texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST` en código —
consumido en `poker_table_net.gd` y `blackjack_table_net.gd`),
legibilidad verificada compuesta sobre `felt_table_bg` real y sobre
navy a 48×48 (tamaño real de `CasinoChip`, `RADIUS=24`) — número
distinguible en las 6 denominaciones (dígito oscuro sobre fichas claras,
dígito claro con contorno oscuro sobre fichas de color, `chip_100`
blanco sobre casi-negro).

**Discrepancia encontrada, no bloqueante — reportar a `CasinoArtDirector`:**
`ART_DIRECTION.md` (sección "Resolución y pixel density") fija el grid
de fichas en **32×32**, y solo documenta una excepción explícita de
tamaño para `roulette_wheel`. Las 6 fichas reales son **22×22**
(consistente entre sí y con `ASSET_REGISTRY.md`/`artgroup-chips.md`, y
coherente con el uso real en `CasinoChip`), pero esa desviación de
32×32 nunca quedó documentada como excepción en `ART_DIRECTION.md` como
exige su propia regla ("si un asset concreto necesita un tamaño
distinto... se documenta como excepción ahí mismo, nunca en
silencio"). No se regenera para forzar 32×32 (las fichas ya estaban
`APPROVED` por el gatekeeper con 22×22, y ni 22×22 ni 32×32 caen en
escala entera contra el `custom_minimum_size` real de `CasinoChip`,
48×48 con `RADIUS=24` fijado en `scripts/ui/casino/casino_chip.gd`,
fuera de mi dominio) — se deja documentado aquí para que
`CasinoArtDirector` añada la excepción a `ART_DIRECTION.md` o decida
recortar el master.

**RESUELTO (`CasinoArtDirector`, 2026-08-28):** excepción añadida a
`ART_DIRECTION.md` (sección "Resolución y pixel density") — 22×22 real
queda documentado ahí, sin regenerar ningún PNG.

## Botones — `common/buttons/` (12) — Master: BUTTON_MASTER

| ID | Tamaño | Status |
|---|---|---|
| button_neutral_normal / hover / pressed / disabled | 93×30 | FINAL ×4 |
| button_positive_normal / hover / pressed / disabled | 93×30 | FINAL ×4 |
| button_negative_normal / hover / pressed / disabled | 93×30 | FINAL ×4 |

Método: `BUTTON_MASTER` limpiado, cuerpo recoloreado por variante
(navy/verde/rojo, borde dorado preservado por hue), 4 estados por
brillo/desaturación (hover +18% brillo, pressed −22%, disabled
desaturado 65% + alfa 75%). 0 generaciones PixelLab.

Validación `artgroup-buttons-panels` (2026-08-28) — checklist completo
de `ART_VALIDATION.md` corrido contra los 12 archivos reales. Técnica:
12/12 tamaño real 93×30 confirmado, RGBA, alfa binaria 0/255 sin halo
de anti-aliasing (disabled ×3 en alfa plana 191 = 75% exacto), PNG
lossless, `.import` presente en los 12 con `compress/mode=0` y
`mipmaps/generate=false`. Visual: los 4 estados de cada variante son
distinguibles entre sí por brillo/color de forma inequívoca a escala
real (verificado por histograma de color: hover más claro que normal,
pressed más oscuro, disabled desaturado+alfa reducida en los 3
variantes); borde dorado (`#fbd173`→`#fff6d8` hover→`#c3a359` pressed)
se mantiene reconocible como oro en los 4 estados de las 3 variantes.
Gameplay: implementación confirmada en `scripts/ui/casino/casino_button.gd`
(`CasinoButton._texture_style()` carga
`res://assets/pixels/common/buttons/button_%s_%s/...png` real por
variante+estado vía `StyleBoxTexture`, no dibujo procedural) — los 12
PNG sí están enganchados en producción, a diferencia de otras
categorías (Ruleta/Dice/Mines) que quedan en librería sin consumir.

**Corrección aplicada — `.import`:** los 12 traían
`process/fix_alpha_border=true` (default del editor de Godot), contra
el `false` que exige `ART_PIPELINE.md` para pixel art ("no difuminar
bordes") — corregido en los 12.

**Discrepancia encontrada, no bloqueante — reportar a
`CasinoArtDirector`:** `ASSET_REGISTRY.md` describe la paleta de
`BUTTON_MASTER` como `#1C2733` (navy real de `CasinoTheme`), pero el
relleno real del master y de `button_neutral_*` es `#140b35`
(indigo/violeta, hue ~253° frente a los ~211° de `PANEL_NAVY_MID`) —
no es el navy documentado. `BUTTON_MASTER` está en `_masters/`, fuera
del scope de este agente (`common/buttons/`/`common/panels/`), y ya
fue aprobado explícitamente "tal cual" por el usuario en FASE 2 junto
al resto de masters — no se ha regenerado ni tocado aquí. Visualmente
sigue leyéndose como un botón oscuro neutro coherente con el resto de
la UI (contraste suficiente, no rompe legibilidad), pero el hex no
coincide con el token citado en el registro. Queda documentado para
que `CasinoArtDirector` decida si amerita reabrir `BUTTON_MASTER`.

**RESUELTO (`CasinoArtDirector`, 2026-08-28):** no se reabre
`BUTTON_MASTER` — fue `APPROVED` "tal cual" por decisión explícita del
usuario en FASE 2, y visualmente cumple. Se corrigió la tabla "Detalle
de generación — FASE 2" arriba para citar el hex real `#140b35` en vez
del `#1C2733` incorrecto — era un error de transcripción del registro,
no un defecto del asset.

Con eso, técnica/visual/gameplay/import pasan completos (salvo la
discrepancia de palabra-vs-hex arriba, no bloqueante) → `FINAL`.

## Paneles — `common/panels/` (2) — Sin master de imagen (geometría por código)

| ID | Tamaño | Status |
|---|---|---|
| bet_sidebar_bg | 96×144 | FINAL |
| panel_border | 96×144 | FINAL |

Método: rect redondeado por código con gradiente vertical
`PANEL_NAVY_LIGHT`→`PANEL_NAVY_DARK` + borde `PANEL_NAVY_LIGHT` 2-3px,
tokens reales de `CasinoTheme` (no `PANEL_MASTER`, ver corrección de
plan arriba). 0 generaciones PixelLab.

**Corrección aplicada — `bet_sidebar_bg.png` regenerado por código
(Pillow, sin PixelLab — es geometría plana, no requiere el MCP):** el
archivo `APPROVED` real tenía un defecto verificado a nivel de píxel,
no visible en la descripción del registro: las filas 0-1 (96 px de
ancho completo) eran blanco sólido opaco `#ffffff` en vez de
transparente/esquina redondeada, y las filas 141-142 (cerca del borde
inferior) revertían a `PANEL_NAVY_LIGHT` en vez de continuar el
degradado hacia `PANEL_NAVY_DARK` — ambos son artefactos de la
generación original, no una decisión de estilo. Regenerado desde cero
con `PIL.ImageDraw.rounded_rectangle` (radio 8px, mismo grid 96×144,
sin anti-aliasing) + degradado vertical línea-a-línea
`PANEL_NAVY_LIGHT` (`#28374a`, fila 0) → `PANEL_NAVY_DARK` (`#131b26`,
fila 143), verificado post-fix: 0 píxeles blancos, alfa binaria 0/255,
degradado monótono confirmado columna a columna. `panel_border.png` se
inspeccionó con el mismo método y no tenía el defecto (alfa limpia,
único color de relleno `#28374a` sólido, sin blancos) — no se tocó.

Validación `artgroup-buttons-panels` (2026-08-28): técnica (96×144
confirmado en los 2, alfa binaria sin halo tras el fix, `.import` con
`compress/mode=0`/`mipmaps/generate=false`, corregido
`process/fix_alpha_border` de `true` a `false` en los 2 igual que en
botones). Visual: paleta fiel a los hex reales leídos de
`scripts/ui/casino/casino_theme.gd` (`PANEL_NAVY_DARK #131b26`,
`PANEL_NAVY_MID #1c2733`, `PANEL_NAVY_LIGHT #28374a`), no a una versión
de memoria. Gameplay/implementación: **ninguno de los dos PNG está
enganchado todavía** — `scripts/ui/casino/bet_sidebar_panel.gd` sigue
dibujando el panel real con `StyleBoxFlat` + `PANEL_NAVY_MID` plano por
código (mismo patrón de "listo en la librería, no consumido" que
Ruleta/Dice/Mines) — no es tarea de este agente engancharlo, solo
dejarlo correcto para cuando `pilar.md` decida sustituir el dibujo
procedural.

Con eso, técnica/visual/import pasan completos (gameplay/implementación
queda como "no enganchado", igual que otras categorías ya `FINAL` con
el mismo patrón, ej. Ruleta/Dice/Mines) → `FINAL`.

## Blackjack (1)

| ID | Tamaño | Status |
|---|---|---|
| felt_table_bg | 320×180 | FINAL |

Fragmento de FASE 2 (`felt_table_bg_fragment`, PixelLab pixflux)
adoptado tal cual como asset final — aprobado explícitamente por el
usuario con los iconos de palo decorativos incluidos.

Validado por `artgroup-blackjack-poker` (2026-08-28) contra
`ART_VALIDATION.md`: archivo real 320×180 RGBA, alfa constante 255 (sin
halo de anti-aliasing, opaco), 29 colores únicos (clusters de píxel
limpios, sin gradiente), `.import` con `compress/mode=0` y
`mipmaps/generate=false`. Paleta: verdes de fieltro y dorados de ribete
próximos a `FELT_GREEN_DARK`/`GOLD_ACCENT`; el riel de madera usa tonos
caoba más rojizos que `WOOD_BROWN_DARK`/`WOOD_BROWN_LIGHT` — coherente
con la descripción de material "Caoba/marrón oscuro" de
`ART_DIRECTION.md` (variante de sombreado dentro de la familia madera,
no un color ajeno a la paleta). Ubicación y nombre correctos
(`assets/pixels/blackjack/felt_table_bg/felt_table_bg.png`). No hay
ningún nodo en escena que consuma esta textura todavía —
`felt_table_panel.gd` sigue dibujando el óvalo procedural
(`test_felt_table_panel.gd` no referencia el PNG, no se rompe nada); el
filtro nearest y la integración quedan pendientes de la decisión de
diseño documentada en `ART_INTEGRATION_PLAN.md` ("Pendiente real"),
trabajo de `pilar.md`, no bloquea el estado `FINAL` del asset en sí.

## Póker (0 — carpeta vacía a propósito, reutiliza cards/chips/panel)

Confirmado (2026-08-28, `artgroup-blackjack-poker`): la carpeta
`assets/pixels/poker/` solo contiene `.gitkeep`, sin PNG — sigue vacía a
propósito, sin generación pendiente. No se ha tocado.

## Ruleta (5) — FASE 8 completa, FINAL (2026-08-28, validado por `artgroup-roulette`)

| ID | Tamaño | Status | Source |
|---|---|---|---|
| roulette_wheel | 124×124 | FINAL | PixelLab pixflux, transparente a la primera |
| roulette_ball | 9×10 | FINAL | PixelLab pixen, opaco sobre fondo oscuro (mismo gotcha que fichas/cartas) + 2 pasadas de flood-fill (gris exterior + anillo navy) |
| roulette_grid_cell_red | 40×40 | FINAL | código (Pillow) |
| roulette_grid_cell_black | 40×40 | FINAL | código (Pillow) |
| roulette_grid_cell_green | 40×40 | FINAL | código (Pillow) |

`ROULETTE_CELL_MASTER`: no existe como PNG standalone — las 3 celdas
comparten una función `make_cell()` por código (mismo patrón que
`bet_sidebar_bg`/`panel_border`), no hace falta un master de imagen
para geometría plana. 2 generaciones PixelLab usadas en FASE 8 (12/40
del trial en total).

**Validación `artgroup-roulette` (2026-08-28):** checklist completo de
`ART_VALIDATION.md` contra los 5 archivos reales. Tamaños exactos
(124×124 / 9×10 / 40×40×3, confirmados con Pillow). Alfa binaria (0/255,
sin halo de anti-aliasing) en los 5. Paleta de las 3 celdas verificada
píxel a píxel = tokens exactos de `CasinoTheme` (`CARD_RED` #C0392B,
`CARD_BLACK` #1A1A1A, `ACCENT_GREEN` #4CAF6E), coherente 1:1 con
`_color_for_number()` en `roulette_wheel_display.gd`. `roulette_wheel`
coherente en iluminación/material (madera + oro + navy) con el resto de
la familia panel oscuro. Único fallo encontrado: los 5 `.import`
traían `process/fix_alpha_border=true` (default de Godot), contra el
`false` que exige `ART_PIPELINE.md` para pixel art — corregido en los 5
(no afecta a otros assets del repo, que comparten el mismo default y
quedan fuera de este scope). Con eso, técnica/visual/gameplay/import
pasan completos → `FINAL`.

**Nota de integración (no es tarea de `CasinoArtDirector`):**
`RouletteWheelDisplay._draw()` y `roulette_betting_grid.gd` dibujan hoy
la rueda y la grid enteramente por código (`draw_colored_polygon`,
`StyleBoxFlat`) — ningún script consume todavía estos PNGs. Quedan
listos en la librería para cuando alguien (pilar/agente de código)
decida reemplazar ese dibujo procedural por texturas.

## Dice (3) — FASE 10 completa (2026-08-28, FINAL tras `artgroup-dice`)

| ID | Tamaño | Status |
|---|---|---|
| dice_slider_handle | 24×24 | FINAL |
| dice_slider_track_win | 32×10 | FINAL |
| dice_slider_track_lose | 32×10 | FINAL |

Método: código (Pillow), replica exactamente los colores/proporciones
que `DiceThresholdSlider._draw()` ya usa (`TEXT_LIGHT` handle,
`PANEL_NAVY_LIGHT` outline, `ACCENT_GREEN`/`ACCENT_RED` tracks) — mismo
caso que Ruleta: el slider se dibuja hoy por código, estos PNGs quedan
listos para una integración futura. 0 generaciones PixelLab.

**Correcciones `artgroup-dice` (2026-08-28), checklist `ART_VALIDATION.md`
contra los 3 archivos reales:**

- `dice_slider_handle.png` tenía un brillo blanco (glare) y un punto
  central navy (aspecto "canica/ojo") que `_draw()` no dibuja
  (`draw_circle` + `draw_arc` es un relleno plano + anillo, sin más
  detalle). Corregido por código: círculo plano `TEXT_LIGHT`
  (`#e8edf2`) con anillo `PANEL_NAVY_LIGHT` (`#28374a`) de 2px, sin
  highlight ni decoración interna — ahora 2 colores + alfa binario (sin
  halo de anti-aliasing), coherente con "no inventar un estilo
  distinto".
- `dice_slider_track_win.png`/`dice_slider_track_lose.png` tenían un
  bisel de 3 tonos (fila superior más clara, fila inferior más oscura)
  que `draw_rect` tampoco dibuja (relleno plano). Corregido a relleno
  100% plano con el token exacto (`ACCENT_GREEN` `#4caf6e` /
  `ACCENT_RED` `#d9534f`) — coincide además con la regla de
  `ART_DIRECTION.md` para la familia "Panel oscuro": "superficies lisas
  con bordes duros", sin textura.
- Los 3 `.import` tenían `process/fix_alpha_border=true`; `ART_PIPELINE.md`
  exige `false` para pixel art (no difuminar bordes). Corregido en los 3.
- Tamaños verificados exactos: 24×24, 32×10, 32×10. `compress/mode=0`,
  `mipmaps/generate=false` ya correctos, sin tocar.
- 0 generaciones PixelLab — correcciones puramente mecánicas de
  color/proporción sobre assets ya generados por código, sin pixel art
  nuevo que regenerar.

## Crash (1 de 2 — FASE 11 completa, `artgroup-crash` FINAL 2026-08-28)

| ID | Tamaño | Status |
|---|---|---|
| crash_rocket_idle | 20×32 | FINAL |
| crash_rocket_launch | 12×24 | FINAL |
| crash_rocket_flame | 14×36 | FINAL |
| crash_line_texture | — | **N/A — decisión de no generar** |

`crash_rocket`: 3 generaciones PixelLab pixflux (15/40 del trial en
total), trimeadas a bbox. `crash_line_texture` descartado a propósito:
`CrashGraph._draw()` ya dibuja la curva con `draw_polyline`/
`draw_colored_polygon` de forma dinámica (la forma cambia cada frame
con el multiplicador real) — generar una textura estática violaría la
regla de `ART_PIPELINE.md` ("no generar una textura si el motor puede
dibujarlo mejor"). La referencia `crash-acebet-reference.png` tampoco
usa una, solo un punto en la punta de la línea — que es exactamente lo
que el código ya dibuja (`draw_circle`).

**Validación `artgroup-crash` (2026-08-28) — checklist `ART_VALIDATION.md`
completo, sin regeneración necesaria (los 3 archivos ya cumplían):**

- Tamaño exacto verificado por PNG IHDR: `crash_rocket_idle` 20×32,
  `crash_rocket_launch` 12×24, `crash_rocket_flame` 14×36 (coincide con
  la tabla y con `ASSET_REGISTRY.md`).
- PNG-32 (colortype 6, RGBA), sin compresión con pérdida. 0% píxeles con
  alfa parcial en los 3 archivos (sin halo de anti-aliasing en el
  borde). Paleta cuantizada: 9–21 colores opacos por sprite.
- `.import` de los 3: `compress/mode=0` (Lossless),
  `mipmaps/generate=false`, `detect_3d/compress_to=1` (Disabled) — los
  tres puntos que exige `ART_VALIDATION.md`/`ART_PIPELINE.md`. Filtro
  nearest confirmado en el nodo consumidor real (`CrashGraph._init()`
  fija `texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST`); no existe
  parámetro `Filter` en el `.import` de Godot 4 (el filtrado se aplica
  por `CanvasItem`, no por importador) — ya cubierto ahí.
  **Discrepancia menor no bloqueante:** `process/fix_alpha_border=true`
  en los 3 `.import` (Godot lo pone por defecto), mientras
  `ART_PIPELINE.md` recomienda `false` para pixel art. Es el mismo valor
  que tienen los otros 118/121 `.import` del repo (no es un problema
  específico de Crash, es el default de Godot en todo el proyecto — no
  bloquea `FINAL` porque no forma parte de la lista explícita de
  `ART_VALIDATION.md` y el 0% de alfa parcial medido demuestra que no
  produce halo real en estos 3 sprites). Se reporta para que
  `CasinoArtDirector` decida si vale la pena corregirlo a nivel de
  proyecto.
- Silueta legible: inspección visual a tamaño nativo confirma forma de
  cohete reconocible en los 3 frames (cuerpo + aletas + llama/chispa),
  coherente con familia panel oscuro (acentos rojo/dorado sobre cuerpo
  navy/morado oscuro). `crash_rocket_flame` confirmado en render real
  como marcador de punta en `crash_table_net.tscn` →
  `CrashGraph` (commit `dd90f48`), dibujado a tamaño nativo
  (`draw_texture_rect` con `tex.get_size()`, sin escalar) sobre el fondo
  navy del panel — contraste suficiente por los acentos rojo/dorado de
  la llama. `crash_rocket_idle`/`_launch` no tienen nodo consumidor
  todavía (no hay estado intermedio en `crash_graph.gd` que los use) —
  el archivo en sí pasa el checklist técnico/visual completo; el
  enganche en escena queda pendiente de un estado nuevo de gameplay que
  es dominio de `pilar.md`, no de este agente (ver
  `.claude/agents/CasinoArtDirector.md`, "tu entregable es el `.png`
  ... no necesariamente el enganche en la escena").
- Test GUT relevante (`tests/unit/test_crash_graph.gd`,
  `test_crash_table_scene_structure.gd`, `test_crash_table_view.gd`)
  revisados: no dependen del contenido de los PNG, solo de la lógica de
  `CrashGraph`/escena — no hay riesgo de romperlos.
- 0 generaciones PixelLab nuevas — los 3 archivos ya cumplían el
  checklist tal cual estaban, ninguna corrección hizo falta.

## Mines (4) — FASE 12 completa (2026-08-28) — validado `artgroup-mines`

| ID | Tamaño | Status |
|---|---|---|
| mines_cell_hidden | 48×48 | FINAL |
| mines_cell_safe | 48×48 | FINAL |
| mines_cell_mine | 48×48 | FINAL |
| mines_cell_mine_dim | 48×48 | FINAL |

`MINES_CELL_MASTER`: sin PNG standalone, base compartida por código
(`base_cell()`) — mismo patrón que Ruleta/Dice. Colores y geometría
calcados de `mines_cell.gd` (`PANEL_NAVY_MID`/`LIGHT`, diamante
`ACCENT_GREEN`, círculo `ACCENT_RED`), con un añadido propio de dirección
de arte: la mina es una bomba con mecha/chispa dorada en vez de un
círculo liso. 0 generaciones PixelLab.

Validación `artgroup-mines` (2026-08-28): checklist completo de
`ART_VALIDATION.md` contra los 4 archivos reales — 48×48 RGBA los 4,
`compress/mode=0`/`mipmaps/generate=false` correctos, filtro nearest ya
aplicado en `mines_cell.gd._init()`. Único fallo encontrado: los 4
`.import` traían `process/fix_alpha_border=true` (default de Godot)
contra el `false` que exige `ART_PIPELINE.md` para pixel art — mismo bug
ya corregido en `roulette/` (commit `8a6dee2`); corregido aquí igual, sin
regenerar PNG. Los 4 estados distinguibles entre sí a escala real de
grid (navy vacío / diamante verde / bomba roja con chispa dorada / bomba
roja atenuada sin chispa). 0 generaciones PixelLab. Fila
`MINES_CELL_MASTER` corregida en la tabla de masters (`PLANNED` →
`N/A (geometría por código)`).

## Plinko (3) — FASE 13 completa, FINAL (2026-08-28, validado por `artgroup-plinko`)

| ID | Tamaño | Status |
|---|---|---|
| plinko_peg | 8×8 | FINAL |
| plinko_ball | 16×16 | FINAL |
| plinko_slot_bg | 36×26 | FINAL |

Método: código, calcado de `plinko_board.gd`
(`TEXT_MUTED` peg, `TEXT_LIGHT` ball, slot con blend
`PANEL_NAVY_LIGHT`→`ACCENT_GREEN` — el código tiñe el slot según el
multiplicador en tiempo real, este PNG es la base neutra de referencia,
no sustituye ese tinte dinámico). 0 generaciones PixelLab.

**Correcciones `artgroup-plinko` (2026-08-28), checklist `ART_VALIDATION.md`
contra los 3 archivos reales:**

- `plinko_peg.png` traía un highlight de 4-5px (`#c8d0d8`) descentrado
  encima del relleno base — `_draw()` (`draw_circle(pos, PEG_RADIUS,
  CasinoTheme.TEXT_MUTED)`) es una llamada de un solo color, sin
  highlight. Corregido: círculo plano `TEXT_MUTED` (`#7c8a9a`) puro, sin
  decoración, alfa binaria 0/255 (52 px de relleno / 12 transparentes).
- `plinko_ball.png` traía un anillo de sombra (`#a0a8b0`) y un brillo
  blanco interior (`#ffffff`) sobre el relleno base — `_draw()`
  (`draw_circle(pos, BALL_RADIUS, CasinoTheme.TEXT_LIGHT)`) también es
  un solo color. Corregido: círculo plano `TEXT_LIGHT` (`#e8edf2`) puro,
  alfa binaria 0/255 (200 px de relleno / 56 transparentes).
- `plinko_slot_bg.png` traía esquinas redondeadas transparentes, un
  borde `#141c16` y una franja de highlight `#538c75` — `_draw_multiplier_row()`
  dibuja el slot con `draw_rect(Rect2(...), color)`, un rectángulo recto
  sin esquinas redondeadas ni borde. Corregido: relleno 100% plano y
  opaco con el color base que ya traía el archivo (`#3a735c` —
  confirmado por cálculo el lerp exacto `PANEL_NAVY_LIGHT`→`ACCENT_GREEN`
  en t=0.5, el punto neutro de referencia), 36×26 sin transparencia.
- Mismo patrón que la corrección de `dice_slider_track_win/lose`
  (`artgroup-dice`): un bisel/highlight que el `_draw()` real no
  produce, contra la regla de `ART_DIRECTION.md` para la familia "Panel
  oscuro" ("superficies lisas con bordes duros... sin textura").
- Los 3 `.import` tenían `process/fix_alpha_border=true` (default de
  Godot); `ART_PIPELINE.md` exige `false` para pixel art. Corregido en
  los 3.
- Tamaños verificados exactos: 8×8, 16×16, 36×26 (coinciden con la tabla
  y con `docs/art/ART_ASSET_PLAN.md`). `compress/mode=0`,
  `mipmaps/generate=false` ya correctos, sin tocar.
- Paleta: los 3 archivos ahora usan exclusivamente tokens reales de
  `CasinoTheme` (`TEXT_MUTED #7c8a9a`, `TEXT_LIGHT #e8edf2`,
  `PANEL_NAVY_LIGHT`/`ACCENT_GREEN` interpolados) — sin colores fuera de
  familia.
- Gameplay/implementación: ningún nodo consume todavía estos 3 PNG
  (`scripts/`/`scenes/` sin referencias) — `PlinkoBoard._draw()` sigue
  dibujando pegs/bola/slots por código, mismo patrón "listo en librería,
  no enganchado" que Ruleta/Dice/Mines/Crash. No bloquea `FINAL`.
- 0 generaciones PixelLab — correcciones puramente mecánicas de color
  sobre assets ya derivados por código, sin pixel art nuevo que
  regenerar.

## Lobby — `lobby/` (7) — FASE 14 completa (2026-08-28)

| ID | Tamaño | Status | Icono central |
|---|---|---|---|
| card_blackjack | 96×128 | FINAL | 2 cartas en abanico (reusa `card_hearts_K`/`card_spades_A`) |
| card_roulette | 96×128 | FINAL | `roulette_wheel` reescalado |
| card_poker | 96×128 | FINAL | `card_hearts_K` + `chip_25` |
| card_dice | 96×128 | FINAL | dado de 5 pips, nuevo por código |
| card_crash | 96×128 | FINAL | `crash_rocket_flame` |
| card_mines | 96×128 | FINAL | bomba de `mines_cell_mine` (fondo de celda recortado) |
| card_plinko | 96×128 | FINAL | `plinko_ball` + 3× `plinko_peg` |

`LOBBY_CARD_MASTER`: 1 generación PixelLab pixflux (marco ornamentado
oro/navy, 16/40 del trial en total). Las 7 tarjetas son ese marco +
un icono central compuesto por código **reutilizando assets ya
APPROVED de otras fases** (cartas, fichas, cohete, bomba, rueda, bola de
plinko) en vez de generar 7 ilustraciones nuevas — 0 generaciones
PixelLab adicionales, y refuerza la identidad visual compartida entre
el lobby y las mesas reales. Solo el dado es nuevo (Dice no tenía un
icono reusable — el juego usa un slider, no un cubo físico).

Validación `artgroup-lobby` (2026-08-28): checklist completo de
`ART_VALIDATION.md` corrido contra los 7 archivos reales en
`assets/pixels/lobby/` (script Pillow ad hoc contra el repo real, no
contra el registro). Técnica: 7/7 tamaño real 96×128 confirmado (modo
RGBA), 0% píxeles de alfa parcial en los 7 (sin halo de
anti-aliasing), PNG lossless, nombre/ubicación conformes a
`ART_NAMING_CONVENTIONS.md`. Consistencia de marco: diff píxel a píxel
de la franja ornamental oro/navy (bordes laterales completos + riel
superior + riel inferior) entre las 7 tarjetas → **0 píxeles de
diferencia**, confirma que las 7 comparten literalmente el mismo
`LOBBY_CARD_MASTER` sin desviación de marco/iluminación; solo difieren
el icono central y el texto de la placa inferior, como corresponde.
Iluminación/paleta: navy `#091629` de fondo y dorado de marco
idénticos en los 7 (muestreados). Gameplay: siluetas legibles a escala
reducida (contact sheet 0.6× de las 7 en fila) y a tamaño nativo;
centrado horizontal del icono dentro de ±5px del centro de tarjeta en
las 7. Import: los 7 traían `process/fix_alpha_border=true` (default
del editor de Godot), contra el `false` que exige `ART_PIPELINE.md`
para pixel art — corregido en los 7 `.import` (mismo criterio ya
aplicado por `artgroup-roulette`/`artgroup-cards` en sus secciones);
`compress/mode=0` y `mipmaps/generate=false` ya estaban correctos de
origen. 0 generaciones PixelLab nuevas (ninguna hizo falta) — única
corrección aplicada fue de `.import`. `LOBBY_CARD_MASTER` confirmado
`APPROVED` (fila de masters) antes de tocar nada. Con eso,
técnica/visual/gameplay/import pasan completos → 7/7 `FINAL`.

**Discrepancia de documentación encontrada (no corregida, fuera de
scope de `artgroup-lobby`):** `ART_DIRECTION.md` línea 172 lista
"Fichas de lobby (card_*): 192×256 (6×8 celdas)" en la tabla de
pixel density, pero el master `LOBBY_CARD_MASTER` (fila de masters,
`APPROVED`) y las 7 tarjetas reales están construidas y aprobadas a
96×128 (3×4 celdas de grid de 32px) desde FASE 14 — coincide con lo
que pide este propio archivo (`artgroup-lobby.md`) y con
`ART_NAMING_CONVENTIONS.md`. Parece una entrada de tabla desactualizada
en `ART_DIRECTION.md`, no un fallo de las 7 tarjetas; se reporta para
que `CasinoArtDirector` la corrija (edición de `ART_DIRECTION.md` está
fuera de mi scope).

**RESUELTO (`CasinoArtDirector`, 2026-08-28):** entrada corregida en
`ART_DIRECTION.md` — 96×128 real queda documentado como excepción,
sin regenerar ningún PNG.

**Nota de integración (informativa, no accionable por este agente):**
el componente de tarjeta de selección de juego que consumiría estos 7
PNGs no existe todavía en `casino_floor.tscn` (usa botones de texto
plano) — confirmado de nuevo en esta sesión. La integración es de
`pilar.md`/`plan12-lobby`, no de `artgroup-lobby`.

## HUD — `hud/` (7) — Iconos: Master ICON_MASTER; fondos: BACKGROUND_MASTER

| ID | Tamaño | Status |
|---|---|---|
| icon_pot | 28×28 | FINAL |
| icon_crown_a | 28×28 | FINAL |
| icon_crown_b | 28×28 | FINAL |
| icon_win | 28×28 | FINAL |
| icon_lose | 28×28 | FINAL |
| victory_bg | 220×264 | FINAL |
| defeat_bg | 220×264 | FINAL |

Fondos método: `victory_bg` y `defeat_bg` generados individualmente con
PixelLab pixflux (mood propio: estallido dorado de luz vs. vignette rojo
somero) — no comparten `BACKGROUND_MASTER`, se ganan su propia identidad
por ser pantallas de resultado. 2 generaciones (20/40 del trial).

Iconos método: `ICON_MASTER` limpiado + pictograma a mano por código
(Pillow, formas geométricas sin anti-aliasing) — pila de monedas
(pot), corona simple (crown_a), corona con gema roja (crown_b), check
verde (`ACCENT_GREEN`, win), X roja (`ACCENT_RED`, lose). 0
generaciones PixelLab.

Excepción de resolución documentada: `ART_DIRECTION.md` fija el grid de
iconos HUD en 32×32, pero los 5 entregados miden 28×28 — recorte del
margen transparente del `ICON_MASTER` (32×32) a la caja real del
pictograma, uniforme en los 5, sin romper el grid base de 32px (el
hueco de 2px por lado queda implícito al colocarlos en una celda de
32×32 en el nodo que los consuma). No es una desviación de escala entre
iconos — los 5 comparten exactamente 28×28 y el mismo anillo dorado de
borde, cumpliendo "escala coherente con los demás assets de su
categoría".

**RESUELTO (`CasinoArtDirector`, 2026-08-28):** excepción añadida a
`ART_DIRECTION.md` (sección "Resolución y pixel density") — 28×28 real
queda documentado ahí, sin regenerar ningún PNG.

Validación FINAL (2026-08-28, `artgroup-hud`): 7/7 archivos verificados
contra `ART_VALIDATION.md` — resolución correcta (28×28 iconos con
excepción documentada arriba, 220×264 fondos), sin halo de
anti-aliasing (alfa binario 0/255 en los 5 iconos, comprobado por
script), `.import` con `compress/mode=0` y `mipmaps/generate=false` en
los 7. Corrección aplicada: los 7 `.import` traían
`process/fix_alpha_border=true` (contradice `ART_PIPELINE.md`, que pide
`false` para pixel art — mismo defecto ya corregido antes en
`roulette/`); se corrigieron a `false` sin regenerar el PNG (ajuste de
`.import`, no de pixel art — no hizo falta PixelLab). Los 5 iconos
comparten lenguaje de iconografía (anillo dorado + interior navy) y son
legibles a escala real de HUD. Pendiente fuera de este scope: ninguno
de los 7 assets está referenciado todavía en `scenes/` (`victory_bg`/
`defeat_bg` ya documentado en `ART_INTEGRATION_PLAN.md`; los 5 iconos no
aparecen ahí y tampoco tienen nodo consumidor — ambos casos son
integración de `pilar.md`, no de este agente).

## Home / Loading (2) — FASE 15 completa (2026-08-28)

| ID | Tamaño | Status |
|---|---|---|
| lobby_bg (`inicio/`) | 220×264 | FINAL |
| loading_bg (`carga/`) | 220×264 | FINAL (= `BACKGROUND_MASTER`) |

`lobby_bg` generado aparte con PixelLab (más rico: cartas/fichas
insinuadas en las esquinas, pantalla de bienvenida). `loading_bg`
reutiliza `BACKGROUND_MASTER` tal cual — es una pantalla de tránsito de
menos de un segundo, no necesita identidad propia.

Validado por `artgroup-home-loading` (2026-08-28) contra
`ART_VALIDATION.md`: ambos archivos reales 220×264 RGBA, alfa constante
255 (opacos, sin halo de anti-aliasing en bordes), paleta de bajo
recuento (42 colores `lobby_bg`, 16 `loading_bg` — bandas/clusters
limpios, sin gradiente fotográfico), navy oscuro próximo a
`PANEL_NAVY_DARK`/`PANEL_NAVY_MID` con acentos dorados/cobrizos
(`#EBC346`/`#F8D652` en `lobby_bg`, familia `GOLD_ACCENT`; tonos bronce
más cálidos en las esquinas de `loading_bg`, variante de sombreado
dentro de la misma familia Oro documentada en `ART_DIRECTION.md`).
Amplio espacio negativo central en ambos — ningún background lleva
texto/UI incrustado, coherente con que la UI real se superpone encima.
Nombre y ubicación correctos
(`assets/pixels/inicio/lobby_bg/lobby_bg.png`,
`assets/pixels/carga/loading_bg/loading_bg.png`). Confirmada la
integración en escena ya existente (Oleada 1, commit `998813c`):
`scenes/lobby_menu.tscn` referencia `lobby_bg.png` y
`scenes/ui/casino/loading_screen.tscn` referencia `loading_bg.png`,
ambos en `TextureRect` con `stretch_mode=6`/`texture_filter=1`
(NEAREST) — no se tocó ningún `.gd`/`.tscn`.

Corrección aplicada: los dos `.import` traían
`process/fix_alpha_border=true` (default de Godot), contra el `false`
que exige `ART_PIPELINE.md` para pixel art (mismo defecto ya corregido
en `assets/pixels/roulette/`, commit `8a6dee2`). Corregidos a `false`
en ambos `.import` — `compress/mode=0` y `mipmaps/generate=false` ya
estaban correctos, no hizo falta regenerar el PNG ni usar PixelLab.

## Menús (4) — FASE 17 completa (2026-08-28) — validado `artgroup-menus` (2026-08-28)

| ID | Tamaño | Status |
|---|---|---|
| settings_bg | 220×264 | FINAL (= `BACKGROUND_MASTER`) |
| pause_bg | 220×264 | FINAL (= `BACKGROUND_MASTER`) |
| credits_bg | 220×264 | FINAL (= `BACKGROUND_MASTER`) |
| help_bg | 220×264 | FINAL (= `BACKGROUND_MASTER`) |

Los 4 reutilizan `BACKGROUND_MASTER` tal cual — son pantallas de menú
neutrales donde el contenido real (texto de ajustes, créditos, reglas)
va encima; generar 4 variantes distintas habría sido ruido visual sin
propósito (regla 39, "no generar basura"). 1 generación PixelLab para
`BACKGROUND_MASTER` (19/40 del trial en total, incluye lobby+victory+
defeat = 4 generaciones de esta fase).

Validación `ART_VALIDATION.md` (`artgroup-menus`, 2026-08-28): los 4 PNG
en disco son idénticos byte a byte a `assets/pixels/_masters/BACKGROUND_MASTER.png`
(mismo sha256, 220×264, RGBA, alfa 100% opaco sin borde transparente —
confirma "reutiliza tal cual"). Sin texto de UI incrustado (solo marco
ornamental dorado en las 4 esquinas sobre fondo navy con vignette
central); espacio central libre amplio para el contenido real de cada
menú. `.import` de los 4: `compress/mode=0`, `mipmaps/generate=false`
ya correctos; se corrigió `process/fix_alpha_border` de `true` a
`false` en los 4 (inofensivo visualmente por ser 100% opacos sin borde
alfa, pero desviaba del estándar de `ART_PIPELINE.md` — mismo fix ya
aplicado antes a `roulette_wheel`, commit `8a6dee2`). Filtro nearest en
nodo: N/A para `settings_bg`/`pause_bg`/`help_bg` (no integrados en
escena — sus overlays modales usan `ColorRect` semitransparente a
propósito, ver nota de integración abajo); `credits_bg` sí está
integrado en `credits_menu.tscn` (`TextureRect` de fondo a pantalla
completa, `texture_filter = 1` NEAREST) — el registro no lo reflejaba
antes de esta validación.

**Nota de integración (no es tarea de `artgroup-menus`, informativo
para `pilar.md`):** `settings_menu.gd`/`pause_menu.gd`/`help_overlay.gd`
quedaron fuera de Oleada 1 — son overlays modales sobre gameplay en
curso, su `Backdrop` es un `ColorRect(PANEL_NAVY_DARK, 0.85)`
semitransparente a propósito; sustituirlo por `settings_bg`/`pause_bg`/
`help_bg` opacos taparía la partida en marcha. Decisión de tratamiento
(imagen con alfa parcial sobre el `Dim` actual, o dejarlo tal cual)
sigue pendiente y abierta — no se cierra aquí.

---

## Cierre — sistema completo (2026-08-28)

**111/112 assets finales `APPROVED`** (todos salvo `crash_line_texture`,
descartado a propósito — ver FASE 11). Póker se queda en 0 assets
propios a propósito (reutiliza cards/chips/panel de fieltro). **9/9
masters `APPROVED`** (2 de ellos, `ROULETTE_CELL_MASTER` y el "master"
de celdas de Mines, no tienen PNG standalone — son funciones de código
compartidas, documentado en cada sección).

**20/40 generaciones PixelLab usadas** en total — el resto (91 assets)
se derivó 100% por código (Pillow) desde los masters aprobados o
reutilizando otros assets ya aprobados, siguiendo la jerarquía de
`ART_PIPELINE.md`.

**Pendiente real, no bloqueante:**
- Integración en escena: la mayoría de estos PNGs no están enganchados
  todavía — Ruleta/Dice/Mines/Plinko/Crash siguen dibujándose por
  código en producción (`_draw()`/`StyleBoxFlat`). Sustituir ese dibujo
  procedural por estos PNGs es tarea de código, no de
  `CasinoArtDirector` — coordínalo con la sesión pilar (`pilar.md`)
  cuando quieras esa migración.
- `roulette_wheel` — tamaño de display **resuelto (2026-08-28)**: nativo
  124×124, contenedor real `RouletteWheelDisplay` es 260×260
  (`RADIUS=130.0` en `roulette_wheel_display.gd`), escala entera ×2 →
  **248×248 px**, centrado (detalle en `ART_DIRECTION.md`). Falta solo
  la implementación en código (`TextureRect` detrás del control), no
  arte pendiente.
- Duplicados sueltos en la raíz del repo (`crash.png`, etc.): **resuelto**
  — borrados en commit `a90d385`, confirmado por `CasinoArtDirector`
  (2026-08-28) que no existen en disco. Esta línea estaba desactualizada.

Total assets finales: 112 (coincide con `assets/pixels/ASSETS.md`).
Total masters: 9. Total filas de trabajo: 121.

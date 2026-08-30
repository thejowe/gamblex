# Art Integration Plan — enganchar los 111 PNGs aprobados en escena

## Pendiente real — recomponer `lobby_bg`/`credits_bg`/`loading_bg` para COVER en ultra-wide (2026-08-29, sesión pilar)

**Encargo para `CasinoArtDirector`** (parámetros, no diseño — el
director decide cómo dibujarlo):

Usuario reportó que en su monitor ultra-wide (~3.55:1 real) el fondo
de `HomeScreen` (`inicio/lobby_bg/lobby_bg.png`, la entrada de casino
con puertas/neón/alfombra regenerada el 2026-08-29) se ve muy ampliado
y recortado. Causa raíz confirmada por la sesión pilar de código: las 3
escenas full-bleed (`home_screen.tscn`, `credits_menu.tscn`,
`loading_screen.tscn`) usan `TextureRect` con `stretch_mode=
KEEP_ASPECT_COVERED` sobre un lienzo portrait 220×264 — con ese aspect
ratio tan distinto al de un monitor ultra-wide, `COVER` escala por el
ancho y recorta el alto agresivamente.

**Se probó y el usuario rechazó explícitamente** cambiar a
`KEEP_ASPECT_CENTERED` (sin recorte, pero con barras de color sólido a
los lados en pantallas anchas — "salen espacios negros a los lados").
Quiere que el arte se recomponga para seguir cubriendo la pantalla sin
barras, no que se cambie el modo de stretch. **No se toca el motor**:
las 3 escenas siguen en `stretch_mode=6` (COVER), sin cambios de
código pendientes ahí.

Los 3 números con los que trabajar (calculados por la sesión pilar de
código, verificar antes de dar por buenos si el lienzo cambia de
tamaño):

1. **Modo de stretch a respetar:** `COVER` (`KEEP_ASPECT_COVERED`) en
   las 3 escenas — no cambia.
2. **Rango de aspect ratio a soportar sin que el recorte destroce el
   detalle central:** desde 4:3 (1.33:1) hasta 3.55:1 (ultra-wide real
   del usuario, peor caso). Siempre landscape — el lienzo portrait
   220×264 nunca pierde ancho en ese rango, solo alto.
3. **Área garantizada visible en el peor caso (3.55:1):** franja
   horizontal central de **220×62px** (ancho completo del lienzo,
   filas ~101–163 de las 264 de alto — el resto, ~101px arriba y
   ~101px abajo, se recorta en ultra-wide pero se ve en monitores menos
   anchos, sangrado progresivo).

Aplica a los 3 fondos que comparten exactamente este problema
(`lobby_bg`, `credits_bg`, `loading_bg`, los 3 a 220×264,
`FINAL`/`APPROVED` hoy) — decidir si conviene recomponerlos los 3 a la
vez con el mismo criterio o uno a uno empezando por `lobby_bg`
(mayor visibilidad, ya regenerado hoy mismo). Actualizar
`ASSET_REGISTRY.md` con el estado de cada uno tras el retoque, como
siempre. Cuando termines, avisa a la sesión pilar de código para
verificar en vivo (esta vez con capturas reales, no solo lectura de
`.tscn`) antes de cerrarlo.

## Cierre de sesión (2026-08-28, sesión pilar) — las 5 decisiones pendientes

Ejecutadas 3 de 5, documentadas 2 como "no aplica" con motivo técnico
verificado (no es solo juicio de diseño). 441/441 tests GUT en cada
paso. Commits: `9b741cb` (fieltro) → `b825a90` (victoria/derrota) →
`4e9eca6` (bet sidebar).

1. **`felt_table_panel.gd` — EJECUTADO.** `NinePatchRect` con
   `felt_table_bg.png` como hermano previo a `FeltTablePanel` en
   `blackjack_table_net.tscn`/`poker_table_net.tscn` (dibuja detrás, cero
   cambios en `felt_table_panel.gd`). Se descartó sustituir el óvalo
   paramétrico: `felt_table_bg.png` es un pill completo (redondeado en
   ambos extremos), pero Blackjack dibuja solo el semi-óvalo superior
   (`_arc_points` con `angle_end=PI`) — sustituir habría puesto una forma
   incorrecta además de perder adaptabilidad. `NinePatchRect`
   (`patch_margin` 40) preserva las esquinas redondeadas al escalar con
   la ventana.
2. **Victoria/Derrota — EJECUTADO.** `bg_color` de `DefeatPanelStyle`/
   `VictoryPanelStyle` pasó a alpha 0 (conserva `corner_radius` +
   `border_color`); `NinePatchRect` nuevo (`PanelBackground`) con
   `victory_bg.png`/`defeat_bg.png` insertado detrás de cada `Panel`,
   mismos anchors 0.32–0.68. Antes el `StyleBoxFlat` opaco tapaba
   cualquier imagen detrás — ahora el borde de color queda encima de la
   textura decorativa en vez de sustituir el estilo entero (igual que la
   recomendación original de este documento).
3. **`roulette_wheel.png` como fondo decorativo — NO APLICA, verificado
   en código.** `roulette_wheel_display.gd._draw()` pinta 37 gajos con
   `draw_colored_polygon` opacos que cubren el círculo completo (radio
   130, sin huecos) — cualquier textura puesta detrás quedaría 100%
   oculta, cero ganancia visual a cambio de un dibujo doble. No se
   ejecuta, no es "postergado", es un descarte técnico definitivo salvo
   que se rediseñe `roulette_wheel_display.gd` para dejar huecos (fuera
   de alcance de esta decisión).
4. **Overlays Ajustes/Pausa/Ayuda — NO APLICA.** Confirmado que
   `settings_menu.tscn`/`pause_menu.tscn`/`help_overlay.tscn` siguen con
   `Backdrop` `ColorRect(PANEL_NAVY_DARK, 0.85)` semitransparente. Los
   PNG (`settings_bg`/`pause_bg`/`help_bg`) son fondos opacos pensados
   para pantalla completa (mismo assets que loading/credits/lobby) — no
   existe una versión con alfa parcial en el registro, y generar una
   nueva variante es trabajo de `CasinoArtDirector`/`ART_ASSET_PLAN.md`,
   no de esta sesión. Se cierra el ítem tal cual, sin cambio de código.
5. **`bet_sidebar_panel.gd` — EJECUTADO.** `NinePatchRect`
   (`bet_sidebar_bg.png`, `patch_margin` 12) como primer hijo de
   `BetSidebarPanel`, detrás de `Margin/VBox`. El `StyleBoxFlat`
   programático en `_ready()` pasa a alpha 0 (ya no pinta panel sólido,
   solo evita que se vea el estilo por defecto de `PanelContainer`).

`crash_rocket_idle`/`_launch`: sin cambios, se deja documentado como ya
estaba (no hay estado de gameplay que los necesite hoy).

**Verificación visual: 2 de 3 confirmadas en vivo con capturas reales.**
El editor abierto con una escena `Control` aislada no sirve (nodo raíz
sin padre = rect 0×0, no se ve color) — el truco real, ya usado en la
sesión de Ruleta de hoy mismo, es correr la escena suelta directamente:
`Godot_v4.7.1-stable_win64_console.exe --path . scenes/<escena>.tscn`
lanza una ventana de juego real con tamaño de viewport correcto, sin
pasar por Lobby/Steam. Capturas (`CopyFromScreen` sobre el rect de la
ventana):
- **`blackjack_table_net.tscn`**: fieltro con el riel de madera +
  4 iconos de palo de `felt_table_bg.png` visibles detrás del óvalo
  procedural (semi-óvalo superior intacto, sin doble dibujo raro), panel
  lateral de apuesta renderiza sin artefactos.
- **`poker_table_net.tscn`** (`full_oval=true`): las 4 esquinas del
  `NinePatchRect` completo visibles alrededor del óvalo procedural
  completo — confirma que el `patch_margin=40` escala bien el pill.
- **Victoria/Derrota — no confirmado en vivo.** `casino_floor.gd` fuerza
  `defeat_overlay.visible = false` en cuanto llega el primer estado del
  pozo (`_on_goal_state_changed`, línea ~202) aunque el `.tscn` diga
  `visible=true` a mano — forzar el overlay sin jugar una partida real
  hasta la bancarrota exige más que un toggle de visibilidad (se probó,
  se revirtió sin commitear). La técnica en sí (`NinePatchRect` +
  `StyleBoxFlat` a alpha 0) es exactamente la misma que ya se confirmó
  funcionando en vivo para `bet_sidebar_panel.gd` — riesgo bajo, pero
  **pendiente que el usuario lo vea con una partida real que llegue a
  victoria/derrota**.
- Efecto colateral de abrir el editor headless antes de esto:
  `project.godot` y `assets/icon.svg.import` se tocaron solo por abrirlo
  (gotcha de siempre), revertidos antes de commitear.

## Cierre de sesión (2026-08-28, sesión pilar) — Lobby

Ejecutado y verificado (432/432 tests GUT), commit `9bff9dd`, pusheado a
`main`: item "Lobby: crear componente de tarjeta de selección de juego"
de la sección "Pendiente real" de abajo. `LobbyGameCard`
(`scripts/ui/casino/lobby_game_card.gd`, `TextureButton`) sustituye los
7 botones de texto plano de `CardGrid` en `casino_floor.tscn` por los 7
`lobby/card_*.png` reales (96×128, ya incluyen el nombre del juego en
el arte — no hace falta `Label` aparte). Grid pasó de 2 a 4 columnas
(176×235 en pantalla, aspecto retrato). Reutiliza el mismo lenguaje de
hover/press por tween que `CasinoButton` (no hay variantes hover/
pressed para estas cartas). `_on_card_pressed`/nombres de nodo
(`BlackjackCard`…`PlinkoCard`) intactos — cero cambio de lógica de
navegación.

**Verificación visual en editor: no se pudo completar esta sesión.**
Se abrió el editor con la escena cargada (sin errores, "0 errores" en
Salida) pero la automatización de clic de Windows (`SetCursorPos`+
`mouse_event`) no logró cambiar de la pestaña "Tienda de Assets" a "2D"
tras 2 intentos con foco confirmado — probablemente desajuste de
escalado DPI entre coordenadas físicas y el área cliente de la ventana.
Se cerró el editor en vez de seguir insistiendo (mismo criterio de "no
rabbit-holing" en automatización de UI). Queda pendiente que el usuario
o una sesión con Godot a mano confirmen visualmente el grid de 7
tarjetas antes de dar el ítem por cerrado del todo — mismo patrón que
otras oleadas de este plan que se cerraron solo con tests en verde.

## Cierre de sesión (2026-08-28)

Ejecutado y verificado (429/429 tests GUT en cada paso), pusheado a
`main`: **Oleada 1** (loading/credits/lobby a `TextureRect` real —
Ajustes/Pausa/Ayuda quedaron fuera, ver corrección abajo), **Oleada 2**
completa (botones, fichas, casillas de Mines), **Oleada 3 parcial**
(cartas — `felt_table_panel.gd` queda fuera a propósito), **Oleada 4
parcial** (cohete de Crash en la punta del gráfico).

Commits: `998813c` (Oleada 1) → `3eec9e0` (Oleada 2) → `fd330eb`
(Oleada 3 cartas) → `dd90f48` (Oleada 4 cohete).

**Pendiente real — actualizado 2026-08-28 (sesión pilar), ver cierre de
sesión arriba para el detalle completo:**
- ~~`felt_table_panel.gd`~~ — **hecho**, `9b741cb` (NinePatchRect
  decorativo, dibujo procedural intacto).
- ~~Victoria/Derrota~~ — **hecho**, `b825a90` (NinePatchRect detrás,
  borde de color conservado vía alpha 0 en el `StyleBoxFlat`).
- ~~`roulette_wheel.png` como fondo decorativo~~ — **cerrado, no
  aplica** (el dibujo procedural es 100% opaco, cualquier textura detrás
  quedaría oculta).
- ~~Overlays Ajustes/Pausa/Ayuda~~ — **cerrado, no aplica** (el Backdrop
  semitransparente actual cumple su función; no hay asset con alfa
  parcial en el registro).
- ~~`bet_sidebar_panel.gd`~~ — **hecho**, `4e9eca6` (NinePatchRect de
  fondo).
- ~~Tarjetas de Lobby (`lobby/card_*.png`)~~ — **hecho (2026-08-28,
  `9bff9dd`)**, ver sección de cierre arriba. Visual en editor pendiente
  de confirmar por el usuario.
- `crash_rocket_idle`/`_launch` (generados en FASE 11) siguen sin
  usarse — no hay un estado intermedio en `crash_graph.gd` hoy que los
  necesite. Sin urgencia, documentado sin más.

**Confirmación visual en vivo pendiente para todo lo de hoy** — ver
"Verificación visual" en el cierre de sesión de arriba (limitación real
del editor con escenas `Control` aisladas + Lobby tapando `TablesLayer`,
no solo el bloqueador de clic sintético de siempre).

Prompt para retomar en una sesión nueva: igual que siempre, actuar como
`CasinoArtDirector` (ver `.claude/agents/CasinoArtDirector.md`), y
decirle que continúe este documento desde "Pendiente real" arriba.

## Prerrequisito universal — DESCUBIERTO EN OLEADA 1, aplica a TODAS las oleadas

Ningún PNG de `assets/pixels/` tenía `.import` generado (0/121 antes de
Oleada 1) — `ASSET_VALIDATION.md` ya pedía comprobar "el motor lo
detecta" pero esta sesión nunca lo había verificado de verdad, solo
revisión visual. Referenciar un asset sin `.import` rompe en seco con
`Parse Error: [ext_resource] referenced non-existent resource`, lo
confirmaron los tests (`test_loading_screen.gd`, `test_lobby_menu.gd`)
al fallar 12/429 en el primer intento.

**Antes de referenciar cualquier PNG nuevo desde una `.tscn`/`.gd`,
correr:**

```
"<ruta a Godot>_console.exe" --headless --editor --quit-after 60
```

desde la raíz del repo. Esto reimporta todo `assets/pixels/` y genera
los `.png.import` que faltan (commitear esos `.import`, son texto
plano y regenerables pero Godot los espera versionados — mismo patrón
que ya tenía `docs/superpowers/specs/references/*.import`). Repetirlo
cada vez que se generen assets nuevos, antes de intentar engancharlos.

## Hallazgo de partida

Toda la capa visual del juego —las 7 mesas, fichas, cartas, botones,
paneles, HUD— está dibujada hoy con `_draw()`/`StyleBoxFlat` puro,
usando los colores de `CasinoTheme`. **Cero nodos consumen una textura
`.png` en todo `scripts/ui/casino/`.** No es un caso aislado de Ruleta:
es la arquitectura completa (Plan 14/16-20/31 construyeron un sistema
de "pixel art vectorial", no basado en sprites).

Componentes confirmados 100% procedurales (leídos completos, no
inferidos):

| Script | Dibuja | Assets ya aprobados que podrían sustituirlo |
|---|---|---|
| `playing_card.gd` | rect + texto + símbolo de palo | 52 `card_*` + `card_back` |
| `casino_chip.gd` | círculo + notches + texto | 6 `chip_*` |
| `casino_button.gd` | `StyleBoxFlat` con corner radius | 12 `button_*_*` |
| `felt_table_panel.gd` | polígono ovalado madera+fieltro | `felt_table_bg` (parcial, ver riesgo abajo) |
| `bet_sidebar_panel.gd` | `StyleBoxFlat` navy | `bet_sidebar_bg`, `panel_border` |
| `mines_cell.gd` | rect + diamante/círculo | 4 `mines_cell_*` |
| `roulette_wheel_display.gd` | polígonos + arco + círculo (bola animada) | `roulette_wheel`, `roulette_ball` |
| `roulette_betting_grid.gd` | `StyleBoxFlat` por celda | 3 `roulette_grid_cell_*` |
| `dice_threshold_slider.gd` | círculo + 2 rects | `dice_slider_handle`, `dice_slider_track_*` |
| `plinko_board.gd` | círculos (peg/ball) + rect con lerp de color | `plinko_peg`, `plinko_ball`, `plinko_slot_bg` |
| `crash_graph.gd` | polilínea + polígono dinámicos | ninguno lo sustituye (ver "Nunca cambia") |
| `loading_screen.gd`, `settings_menu.gd`, `pause_menu.gd`, `help_overlay.gd` | `ColorRect` plano | `BACKGROUND_MASTER` (mismo PNG en los 4) |
| `lobby_menu.gd`, `casino_floor.gd` (Hud) | sin fondo de imagen | `lobby_bg`, `victory_bg`, `defeat_bg` |
| Lobby (selección de juego) | sin componente dedicado, botones de texto | 7 `card_*` de `lobby/` |

## Por qué esto es más grande de lo que parece

Sustituir un `_draw()` por una textura no es solo "cargar un PNG": cada
componente expone estado (`rank`/`suit`, `denomination`, `variant`,
`state`) que hoy decide qué dibujar. El reemplazo tiene que mapear ese
mismo estado a **qué archivo cargar**, preservando la interfaz pública
exacta (propiedades exportadas, señales, `custom_minimum_size`, métodos
como `rank_label()`/`flip()`/`color_for_variant()`) — los 6 archivos de
test (`test_playing_card.gd`, `test_casino_chip.gd`,
`test_casino_button.gd`, `test_felt_table_panel.gd`,
`test_blackjack_table_scene_structure.gd`,
`test_poker_table_scene_structure.gd`) solo verifican esa interfaz
pública y comportamiento sin crashear — **no hay ningún assert sobre
píxeles dibujados**, así que el riesgo real de romper tests es bajo
*si* se preserva la interfaz. El riesgo real está en:

1. **Preload de 52+ texturas de carta** sin penalizar tiempo de carga.
2. **Componer estado dinámico sobre una textura estática** (mina
   revelada con animación de escala, ficha resaltada al pasar el
   ratón, `mines_cell.gd` ya anima `scale` en `_animate_reveal()` — eso
   sigue funcionando igual sobre un `TextureRect`, no hay que tocarlo).
3. **Alinear el tamaño real de cada asset** con el `custom_minimum_size`
   actual del componente (ej. `PlayingCard.CARD_SIZE = Vector2(70,100)`
   vs `card_hearts_A.png` real a 52×86 — hace falta decidir si se
   estira la textura o se regenera al tamaño exacto).
4. **No perder in-game contraste/legibilidad** al pasar de vector nítido
   a bitmap escalado — verificar visualmente en el editor, no solo con
   GUT.

## Qué NO cambia (se queda procedural a propósito)

- **`crash_graph.gd`**: la curva/polilínea se recalcula cada frame según
  el multiplicador real (`CrashTableState.multiplier_at`). No hay
  textura que pueda sustituir eso — ya se decidió en FASE 11 no generar
  `crash_line_texture`. Lo único integrable ahí es el marcador de
  punta: cambiar el `draw_circle` final por `crash_rocket_idle/launch/
  flame.png` según `state`, eso sí es un candidato real (bajo riesgo,
  cambio aislado a una función).
- **`roulette_wheel_display.gd`**: los 37 número/color de la rueda y la
  posición angular de la bola dependen de `WHEEL_ORDER` y
  `ball_angle` en tiempo real — la rueda como imagen estática
  (`roulette_wheel.png`) puede ir DETRÁS como fondo decorativo, pero
  los números/colores/bola interactivos siguen dibujándose encima por
  código (o se necesitaría generar 37 posiciones de número que no
  están en el plan). Recomendación: usar `roulette_wheel.png` como capa
  de fondo decorativa nada más, no como reemplazo funcional.
- **`plinko_board.gd`** fila de multiplicadores: el color depende de un
  `lerp` en tiempo real contra el multiplicador de cada slot — igual
  que Crash, no se puede fijar en una textura sin perder esa
  información. `plinko_slot_bg.png` puede ir de fondo, el tinte dinámico
  sigue por código encima (`modulate` en vez de recalcular el color).

## Orden de ejecución (por riesgo, de menor a mayor)

### Oleada 1 — estático puro, sin estado dinámico que preservar

**Corrección real encontrada al ejecutar:** `settings_menu.gd`,
`pause_menu.gd` y `help_overlay.gd` NO tienen un fondo de pantalla
completa — su nodo `Backdrop` es un `ColorRect` **semitransparente**
(`Color(PANEL_NAVY_DARK, 0.85)`) que atenúa la mesa/escena que sigue
viva detrás, porque son overlays modales sobre gameplay en curso, no
pantallas propias. Sustituirlo por `BACKGROUND_MASTER` opaco taparía la
partida en marcha — **se sacan de esta oleada**, quedan fuera de plan
hasta que se decida un tratamiento distinto (¿imagen con alfa parcial
sobre el `Dim` actual? ¿dejarlo tal cual?). No están en `ASSETS.md`
como pantallas propias tampoco — revisar si de verdad hace falta un
asset ahí.

Ejecutado (2026-08-28):
1. ~~`settings_menu.gd`/`pause_menu.gd`/`help_overlay.gd`~~ — **fuera de
   oleada**, ver corrección arriba.
2. `loading_screen.gd` + `.tscn`: `Background` `ColorRect` → `TextureRect`
   con `loading_bg.png` (`stretch_mode=6` KEEP_ASPECT_COVERED,
   `texture_filter=1` NEAREST). Se quitó `background.color = ...` del
   script (ya no aplica a `TextureRect`).
3. `credits_menu.tscn`: mismo cambio, `credits_bg.png`. El script no
   referenciaba `Background`, cero cambios en `.gd`.
4. `lobby_menu.tscn`: no tenía nodo de fondo — se añadió `Background`
   `TextureRect` nuevo como primer hijo, `lobby_bg.png`, mismo
   stretch/filter. Cero cambios en `.gd` (nadie lo referenciaba).
5. `casino_floor.gd`/`victory_overlay`/`defeat_overlay`: **no
   ejecutado** — su `Dim` también es un `ColorRect` translúcido
   (alfa 0.6) sobre la mesa en vivo, y el `Panel` central usa
   `StyleBoxFlat` con `corner_radius` (border rojo/dorado) que
   `StyleBoxTexture` no reproduce igual — mismo problema que la
   Oleada 3 (`felt_table_panel.gd`). Movido a una oleada aparte con
   diseño explícito, ver sección nueva más abajo.

Verificado: `godot --headless -s addons/gut/gut_cmdln.gd
-gdir=res://tests/unit -gexit` → **429/429 tests pasan** (tras generar
los `.import` que faltaban, ver prerrequisito arriba). Efecto
secundario detectado y revertido: abrir el editor headless reindentó
`scripts/net/casino_floor.gd` (4 espacios → tabs) solo por tenerlo
abierto — sin relación con este trabajo, se revirtió con `git checkout
-- scripts/net/casino_floor.gd` antes de commitear. **Si otra sesión
repite el paso de reimport, revisar `git diff` completo antes de
commitear por si el editor reformatea algún script que tuviera abierto
de una sesión anterior.**

Riesgo real observado: mínimo en los 3 componentes ejecutados. El resto
de la oleada original resultó tener más matices de lo esperado — ya
corregido arriba antes de tocar código.

### Oleada 2 — componentes con estado simple (enum → textura) — EJECUTADA (2026-08-28)

5. `casino_button.gd`: `_style()` (StyleBoxFlat) → `StyleBoxTexture`
   cacheado por `variant_state` (`_style_cache` estático, evita recargar
   la misma textura por cada botón instanciado). `color_for_variant()`
   y `VARIANT_COLORS` se dejaron intactos (el test los verifica
   directamente).
6. `casino_chip.gd`: `_draw()` intenta `chip_<denomination>.png` si la
   denominación está en `KNOWN_DENOMINATIONS` (1/5/10/25/50/100); si no,
   cae al dibujo vectorial original (renombrado `_draw_vector_fallback()`)
   — cubre denominaciones huérfanas sin asset.
7. `mines_cell.gd`: `_draw()` → textura por `state` vía diccionario
   `STATE_TEXTURE_PATHS`. Se borró `_draw_diamond()` (quedó muerto tras
   el cambio, sin otras referencias). `_animate_reveal()` intacto —
   anima `scale`, no toca `_draw()`.

Los 3 llevan `texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST` en
`_init()` para que el pixel art no salga difuminado al escalar.

Verificado: 429/429 tests GUT. Sin verificación visual en el editor
todavía — pendiente que alguien lo abra y lo mire (ART_VALIDATION.md
"Gameplay" lo exige, ningún test lo puede confirmar).

### Oleada 3 — tamaño/geometría a reconciliar

8. `playing_card.gd`: **EJECUTADA (2026-08-28).** `CARD_SIZE` pasó de
   `(70,100)` a `(52,86)` (tamaño real de `card_*.png`). Se confirmó
   antes de tocarlo que nada más en el repo asume el literal
   `(70,100)`: `poker_table_net.gd` lee `card.CARD_SIZE.y` en
   runtime (se adapta solo), `blackjack_table_net.gd` no asume tamaño
   de carta en ningún punto. `_draw()` ahora carga
   `card_<suit>_<rank>.png`/`card_back.png` vía `SUIT_NAMES` +
   `rank_label()` (el mapeo de rango ya devolvía exactamente "2".."10"/
   "A"/"J"/"Q"/"K", igual que el naming de archivo). `SUIT_SYMBOLS`
   quedó muerto tras el cambio (ya no se dibuja el glifo Unicode) y se
   borró. Verificado: 429/429 tests GUT, incluidos
   `test_blackjack_table_scene_structure.gd`/
   `test_poker_table_scene_structure.gd` (no asumen tamaño de carta).
9. `felt_table_panel.gd`: **EJECUTADA (2026-08-28, `9b741cb`).**
   `NinePatchRect` con `felt_table_bg.png` como fondo decorativo detrás
   del dibujo procedural (que se dejó intacto) — ver detalle en el
   cierre de sesión de arriba.
10. `bet_sidebar_panel.gd`: **EJECUTADA (2026-08-28, `4e9eca6`).**
    `NinePatchRect` con `bet_sidebar_bg.png` (96×144, 9-slice) como
    fondo, `StyleBoxFlat` programático a alpha 0.

### Oleada nueva — Victoria/Derrota (`victory_bg`/`defeat_bg`) — EJECUTADA (2026-08-28, `b825a90`)

`Hud/DefeatOverlay` y `Hud/VictoryOverlay` en `casino_floor.tscn` tenían
`Dim` (`ColorRect` translúcido sobre la mesa) + `Panel` centrado
(`StyleBoxFlat` con `corner_radius` y borde de color, rojo/dorado). Se
aplicó la opción recomendada: `bg_color` de `DefeatPanelStyle`/
`VictoryPanelStyle` a alpha 0 (conserva `corner_radius` + borde) y un
`NinePatchRect` nuevo (`PanelBackground`) con `victory_bg.png`/
`defeat_bg.png` insertado como hermano justo antes del `Panel`, mismos
anchors 0.32–0.68 — el borde de color queda encima de la imagen en vez
de sustituir el estilo. `casino_floor.gd` no necesitó cambios
(`_play_victory_pulse` sigue usando `get_node("Panel")`, que no se
movió). 441/441 tests GUT.

### Oleada 4 — decorativo sobre lógica dinámica (opcional, bajo impacto)
11. `crash_graph.gd` — **EJECUTADA (2026-08-28).** El marcador de punta
    ahora es `crash_rocket_flame.png` (ancla base/llama exactamente en
    el punto final de la curva, nariz hacia arriba) mientras
    `state != CRASHED`; en `CRASHED` se conserva el círculo rojo
    original (no hay asset de "explosión", y el círculo ya comunica
    bien el impacto). `crash_rocket_idle`/`_launch` quedan sin usar
    aquí — no hay un momento en el código actual donde `state` sea
    "arrancando pero sin subir todavía" que los necesite; quedan en la
    librería para cuando se quiera ese matiz. `texture_filter` nearest
    añadido en `_init()` (no existía antes en este script).
    Verificado: 429/429 tests GUT.
12. `roulette_wheel_display.gd`: **cerrado, no aplica (2026-08-28)** —
    `_draw()` pinta 37 gajos opacos que cubren el círculo completo, sin
    huecos; `roulette_wheel.png` detrás quedaría 100% oculto. Descarte
    técnico, no decisión de gusto.
13. ~~Lobby: crear el componente de tarjeta de selección de juego~~ —
    **EJECUTADA (2026-08-28, `9bff9dd`).** Ver sección de cierre arriba.

## Verificación obligatoria en cada oleada

1. `godot --headless --run-tests` (o el runner GUT que use el proyecto)
   completo — no solo los tests del componente tocado, la Oleada 3
   toca tamaños que otras escenas podrían asumir.
2. Abrir el editor y mirar la mesa/escena afectada al menos una vez
   (esto no lo puede confirmar un test, ART_VALIDATION.md lo exige
   explícitamente en la sección "Gameplay").
3. Commit por oleada, no por componente — cada oleada es la unidad
   mínima que deja el juego en un estado consistente.

## Recomendación de secuencia real

No lo haga un agente único de una sentada. Cada oleada es del tamaño de
un plan de agente normal del proyecto (comparable a Plan 14/16-20/31).
Sugerencia: una sesión de `CasinoArtDirector` (u otro agente dedicado,
a decidir con `pilar.md`) por oleada, verificando tests antes de pasar
a la siguiente — igual que el resto del roadmap del proyecto.

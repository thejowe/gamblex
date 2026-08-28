# Art Integration Plan — enganchar los 111 PNGs aprobados en escena

Estado: **PLAN, no ejecutado.** Ningún script tocado todavía — el
usuario pidió explícitamente "solo planifica" antes de escribir código.
Este documento es lo que un agente (`CasinoArtDirector` u otro) ejecuta
cuando se dé luz verde.

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
1. `loading_screen.gd`, `settings_menu.gd`, `pause_menu.gd`,
   `help_overlay.gd`: cambiar su `ColorRect` por un
   `TextureRect` con `BACKGROUND_MASTER` (stretch_mode
   `KEEP_ASPECT_COVERED`). Cambio de 1 línea por script.
2. `credits_menu.gd` (fondo, si tiene `ColorRect` propio — confirmar al
   ejecutar) → `credits_bg.png`.
3. `lobby_menu.gd` → `lobby_bg.png`.
4. `casino_floor.gd` Hud → `victory_overlay`/`defeat_overlay` ganan un
   `TextureRect` de fondo (`victory_bg.png`/`defeat_bg.png`) detrás del
   contenido actual, sin tocar la lógica de victoria/derrota.

Riesgo: mínimo. Ningún test referencia estos nodos por contenido visual.

### Oleada 2 — componentes con estado simple (enum → textura)
5. `casino_button.gd`: sustituir `_style()` (StyleBoxFlat) por
   `StyleBoxTexture` cargando `button_<variant>_<state>.png` según
   `variant` + el estado real de `Button` (normal/hover/pressed/
   disabled ya existen como StyleBox slots nativos de Godot — encaja
   perfecto, `add_theme_stylebox_override` acepta cualquier StyleBox).
6. `casino_chip.gd`: `_draw()` → `draw_texture_rect()` con
   `chip_<denomination>.png`; si `denomination` no está en el diccionario
   (huérfano según `CasinoTheme.chip_color`), fallback a dibujo
   vectorial actual (no todos los denominaciones tienen PNG).
7. `mines_cell.gd`: `_draw()` → textura según `state`
   (`mines_cell_hidden/safe/mine/mine_dim.png`), conserva
   `_animate_reveal()` intacto (anima `scale`, no `_draw`).

Riesgo: bajo. Tests de estos 3 solo verifican la propiedad pública, no
el método de dibujo.

### Oleada 3 — tamaño/geometría a reconciliar
8. `playing_card.gd`: mapear `(suit, rank)` a
   `card_<suit>_<rank>.png`/`card_back.png` según `face_up`. Requiere
   decidir: ¿se regenera `CARD_SIZE` a 52×86 (tamaño real del asset) o
   se estira la textura a 70×100 (tamaño actual)? Recomendación:
   regenerar `CARD_SIZE` al tamaño real del asset y dejar que el layout
   de cada mesa absorba la diferencia — estirar pixel art rompe la
   nitidez. Esto es lo único de esta oleada que toca más de un archivo
   (cualquier escena que asuma `CARD_SIZE = (70,100)` a mano).
9. `felt_table_panel.gd`: **riesgo más alto de la oleada** — hoy dibuja
   un óvalo *paramétrico* que se adapta a cualquier `size` del
   contenedor (usado en Blackjack Y Póker con `full_oval` distinto).
   `felt_table_bg.png` es una imagen fija a 320×180. Sustituir el
   dibujo por la textura pierde la adaptabilidad a distintos tamaños de
   ventana (el juego usa `stretch/aspect=expand`, tamaños de ventana
   variables). Recomendación: **no sustituir esta por ahora** — dejarla
   procedural, o usar la textura solo como fondo decorativo con
   `NinePatchRect` si se quiere textura real sin perder el
   adaptabilidad. Marcar como decisión pendiente del usuario, no
   ejecutar sin confirmar.
10. `bet_sidebar_panel.gd`: mismo patrón que 9 pero más simple
    (`bet_sidebar_bg.png` ya se generó a 96×144 pensado como 9-slice) —
    usar `NinePatchRect` en vez de `TextureRect` para que escale bien.

### Oleada 4 — decorativo sobre lógica dinámica (opcional, bajo impacto)
11. `crash_graph.gd`: cambiar el `draw_circle` de la punta por
    `crash_rocket_<state>.png` (idle si no ha empezado, flame si está
    subiendo). Aislado, una función.
12. `roulette_wheel_display.gd`: `roulette_wheel.png` como fondo
    decorativo detrás del dibujo actual (que sigue siendo la fuente de
    verdad interactiva). Requiere decidir si vale la pena el doble
    dibujo (imagen + polígonos encima) o si se deja tal cual.
13. Lobby: crear el componente de tarjeta de selección de juego que hoy
    no existe (los botones de juego son texto plano) y usar los 7
    `card_*.png` — esto es una **adición de UI nueva**, no un
    reemplazo, más grande que las anteriores.

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

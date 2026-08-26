# Plan: reflow responsive de las 6 mesas restantes

Contexto completo, decisión y receta de conversión:
`docs/superpowers/specs/2026-08-25-responsive-layout-design.md` — **léelo
entero primero**, no lo repitas de memoria.

Ya hecho por la sesión pilar y mergeado a `main` (commit `0b9568d`):
`project.godot` (`window/stretch/aspect="expand"`), `casino_floor.tscn`
(lobby + HUD), `blackjack_table_net.tscn` completo. Ese commit es tu
referencia nodo-por-nodo — `git show 0b9568d` antes de tocar nada.

## Alcance

Aplica la misma conversión a las 6 escenas restantes:
- `scenes/roulette_table_net.tscn`
- `scenes/poker_table_net.tscn`
- `scenes/dice_table_net.tscn`
- `scenes/crash_table_net.tscn`
- `scenes/mines_table_net.tscn`
- `scenes/plinko_table_net.tscn`

No toques `blackjack_table_net.tscn`, `casino_floor.tscn` ni
`project.godot` — ya están hechos. No toques lógica de juego
(`scripts/<juego>/*.gd`, `scripts/net/*_table_controller.gd`) salvo que
encuentres coordenadas hardcodeadas de posicionamiento (ver Tarea 0).

Los 6 roots de estas escenas ya son `anchor_right=1.0, anchor_bottom=1.0`
(full-rect) — confirmado por la sesión pilar antes de escribir este plan,
no hace falta tocarlos. El trabajo está en sus nodos hijos.

## Tarea 0 — por cada mesa, antes de tocar el `.tscn`

1. `git grep -n "900\|1080" scripts/<juego>/*.gd scripts/net/*_table_controller.gd`
   (o el `.gd` de la propia escena, `scenes/<mesa>_table_net.gd`) — si
   aparece una constante de posición/tamaño hardcodeada contra el canvas
   viejo (no un valor de juego como "meta a 1000 fichas", que no tiene
   nada que ver), anótalo. El patrón de Blackjack (`seat_anchor()` ya
   relativo a `size`) es la expectativa, pero cada mesa se construyó por
   un agente distinto — no asumas que se cumple sin comprobarlo.
2. Si encuentras una constante así, decide si el fix es de `.tscn`
   (nodo mal anclado) o de `.gd` (matemática de posición mal hecha) antes
   de aplicar la receta genérica — la receta de la spec es solo para
   nodos `.tscn`, no cubre lógica.

## Tarea 1 — por cada mesa, conversión de `.tscn`

Lee el archivo completo, identifica cada nodo hijo con `layout_mode = 0`
(o sin anchors explícitos) y offsets ajustados al canvas 900x1080 viejo.
Clasifica cada uno con la tabla de la spec (rect completo / esquina fija
/ borde derecho / borde inferior / esquina inferior-derecha / centrado) y
aplica el anchor+offset correspondiente. Presta atención especial a:
- Paneles de apuesta (`BetSidebarPanel`) — normalmente esquina superior
  izquierda, sin cambio (igual que en Blackjack).
- Barra HUD (`CasinoHudBar`) — banda inferior, ancho completo.
- Cualquier fila de botones de acción — normalmente banda inferior.
- Componentes propios de cada mesa dibujados con `_draw()` a mano
  (`RouletteWheelDisplay`, `PlinkoBoard`, grid de `MinesCell`,
  `DiceThresholdSlider`, `CrashGraph`, historial/badges de Ruleta) —
  igual que en Blackjack, si su nodo contenedor está bien anclado a
  rect-completo o al borde que le toca, su propio `_draw()` interno no
  necesita tocarse (ya usan `size` relativo, confirmado en la spec) —
  **verifícalo leyendo el `.gd` de cada uno igualmente**, no lo des por
  hecho solo porque Blackjack lo cumplía.

## Tarea 2 — verificación por mesa

1. `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit --path .`
   tras cada mesa (o al final de las 6, tu decisión) — nada debería
   romperse, ningún test existente comprueba offsets/anchors exactos.
2. Verificación visual sin depender de clics (el clic sintético no es
   fiable en este entorno, ver gotchas de sesiones anteriores en
   `todo_agents.md`): lanza el juego con `--resolution 1600x900` (un
   aspect ratio bien distinto del 900x1080 de diseño) y compara con
   `--resolution 900x1080` (el de siempre) usando captura por
   `PrintWindow` sobre el handle de la ventana "Casino Pixel (DEBUG)"
   (método ya documentado y probado en sesiones anteriores, funciona sin
   foco). Solo necesitas confirmar que nada queda pegado en una esquina
   con un hueco enorme al otro lado — no hace falta navegar con clics
   para ver el lobby en sí mismo a las dos resoluciones, ya es suficiente
   para pillar la mayoría de los problemas de anclaje.
3. Dejar constancia en el reporte final de qué mesas se pudieron
   verificar visualmente así y cuáles no.

## Tarea 3 — reporte a pilar

Al terminar: qué archivos tocaste, qué constantes hardcodeadas
encontraste en Tarea 0 (si alguna) y cómo las arreglaste, resultado de
tests, resultado de la verificación visual a las dos resoluciones.
Commit + push directo a `main` si todo está en verde (no hace falta rama
propia — es trabajo de layout acotado a 6 archivos que no se solapan con
nada más en curso).

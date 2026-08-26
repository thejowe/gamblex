# Layout responsive real (canvas fijo → adapta a cualquier resolución)

2026-08-25. Decisión tomada con el usuario tras reportar barras negras
(pillarboxing) jugando en su monitor panorámico.

## Problema real

`project.godot` tenía `window/stretch/mode="canvas_items"` +
`window/stretch/aspect="keep"` sobre un canvas de diseño de 900x1080
(vertical). `keep` preserva el tamaño exacto del viewport virtual y rellena
el resto de la ventana con barras negras — en cualquier monitor panorámico
normal (16:9/16:10) eso deja franjas enormes a los lados, no "pantalla
completa" de verdad aunque `window/size/mode=3` (fullscreen) ya estuviera
puesto desde un fix anterior (2026-08-24).

## Dos opciones evaluadas con el usuario

- **B (descartada)**: cambiar el canvas de diseño fijo a otro tamaño
  panorámico (p.ej. 1600x900), mismo sistema de offsets absolutos de
  siempre. Menos trabajo, pero solo cubre bien resoluciones cercanas a
  16:9 — sigue habiendo barra en monitores raros (ultrawide, 4:3).
- **A (elegida)**: `window/stretch/aspect="expand"` en vez de `"keep"` +
  convertir los nodos que dependían de offsets absolutos fijos a anchors
  de verdad. Se adapta a cualquier resolución/aspecto sin barras nunca.
  Coste mayor (toca las 7 mesas + el lobby/HUD), pero es la solución
  correcta permanente, no un parche para un aspect ratio concreto.

Confirmado el comportamiento exacto de `expand` contra la documentación
oficial de Godot antes de tocar nada (no se adivinó): con `canvas_items`
+ `expand`, el viewport efectivo que usan los anchors **crece** para
igualar el aspect ratio real de la ventana — no hay reescalado
proporcional con barras, aparece más canvas visible en el eje que
corresponda. La resolución base (900x1080) sigue fijando la escala de
referencia (tamaños de fuente, `custom_minimum_size`, radios de círculos
dibujados a mano, etc. no cambian), solo crece el área de trabajo.

## Hallazgo importante durante la implementación (abarata el trabajo)

Antes de asumir que hacía falta reescribir lógica GDScript de
posicionamiento en cada juego, se revisó `blackjack_table_net.gd`: la
función `seat_anchor()` que calcula dónde van los jugadores **ya**
calculaba posiciones a partir de `size.x`/`size.y` del `Control` en
tiempo de ejecución, no de constantes 900/1080 hardcodeadas. Mismo patrón
confirmado en los componentes compartidos que se dibujan a mano
(`FeltTablePanel`, `PlinkoBoard`, `MinesCell`, `DiceThresholdSlider`,
`RouletteWheelDisplay`, `CasinoButton`) — todos dibujan relativo a su
propio `size`, ninguno hardcodea el canvas completo.

Conclusión: el problema real está casi enteramente en los **`.tscn`**,
no en el GDScript. Cada nodo hijo que use `layout_mode = 0` con anchors
por defecto (0,0,0,0, "top-left fijo") y offsets ajustados a mano para
que coincidieran con los bordes del canvas viejo de 900x1080 (`900`,
`1080`, o centrado en `450`) se queda pegado a la esquina superior
izquierda cuando el viewport crece — en vez de mover 1 línea de config,
ese nodo necesita que su `anchor_*` apunte al borde que le corresponde
de verdad (derecha, abajo, centro, o rect completo).

**Aun así**, cada mesa nueva debe revisarse por si acaso tiene lógica
GDScript con constantes de posición hardcodeadas — no asumir que el
patrón de Blackjack se cumple en las 6 restantes sin comprobarlo.

## Receta de conversión (aplicada ya a Blackjack + `casino_floor.tscn`, referencia para el resto)

Para cada nodo con `layout_mode = 0` (o sin `layout_mode`, que es lo
mismo) y offsets ajustados al canvas 900x1080:

| Rol visual del nodo | Anchors a poner | Offsets |
|---|---|---|
| Cubre todo el canvas (contenedor de cartas/asientos, fondo) | `anchor_right=1.0, anchor_bottom=1.0`, `grow_horizontal=2, grow_vertical=2` | `offset_right=0.0, offset_bottom=0.0` (izq/arriba se quedan en 0) |
| Pegado a la esquina/borde superior-izquierdo (sidebar de apuesta, panel fijo) | Sin cambio — el default (0,0,0,0) ya es correcto | offsets tal cual |
| Pegado al borde derecho (icono de mazo, botón que vive a la derecha) | `anchor_left=1.0, anchor_right=1.0`, `grow_horizontal=0` | offsets = valor_viejo − 900 (negativos) |
| Pegado al borde inferior (HUD, fila de botones de acción, labels de meta/batalla) | `anchor_top=1.0, anchor_bottom=1.0`, `grow_vertical=0` | offsets = valor_viejo − 1080 (negativos) |
| Pegado a una esquina inferior-derecha (botón "Volver") | combina las dos anteriores | offsets = (valor_x − 900, valor_y − 1080) |
| Centrado horizontalmente (label de valor de mano, bloque de tarjetas del lobby) | `anchor_left=0.5, anchor_right=0.5`, `grow_horizontal=2` | offsets = valor_viejo − 450 (mitad izq/mitad der del ancho del bloque) |

Diff real de referencia ya mergeado a `main`: commit `0b9568d`
(`scenes/blackjack_table_net.tscn`, `scenes/casino_floor.tscn`,
`project.godot`). Antes de tocar una mesa nueva, mirar ese diff con
`git show 0b9568d` — es la conversión completa, nodo por nodo, con los
mismos roles que se van a repetir en las otras 6 mesas.

## Fuera de alcance de esta ampliación

- Pixel art (`assets/pixels/`, ampliación aparte, en curso en paralelo).
- Reskin visual de Póker (sigue sin foto de referencia).
- Nada de esto cambia lógica de juego/red — es puro layout visual.

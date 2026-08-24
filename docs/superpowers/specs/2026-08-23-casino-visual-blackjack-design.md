# Ampliación v1.3: fundación visual de casino + reskin de Blackjack

**Fecha:** 2026-08-23
**Estado:** aprobado por el usuario, listo para plan de implementación
**Referencia visual:** `docs/superpowers/specs/references/blackjack-evolution-reference.png`
(captura de "First Person Blackjack" de Evolution Gaming — look objetivo para
esta fase: tapete verde, borde de madera, fichas apiladas, cartas reales,
botones de decisión, HUD inferior).

## Contexto

Los Planes 1-13 dejaron el juego funcionalmente completo pero visualmente en
blanco: cada mesa es `Label`/`Button` planos con el tema por defecto de
Godot, sin representación real de cartas ni fichas (confirmado leyendo
`scenes/blackjack_table_net.tscn` — todo el contenido son etiquetas de texto
tipo "Banca: 0", "Asiento 0: libre"). No existe carpeta `assets/`, ni
texturas, ni theme resource en el repo.

El usuario quiere ahora un pase de diseño **básico pero intencional**,
estética de casino online, con animación — sin llegar todavía al pixel art
final (eso es una fase futura separada). Esta fase es el primer sub-proyecto:
construir un sistema de componentes visuales reutilizable y aplicarlo por
completo a Blackjack. Las demás mesas se reskinarán una por una en fases
posteriores, reutilizando estos mismos componentes, con referencias
adicionales que el usuario irá aportando por juego.

## Decisiones ya tomadas con el usuario

- **Sin pipeline de arte**: todo el look se logra con dibujo procedural de
  Godot (`_draw()`, `StyleBoxFlat`, `Tween`) — cero archivos de imagen. Look
  plano/vectorial "afinado", no foto-realista como la referencia, y fácil de
  reemplazar íntegramente cuando llegue la fase de pixel art.
- **Fundación compartida primero**: los componentes viven en
  `scripts/ui/casino/` y `scenes/ui/casino/`, pensados desde el principio
  para las 7 mesas, no solo Blackjack.
- **Animación completa en esta fase**: reparto de cartas con movimiento,
  fichas volando a la apuesta, celebración de victoria — no solo estático.

## Arquitectura

### Componentes compartidos (`scripts/ui/casino/`, `scenes/ui/casino/`)

1. **`casino_theme.gd`** — clase con constantes de color/paleta: verde
   fieltro (claro/oscuro para el degradado), marrón madera (claro/oscuro),
   dorado de acento, blanco de carta, texto crema. Sin lógica, solo datos,
   para que las 7 mesas usen los mismos tonos.

2. **`felt_table_panel.tscn` / `.gd`** — `Control` con `_draw()`: óvalo verde
   con degradado radial de dos tonos (`draw_colored_polygon` con puntos
   interpolados en color, o dos óvalos superpuestos con alpha), borde marrón
   grueso tipo madera alrededor, y método `draw_curved_text(text, radius,
   start_angle, font)` que dibuja cada carácter rotado a lo largo de un arco
   (usado para "BLACKJACK PAYS 3 TO 2" / "INSURANCE PAYS 2 TO 1", igual que
   la referencia). Parametrizable en tamaño para que otras mesas la reutilicen
   a otra escala.

3. **`casino_chip.tscn` / `.gd`** — `Control` pequeño (~48px), `_draw()`
   dibuja un disco de color sólido + anillo de muescas (rectángulos
   alternados alrededor del borde, como una ficha real) + el valor
   (`denomination: int`) centrado en texto. Paleta de color por denominación
   fija en `casino_theme.gd` (ej. 50 = naranja, a definir en implementación
   según las denominaciones reales que usa Blackjack).

4. **`playing_card.tscn` / `.gd`** — `Control` (~70x100), propiedades
   exportadas `rank: int` (1-13, mismo rango que `Card.rank`), `suit: int`
   (mismo enum `Card.Suit`), `face_up: bool`. Cuando `face_up`, dibuja
   rounded-rect blanco + rank/palo (símbolo Unicode ♠♥♦♣, rojo para
   corazones/diamantes, negro para picas/tréboles) arriba-izquierda y
   centrado grande. Cuando no, dibuja un reverso con patrón simple
   (rombos/rejilla sobre fondo azul o rojo). Método `flip() -> void` anima
   con `create_tween()`: `scale.x` de 1→0 (150ms), cambia `face_up` a mitad
   de la animación, `scale.x` de 0→1 (150ms).

5. **`casino_button.tscn` / `.gd`** — extiende `Button`, con `StyleBoxFlat`
   para los estados normal/hover/pressed/disabled generados por código
   (no `.tres` sueltos) y una variante de color exportada (`enum Variant {
   NEUTRAL, POSITIVE, NEGATIVE }` — gris/verde/rojo, como Double/Hit/Stand en
   la referencia). Tween de escala 1.0→1.05 en hover (100ms), 1.0→0.95 en
   press.

6. **`casino_hud_bar.tscn` / `.gd`** — barra inferior oscura con `Label`s
   para Balance y Apuesta Total en texto dorado, reemplaza los `Label`s
   sueltos que hoy están dispersos por la escena.

Estos 6 componentes son las únicas piezas nuevas de UI genérica. No hay
lógica de juego en ninguno — todos son presentacionales, reciben datos por
propiedad/parámetro y no conocen `TableController` ni RPCs.

### Reconstrucción de la escena de Blackjack

`scenes/blackjack_table_net.tscn` se reconstruye sobre los componentes de
arriba, manteniendo intacto el `TableController` existente y su contrato
(`state_changed`, `chips_won`, `sit()/bet()/hit()/stand()`):

- `FeltTablePanel` de fondo, con el texto curvo de reglas.
- Fila de fichas decorativas arriba (instancias de `CasinoChip`, estáticas,
  como en la referencia — no interactivas).
- Slots de mano por asiento: hasta 4 asientos, instancias de `PlayingCard`
  en abanico (posición calculada, no hardcodeada por asiento para que
  escale con `SEAT_COUNT`), etiqueta de valor de mano en círculo oscuro
  superpuesto (como el "20"/"5" de la referencia).
- Mano del dealer arriba centro, misma lógica de `PlayingCard` + valor.
- Ficha(s) de apuesta como `CasinoChip` en el punto de apuesta de cada
  asiento activo.
- Fila de botones Hit/Stand/Double/Split como `CasinoButton` (Double/Split
  deshabilitados visualmente si no aplican — la lógica de habilitación real
  de Double/Split no existe todavía en `BlackjackTableState`, así que quedan
  deshabilitados siempre en esta fase; no es objetivo de este plan añadir
  esa lógica de juego).
- `CasinoHudBar` abajo con Balance/Apuesta Total, más el botón de
  Sentarse/Apostar existentes reestilizados como `CasinoButton`.

La vista sigue siendo un observador puro de `state_changed`: en cada
actualización compara el estado anterior contra el nuevo para decidir qué
animar (carta nueva → deal, `chips_won` → celebración), pero nunca inicia
una RPC nueva ni cambia el contrato de `TableController`.

### Extensión de datos: `BlackjackTableState.to_dict()`

Único cambio fuera de la capa visual, y el único justificado: hoy
`to_dict()` solo expone `hand_value` (int) por asiento y `dealer_value`
(int) — no hay forma de dibujar cartas reales sin esto. Se añade, siguiendo
el mismo patrón que ya usa `poker_table_state.to_dict()` (`{"rank":
card.rank, "suit": card.suit}` por carta):

- Por asiento: `"hand": [{"rank": .., "suit": ..}, ...]` (además de
  `hand_value`, que se mantiene tal cual).
- Nivel de mesa: `"dealer_hand": [...]` con la misma forma, **excepto** que
  mientras `round_active == true`, el segundo elemento (la carta tapada del
  dealer) se serializa como `{"hidden": true}` en vez de rank/suit — igual
  que la mecánica clásica de blackjack y la referencia visual (dealer
  muestra una carta arriba, una tapada, hasta que termina la ronda). Cuando
  `round_active` pasa a `false` tras `_resolve_round()`, la carta se sirve
  completa.

Ninguna función de apuesta/turno/pago (`sit`, `place_bet`, `hit`, `stand`,
`_resolve_round`, `_resolve_seat_payout`) cambia. Es un cambio aditivo y de
solo-lectura en el serializador. Test nuevo en
`tests/unit/test_blackjack_table_state.gd` que verifica: shape de `hand`
por asiento tras repartir, que la 2ª carta del dealer llega oculta durante
`round_active` y completa después de resolver la ronda.

### Animación

- **Reparto de cartas**: al detectar en `_on_state_changed` que una mano
  tiene más cartas que en el estado anterior, instanciar la(s) `PlayingCard`
  nuevas en la posición del "mazo" (esquina superior derecha, como el ícono
  de carta-reverso de la referencia) y animar con `create_tween()` posición
  + rotación hacia el slot destino, con `stagger` de ~150ms entre cartas si
  llegan varias a la vez.
- **Fichas a la apuesta**: al pulsar Apostar, instanciar/mover una
  `CasinoChip` desde la zona del HUD hasta el punto de apuesta del asiento,
  con dos tweens paralelos en X/Y con easing distinto (simula un arco sin
  necesitar curva Bezier explícita).
- **Victoria**: al recibir la señal `chips_won(player_id, amount)`, flash
  dorado (`modulate` pulse con tween) sobre la mano del asiento ganador +
  `CPUParticles2D` de confeti, ráfaga corta (~1s), centrado en esa mano.
- **Botones**: hover/press ya cubiertos en `casino_button.gd` (sección
  anterior), no requiere código adicional en la escena de Blackjack.

### Testing y verificación

GUT no valida contenido visual (dibujo/Tweens no son verificables por
aserción). Cobertura real de esta fase:

- Test unitario nuevo para la extensión de `to_dict()` descrita arriba
  (lógica pura, sí verificable).
- Los 215 tests existentes deben seguir en verde tras el cambio (correr
  suite completa, con la caché de clases reconstruida — ver gotcha de
  `todo_agents.md` sobre `global_script_class_cache.cfg`).
- Verificación visual manual: el agente debe correr el proyecto (Godot
  estándar 4.7.1, `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`,
  con Steam corriendo) y describir o capturar cómo se ve la mesa, y el
  usuario debe confirmarlo en vivo antes de dar la fase por cerrada — mismo
  patrón ya usado para cerrar el fix de resolución de pantalla.

### Fuera de alcance de este plan

- Reskin de cualquier otra mesa (Ruleta, Póker, Dice, Crash, Mines, Plinko,
  Lobby) — fases posteriores, un agente por mesa, reutilizando estos mismos
  componentes.
- Cualquier cambio a reglas de juego (Double/Split reales, lógica de
  apuestas, payout).
- Pixel art final — fase separada y futura, sustituirá esta capa
  procedural por completo.
- Sonido/música.

## Agente y rama

Un solo agente nuevo, `plan14-casino-visual`, trabaja en su propio worktree
aislado (lección del merge de Planes 9-11: nunca tocar el checkout
compartido de pilar) en rama `feature/casino-visual-blackjack`. No toca
ninguna otra mesa ni archivo fuera de: `scripts/ui/casino/`,
`scenes/ui/casino/`, `scenes/blackjack_table_net.tscn`/`.gd`,
`scripts/blackjack/blackjack_table_state.gd` (solo `to_dict()`), y su test
nuevo.

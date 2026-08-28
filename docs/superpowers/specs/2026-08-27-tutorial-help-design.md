# Spec: tutorial / "Cómo jugar" por mesa — Ampliación v1.7, Agente 28

## Contexto

Auditoría de la sesión pilar (2026-08-27): ninguna de las 7 mesas tiene
botón de ayuda ni overlay de reglas — grep exhaustivo de "tutorial"/
"how_to_play"/"reglas" en `scripts/`/`scenes/` sin resultados. Comparado
contra casino online exitoso (Evolution Gaming, PokerStars): todas las
mesas reales tienen un icono "?" que explica reglas y pagos sin salir de
la mesa. Este agente es independiente del resto de la Ampliación v1.7 —
no depende de `AudioManager` (plan25) ni de nada más, puede correr en
paralelo con cualquiera de los otros cinco.

## Decisión de diseño

Un componente reusable `HelpOverlay` (modal semi-transparente, botón
"Cerrar"), instanciado una vez por mesa con texto de reglas propio
pasado por `@export`/setter — mismo patrón que `PlayingCard`/`CasinoChip`
(componente genérico + datos inyectados), no 7 escenas de overlay
distintas.

Botón "?" (`CasinoButton`, variante `NEUTRAL`, 36×36px, texto "?") en
cada mesa. **No hay una esquina única válida para las 7** — Blackjack
(Plan 14, tapete verde) y las otras 6 (Plan 16+, panel oscuro) tienen
layouts distintos entre sí, y ya ocupan zonas distintas de la parte
superior (p.ej. Dice tiene `BetSidebarPanel` en la esquina superior
izquierda dejando la derecha libre; Blackjack tiene `DeckIcon` en la
esquina superior derecha). El agente debe **leer el `.tscn` real de cada
mesa** antes de decidir dónde va su botón "?" en esa mesa concreta — no
asumir que la misma esquina sirve para las 7. Usa anchors reales
(patrón ya establecido desde Plan 23), nunca offsets absolutos nuevos
sin anchor.

## Texto de reglas por juego (contenido, verificado contra el código real)

- **Blackjack** (`scripts/blackjack/blackjack_table_state.gd`,
  `blackjack_game.gd`): pide cartas para acercarte a 21 sin pasarte.
  Ganas si tu mano vale más que la del crupier sin pasarte de 21 — pagas
  el doble de tu apuesta. Empate (mismo valor): recuperas tu apuesta.
  Te pasas de 21: pierdes la apuesta. El crupier también se planta o
  pide según sus propias reglas.
- **Ruleta** (`scripts/roulette/roulette_table_state.gd`,
  `_payout_multiplier`): apuesta a un número exacto (pago 36×: 35 a 1 +
  tu apuesta), a rojo/negro o par/impar (pago 2×: 1 a 1), o a una docena
  de 12 números (pago 3×: 2 a 1). La bola cae en un número del 0 al 36.
- **Póker** (`scripts/poker/poker_table_state.gd`,
  `poker_hand_evaluator.gd`): Texas Hold'em estándar — 2 cartas propias +
  5 comunes, ronda de apuestas (pasar/igualar/subir/retirarse), gana la
  mejor mano de 5 cartas en el showdown.
- **Dice** (`scripts/dice/dice_table_state.gd`, `multiplier()`): elige un
  umbral y si el resultado va a ser mayor o menor que ese umbral. Cuanto
  más difícil el umbral elegido (menor probabilidad de acertar), mayor el
  multiplicador — fórmula `99 / probabilidad%`, el 1% de margen de casa ya
  está descontado ahí.
- **Crash** (`scripts/crash/crash_table_state.gd`, `multiplier_at`):
  el multiplicador sube con el tiempo desde 1.00× — retira tus fichas
  antes de que "explote" (punto aleatorio decidido al apostar, oculto
  hasta que pasa) o pierdes toda la apuesta.
- **Mines** (`scripts/mines/mines_table_state.gd`, `multiplier()`):
  elige tamaño de grid y número de minas ocultas. Cada casilla segura que
  destapas sube el multiplicador; retira cuando quieras. Destapar una
  mina pierde la apuesta entera.
- **Plinko** (`scripts/plinko/plinko_table_state.gd`,
  `slot_multiplier`): suelta la bola, rebota por filas de clavijas
  (elige cuántas filas, 8 a 16) y cae en una casilla con un multiplicador
  — las casillas de los extremos pagan mucho más que las del centro.

Redacta esto en tono directo, sin jerga, 3-5 frases por juego máximo —
el texto de arriba es la base factual, el agente puede pulir la
redacción siempre que no cambie ningún número/regla.

## Archivos que toca (y solo esos)

- `scripts/ui/casino/help_overlay.gd` + `scenes/ui/casino/help_overlay.tscn` (nuevo, componente compartido).
- Las 7 `scenes/*_table_net.tscn` + `.gd` (añadir botón "?" + instanciar overlay con su texto).

**No toca**: `casino_floor.gd`/`.tscn`, `AudioManager`, ningún
`*_table_state.gd`/`*_game_logic.gd` (solo lectura, para sacar el texto
de reglas — cero cambios de lógica de juego).

## Fuera de alcance

- Tutorial interactivo paso a paso (esto es solo texto estático).
- Traducción a otros idiomas.
- Locución/voz.

## Verificación

- Tests GUT: `HelpOverlay` se instancia, `set_rules_text(text)` (o
  equivalente) cambia el label visible, `Cerrar` oculta el overlay.
  Un test de humo por mesa: el botón "?" existe en la escena y su
  `pressed` muestra el overlay (`overlay.visible == true`).
- Revisión visual (aunque sea solo por `.tscn`/coordenadas, sin Godot en
  vivo): confirmar que el botón "?" no se solapa con ningún nodo
  existente en ninguna de las 7 mesas — calcula los rects, no asumas.

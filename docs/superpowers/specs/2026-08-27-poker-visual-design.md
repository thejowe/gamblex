# Spec: reskin visual de Póker — Agente 31

## Contexto

Última de las 7 mesas sin reskin — quedó pospuesta desde la Ampliación
v1.4 por no tener referencia. El usuario aportó `poker.webp` (guardar
copia en `docs/superpowers/specs/references/poker-reference.webp` antes
de empezar, mismo patrón que las otras 6 referencias).

La referencia (app tipo PPPoker) es una **mesa de fieltro ovalada**, no
el panel oscuro de las otras 5 mesas (Ruleta/Dice/Crash/Mines/Plinko de
Plan 16+) — mismo lenguaje visual que ya tiene Blackjack (Plan 14):
tapete verde, riel de madera, cartas y fichas dibujadas por código. Por
eso este agente **reutiliza los componentes de Blackjack**
(`FeltTablePanel`, `PlayingCard`, `CasinoChip`, todos en
`scripts/ui/casino/`), no los de Ruleta/Dice/Crash/Mines/Plinko
(`BetSidebarPanel`/`CasinoHudBar`).

`scripts/poker/poker_table_state.gd` y `scripts/net/poker_table_controller.gd`
ya están completos y no se tocan — `SEAT_COUNT := 6` coincide con la
referencia. `to_dict(viewer_player_id)` ya expone todo lo necesario:
`seats` (cada uno con `player_id`/`balance`/`current_bet`/`folded`/
`hole_cards`, `hole_cards` vacío si no eres tú ni estás en showdown),
`community_cards`, `pot`, `current_bet`, `min_raise`, `active_seat_index`,
`betting_round`, `hand_active`, `dealer_button_index`,
`last_winner_seats`.

## Qué reutiliza (no reinventar)

- `FeltTablePanel` (`_draw()` con tapete + riel) como fondo, tal cual
  Blackjack.
- `PlayingCard` (`rank`/`suit`/`face_up`, ya soporta dorso) para cartas
  comunitarias y de cada asiento — `face_up = true` para las tuyas
  siempre, para las de otros solo si `hole_cards` no viene vacío
  (showdown) o al terminar la mano.
- `CasinoChip` (`scripts/ui/casino/casino_chip.gd`,
  `CasinoTheme.CHIP_COLORS`) para representar `current_bet` de cada
  asiento — no hace falta contar fichas exactas, un stack simple (1-3
  fichas apiladas según magnitud de la apuesta) basta, mismo criterio
  visual que Blackjack.
- `CasinoButton` para Sentarse/Repartir/Retirarse/Pasar/Igualar/Subir —
  variantes: `NEGATIVE` para Retirarse, `POSITIVE` para Repartir/
  Igualar/Subir, `NEUTRAL` para el resto.
- `HelpOverlay` + `RULES_TEXT` ya existen en `scenes/poker_table_net.gd`
  (Plan 28) — no los toques, solo reposiciona el botón "?" si el layout
  nuevo lo tapa.
- `AudioManager.play_sfx("card")` al repartir/mostrar cartas nuevas,
  `"chip"` al apostar/igualar/subir, `"win")` cuando `last_winner_seats`
  incluye tu asiento, `"lose"` cuando la mano termina y no estás entre
  los ganadores (solo si estabas sentado y no te retiraste antes —
  no sonar derrota a quien se retiró voluntariamente).

## Qué construye nuevo

- **`seat_anchor_oval(seat_index, seat_count)`**: función de
  posicionamiento nueva (Blackjack's `seat_anchor` es una fila recta, no
  sirve aquí) — distribuye los 6 asientos en una elipse alrededor del
  tapete, dejando el hueco inferior-central para tus propias cartas /
  la fila de botones de acción (igual que la referencia, donde el
  jugador humano no tiene avatar propio, solo sus cartas abajo). Debe
  ser responsive (relativa a `size` del `Control`, no offsets
  hardcodeados — regla del proyecto desde Plan 23).
- **Avatar de asiento**: círculo procedural simple (`_draw()` con
  `draw_circle`) con la inicial del nombre del jugador (`_display_name`
  ya existe) sobre un color determinista derivado del `player_id` (p.ej.
  hash a un color de una paleta fija de 6-8 tonos) — **no hay fotos de
  avatar reales ni banderas de país en este proyecto**, es un
  placeholder con identidad visual mínima, no una réplica exacta de la
  referencia.
- **Ficha de dealer ("D")**: círculo dorado pequeño con "D" junto al
  asiento en `dealer_button_index`.
- **Bote**: label centrado arriba de las cartas comunitarias, estilo
  `CasinoTheme.GOLD_ACCENT`, "Bote: N" (ya existe el dato, solo cambia
  el estilo del label actual).
- **Banner de ganador**: al terminar una mano con `last_winner_seats`
  no vacío, un banner corto (2-3s, tween de aparición/desaparición,
  reutiliza el patrón `ResultFlash`/tween ya visto en Dice/Mines) cerca
  del asiento ganador, texto "¡Gana [nombre]!" — no es la pantalla de
  victoria/derrota de Plan 26 (esa es de partida completa/Modo Batalla),
  esta es un feedback de mano suelta, con foco visual, no un overlay
  modal a pantalla completa.
- **Mejora opcional de UX de apuesta** (si el tiempo alcanza, no
  bloqueante): hoy "Subir" siempre sube exactamente `current_bet +
  min_raise` sin poder elegir cantidad — un `HSlider` simple entre
  `current_bet + min_raise` y tu `balance`, con un label mostrando el
  valor elegido antes de confirmar, llamando a
  `table_controller.raise_bet(seat, valor_elegido)` (interfaz ya
  existente, ningún cambio de lógica de juego). Si no da tiempo, el
  botón "Subir" actual (incremento fijo) se queda como está — no es un
  bloqueante para cerrar la tarea.

## Fuera de alcance

- Banderas de país, fotos de avatar reales, emojis de reacción
  (risa/enfado de la referencia) — sin backend ni pipeline de arte para
  eso.
- Opciones "Move Table"/"Straddle"/"Global Cash Game Sit-out" de la
  referencia — funciones específicas de PPPoker sin backend en este
  proyecto, no existen en `PokerTableState`.
- Cambiar reglas, ciegas, o cualquier lógica de `poker_table_state.gd`/
  `poker_table_controller.gd` — cero ediciones ahí, es puramente capa
  visual sobre datos ya expuestos por `to_dict()`.
- Animación de reparto carta-por-carta con vuelo (como Blackjack Plan 14
  sí tiene) — deseable pero no bloqueante; si se hace, reutilizar el
  patrón de tween de Blackjack, no inventar uno nuevo.

## Verificación

- Tests GUT existentes de estructura de escena
  (`tests/unit/test_poker_table_scene_structure.gd` si existe, o
  crearlo si no) deben confirmar que los nodos nuevos existen sin
  romper los que Plan 28 (tutorial) ya puso (`HelpButton`/
  `HelpOverlay`).
- `_display_name`/`_card_name` ya no se usan para pintar UI (eran solo
  para los Labels de texto plano que este agente reemplaza) — si dejan
  de usarse en ningún sitio tras el reskin, puede borrarlos; si el help
  overlay u otro sitio los sigue necesitando, déjalos.
- Verificación en vivo: **no será posible confirmar una mano completa
  con 6 jugadores reales** (mismo bloqueador de siempre — solo hay una
  cuenta Steam disponible en esta máquina). Verificar con estado
  simulado en tests + revisión visual de una sola sesión sentada
  (headless, capturas si el entorno lo permite) es suficiente para
  cerrar la tarea.

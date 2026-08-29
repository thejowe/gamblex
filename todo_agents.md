# Todo Agents — Casino Multijugador

## Sesiones pilar

Este documento lo mantiene una **sesión pilar**: la sesión orquestadora que
decide qué agente toca, verifica lo entregado contra el repo real, y le da
al usuario el prompt exacto para cada sesión de agente. Su rol completo
está en `.claude/agents/pilar.md`. Si necesitas abrir otra sesión pilar
(nueva ventana, o porque esta se cerró), el prompt para arrancarla es:

> Actúa como la sesión pilar del proyecto de casino multijugador — lee y
> sigue al pie de la letra `.claude/agents/pilar.md`, y luego revisa
> `todo_agents.md` y el estado real del repo (`git pull`, `git log
> --oneline -20`) antes de decirme nada.

## Cómo funciona

La sesión pilar define qué hace cada agente y en qué orden. Cada agente
tiene su definición completa (rol, contexto, plan a
ejecutar o a escribir, rama, formato de reporte) en `.claude/agents/`, así
que el prompt que pegas en la sesión nueva es siempre el mismo formato corto:

> Actúa como el agente `<nombre>` — lee y sigue al pie de la letra
> `.claude/agents/<nombre>.md`.

Abre una sesión nueva de Claude Code por agente, en la misma carpeta del
repo (`C:\Users\Usuari\Downloads\gablex`), pégale ese prompt. Cuando termine
y haga commit/push, vuelves a esta sesión pilar y te digo si el siguiente
agente ya puede arrancar. Esto también deja el terreno listo para que en el
futuro esta sesión pilar lance varios de estos agentes a la vez (Agent tool,
`subagent_type` = el nombre del agente) en vez de que tú abras las sesiones
a mano una por una.

Repo: https://github.com/thejowe/gamblex (rama `main`)
Spec maestra: `docs/superpowers/specs/2026-08-17-casino-multiplayer-design.md`

Regla de oro: cada agente hace `git pull`/`git checkout` al empezar y
`git commit` + `git push` frecuentes al terminar cada tarea. Los agentes que
van en paralelo (4, 5, 6, 7) trabajan cada uno en su propia rama
`feature/<nombre>` y nunca mergean a `main` ellos mismos — eso lo decide la
sesión pilar para evitar conflictos entre ramas.

---

## Cierre de sesión (2026-08-28, sesión pilar — reskin estructural de Ruleta + ronda con timer)

El usuario aportó una referencia real (mesa clásica de Evolution
Gaming, `docs/superpowers/specs/references/roulette-classic-table-reference.png`)
y pidió tres cosas: (1) que la tabla de apuestas tenga la estructura
clásica de verdad, (2) que la rueda completa se vea durante la apuesta
(ya era así, dibujo procedural siempre visible — no hacía falta
cambiar nada ahí), (3) un temporizador de ~20s para que varios
jugadores de la sala aporten apuestas a la vez en vez de que uno solo
pulse "girar".

Ejecutado directamente por esta sesión pilar (441/441 tests GUT),
commit `37ec7a1`, pusheado:
- `RouletteBettingGrid` reescrito de una fila lineal de 12 columnas a
  la mesa real: 0 verde a la izquierda (abarca las 3 filas), números
  1-36 en **orden de columna** (no en orden de la rueda —
  `WHEEL_ORDER` de `roulette_wheel_display.gd` es un array distinto,
  no se tocó), columnas "2 a 1" a la derecha, docenas debajo, fila
  final 1-18/Par/Rojo/Negro/Impar/19-36.
- `RouletteTableState` gana `BetType.COLUMN_1/2/3` (pagan 2 a 1) y
  `LOW`/`HIGH` (pagan 1 a 1).
- **Cambio de fondo, no cosmético:** las rondas ya no las dispara un
  botón "Girar" que cualquiera pulsa cuando quiere — ahora es una
  ronda compartida de 20s (`ROUND_DURATION_SEC`) donde todos los
  sentados apuestan libremente, y al agotarse el tiempo la mesa gira
  sola y resuelve a todos a la vez
  (`RouletteTableState.advance_time()`, llamado cada frame desde
  `RouletteTableController._process()` en el host — mismo patrón que
  `CrashTableController`, solo retransmite en los cambios de fase, no
  cada frame). 5s de pausa (`RESULT_DURATION_SEC`) para ver el
  resultado antes de reabrir. `SpinButton` eliminado.
- Componente nuevo `RoundTimerBadge`
  (`scripts/ui/casino/round_timer_badge.gd`, anillo de progreso +
  segundos por `_draw()`) — reutilizable si otra mesa necesita una
  ronda temporizada más adelante.

**Verificación visual en editor: no confirmada esta sesión**, mismo
motivo que el cierre anterior (automatización de clic de Windows no
responde en la ventana de Godot, sospecha de desajuste de escalado
DPI, sin investigar todavía). El ajuste de tamaño de la grilla nueva sí
se verificó por código: se recuperó el mismo test de "cabe en la caja
asignada" que existía antes del bug de Plan 22, adaptado al layout
nuevo (`test_grid_fits_within_roulette_table_net_assigned_box`), y
pasa con margen (702×116 de contenido en una caja de 860×230).

Pendiente real: que el usuario confirme visualmente la mesa en juego,
y si algún día se investiga el gotcha de DPI de la automatización de
clic, dejarlo documentado en memoria para no repetir la investigación.

## Cierre de sesión (2026-08-28, sesión pilar — integración de arte, Lobby)

Sesión arrancó encontrando **17 commits locales sin pushear** (arte de
la sesión de cierre anterior, `CasinoArtDirector`) — `todo_agents.md`
seguía diciendo el estado correcto en agentes pero el repo no estaba
sincronizado con `origin`. Pusheado sin incidentes (`c8b3813`).

Retomado `docs/art/ART_INTEGRATION_PLAN.md` desde "Pendiente real" —
el usuario priorizó el ítem Lobby (mayor impacto visible, menor riesgo
técnico). Ejecutado directamente por esta sesión pilar (no delegado a
un agente aparte, tarea acotada a un componente): `LobbyGameCard`
(`scripts/ui/casino/lobby_game_card.gd`, nuevo) sustituye los 7 botones
de texto plano de `CardGrid` en `casino_floor.tscn` por los 7
`lobby/card_*.png` reales (ya `FINAL`, incluyen el nombre del juego
horneado en el arte). Grid 2→4 columnas para el aspecto retrato
96×128→176×235 en pantalla. **432/432 tests GUT** (429 previos + 3
nuevos). Commit `9bff9dd`, pusheado.

**Verificación visual en editor no completada esta sesión** — se abrió
Godot con la escena cargada (0 errores) pero la automatización de clic
de Windows no logró cambiar de pestaña tras 2 intentos con foco
confirmado (sospecha: desajuste de escalado DPI). Se cerró el editor en
vez de seguir insistiendo. Detalle completo en
`docs/art/ART_INTEGRATION_PLAN.md`, sección de cierre 2026-08-28
"Lobby".

Pendiente real, sin urgencia (siguientes ítems de
`ART_INTEGRATION_PLAN.md` "Pendiente real", cada uno necesita una
decisión de diseño antes de tocarse):
- **Confirmación visual en editor de la tarjeta de Lobby** (ver arriba).
- `felt_table_panel.gd` (Blackjack/Póker): ¿queda procedural o se usa
  `felt_table_bg.png` como fondo decorativo?
- Victoria/Derrota (`victory_bg`/`defeat_bg`): requiere rediseñar el
  estilo del `Panel` (`StyleBoxTexture` no reproduce `corner_radius`).
- `roulette_wheel.png` como fondo decorativo tras la rueda interactiva.
- `crash_rocket_idle`/`_launch` sin usar todavía (sin estado
  intermedio en `crash_graph.gd` que los necesite).

Sigue sin cambios, arrastrado de cierres anteriores: playtest real de 2
clientes Steam (Modo Batalla), 6 worktrees viejos sin limpiar, basura
sin trackear en la raíz (`tests/unit/test_poker_table_view.gd.uid`).

## Cierre de sesión (2026-08-27)

Estado al cerrar: **Planes 1-31 completados y mergeados a `main`**
(`494785a`), working tree limpio, todo pusheado a `origin/main`. Ningún
agente desbloqueado esperando prompt ahora mismo — las 7 mesas tienen
reskin visual completo, Ampliación v1.7 (audio/ajustes/pausa/tutorial/
victoria-derrota/carga/créditos/logros/icono) y Ampliación v1.8 (Póker)
cerradas del todo.

Sesión larga: auditoría completa del proyecto pedida por el usuario
("compáralo con juegos exitosos, qué falta") → 6 agentes nuevos (25-30)
escritos (uno a mano por ser fundacional, 5 en forks paralelos — un
fork "reportó éxito" sin escribir nada real, detectado verificando
disco, relanzado) → los 6 verificados y mergeados con 2 bugs reales
encontrados y arreglados por esta sesión antes de cerrar (mensaje de
resultado al revés en Plan 26, test descartado en silencio por GUT en
Plan 29) → verificación en vivo con Steam real pedida explícitamente
por el usuario, encontró y arregló un tercer bug real (splash SVG
inválido) → usuario aportó referencia de Póker → Plan 31 escrito,
verificado (Blackjack sin regresión confirmado) y mergeado.

Pendiente real, no urgente:
- **Confirmación visual en vivo de todo lo de hoy** (Ampliación v1.7
  completa más allá de LobbyMenu/Ajustes/Créditos, y Plan 31/Póker):
  bloqueado por tener solo una cuenta Steam disponible en esta máquina
  — Modo Libre necesita 2 miembros reales para que el host entre a
  `CasinoFloor`. `PauseMenu`, `HelpOverlay` por mesa, `LoadingScreen`
  real, Victoria/Derrota, y la mesa de Póker completa solo se
  confirmaron por código + 429/429 tests, no visualmente en vivo.
- **Playtest real de 2 clientes Steam en Modo Batalla**: sigue sin
  confirmarse (bloqueador de siempre, sin cambios desde el cierre
  anterior).
- **6 worktrees viejos sin limpiar** (`feature+battle-mode`,
  `feature+battle-sync-fix`, `feature+lobby`, `feature+poker`,
  `feature+roulette`, `feature+roulette-visual`) — mergeados hace mucho,
  detectados en cierres anteriores, nunca se han limpiado. No urgente.
- **Basura sin trackear en la raíz** (pngs/webp de referencia sueltos +
  sus `.import`, `tests/unit/test_poker_table_view.gd.uid`) — mismo
  inventario de siempre, nunca confirmado con el usuario si limpiar o
  dejar.

Sin ampliación nueva propuesta todavía — el roadmap de pulido visible
en la auditoría de esta sesión está cerrado del todo. Próximo paso
natural, sin agente creado: ampliación de pixel art real (108 carpetas
reservadas en `assets/pixels/ASSETS.md`, casi todas vacías) para
reemplazar el dibujo procedural — o lo que el usuario traiga.

## Cierre de sesión (2026-08-24)

Estado al cerrar por hoy: **Planes 1-22 completados y mergeados a
`main`** (`e369aae`), working tree limpio, todo pusheado a
`origin/main`. Ningún agente desbloqueado esperando prompt ahora mismo.

Pendiente real, no urgente:
- **Confirmación visual del usuario**: Plan 22 (grid de Ruleta) tiene
  código+tests correctos pero esta sesión pilar no pudo confirmarlo en
  vivo (el clic sintético vía PowerShell/Win32 no registra de forma
  fiable en la ventana de Godot — ver nota en la sección de merge de
  Plan 22 más abajo). Cuando el usuario entre a Ruleta, confirmar que los
  37 números ya se ven completos.
- **Playtest real de 2 clientes Steam en Modo Batalla**: sigue sin
  confirmarse en vivo que el pozo compartido (Plan 15) se comporta bien
  con gente de verdad — el fix de Modo Libre (Plan 21) sí se confirmó en
  vivo por esta sesión, Modo Batalla no.
- **Blackjack/Dice/Crash/Mines/Plinko**: reskins visuales mergeados con
  tests en verde, pero sin confirmación visual de una sesión pilar
  (los agentes que las construyeron sí verificaron, según sus reportes,
  salvo Dice que se saltó ese paso — ver nota en el merge de Plan 16).

Próxima ampliación posible, sin agente creado todavía: reskin visual de
Póker (sin foto de referencia del usuario todavía, explícitamente
pospuesto).

Prompt para la próxima sesión pilar, igual que siempre:

> Actúa como la sesión pilar del proyecto de casino multijugador — lee y
> sigue al pie de la letra `.claude/agents/pilar.md`, y luego revisa
> `todo_agents.md` y el estado real del repo (`git pull`, `git log
> --oneline -20`) antes de decirme nada.

---

## Tabla de agentes

| # | Agente (`.claude/agents/…`) | Encargo | Rama | Estado |
|---|---|---|---|---|
| 1 | `plan1-blackjack` | Base del proyecto + Blackjack en solitario | `main` | ✅ Completado |
| 2 | `plan2-steam` | GodotSteam: init, lobbies, invitaciones, SteamMultiplayerPeer | `main` | ✅ Completado |
| 3 | `plan3-casinofloor` | CasinoFloor compartido + Blackjack multijugador | `main` | ✅ Completado |
| 4 | `plan4-battle` | Modo batalla: equipos, pozo compartido, MatchRules | `feature/battle-mode` (mergeado) | ✅ Completado, mergeado a `main` |
| 5 | `plan5-roulette` | Módulo Ruleta | `feature/roulette` (mergeado) | ✅ Completado, mergeado a `main` |
| 6 | `plan6-poker` | Módulo Póker | `feature/poker` (mergeado) | ✅ Completado, mergeado a `main` |
| 7 | `plan7-freemode` | Modo libre: meta colectiva de grupo | `main` (directo, sin rama) | ✅ Completado, ya en `main` |
| 8 | `plan8-dice` | Dice + define la interfaz base de "ronda independiente por jugador" | `feature/dice` (mergeado) | ✅ Completado, mergeado a `main` (`dad6f7c`) |
| 9 | `plan9-crash` | Crash: multiplicador creciente + cash-out | `feature/crash` (mergeado) | ✅ Completado, mergeado a `main` |
| 10 | `plan10-mines` | Mines: grid con minas + cash-out progresivo | `feature/mines` (mergeado) | ✅ Completado, mergeado a `main` |
| 11 | `plan11-plinko` | Plinko: tablero de clavijas + tabla de multiplicadores | `feature/plinko` (mergeado) | ✅ Completado, mergeado a `main` |
| 12 | `plan12-lobby` | Lobby de selección de juego: rejilla de 7 tarjetas, sala aislada por jugador, HUD persistente | `feature/lobby` (mergeado) | ✅ Completado, mergeado a `main` (`81dd979`) |
| 13 | `plan13-battle-sync-fix` | Fix: `chosen_match_type` nunca se sincroniza host→invitado, rompe modo batalla en vivo (bug real de playtest) | `feature/battle-sync-fix` (mergeado) | ✅ Completado, mergeado a `main` (`406d914`) |
| 14 | `plan14-casino-visual` | Fundación visual de casino (tapete/fichas/cartas/botones/HUD dibujados por código) + reskin completo de Blackjack con animación de reparto/apuesta/victoria | `feature/casino-visual-blackjack` (mergeado) | ✅ Completado, mergeado a `main` (`876526b`) |
| 15 | `plan15-battle-pool-wiring` | Fix: conectar el pozo compartido de Modo Batalla (`TeamChipPool`/`MatchRules`/`BattleController`, ya completo desde Plan 4 pero nunca llamado) a las 7 mesas — cada asiento/jugador usa el `ChipLedger` del equipo en vez de uno individual | `feature/battle-pool-wiring` (mergeado) | ✅ Completado, mergeado a `main` (`876526b`) |
| 16 | `plan16-dark-casino-foundation-dice` | Fundación de panel oscuro compartido (`BetSidebarPanel`) + reskin completo de Dice con slider de umbral arrastrable | `feature/dark-casino-foundation-dice` (mergeado) | ✅ Completado, mergeado a `main` (`6f7f917`) |
| 17 | `plan17-roulette-visual` | Reskin visual de Ruleta: rueda animada, grid de 37 números clicable, historial de resultados | `feature/roulette-visual` (mergeado) | ✅ Completado, mergeado a `main` (`c38e9a6`) — bug de layout del grid arreglado por Plan 22 |
| 18 | `plan18-crash-visual` | Reskin visual de Crash: gráfico de multiplicador creciente en tiempo real | `feature/crash-visual` (mergeado) | ✅ Completado, mergeado a `main` (`c38e9a6`) |
| 19 | `plan19-mines-visual` | Reskin visual de Mines: grid dinámico de casillas con estados tapada/revelada/mina | `feature/mines-visual` (mergeado) | ✅ Completado, mergeado a `main` (`c38e9a6`) |
| 20 | `plan20-plinko-visual` | Reskin visual de Plinko: tablero de clavijas con bola animada y fila de multiplicadores | `feature/plinko-visual` (mergeado) | ✅ Completado, mergeado a `main` (`c38e9a6`) |
| 21 | `plan21-free-mode-shared-pool` | Fix: pozo compartido real en Modo Libre (reemplaza `CollectiveGoal` acumulativo) + pantalla de derrota si el pozo llega a 0 | `feature/free-mode-shared-pool` (mergeado) | ✅ Completado, mergeado a `main` (`c38e9a6`) — confirmado funcionando en vivo |
| 22 | `plan22-roulette-grid-overflow-fix` | Fix: grid de 37 números de Ruleta se sale de la ventana (columnas compartidas con apuestas de fuera más anchas) | `feature/roulette-grid-overflow-fix` (mergeado) | ✅ Completado, mergeado a `main` (`2fc5bb1`) — código+tests verificados, visual pendiente de confirmar (ver nota) |
| 23 | `plan23-responsive-layout` | Layout responsive real: aplicar a las 6 mesas restantes (Ruleta/Póker/Dice/Crash/Mines/Plinko) la conversión de offsets absolutos a anchors que ya se hizo en Blackjack/lobby/HUD | `main` (directo, sin rama) | ✅ Completado, mergeado a `main` (`d9427ac` + fix de causa raíz `ca10e2d`) — ver nota abajo |
| 24 | `plan24-room-lifecycle` | Conectar `LobbyMenu` (huérfana hoy) como pantalla de inicio real: crear/unir/cancelar sala Steam, errores visibles, "Salir de la sala" desde CasinoFloor | `feature/room-lifecycle` (mergeado) | ✅ Completado, mergeado a `main` (`9c95682`) — código+tests verificados línea a línea, visual pendiente de confirmar (ver nota) |
| 25 | `plan25-audio-foundation` | Fundación de audio: autoload `AudioManager`, música+SFX generados proceduralmente (`AudioStreamGenerator`, sin pipeline de audio real), buses `Master`/`Music`/`SFX`, volumen persistido. Fundacional — 26/29/30 dependen de su contrato público | `feature/audio-foundation` (mergeado) | ✅ Completado, mergeado a `main` (`c7575bd`) — 370/370 tests, contrato de 7 funciones verificado exacto |
| 26 | `plan26-victory-defeat-screens` | Pantallas de victoria (nueva, Modo Batalla) y derrota (mejora el `ColorRect` liso actual) temporales/procedurales, con SFX de `AudioManager` | `feature/victory-defeat-screens` (mergeado) | ✅ Completado, mergeado a `main` (`edf370b`) — 395/395 tests en rama; pilar encontró y arregló bug real antes de cerrar (ver nota) |
| 27 | `plan27-loading-screen` | Pantalla de carga/transición procedural para el corte seco Lobby→CasinoFloor | `feature/loading-screen` (mergeado) | ✅ Completado, mergeado a `main` (`6ddd0c6`) — 365/365 tests en rama, auto-merge limpio con Plan 25 en `lobby_menu.gd` |
| 28 | `plan28-tutorial-help` | Componente `HelpOverlay` + botón "?" con reglas reales de cada juego en las 7 mesas | `feature/tutorial-help` (mergeado) | ✅ Completado, mergeado a `main` (`a3949e5`) — 370/370 tests en rama, reglas verificadas contra código real de las 7 mesas, auto-merge limpio con Plan 25 en `dice_table_net.gd` |
| 29 | `plan29-settings-pause-menu` | `SettingsMenu` (volumen vía `AudioManager`, fullscreen/ventana, salir a escritorio) + `PauseMenu` (ESC/`ui_cancel`, nunca pausa el árbol de escena — multijugador) | `feature/settings-pause-menu` (mergeado) | ✅ Completado, mergeado a `main` (`09feb27`) — 400/400 tests en rama; pilar encontró y arregló un test que GUT descartaba en silencio (ver nota) |
| 30 | `plan30-achievements-credits-icon` | Logros de Steam (API GodotSteam confirmada), pantalla de créditos, icono/splash (SVG a mano, sin arte real) | `feature/achievements-credits-icon` (mergeado) | ✅ Completado, mergeado a `main` (`32bae85`) — 390/390 tests en rama, conflicto textual real con Plan 26 en `_on_match_state_changed` (esperado, resuelto combinando ambas) |
| 31 | `plan31-poker-visual` | Reskin visual de Póker (última mesa sin reskin): mesa de fieltro ovalada (referencia real del usuario), reutiliza `FeltTablePanel`/`PlayingCard`/`CasinoChip` de Blackjack (no el panel oscuro de las otras 5), 6 asientos alrededor de un óvalo completo, avatares procedurales, ficha de dealer, banner de mano ganada | `feature/poker-visual` (mergeado) | ✅ Completado, mergeado a `main` (`78bcc18`) — 429/429 tests, Blackjack confirmado sin regresión (36/36 aislado), incluyó la Tarea 6 opcional (slider de subida) |

## Ampliación v1.8: reskin visual de Póker (2026-08-27)

El usuario aportó la referencia que faltaba (`poker.webp`, app tipo
PPPoker) — última de las 7 mesas sin reskin, pospuesta desde la
Ampliación v1.4. Copiada a
`docs/superpowers/specs/references/poker-reference.webp`.

**Decisión de diseño real, no obvia**: la referencia es una mesa de
fieltro ovalada — mismo lenguaje visual que Blackjack (Plan 14), **no**
el panel oscuro moderno que usan Ruleta/Dice/Crash/Mines/Plinko desde
Plan 16. Plan 31 reutiliza `FeltTablePanel`/`PlayingCard`/`CasinoChip`.

**Hallazgo real al inspeccionar el componente a reutilizar**:
`FeltTablePanel._draw()` dibuja hoy solo un **semi-óvalo** (la mitad
superior de una elipse, `_arc_points` recorre `t` de `0` a `PI`) — le
basta a Blackjack (crupier arriba, jugadores en fila abajo) pero Póker
necesita un óvalo completo con 6 asientos alrededor. El plan pide
extender el componente compartido con un flag `full_oval` (por defecto
`false, comportamiento de Blackjack intacto) en vez de duplicarlo o
inventar uno nuevo — con instrucción explícita de confirmar cero
regresión en la suite de tests de Blackjack antes de cerrar esa tarea.

Creado `plan31-poker-visual`, desbloqueado, spec y plan de
implementación completos (6 tareas con TDD, la última — slider de
cantidad al subir apuesta — explícitamente opcional) ya escritos por
esta sesión pilar. Toca `scripts/ui/casino/felt_table_panel.gd` (flag
nuevo) y `scenes/poker_table_net.tscn`/`.gd`. No toca
`scripts/poker/poker_table_state.gd`/`poker_table_controller.gd`
(lógica ya completa desde Plan 6), no toca ninguna otra mesa.

**Merge de Plan 31 (2026-08-27).** Diff revisado línea a línea antes de
mergear: `full_oval` implementado exacto al plan (mismo cálculo de
centro/ángulo, comportamiento por defecto intacto), `seat_anchor_oval`
nuevo, `SeatAvatar` (color determinista por `player_id`, inicial),
`_maybe_play_audio_cues`/`_maybe_show_winner_banner` con guardas
anti-duplicado correctas (comparan contra el estado previo antes de
sobreescribirlo, mismo cuidado que Plan 26 tuvo que aprender a mano).
**429/429 tests** tras reconstruir caché, **Blackjack confirmado sin
regresión** corriendo su suite aislada (36/36) además de la completa —
exactamente lo que pedía el plan antes de dar la Tarea 1 por cerrada.
Incluyó la Tarea 6 opcional (slider de cantidad al subir). Sin
conflictos al mergear (`78bcc18`), mismo gotcha de reformateo de
siempre en `casino_floor.gd`/`icon.svg.import` (descartado).

**Verificación visual en vivo: bloqueada, mismo motivo de siempre.**
Esta sesión lanzó el juego real con Steam corriendo para confirmar la
mesa de Póker en pantalla, pero Modo Libre exige 2 miembros reales en la
sala para que el host entre a `CasinoFloor` (`_on_lobby_chat_update`) —
con una sola cuenta Steam disponible en esta máquina, el host se queda
esperando en el lobby indefinidamente. No se fuerza ningún atajo de
código para saltarse esto. Verificación de código + 429/429 tests es lo
que sostiene el cierre de esta tarea; falta que el usuario confirme
visualmente jugando (o que aparezca una segunda cuenta Steam para que
una sesión pilar futura lo confirme sola).

## Ampliación v1.7: pulido de producto — audio, UI de sistema, polish (2026-08-27)

El usuario pidió una auditoría completa del proyecto comparada contra
juegos casino/party exitosos y "todo lo que falte, ni que sea mínimo".
Hallazgos (grep exhaustivo en `scripts/`/`scenes/`/`autoloads/`/
`project.godot`, excluyendo worktrees/addons): **cero audio** (ni un
`AudioStreamPlayer` en todo el repo), **cero pantalla de ajustes** (sin
control de volumen, sin toggle fullscreen/ventana, sin salir a
escritorio limpio), **cero créditos**, **cero pantalla de carga**
(confirmado explícito en `assets/pixels/ASSETS.md`), **cero pantalla de
victoria real** (Modo Batalla solo tiene texto en un `Label`, confirmado
en el mismo doc), **cero menú de pausa** (`project.godot` no define ni
una acción `[input]`), **cero tutorial/ayuda** por mesa, **cero
logros**. Comparado contra el estándar de Evolution Gaming/PokerStars/
Stumble Guys/Balatro.

Decisión de diseño transversal: mismo criterio "sin pipeline de arte
real" que ya usó Plan 14 para lo visual — audio generado
proceduralmente con `AudioStreamGenerator` (Plan 25), pantallas
temporales dibujadas por código con `CasinoTheme` (Plan 26), icono en
SVG a mano (Plan 30). Nada bloqueado esperando assets reales que aún no
existen.

Seis agentes nuevos (25-30), specs y planes completos ya escritos (la
sesión pilar escribió Plan 25 a mano por ser el fundacional; 5 forks en
paralelo de esta misma sesión pilar escribieron 26-30, mismo patrón que
los forks de Plan 18-20 en la Ampliación v1.4 — un fork del lote inicial
"completó" sin escribir nada real (0 tool calls, respuesta genérica);
detectado por verificación de archivos en disco antes de confiar en la
notificación, relanzado, el reintento sí escribió los 3 archivos de
verdad). Cadena de dependencias real (no solo textual): `plan26` y
`plan29` llaman a `AudioManager.play_sfx`/`set_bus_volume_db` de
`plan25`, así que **no arrancan hasta que `plan25` esté mergeado a
`main`** — mismo criterio que "Dice primero" en la Ampliación v1.1.
`plan27`, `plan28` y `plan30` no dependen de nadie y pueden lanzarse ya
mismo en paralelo con `plan25`.

**Orden de lanzamiento recomendado:**
1. ~~`plan25-audio-foundation` — solo, primero (fundacional)~~ ✅.
   ~~En paralelo: `plan27-loading-screen` y `plan28-tutorial-help`~~ ✅ —
   los tres terminaron, verificados por esta sesión pilar (370/370,
   365/365, 370/370 tests en rama respectivamente) y mergeados a `main`
   en ese orden (`c7575bd` → `6ddd0c6` → `a3949e5`). Auto-merge limpio en
   ambos puntos de solape esperados (`lobby_menu.gd` entre 25/27,
   `dice_table_net.gd` entre 25/28) — sin conflictos textuales de
   verdad, git los resolvió solo. 387/387 tests tras el merge completo
   en `main`, caché de clases reconstruida, único descarte fue el
   reformateo espacios/tabs de siempre en `casino_floor.gd` (gotcha ya
   conocido). Worktrees de los 3 borrados (`git worktree remove --force`
   — solo contenían caché `.import` sin trackear, nada de trabajo real).
2. ~~`plan26-victory-defeat-screens`, `plan29-settings-pause-menu`,
   `plan30-achievements-credits-icon` en paralelo~~ ✅ — los tres
   terminaron, verificados por esta sesión pilar (395/395, 400/400,
   390/390 tests en rama respectivamente) y mergeados a `main` en orden
   26→30→29 (`edf370b`→`32bae85`→`09feb27`). **414/414 tests reales tras
   el merge completo**, caché de clases reconstruida.

**Bugs reales encontrados y arreglados por esta sesión pilar antes de
cerrar la Ampliación v1.7 (ninguno de los dos lo habría pillado un
`git diff` superficial ni una lectura rápida del reporte del agente):**

- **Plan 26** (`eea4404`): `_reason_label(reason)` devolvía el mismo
  texto para el mensaje de victoria y el de derrota — el equipo ganador
  veía "Tu equipo ganó — el equipo rival llegó antes a la meta" (al
  revés). Arreglado añadiendo un booleano `i_won` que decide la
  perspectiva. **Nota de proceso**: el fix se hizo primero directo en el
  worktree de la rama pero sin comitear ahí — se perdió al mergear sin
  que el primer intento de merge lo llevara. Reaplicado directo sobre
  `main` tras el merge, comiteado aparte. Para la próxima: si vas a
  arreglar algo en un worktree de un agente antes de mergear, comitéalo
  en esa rama ANTES de volver a la carpeta principal a mergear, o
  hazlo directo sobre `main` después del merge, nunca a medias.
- **Plan 29** (`74f96f9`): `tests/unit/test_casino_floor_pause_menu.gd`
  tenía `var connections := floor.pause_menu.exit_room_requested.get_connections()`
  — `:=` no podía inferir el tipo porque `floor` no está tipado
  (`preload(...).instantiate()`). GUT fallaba a parsear el script y lo
  descartaba en silencio con el mensaje engañoso "Ignoring script...
  because it does not extend GutTest" — sus 3 tests nunca corrían pese a
  que la suite completa decía "All tests passed" con 62 scripts en vez
  de 63. **Este es el mismo gotcha de caché de clases ya documentado
  arriba, pero con una causa distinta** (error de tipado real en el
  test, no caché sin reconstruir) — mismo síntoma engañoso, así que
  cualquier "Ignoring script" en la salida de GUT merece investigarse
  con `-gselect=<nombre>` en vez de descartarse como ruido conocido.

Conflicto textual real (no solo esperado) al mergear Plan 30 sobre
Plan 26: ambos reescribían `_on_match_state_changed` en
`scripts/net/casino_floor.gd` moviendo `var my_team` al mismo sitio —
resuelto combinando la llamada al overlay de victoria (26) con el
`SteamManager.unlock_achievement("BATTLE_MODE_WIN")` (30) dentro del
mismo bloque `if`. Plan 29 mergeó limpio salvo conflictos textuales
triviales (auto-resolubles a mano) en `casino_floor.tscn`/
`lobby_menu.gd`/`lobby_menu.tscn` por tocar las mismas zonas que 26/30
(botones nuevos en `LobbyMenu`, nodos nuevos bajo `Hud`).

**Con esto, la Ampliación v1.7 completa (Agentes 25-30) está mergeada a
`main`.**

## Verificación en vivo real (2026-08-27, pedida explícitamente por el usuario)

Steam no estaba corriendo — lanzado por esta sesión pilar, login ya
guardado (mismo usuario "Jowe el vende trufas" de sesiones anteriores).
Juego lanzado real (`--path .`, sin `--editor`), un solo proceso con
ventana confirmado antes de automatizar clics (mismo gotcha de siempre:
2+ ventanas superpuestas dan clics no deterministas). Método de
siempre: `PrintWindow` para capturar, `SetForegroundWindow`+
`SetCursorPos`+`mouse_event` para clics — funcionó de forma fiable en
esta sesión (usuario no estaba usando el escritorio en paralelo).

**Confirmado funcionando de verdad:**
- `LobbyMenu` arranca limpio, "Crear partida" se habilita solo cuando
  Steam está listo (confirmado con timing: primeros 5-8s tras lanzar,
  "Crear partida"/"Invitar amigos" aparecen deshabilitados hasta que
  `steam_ready` llega).
- Botón "Ajustes" abre `SettingsMenu` con estilo `CasinoTheme` correcto
  (panel navy, borde dorado). **Persistencia de volumen confirmada
  real**: al abrir, "Música" ya aparecía en Mute y los sliders en
  valores no-default — cargados de un `user://settings.cfg` de una
  sesión de prueba anterior (probablemente del propio Agente 29). Se
  volvió a togglear Mute de Música y Pantalla completa con clic real,
  ambos checkboxes reaccionaron. "Cerrar" vuelve a `LobbyMenu` sin
  romper nada.
- Botón "Créditos" navega a `credits_menu.tscn` — texto correcto
  (Godot Engine/GodotSteam/GUT, licencia MIT cada uno), "‹ Volver"
  regresa limpio a `LobbyMenu`.
- "Crear partida" en Modo Libre crea una sala Steam real — `Jugadores:`
  muestra el nombre real de Steam del usuario, "Cancelar"/"Invitar
  amigos" se habilitan. Cancelado limpio después sin dejar la sala
  huérfana.
- Icono de la app (`assets/icon.svg`, ficha de casino navy/dorado) carga
  sin error en `config/icon` (SVG sí soportado ahí).

**Bug real encontrado y arreglado en el mismo hallazgo (`143c248`):**
`boot_splash/image="res://assets/icon.svg"` — Godot **solo admite PNG**
para el splash de arranque, SVG no. El log de consola mostraba el error
exacto (`"The only supported format is PNG. Loading default splash."`)
y caía en silencio al robot de Godot de siempre — justo lo que Plan 30
quería evitar y nadie había detectado porque headless no imprime el
mismo log de arranque de la misma forma / nadie miró la consola con
atención. Reemplazado por `boot_splash/show_image=false` (deja solo
`boot_splash/bg_color`, el navy del tema) — confirmado sin error tras
relanzar. 414/414 tests siguen en verde tras el fix.

**No confirmado en esta sesión, sigue pendiente (bloqueador real, no
nuevo):** `PauseMenu`, `HelpOverlay` (tutorial por mesa), `LoadingScreen`
en la transición real, y las pantallas de Victoria/Derrota solo se
alcanzan dentro de `CasinoFloor`, que en Modo Libre necesita **2
miembros reales en la sala** para que el host transicione — esta sesión
solo tiene una cuenta Steam disponible, mismo bloqueador documentado
desde Plan 13. SFX/música proceduales tampoco se pueden confirmar al
oído por esta sesión (agente de IA, no tiene oídos) — sí se confirmó por
log que `AudioManager` no lanza ningún error en los eventos disparados
(música de lobby, clics de botón) durante toda la sesión de prueba.

Los cuatro (#4-#7) terminaron en paralelo. **Nota para la próxima sesión
pilar**: el Agente 7 no siguió su rama (`feature/free-mode`) — commiteó 8
commits directo sobre `main` local y no los pusheó hasta que esta sesión
pilar lo detectó y empujó. Los Agentes 4/5/6 sí usaron su rama correctamente
(aunque la de poker se creó mal nombrada como `worktree-feature+poker`;
esta sesión la renombró a `feature/poker` antes de mergear).

## Merge de Planes 4-7 (2026-08-19)

Orden de merge: roulette → poker → battle-mode (free-mode ya estaba en
`main`). Todos con conflicto en `scenes/casino_floor.tscn` (cada agente
añadió su mesa sin ver a los demás — esperado, por eso el merge lo hace
pilar y no un agente aislado). Resueltos a mano:

- **Layout**: Blackjack/Ruleta/Póker repartidos en 3 franjas verticales
  (33%/33%/33%) en vez de superpuestos. Sin verificar visualmente en el
  editor (esta sesión no tiene Godot para probar) — el próximo agente o el
  usuario debería abrir el proyecto y confirmar que no se solapan de forma
  rara antes de darlo por bueno.
- **Conflicto real (no solo textual)**: `CasinoFloor` solo admite un script
  en su nodo raíz, y free-mode y battle-mode traían cada uno el suyo
  (`scripts/net/casino_floor.gd` vs `scenes/casino_floor.gd`). Se fusionaron
  en un único script en `scripts/net/casino_floor.gd`, consciente de modo vía
  `SteamManager.chosen_match_type` (`-1` = modo libre, default; enum
  `TeamAssignment.MatchType.*` = modo batalla). Se borró el script duplicado.
- `LobbyMenu` ahora tiene opción "Libre" en el selector de tipo de partida
  (antes solo ofrecía 1v1/2v2/4v4, porque el agente de batalla no sabía del
  modo libre).
- Las 4 ramas feature quedaron pusheadas a origin además de mergeadas
  (registro histórico), aunque ya no hace falta trabajar en ellas.

**Verificación post-merge (2026-08-19, hecha por esta sesión pilar):**
las 5 escenas relevantes cargan e instancian sin error (chequeo headless
con el editor de GodotSteam, sin GPU). Layout corregido dos veces: primero
de columnas a franjas verticales apiladas (`5deaf90`) porque el contenido
interno de cada mesa usa offsets absolutos que no encogían con el ancho de
columna; luego los botones de Ruleta en sí (`cb50b8e`) porque textos largos
como "Apostar Negro 50" desbordaban botones de 120px hacia el vecino de al
lado, a solo 10px. Confirmado visualmente por el usuario tras el segundo
fix. **Sigue sin probarse una partida real de 2+ jugadores** (bloqueado por
la DLL de GodotSteam rota, ver abajo) — el gotcha del self-RPC en
`BattleController`/`CasinoFloor` está mitigado en el código pero no
verificado en vivo.

**Actualización 2026-08-20 (sesión pilar):** el "Error 127 / DLL no carga"
de más abajo **no reprodujo**. Se encontró Godot estándar ya instalado en
esta máquina (`/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`,
coincide con `config/features` de `project.godot`). Corriendo el proyecto
headless con ese binario, el GDExtension de GodotSteam **carga sin error**;
el único fallo es `Steam init failed (2): Cannot create IPC pipe to Steam
client process` — error normal de Steamworks (cliente no corriendo), no un
fallo de carga de librería. Steam está instalado en la máquina
(`C:\Program Files (x86)\Steam`) pero no estaba corriendo en el momento del
test. **Resuelto (2026-08-20, mismo día):** usuario abrió Steam logueado, se
repitió el test headless — `steamInitEx` devuelve `status 0`:
`Steam initialized OK for user: Jowe el vende trufas (76561199230221215)`.
GodotSteam funciona en esta máquina siempre que Steam esté corriendo antes
de lanzar el proyecto. **Bloqueador de entorno cerrado.** Sigue pendiente
el playtest real con 2 clientes (necesita segunda cuenta Steam), ver abajo.

**Nota aparte, no confundir con lo anterior:** el binario custom
`godotsteam.multiplayerpeer.451...` (usado desde el Agente 8/Dice para
correr GUT porque en su momento no había Godot estándar a mano) **sí**
tiene su propio Error 127 al cargar `libgodotsteam...dll` — reproducible
siempre, en cualquier checkout. No bloquea nada porque el Godot estándar
4.7.1 (`/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`)
no tiene ese problema — úsalo para tests desde ahora en vez del binario
custom.

**Gotcha real (2026-08-20, merge de Plan 12):** tras un `git merge` que
trae clases nuevas con `class_name` (p.ej. `LobbyController`,
`CrashRoller`...), correr `--headless --quit` con GUT directamente puede
fallar a resolverlas ("Identifier X not declared in the current scope")
porque `.godot/global_script_class_cache.cfg` no se ha reconstruido — GUT
entonces **descarta esos scripts de test silenciosamente** ("Ignoring
script... because it does not extend GutTest") y sigue diciendo "All tests
passed" con menos tests de los que hay (168 en vez de 211, sin fallar la
suite). Antes de fiarte de un run de tests tras un merge: correr primero
`godot --headless --editor --quit --path .` (fuerza el rescan completo del
proyecto), y solo entonces correr GUT. Ya verificado así en el merge de
Plan 12: 211/211 reales.

<details>
<summary>Nota original (obsoleta, se deja para historial)</summary>

**Bloqueador de entorno, no de código:** la GDExtension de GodotSteam
(`addons/godotsteam/win64/libgodotsteam.windows.template_debug.x86_64.dll`)
no carga en esta máquina — `Error 127` al abrir la librería dinámica. Nadie
lo ha investigado a fondo todavía. Bloquea probar Steam/multijugador real
hasta que se arregle (probable dependencia nativa faltante o mismatch de
build). No lo causó ningún merge de esta sesión.

</details>

## Bug real de playtest — Agente 13 (2026-08-20)

Primer playtest real con 2 cuentas Steam (1v1) tras cerrar Plan 12 encontró
un bug de código genuino, no de entorno: `SteamManager.chosen_match_type`
solo se pone en el cliente del host (`LobbyMenu._on_create_pressed`),
nunca se comunica al invitado. El invitado se queda pensando que está en
modo libre, nunca se une al pozo de equipo, y el host explota
(`goal.to_dict()` sobre `Nil`) cuando el invitado pide el estado de la
meta colectiva equivocada. Diagnóstico completo, causa raíz y fix ya
escritos en `docs/superpowers/plans/2026-08-20-battle-mode-sync-fix.md` y
en `.claude/agents/plan13-battle-sync-fix.md` — Agente 13 desbloqueado,
sin dependencias pendientes.

**Sin confirmar todavía, aparte:** por qué la sesión A (host) no podía
pulsar ninguna tarjeta del lobby. Puede ser síntoma del mismo crash o un
bug aparte — repetir tras el fix de Agente 13 antes de seguir investigando.

**Merge de Agente 13 (2026-08-20):** hecho, sin conflictos. Diff exacto al
plan: `Steam.setLobbyData`/`getLobbyData` en `steam_manager.gd`,
`parse_match_type` + 4 tests, warning de Plinko silenciado. 215/215 tests
tras reconstruir caché de clases. **Gotcha nuevo descubierto en esta
verificación:** correr `godot --headless --editor --quit --path .`
directo sobre el checkout de `main` (no en un worktree) hace que el editor
re-guarde algunos `.gd` abiertos reformateando indentación (espacios↔tabs),
ensuciando `git status` sin cambio de contenido real — pasó dos veces
seguidas con `casino_floor.gd` y `poker_table_state.gd`. Se descartó con
`git checkout --` antes de pushear las dos veces. Para la próxima sesión:
si necesitas reconstruir la caché de clases tras un merge, hazlo, pero
revisa `git status` después y descarta cualquier reformateo antes de
comitear — no es parte del trabajo del agente.

Sigue pendiente el playtest real de 2 clientes para confirmar que el fix
funciona en vivo (host ya no crashea, invitado se une al pozo de equipo,
puede sentarse) y si el freeze de tarjetas de A desaparece con esto.

**Bug de resolución encontrado en vivo (2026-08-21, sesión B, portátil
tope vertical 680px):** `project.godot` no tenía `window/stretch/mode` —
ventana fija 900x1080 sin reescalar. `BackButton` en `casino_floor.tscn`
(offset_top=1005, sin anchor al fondo) quedaba fuera del área visible en
pantallas más bajas. Fix aplicado directo por esta sesión pilar (config de
motor, no lógica de juego, `4626fc0`): `window/size/window_height_override
=680` + `window/stretch/mode="canvas_items"` + `window/stretch/aspect=
"keep"` — reescala toda la UI proporcionalmente en vez de recortarla.
**Corrección (mismo día, feedback del usuario):** el `window_height_override
=680` era un parche solo para ese portátil, no adaptaba a cualquier
resolución. Reemplazado (`f806619`) por `window/size/mode=2` (maximizado)
— la ventana arranca ocupando lo que el SO le dé en cualquier pantalla, y
`canvas_items`+`keep` sigue escalando el diseño 900x1080 proporcionalmente,
en el arranque y en cualquier resize posterior. **Límite conocido:**
escalado proporcional con letterbox (barras negras), no reflow por control
— pantallas con aspect ratio muy distinto a 900x1080 verán barras en vez de
que la UI se reacomode. Reflow real necesitaría retocar anchors escena por
escena (fuera de alcance de este fix). **Confirmado visualmente por el
usuario en sesión B (2026-08-21):** ventana maximiza, BackButton se ve.
Fix cerrado.

**Gotcha ampliado (antes solo se había visto con `--editor`):** correr
`godot --headless --path . --quit` (sin `--editor`) en el checkout
compartido también reformateó espacios→tabs en `scripts/net/casino_floor.gd`
y `scripts/poker/poker_table_state.gd` sin tocarlos. Descartado con
`git checkout --` antes de commitear. Cualquier invocación de Godot en el
checkout compartido de pilar puede ensuciar `git status` — revisar
siempre antes de comitear, no asumir que solo pasa con `--editor`.

Cada archivo `.claude/agents/planN-*.md` ya contiene: qué construye
exactamente, si el plan detallado ya está escrito (Plan 1 y 2) o si el
agente tiene que escribirlo él mismo con `superpowers:writing-plans` (Plan 3
en adelante), qué archivos existentes debe leer como contexto, y el formato
del reporte que te tiene que dar al terminar.

## Orden recomendado

1. ~~Agente `plan2-steam`~~ ✅
2. ~~Agente `plan3-casinofloor`~~ ✅
3. ~~Agentes `plan4-battle`, `plan5-roulette`, `plan6-poker`,
   `plan7-freemode` en paralelo~~ ✅ — mergeados, ver arriba.
4. ~~Agente `plan8-dice`~~ ✅ mergeado a `main` (`dad6f7c`, merge commit
   `merge: Plan 8 Dice module into main`, 2026-08-20, sin conflictos).
5. Agentes `plan9-crash`, `plan10-mines`, `plan11-plinko` — **DESBLOQUEADOS,
   lanzados en paralelo el 2026-08-20 por indicación del usuario.** Cada
   uno en su propia rama (`feature/crash`/`feature/mines`/`feature/plinko`).
   Vuelve a esta sesión pilar cuando cada uno termine para que te diga cómo
   mergear sin conflictos entre sí (los tres van a tocar `casino_floor.tscn`
   sin verse — mismo patrón de conflicto esperado que Planes 4-7).
6. ~~Agentes `plan12-lobby`, `plan13-battle-sync-fix`~~ ✅ — ver tabla.
7. Agente `plan14-casino-visual` — **DESBLOQUEADO.** Ampliación v1.3 (ver
   sección abajo), spec y plan ya escritos por la sesión pilar. Fase 1 de
   varias: fundación visual compartida + Blackjack completo. Las demás
   mesas se reskinarán una por una en fases posteriores (plan16+),
   reutilizando `scripts/ui/casino/`, con referencias que el usuario irá
   aportando por juego.
8. Agente `plan15-battle-pool-wiring` — **DESBLOQUEADO, independiente de
   plan14** (toca lógica de red/juego, no la capa visual — pueden correr
   en paralelo sin pisarse, no comparten ningún archivo). Fix: conecta el
   pozo compartido de Modo Batalla (ya construido desde Plan 4, nunca
   llamado) a las 7 mesas. Spec y plan ya escritos por la sesión pilar.

## Verificación de Agente 8 — Dice (2026-08-20, hecha por esta sesión pilar)

Encontrado ya terminado al arrancar esta sesión: 9 commits en `feature/dice`
local, working tree limpio, **no pusheado todavía** (esta sesión lo pusheó).
`todo_agents.md` seguía diciendo "listo para arrancar" — desfasado, corregido
arriba. El agente tampoco dejó un reporte explícito a pilar; el veredicto de
abajo sale de revisar el repo directamente, no de lo que dijo el agente.

Revisado contra `docs/superpowers/plans/2026-08-19-dice.md` archivo por
archivo — implementación calca el plan tal cual (mismo código, mismos
nombres):
- `scripts/dice/dice_roller.gd` — `DiceRoller`, cola `results` inyectable.
- `scripts/dice/dice_table_state.gd` — `DiceTableState`, jugadores
  perezosos, `win_chance`/`multiplier` con margen de casa 1% (`99 /
  win_chance`), `roll()`/`to_dict()`. Verificado a mano: umbral 50 "mayor
  que" → 99/50 = 1.98x ✓; umbral 10 "mayor que" → 99/90 = 1.1x ✓ (coincide
  con los casos de ejemplo del plan).
- `scripts/net/dice_table_controller.gd` — mismo patrón host-autoridad que
  `RouletteTableController`, wrapper que evita el self-RPC en el host,
  broadcast a todos los presentes (no solo a quien tiró).
- `scenes/dice_table_net.tscn`/`.gd` + `scenes/casino_floor.tscn` — mesa
  añadida en su propia franja (1100-1400), resto de labels recorridos hacia
  abajo sin pisar a Blackjack/Ruleta/Póker.
- `scripts/net/casino_floor.gd` — hook de `chips_won` de
  `DiceTableController` a la meta colectiva, en el bloque correcto (modo
  libre, no batalla) — coherente con que TableController tampoco se conecta
  en modo batalla.
- Tests: `tests/unit/test_dice_roller.gd`, `tests/unit/test_dice_table_state.gd`
  presentes y calcan los casos del plan (incluye los de multiplicador
  conocido, jugadores independientes, `chips_won` con ganancia neta).

**Actualización 2026-08-20 (sesión `plan8-dice`):** se encontró binario
Godot 4.5.1 (build GodotSteam) en
`/tmp/mp_dl/extracted/godotsteam.multiplayerpeer.451.editor.win64.console.exe`
— con eso sí se corrió GUT headless:
`140/140 tests passed` en todo el proyecto, incluidos
`test_dice_roller.gd` (2/2) y `test_dice_table_state.gd` (16/16). Casos de
multiplicador conocidos confirmados por test (umbral 50 mayor-que → 1.98x,
umbral 10 mayor-que / 90 menor-que → 1.1x), no solo a mano.

**Sigue sin verificar:** la prueba manual con dos cuentas Steam (Task 4
Step 2 y Task 5 Step 4 del plan) — necesita dos instancias en red, no se
puede hacer sin cuentas Steam en vivo. Checkboxes correspondientes en
`docs/superpowers/plans/2026-08-19-dice.md` quedaron marcados `[ ]` con
nota `⚠️ no confirmado esta sesión` a propósito.

**Merge a `main` (2026-08-20):** hecho, con autorización explícita del
usuario ("plan 8 ha terminado, lancemos ya el 9 el 10 y el 11"). `git merge
--no-ff feature/dice` sobre `main` — **sin conflictos**, como se anticipaba
(solo archivos nuevos + ediciones acotadas a `casino_floor.tscn`/`.gd` que
no tocaban las franjas de Blackjack/Ruleta/Póker/Batalla). Commit de merge
`dad6f7c`, pusheado a `origin/main`.

**Desbloqueo de Agentes 9/10/11:** hecho tras el merge. Las secciones
"Estado" de `.claude/agents/plan9-crash.md`, `plan10-mines.md` y
`plan11-plinko.md` ya no dicen BLOQUEADO — apuntan directo al patrón base
documentado en `docs/superpowers/plans/2026-08-19-dice.md` (sección final
"Patrón de ronda independiente para Crash/Mines/Plinko") y al código real
(`scripts/dice/dice_roller.gd`, `scripts/dice/dice_table_state.gd`,
`scripts/net/dice_table_controller.gd`), para que ningún agente tenga que
preguntarle a pilar el nombre exacto de la interfaz.

## Merge de Planes 9-11 (2026-08-20)

Autorizado por el usuario tras confirmar que las tres sesiones habían
terminado. Orden de merge: Crash → Mines → Plinko (mismo `main` como punto
de partida para los tres). Cada uno con conflicto textual esperado en
`scenes/casino_floor.tscn`/`scripts/net/casino_floor.gd` (mismo patrón que
Planes 4-7 y el propio Dice: cada agente añadió su mesa sin ver a los
demás). Resuelto apilando verticalmente: Dice (1100-1400) → Crash
(1420-1720) → Mines (1740-2180) → Plinko (2200-2520) → labels de meta
colectiva/batalla (2540-2610). `project.godot` `viewport_height` subido a
`2650` para que quepa todo (Plinko lo había subido a 1850 solo para su
propia vista aislada). Sin verificar visualmente en el editor — igual que
el merge de Planes 4-7, alguien con Godot a mano debería confirmar que las
7 mesas no se solapan antes de darlo por bueno.

**Choque de checkout compartido detectado durante esta sesión:** las
sesiones de Mines y Plinko trabajaron un rato directo en el checkout
compartido (la carpeta raíz del repo) en vez de en worktrees aislados como
Crash sí hizo — se encontraron archivos de ambos agentes mezclados sin
commitear en la misma carpeta a la vez. Ambos terminaron migrando/
commiteando correctamente a sus propias ramas y worktrees (Plinko en
`.claude/worktrees/feature+plinko`) antes de que se perdiera nada, pero fue
suerte de timing, no diseño. **Para la próxima tanda de agentes en
paralelo: exigir worktree aislado desde el primer commit**, no dejar que
ningún agente toque el checkout compartido de la sesión pilar.

Housekeeping tras el merge: se commitearon los planes de Crash/Mines que
los agentes habían dejado sin commitear (`docs: add Crash (Plan 9)
implementation plan`, ya incluido en el merge de Mines para el suyo), se
pushearon las tres ramas a origin (ninguna estaba pusheada todavía), y se
borraron los worktrees de `feature+crash`/`feature+plinko` ya mergeados
(`git worktree remove`). El de `feature+plinko` no se pudo borrar del
disco del todo (`Permission denied` — probablemente un proceso con el
directorio abierto, p.ej. Godot); ya está desregistrado de `git worktree
list`, solo queda basura física en
`.claude/worktrees/feature+plinko/` que alguien puede borrar a mano cuando
cierre lo que lo tenga bloqueado.

**Estado del roadmap:** con esto, los Planes 1-11 (toda la "Ampliación
v1.1" incluida) están mergeados en `main`. Pendiente de siempre (no es
nuevo): la DLL de GodotSteam rota en esta máquina sigue bloqueando probar
una partida real con Steam multijugador — ver sección "Bloqueador de
entorno" arriba.

## Ampliación v1.3: fundación visual de casino + Blackjack (2026-08-23)

El usuario pidió pasar de la UI funcional-pero-en-blanco (Labels/Buttons
por defecto de Godot en las 7 mesas) a una estética básica pero intencional
de casino online, con animación — el pixel art final queda para una fase
futura separada. Aportó una referencia real (Evolution Gaming "First
Person Blackjack"), guardada en
`docs/superpowers/specs/references/blackjack-evolution-reference.png`.

Decisiones tomadas con el usuario (detalle completo en el spec
`docs/superpowers/specs/2026-08-23-casino-visual-blackjack-design.md`):

- **Sin pipeline de arte**: todo el look se logra con dibujo procedural de
  Godot (`_draw()`, `StyleBoxFlat`, `Tween`) — cero archivos de imagen.
  Decisión del usuario, dejando la puerta abierta a mandar fotos de
  referencia si procedural no basta.
- **Fundación compartida primero**: componentes en `scripts/ui/casino/` /
  `scenes/ui/casino/` (tapete, ficha, carta, botón, HUD), pensados desde el
  principio para las 7 mesas, aplicados por completo a Blackjack en esta
  fase.
- **Animación completa ya en esta fase**: reparto de cartas con
  movimiento, fichas volando a la apuesta, flash+confeti de victoria,
  hover/press en botones.
- Único cambio fuera de la capa visual: `BlackjackTableState.to_dict()`
  gana `hand`/`dealer_hand` (cartas reales, mismo patrón que ya usa
  `poker_table_state.to_dict()`) — aditivo, ninguna función de
  apuesta/turno/pago cambia.

Creado `plan14-casino-visual`, desbloqueado, spec y plan de implementación
completos (10 tareas con TDD, código GDScript incluido) ya escritos por
esta sesión pilar. Fuera de alcance explícito: reskin de las otras 6
mesas (fases posteriores, un agente por mesa reutilizando estos
componentes), Double/Split reales, sonido, pixel art final.

## Merge de Planes 14-15 (2026-08-24)

Ambos agentes terminaron en paralelo (no compartían archivos entre sí,
salvo `blackjack_table_state.gd`, en funciones distintas: Plan 14 tocó
`to_dict()`, Plan 15 tocó `sit()`). Verificado antes de mergear: 242/242
tests en `feature/casino-visual-blackjack`, 237/237 en
`feature/battle-pool-wiring`, y captura visual real (`diag1.png`, dejada
por el propio Plan 14 tras su verificación en vivo) confirmando tapete,
cartas, fichas y HUD tal como el spec pedía. Merge sin incidentes:
`feature/casino-visual-blackjack` sin conflictos; `feature/battle-pool-wiring`
con un conflicto textual esperado en `tests/unit/test_blackjack_table_state.gd`
(ambos planes añadieron tests al final del mismo archivo) — resuelto
conservando los dos bloques. 264/264 tests tras el merge, tras reconstruir
la caché de clases. Antes de mergear, el checkout compartido de pilar
tenía cambios sueltos sin commitear en `project.godot` (había perdido
`window/stretch/aspect="keep"`, un fix deliberado de esta sesión) y en
`casino_floor.gd`/`poker_table_state.gd` (reformateo espacios↔tabs) —
descartados por no ser parte de ningún plan, mismo gotcha de siempre. Se
repitió el mismo reformateo tras reconstruir la caché post-merge, también
descartado. Pusheado a `origin/main` (`876526b`).

## Ampliación v1.4: reskin visual de las 6 mesas restantes (2026-08-24)

El usuario pidió aplicar el mismo tratamiento visual de Plan 14 a Ruleta,
Póker, Dice, Crash, Mines y Plinko, y pasó una foto de referencia real por
juego (`rulette.png`, `dice.png`, `crash.png`, `mines.png`, `plinko.png`
en la raíz del repo — copiadas a
`docs/superpowers/specs/references/*-acebet-reference.png` para que no se
pierdan; Póker queda para después, sin referencia todavía).

**Sorpresa real al ver las referencias:** no es el mismo lenguaje visual
de Blackjack (mesa de fieltro). Las 5 con referencia son estilo "app de
casino online moderna" (panel oscuro navy, acento verde) — un sistema de
componentes distinto, `FeltTablePanel`/`PlayingCard`/`CasinoChip` de Plan
14 no aplican aquí. Las 5 comparten casi el mismo panel lateral de
apuesta (monto, 1/2, x2, Máx, botón "Hacer apuesta") — confirmado con el
usuario: se construye esa fundación compartida primero, aplicada a Dice
(el más simple), y solo cuando esa rama mergee se lanzan Ruleta/Crash/
Mines/Plinko en paralelo reutilizándola (mismo criterio que "Dice
primero" en la Ampliación v1.1, para no arriesgar 4 versiones ligeramente
distintas del mismo panel).

**Merge de Plan 16 (2026-08-24):** hecho. 280/280 tests tras reconstruir
caché de clases. Código revisado línea a línea contra el plan (coincide
exacto). El agente se saltó su propio paso de verificación visual en vivo
(Task 6) — a diferencia del agente de Plan 14, no dejó captura de
pantalla; el código y los tests son correctos, pero nadie ha visto
todavía el slider/panel funcionando en pantalla. Pendiente: que el
usuario confirme visualmente la mesa de Dice antes de dar la Ampliación
v1.4a por cerrada del todo. Sin conflictos al mergear, mismo gotcha de
reformateo espacios/tabs de siempre (descartado).

`BetSidebarPanel` (`scripts/ui/casino/bet_sidebar_panel.gd`) ya está en
`main`, listo para que Ruleta/Crash/Mines/Plinko lo reutilicen sin
tocarlo.

**Los 4 agentes restantes, creados (2026-08-24):** `plan17-roulette-visual`
lo escribió esta sesión pilar a mano; `plan18-crash-visual`,
`plan19-mines-visual` y `plan20-plinko-visual` los escribieron 3 forks en
paralelo de esta misma sesión pilar (mismo patrón, mismas restricciones:
reutilizar `BetSidebarPanel`/`CasinoTheme`/`CasinoButton` tal cual, cero
cambios a `scripts/<juego>/` ni a los controllers de red). Ningún agente
toca archivos de los demás — las 4 ramas (`feature/roulette-visual`,
`feature/crash-visual`, `feature/mines-visual`, `feature/plinko-visual`)
pueden correr en paralelo sin pisarse. **Desbloqueados, listos para que
el usuario abra las 4 sesiones.** Nota de Crash: la vista nunca debe leer
`crash_point` del estado (solo `elapsed`/`multiplier_at()`), quedó
explícito en su spec/plan/persona para que ningún agente exponga el punto
de explosión antes de tiempo.

## Fix directo: bola/números de Ruleta + pantalla completa (2026-08-24)

Usuario reportó jugando en vivo: la ruleta gira entera (todas las
casillas) en vez de una bola, los números no se ven en la rueda, y pidió
pasar a pantalla completa. Investigado directo por esta sesión pilar
(mismo criterio que el fix de botones de Ruleta `cb50b8e`: bug visual
acotado a un archivo, sin necesidad de agente):

- `scripts/ui/casino/roulette_wheel_display.gd`: `_draw()` nunca llamaba
  `draw_string` — las 37 casillas se pintaban de color pero sin número.
  `spin_to()` tweeneaba `rotation` del nodo entero (todo el dibujo,
  casillas incluidas). Fix: nueva propiedad `ball_angle` (mismo patrón
  `@export`+setter que `last_result`) que dibuja una bola en un radio
  interior fijo; `spin_to()` anima esa propiedad en vez de `rotation`.
  Las casillas y sus números quedan estáticos, coherente con una ruleta
  real. Reutiliza `ThemeDB.fallback_font` igual que `roulette_result_badge.gd`.
- `project.godot`: `window/size/mode` de `2` (maximizado) a `3`
  (pantalla completa), manteniendo `stretch/aspect="keep"` para que el
  diseño 900x1080 no se deforme.
- Test nuevo `test_spin_to_animates_ball_not_whole_wheel` en
  `tests/unit/test_roulette_wheel_display.gd` — confirma `ball_angle`
  llega al ángulo del resultado y `rotation` del nodo se queda en 0.
  323/323 tests tras rebuild de caché de clases (era 322).

Commiteado y pusheado directo a `main` (`fa033aa`). **Sin confirmar
visualmente en vivo** — mismo bloqueador de siempre (clic sintético no
registra en la ventana de Godot en este entorno). Pendiente que el
usuario confirme jugando: números visibles en la rueda, bola (no la
rueda) es lo que gira, ventana en pantalla completa.

## Fix directo: spoiler de resultado + monto de apuesta atascado en 10 (2026-08-24)

Usuario probó el fix anterior en vivo: bola/números/pantalla completa ya
van bien, pero encontró 2 bugs reales más:

- **`scenes/roulette_table_net.gd`**: `_on_state_changed` metía el número
  ganador en la barra de historial al instante, mientras la bola seguía
  animándose 2s — spoileaba el resultado antes de que cayera. Fix:
  `_push_history` se conecta a `wheel.spin_finished` (`CONNECT_ONE_SHOT`,
  bind del resultado) en vez de llamarse directo. El guard anti-duplicado
  pasó de comparar contra `_history[0]` (desfasado mientras la animación
  corre) a una variable dedicada `_last_seen_result`.
- **`scripts/ui/casino/bet_sidebar_panel.gd`, compartido por las 7
  mesas**: el campo de monto solo sincronizaba `amount` en
  `text_submitted` (tecla Enter). Pulsar "Hacer apuesta" o una celda de
  apuesta le quita el foco al campo primero — eso nunca dispara
  `text_submitted`, así que el valor tecleado se descartaba en silencio y
  toda apuesta usaba el default de 10. Fix: `focus_exited` también
  comitea el texto tecleado (si es inválido, revierte al último monto
  válido en vez de resetear a 1). Bug afectaba a las 7 mesas, no solo
  Ruleta.

327/327 tests tras ambos fixes (era 323 tras el fix anterior). Commiteado
y pusheado directo a `main` (`11e0e3a` spoiler, `53f2663` monto). **Sin
confirmar en vivo todavía** — pendiente que el usuario juegue de nuevo.

## Fix directo: bancarrota prematura antes de resolver la apuesta (2026-08-24)

Usuario reportó: "cuando estas a tus últimas fichas y las apuestas todas
se termina la partida sin ni siquiera terminar la apuesta". Bug real y
de alcance amplio, investigado directo por esta sesión pilar:
`ChipLedger.is_bankrupt()` solo miraba `balance <= 0` — eso se cumple
en el instante en que `place_bet()` descuenta la apuesta, antes de que
la ronda se resuelva. Para cualquier juego con hueco real entre apostar
y resolver (Ruleta: apuesta→girar; Crash: apuesta→sube en vivo→cash
out/explota; Mines: apuesta→revelar→cash out/mina; Blackjack:
apuesta→pedir/plantarse→resolver; Póker: ciegas/igualar/subir→showdown)
la pantalla de derrota saltaba en cuanto apostabas todo, sin darle
tiempo a la ronda a terminar (ni siquiera a ganar). Dice/Plinko no
tenían el bug — resuelven apuesta+pago en la misma llamada, sin hueco.

Fix: `ChipLedger` gana `pending_amount` (incrementado en `place_bet`,
decrementado con `resolve_bet(amount)` nuevo) — `is_bankrupt()` ahora
exige `balance <= 0 AND pending_amount <= 0`. `resolve_bet()` llamado
desde el punto de resolución que cada juego ya tenía: `_resolve_bet`
(Ruleta), `cash_out`/`advance_time` (Crash), `_end_round` (Mines),
`_resolve_round` (Blackjack), y un `_resolve_all_pending_bets()` nuevo
en Póker al final de mano (usa un acumulador `total_wagered` por
asiento porque una mano de Póker puede tener varias `place_bet` —
ciega, igualadas, subidas — antes de un solo resultado).
`TeamChipPool` expone `resolve_bet()` — esto también arregla el mismo
bug en Modo Batalla (`MatchRules.on_balance_changed()` tenía el mismo
problema de timing, solo que nadie lo había reportado en playtest
todavía).

3 tests existentes que codificaban el comportamiento viejo (bancarrota
instantánea) actualizados para resolver la apuesta antes de comprobar:
`test_team_chip_pool.gd`, `test_match_rules.gd`,
`test_casino_floor_ledger_wiring.gd`. Test nuevo "no bancarrota
mientras la apuesta sigue en juego" añadido en cada uno de los 5 juegos
afectados + a nivel `ChipLedger`/`TeamChipPool`. 338/338 tests
(era 327). Commiteado y pusheado directo a `main` (`8eb608c`). **Sin
confirmar en vivo todavía.**

## Verificación en vivo real + fix de pantalla de derrota atascada (2026-08-24)

Usuario pidió que esta sesión pilar jugara el juego ella misma y
revisara errores. Se consiguió automatizar clics reales por primera vez
en este entorno (intentos anteriores con `mouse_event`/`SetCursorPos`
habían fallado o eran dudosos — ver notas de Plan 21/22 más abajo). La
diferencia esta vez: `SetProcessDPIAware()` antes de leer/escribir
coordenadas, y lanzar el juego real (`--path .` sin `--editor`) en vez
de depender de una sesión de editor. Con eso los clics **sí
registraron de forma fiable** — método para futuras sesiones: PrintWindow
sobre la ventana "Casino Pixel (DEBUG)" para capturar, SetCursorPos+
mouse_event (o SendKeys para campos de texto) para interactuar.

Confirmado en vivo, con capturas reales:
- Ruleta: pantalla completa sin deformar, 37 números legibles en la
  rueda, bola (no la rueda) gira y aterriza en su casilla, historial no
  se llena hasta que la bola cae. Los 3 fixes de esta sesión (wheel/
  spoiler/monto de apuesta) funcionan de verdad, no solo en tests.
- Bug de bancarrota prematura: se tecleó 500 sin pulsar Enter, se
  apostó al número 7 (clic directo, sin Enter) — la apuesta SÍ tomó
  500, no 10 (fix de monto confirmado), el balance bajó a 0 y **no**
  saltó la pantalla de derrota hasta girar y perder de verdad (fix de
  bancarrota prematura confirmado en vivo).

**Bug nuevo encontrado y arreglado en el mismo hallazgo:** tras perder
y que saltara la pantalla "PERDISTE — el pozo compartido se agotó", el
botón "‹ Volver al lobby" no respondía a ningún clic — el jugador
quedaba atascado sin ninguna salida salvo cerrar el juego.
`DefeatOverlay` (`scenes/casino_floor.tscn`) es un `ColorRect` a
pantalla completa con `mouse_filter=0` (STOP) declarado después de
`BackButton` en el árbol de `Hud` — absorbía todos los clics de la
ventana, botón incluido. Fix: `mouse_filter=2` (IGNORE), ya que el
overlay es puramente informativo (sin controles propios que necesiten
recibir clics). Confirmado arreglado relanzando el juego y repitiendo
el mismo flujo: el botón ya navega de vuelta al lobby con el overlay
todavía visible (correcto, el pozo sigue en 0). 338/338 tests (sin
cambio de conteo, es un `.tscn`, no añade tests). Commiteado y
pusheado directo a `main` (`a6b2cb7`).

Resto de mesas revisadas visualmente (todas con el overlay de derrota
encima porque el pozo compartido es global): Blackjack, Dice, Crash y
Mines renderizan bien, sin errores de layout visibles. Póker sigue sin
reskin visual (esperado, pospuesto — ver Ampliación v1.4). Plinko/Dice
tienen su tablero/slider llegando justo al borde derecho del área de
diseño de 900px — no se confirmó si es intencional o un pixel-perfect
ajustado al límite; no se tocó, no hay evidencia de que sea un bug
real (nada se corta ni se ve mal).

## Fix directo: Blackjack solo dejaba apostar 50 fichas fijas (2026-08-24)

Usuario, jugando en vivo en paralelo mientras esta sesión probaba el
juego, reportó: "en blackjack solo puedes apostar 50". Causa real:
Blackjack (`scenes/blackjack_table_net.tscn`/`.gd`) es de Plan 14,
anterior a la fundación `BetSidebarPanel` de Plan 16 — se quedó con un
único botón fijo `BetButton` ("Apostar 50") que llamaba
`table_controller.bet(seat, 50)` a pelo, la única de las 7 mesas sin
monto de apuesta ajustable.

Fix: reemplazado por `BetSidebarPanel` (mismo patrón que las otras 6
mesas) — campo de monto, 1/2, x2, Máx, "Hacer apuesta" con la señal
`bet_pressed(amount)`. Fila de botones inferior (Sentarse/DOUBLE/HIT/
STAND/SPLIT) recorrida a la izquierda para llenar el hueco.

**De regalo, arreglado el mismo día el bug de "Máx" pegado en 500**
(`scripts/net/casino_floor.gd`): `BetSidebarPanel.max_amount` nunca se
sincronizaba tras el valor por defecto, así que "Máx" apostaba siempre
el balance inicial (500) sin importar cuánto quedara de verdad en el
pozo compartido/de equipo. `_sync_bet_sidebars_max_amount()` nuevo,
llamado en cada broadcast de `_receive_goal_state` (modo libre) y
`_on_match_state_changed` (modo batalla) — encuentra todos los
`BetSidebarPanel` de la escena vía `find_children` y les empuja el
balance real. El de Blackjack lo hereda gratis, sin cableado extra.

339/339 tests (test de estructura de escena actualizado, más el test
nuevo `test_receive_goal_state_syncs_bet_sidebar_max_amount_to_pool_balance`).
Commiteado y pusheado directo a `main` (`9f13b77`). **El usuario tenía
su propia ventana del juego abierta jugando en vivo durante este fix**
— como el `.tscn`/`.gd` no se recargan en caliente en una instancia ya
corriendo, necesita cerrar y volver a abrir el juego para ver el panel
nuevo de Blackjack y el "Máx" corregido.

**Gotcha nuevo de esta sesión, aparte del reformateo de siempre:**
reconstruir la caché de clases (`godot --headless --editor --quit`)
justo antes de editar `casino_floor.gd` con el Edit tool hizo que el
`git checkout --` de limpieza posterior borrara SIN QUERER también el
cambio real recién hecho (el diff completo del archivo, ~200 líneas,
mezclaba mi fix de 11 líneas con el reformateo tabs/espacios de
siempre, y no había forma de distinguirlos con `git diff --stat` antes
de descartar). Se recuperó rehaciendo los 3 edits a mano sobre la
versión ya reformateada. Para la próxima: si vas a tocar
`casino_floor.gd`, hazlo ANTES de reconstruir la caché de clases, no
después — o revisa el diff línea por línea (no solo `--stat`) antes de
descartar cualquier cosa en ese archivo.

**Gotcha de entorno nuevo:** relanzar el juego varias veces seguidas
sin verificar que el proceso anterior murió del todo puede dejar 2+
ventanas "Casino Pixel (DEBUG)" superpuestas a la vez (fullscreen,
tapándose una a otra) — los clics automatizados van a la que esté
encima de forma no determinista, lo que parece un bug random pero es
solo higiene de proceso. Antes de automatizar clics: `Get-Process |
Where MainWindowTitle -like "Casino Pixel*"` y confirmar que da
exactamente 1 resultado antes de tocar nada.

## Ampliación v1.6: layout responsive real, canvas fijo → adapta a cualquier resolución (2026-08-25)

Usuario reportó barras negras jugando en su monitor panorámico (el
`window/size/mode=3` fullscreen del 24-08 seguía siendo correcto — el
problema real era `window/stretch/aspect="keep"` sobre un canvas de
diseño 900x1080 vertical, letterboxing en cualquier monitor 16:9/16:10
normal). Se ofrecieron dos opciones: (B) canvas fijo panorámico
1600x900, menos trabajo pero solo cubre bien aspect ratios cercanos a
16:9; (A) `stretch/aspect="expand"` + convertir los nodos de offsets
absolutos a anchors reales, se adapta a cualquier resolución sin barra
nunca, más trabajo. **Usuario eligió A.**

Detalle completo, decisión, y receta de conversión nodo-por-nodo:
`docs/superpowers/specs/2026-08-25-responsive-layout-design.md`.
Confirmado el comportamiento exacto de `canvas_items`+`expand` contra la
documentación oficial de Godot antes de tocar nada (no se adivinó).

**Hallazgo que abarató el trabajo:** la lógica de posicionamiento en
GDScript (`blackjack_table_net.gd seat_anchor()`, y todos los
componentes de `scripts/ui/casino/` que dibujan a mano) ya calculaba
todo relativo a `size` del `Control` en tiempo de ejecución, no contra
constantes 900/1080 hardcodeadas — el problema real estaba casi
enteramente en los `.tscn` (nodos con `layout_mode=0` pegados a la
esquina superior-izquierda por defecto en vez de anclados al borde que
les corresponde).

**Hecho directo por esta sesión pilar** (fix de layout acotado, mismo
criterio que los fixes directos anteriores de esta sesión — no logic de
juego): `project.godot` (`stretch/aspect` → `"expand"`),
`casino_floor.tscn` (lobby título/grid de tarjetas, labels de HUD, botón
volver) y `blackjack_table_net.tscn` completo (icono de mazo, contenedor
de cartas/asientos, label de valor del dealer, fila de botones de
acción, barra HUD) convertidos de offsets absolutos a anchors reales.
349/349 tests en verde (ningún test comprueba offsets/anchors exactos).
Commiteado y pusheado directo a `main` (`0b9568d`). **Blackjack sirve de
referencia probada** para el resto.

Creado `plan23-responsive-layout`, **desbloqueado**, spec y plan
completos ya escritos por esta sesión pilar (metodología + tabla de
conversión + referencia al diff real de Blackjack, no fabrica anchors
nuevos por mesa a ciegas — cada agente debe leer su propio `.tscn` y
aplicar la receta). Aplica el mismo tratamiento a las 6 mesas restantes
(Ruleta, Póker, Dice, Crash, Mines, Plinko). Independiente de la
ampliación de pixel art (`assets/pixels/`) — no comparte archivos,
puede correr en paralelo si el usuario quiere.

**Plan 23 completado (2026-08-25).** El agente aplicó la conversión a
las 5 mesas que de verdad la necesitaban (Ruleta, Dice, Crash, Mines,
Plinko — `d9427ac`); Póker no necesitó nada (ningún nodo tenía offsets
pegados al borde viejo, máximo `offset_right=700` de 900). Revisó los
`.gd` de las 6 mesas por constantes 900/1080 hardcodeadas — ninguna,
mismo patrón limpio que Blackjack.

**Bug real encontrado y arreglado por el propio agente, más importante
que el trabajo original (`ca10e2d`):** la conversión de anchors de
`0b9568d` y la del propio Plan 23 **nunca funcionó en tiempo de
ejecución**. Causa raíz verificada con `print()` real desde
`godot --headless`: `Lobby` y las 7 mesas eran hijas directas de
`CasinoFloor` (`Node2D`) — `Node2D` SÍ es un `CanvasItem` (a diferencia
de no tener padre ninguno), así que
`Control::get_parent_anchorable_rect()` no cae al rect del viewport como
pasa cuando no hay ningún `CanvasItem` por encima; usa la implementación
base de `Node2D`, que devuelve un `Rect2` vacío (0x0). Cualquier anchor
no-cero (todo lo tocado en `0b9568d`/Plan 23) se resolvía contra un
rect degenerado — colapsaba a coordenadas negativas/fuera de pantalla.
Por eso el título del lobby se veía cortado por la izquierda y toda la
UI seguía pegada a la esquina superior-izquierda pese a los anchors bien
puestos. El `Hud` nunca tuvo este bug porque es `CanvasLayer`, no
`Control` — no es un `CanvasItem`, así que sí caía correctamente al
viewport.

Fix: nuevo `CanvasLayer` `TablesLayer` como padre de `Lobby` y las 7
mesas (mismo patrón que ya usaba `Hud`), rutas `$Lobby`/`get_node` en
`casino_floor.gd` actualizadas. Confirmado con el mismo método de
`print()` que los rects ahora sí coinciden con el viewport real.
349/349 tests (ningún test comprobaba las rutas viejas).

**Verificado por esta sesión pilar tras el merge:** 349/349 tests en
verde de nuevo, `git status` limpio (descartado el reformateo
tabs/espacios de siempre en `casino_floor.gd`, gotcha ya conocido).

**Confirmado en vivo por el usuario (2026-08-25):** ya no hay barras
negras, pantalla completa bien en su monitor panorámico. Ampliación
v1.6 cerrada del todo.

## Plan 24: ciclo de vida de sala + pantalla de inicio real (2026-08-26)

El usuario pidió pausar reskin visual (Póker sigue pospuesto) y
"perfeccionar la aplicación base": crear salas / interfaces de inicio.
Investigando antes de diseñar nada, esta sesión pilar encontró un
hallazgo real no documentado hasta ahora: **la app empaquetada no tiene
forma de crear ni unirse a una sala Steam.** `scenes/lobby_menu.tscn`/`.gd`
(la única pantalla que llama `SteamManager.create_lobby()`/`join_lobby()`)
no está referenciada desde ningún otro script — `project.godot` arranca
directo en `casino_floor.tscn`, así que `NetworkManager` nunca crea un
`SteamMultiplayerPeer` real. Los playtests con 2 cuentas documentados
arriba (Plan 13, barrida del 24-08) casi con certeza lanzaron
`lobby_menu.tscn` a mano desde el editor (F6), no la app tal como arranca
hoy.

Diseño confirmado con el usuario, pregunta por pregunta (detalle completo
en `docs/superpowers/specs/2026-08-26-room-lifecycle-design.md`):
arreglar y completar `LobbyMenu` como pantalla de inicio real (no solo
conectar `main_scene` sin más), añadir "Salir de la sala" desde
`CasinoFloor` (hoy no existe forma de dejar una sala Steam en curso sin
cerrar la app), mantener el mínimo de 2 jugadores sin cambios (no hay modo
"jugar solo"), y añadir feedback de error visible + botón "Cancelar" (hoy
los fallos de Steam solo se ven en consola). Fuera de alcance explícito:
reskin visual de `LobbyMenu`, Póker, vaciado de asiento cuando un
invitado se desconecta a mitad de partida.

Creado `plan24-room-lifecycle`, **desbloqueado**, spec y plan de
implementación completos (6 tareas con TDD, código GDScript incluido) ya
escritos por esta sesión pilar. Rama `feature/room-lifecycle`, worktree
aislado desde el primer commit. No toca ninguna mesa ni Póker — cero
riesgo de conflicto con trabajo futuro.

**Merge de Plan 24 (2026-08-26).** Diff exacto al plan, línea por línea
(6 commits en la rama: 5 tareas de código + 1 de housekeeping trackeando
los `.uid` nuevos que Godot genera para los tests). Verificado por esta
sesión pilar antes de mergear: caché de clases reconstruida, 359/359
tests (349 previos + 10 nuevos exactamente como preveía el plan: 2
`SteamManager`, 1 `NetworkManager`, 5 `LobbyMenu`, 2 `CasinoFloor`), ambas
escenas (`lobby_menu.tscn` como `main_scene` nuevo, `casino_floor.tscn`)
cargan headless sin error real (el único error en consola es el
`Steam init failed` esperado por no tener Steam corriendo en esta
verificación, no un fallo de carga). Sin conflictos al mergear (`9c95682`).
Mismo gotcha de siempre con el worktree: no se pudo borrar del disco
(`Permission denied`, probablemente Godot con el directorio abierto tras
los runs de verificación) pero sí se desregistró de `git worktree list` —
queda basura física en `.claude/worktrees/feature+room-lifecycle/` para
borrar a mano cuando se libere.

**Sin confirmar todavía:** playtest real con 2 clientes Steam del flujo
completo (crear sala → invitar → jugar → "Salir de la sala" → el otro ve
"El host cerró la sala." si le tocó salir a él) — el agente lo dejó
explícito en su reporte, no lo tiene disponible en su sesión, y esta
verificación de pilar tampoco lo cubre (solo headless, sin Steam en vivo).
Pendiente que el usuario lo pruebe.

**Housekeeping detectado, no de este plan, aparte:** hay 6 worktrees de
ramas ya mergeadas hace tiempo que nunca se limpiaron
(`feature+battle-mode`, `feature+battle-sync-fix`, `feature+lobby`,
`feature+poker`, `feature+roulette`, `feature+roulette-visual`, en
`.claude/worktrees/`) — siguen registrados en `git worktree list` y
ocupando disco. No se tocan en esta sesión (no es parte del encargo
actual), pero la próxima sesión pilar debería limpiarlos con
`git worktree remove` si el usuario lo confirma.

## Barrida exhaustiva de las 7 mesas (2026-08-24)

Usuario pidió una revisión sistemática de las 7 mesas — solapamientos,
botones muertos, fallos internos, todas las funciones. Esta sesión
(un fork de la sesión pilar principal) intentó automatizar la
verificación en vivo con el mismo método Win32 ya usado antes, pero
**el foco de ventana no se pudo forzar de forma fiable**: el usuario
estaba usando su propio escritorio en paralelo (YouTube, luego
Netflix) y Windows bloqueó correctamente el robo de foco
(`SetForegroundWindow` fallaba consistentemente, incluso con el truco
`AttachThreadInput`). Decisión: no forzar el foco mientras el usuario
usa su máquina en vivo — se hizo el resto de la barrida por **revisión
de código estática** (coordenadas de `.tscn` para solapamientos,
grep de señales `.pressed.connect`/`.disabled` para botones muertos,
lectura de la lógica de cada `*_table_state.gd`/`*_table_net.gd`),
apoyada en el test suite completo (GUT) como verificación, no en
capturas de pantalla. Los fixes anteriores de esta sesión (rueda,
spoiler, monto de apuesta, bancarrota prematura, overlay de derrota,
apuesta fija de Blackjack, sync de "Máx") ya estaban confirmados en
vivo antes de este bloqueo y no se volvieron a tocar.

**Bugs encontrados y arreglados (7, todos commiteados y pusheados a
`main`, tests nuevos por cada uno, 349/349 al final):**

- **Ruleta** (`9b3bbb6`): `RouletteBettingGrid` (4 filas de números +
  fila de apuestas de fuera) necesita ~196px de alto pero solo tenía
  160px asignados en `roulette_table_net.tscn` — se desbordaba 16px
  sobre `SeatsLabel`, tapando su texto. Encontrado por cálculo exacto
  de altura de contenido, no por captura (coincide con lo que se vio
  en vivo antes en esta misma sesión y quedó sin diagnosticar en su
  momento).
- **Ruleta** (`a7f0983`): nada bloqueaba el botón "Girar" mientras la
  bola de la ronda anterior seguía animándose (2s). Re-apostar y
  volver a girar en esa ventana crea un segundo tween compitiendo por
  `ball_angle` (bola temblando) y una segunda conexión `spin_finished`
  sin limpiar la primera (el historial podía recibir resultados fuera
  de orden). Botón se bloquea al empezar el giro, se libera al
  terminar.
- **Póker** (`d6e5662`): el nodo raíz de `PokerTableNet` seguía con el
  offset de la franja vertical de antes del Lobby (Plan 12) —
  `offset_left=650, offset_right=1400` en un canvas de diseño de
  900px. La mayoría de la mesa quedaba fuera del área visible/
  clicable. Las otras 6 mesas ya usan rect completo (0,0)-(900,1080)
  porque cada una tuvo su propio agente de reskin que las reconstruyó
  desde cero; Póker nunca tuvo ese agente, así que nadie tocó su nodo
  raíz desde Plan 4-7. Bug de máxima severidad de esta barrida.
- **Póker** (`303c026`): botón "Repartir" sin ningún `disabled` ligado
  al número de sentados — con menos de 2 jugadores o mano ya activa,
  `PokerTableState.start_hand()` rechaza en silencio server-side, cero
  feedback al usuario. Ahora se deshabilita según sentados/mano activa.
- **Blackjack** (`ef78104`): mismo patrón que Póker pero en HIT/STAND
  — nunca se deshabilitaban fuera de turno, `hit()`/`stand()` los
  rechaza en silencio server-side si no es tu turno. Ahora siguen
  `active_seat_index == my_seat_index`.
- **Mines** (`5b3f67c`): selector de tamaño de grid y campo de minas
  sin bloquear durante una ronda activa — cambiarlos a mitad de
  partida llama `_rebuild_grid()` con el tamaño nuevo mientras el
  servidor sigue trackeando el tamaño viejo, desincronizando visualmente
  el grid (no crashea, `start_round` ya rechaza rondas duplicadas
  server-side, pero el grid queda con celdas huérfanas en estado por
  defecto). Bloqueados junto a "Retirar"/apostar mientras hay ronda activa.
- **Plinko** (`8918aaa`): la señal `PlinkoBoard.ball_landed` se emitía
  pero nadie la escuchaba. Nada bloqueaba filas (+/-) ni "Hacer
  apuesta" mientras la bola caía — cambiar filas a mitad de caída hace
  que `_draw()` recalcule las posiciones de las clavijas con el nuevo
  `rows` cada frame (se llama en cada paso del tween de la bola),
  mientras la bola sigue animándose por la trayectoria vieja: bola
  visualmente desconectada de las clavijas. Bloqueados los 3 controles
  mientras `_dropping`, liberados en `ball_landed` (ahora sí conectada).

**Revisado y confirmado correcto, sin cambios:**
- Blackjack `DoubleButton`/`SplitButton` permanentemente deshabilitados
  a propósito — Double/Split reales están fuera de alcance explícito
  desde Plan 14, no es un bug, es trabajo futuro documentado.
- Crash: bloqueo de apostar/retirar durante ronda activa ya estaba
  bien implementado desde el principio (`cash_out_button.disabled`/
  `bet_sidebar.bet_button.disabled` ligados a `is_active`).
- Póker: Retirarse/Pasar/Igualar/Subir ya estaban correctamente
  ligados a `is_my_turn` — solo faltaba "Repartir" (arreglado arriba).
- Dice: slider de umbral, multiplicador/probabilidad en vivo, sin
  solapamientos — todo limpio.

**Gotcha de entorno nuevo, importante para la próxima sesión que
quiera automatizar clics:** si el usuario está usando su propio
escritorio en paralelo (viendo vídeos, otras apps), Windows bloquea
`SetForegroundWindow` de un proceso en segundo plano — es una
protección del SO contra robo de foco, funciona incluso contra el
truco `AttachThreadInput`+`ShowWindow`+`BringWindowToTop`. **No
forzar el foco en ese caso** — es la ventana del usuario, no la
nuestra. `PrintWindow` sí funciona sin foco (captura el buffer de la
ventana igual), así que se puede seguir viendo el estado sin poder
interactuar. Si hace falta seguir probando con clics reales, pedirle
al usuario que deje el juego en primer plano un rato, o hacerlo
cuando conste que no está usando la máquina activamente.

## Merge de Plan 22 (2026-08-24)

Diff exacto al plan (3 archivos: `roulette_betting_grid.gd`/`.tscn` +
su test), incluye el commit final de verificación del agente. 322/322
tests tras el merge, sin conflictos, caché de clases reconstruida.

**Verificación visual: intento fallido, no bloqueante.** Esta sesión
pilar volvió a lanzar el juego con Steam para confirmar el fix en vivo
(mismo método que confirmó Plan 21: `PrintWindow` sobre el handle real
de la ventana "Casino Pixel (DEBUG)", funciona bien para capturar). Pero
el clic sintético (`SetCursorPos` + `mouse_event` de Win32) **no llegó a
registrarse** en la ventana de Godot en dos intentos — se quedó en el
lobby, no pudo navegar a la mesa de Ruleta para ver el grid arreglado.
La vez anterior (verificación de Plan 21) sí pareció "funcionar", pero en
retrospectiva es más probable que esa sesión se uniera a un lobby de
Steam ya existente con estado avanzado de una prueba anterior, no que el
clic sintético funcionara de verdad — no hay que asumir que ese método de
clic es fiable en este entorno. Código y tests del fix son correctos
(revisados línea a línea, coinciden con el diagnóstico de causa raíz);
**falta que el usuario confirme visualmente en vivo** que los 37 números
ya no se cortan — pendiente, no urgente, es un fix de layout de bajo
riesgo ya cubierto por el test de ancho (`test_number_grid_and_outside_bets_row_fit_within_design_width`).

## Merge de Planes 17-21 (2026-08-24)

Las 5 sesiones terminaron en paralelo (4 mesas visuales + fix de modo
libre). Verificado antes de mergear: 5/5 branches con tests en verde de
forma aislada (292-320 según rama), sin cambios sin commitear salvo caché
de import de Godot (ruido, ignorado). **Sin ningún conflicto** al
mergear las 5 — confirmado el análisis de que no comparten archivos entre
sí (cada mesa visual toca solo su propia escena; el fix de modo libre
toca solo `casino_floor.*`). 320/320 tests tras el merge completo, caché
de clases reconstruida. Mismo gotcha de reformateo espacios/tabs de
siempre en `casino_floor.gd`/`poker_table_state.gd` (descartado).

**Desviación real en Ruleta (Plan 17), aceptada, no es un bug:** el
usuario, probando en vivo durante la sesión del agente, pidió que apostar
sea de un clic (clic en número/apuesta de fuera apuesta al instante con
el monto del sidebar) en vez de seleccionar-y-confirmar como decía el
plan original — "Hacer apuesta" del panel lateral ahora repite la última
selección. Documentado en el commit `1e3e46b`, tests actualizados para
cubrir el nuevo comportamiento.

**Verificación en vivo hecha por esta sesión pilar (2026-08-24), lanzando
el juego con Steam y capturando la ventana real:**
- **Plan 21 confirmado funcionando de verdad**: el HUD mostró "Meta
  colectiva: 500 / 1000 fichas" al arrancar, y tras una apuesta perdida
  bajó a "410 / 1000" — el pozo compartido sube y baja de verdad, ya no
  es el contador acumulativo roto que reportó el usuario.
- Rueda de Ruleta, panel lateral oscuro, grid de números, botones e
  historial de resultados renderizan correctamente.
- **Bug real encontrado, sin arreglar todavía**: el grid de 37 números de
  `RouletteBettingGrid` usa `columns = 12`, pero a 12 columnas × ~66px no
  cabe en el ancho de diseño de 900px del proyecto — los números de la
  derecha de cada fila (11, 23, 35, y parte de la última columna) quedan
  cortados fuera de la ventana, invisibles e imposibles de pulsar.
  Necesita su propio fix (menos columnas, o celdas más pequeñas, o ambas)
  — **pendiente de agente**.
- No se pudo automatizar el clic para navegar a Blackjack/Dice/Crash/
  Mines/Plinko desde esta sesión (el clic sintético vía `mouse_event` no
  llegó a registrarse en la ventana de Godot, causa no investigada más a
  fondo) — **esas 4 mesas + Blackjack siguen sin confirmación visual de
  esta sesión pilar**, solo tests + revisión de código. Pendiente que el
  usuario las confirme jugando en vivo, como ya se le pidió a cada agente
  en su Task de verificación.

## Fix: pozo compartido real en Modo Libre (2026-08-24)

Tras cerrar Plan 15 (pozo de batalla), el usuario probó Modo Libre y
reportó que "la meta colectiva sigue siendo errónea, sigue acumulando
solo los puntos ganados" — quería el mismo balance compartido real que
Batalla (500/1000, sube y baja con cada apuesta), no el contador
acumulativo de `CollectiveGoal`. Confirmado con el usuario: al llegar a 0
fichas, pantalla de derrota real (no solo bloqueo silencioso de
apuestas); al llegar a la meta, sigue el comportamiento actual (banner de
desbloqueo, la partida continúa — "niveles" queda como trabajo futuro
aparte, no de este fix).

Creado `plan21-free-mode-shared-pool`, desbloqueado, spec y plan de
implementación completos (4 tareas con TDD, código GDScript incluido) ya
escritos por esta sesión pilar. Reutiliza la tubería
`shared_ledger_provider`/`on_shared_ledger_changed` de Plan 15 sin tocar
ninguna mesa — solo `casino_floor.gd`/`.tscn`, más borrar
`CollectiveGoal` (queda sin uso). Independiente de los Planes 17-20
(visual de las 4 mesas restantes) — no comparte archivos con ellos,
puede correr en paralelo.

## Fix: pozo compartido de Modo Batalla nunca conectado (2026-08-24)

El usuario pidió "todo el equipo empieza con un balance compartido, tiene
que convertirlo en un objetivo" — describiendo, sin saberlo, el Modo
Batalla ya construido en Plan 4 (`TeamChipPool`, `MatchRules`,
`BattleController`, con tests propios: meta alcanzada gana el equipo,
bancarrota pierde el equipo). Investigando el código para asignarle un
agente, esta sesión pilar encontró el bug real: `BattleController.apply_bet()`/
`apply_payout()` no los llama nadie en todo el repo (`grep` confirmado) —
cada una de las 7 mesas sigue creando un `ChipLedger.new(500)` individual
por asiento sin importar el modo, así que el HUD del pozo de equipo nunca
se mueve en la práctica.

Diseño confirmado con el usuario (detalle completo en
`docs/superpowers/specs/2026-08-24-battle-pool-wiring-design.md`): en vez
de sincronizar dos balances, cada asiento/jugador de las 7 mesas usa
directamente el mismo objeto `ChipLedger` que `TeamChipPool` ya envuelve,
inyectado por `CasinoFloor` vía un `Callable` en cada `TableController`.
`TeamChipPool`/`MatchRules`/`BattleController` no cambian su lógica, solo
ganan 3 métodos de conexión (`team_for`/`ledger_for_team`/
`notify_balance_possibly_changed`). Modo Libre no se toca — el usuario lo
dejó explícito ("lo perfeccionaremos luego").

Creado `plan15-battle-pool-wiring`, desbloqueado, spec y plan de
implementación completos (10 tareas con TDD, código GDScript incluido, sin
tests que dependan de `.rpc()`/multiplayer real) ya escritos por esta
sesión pilar.

## Ampliación v1.2: Lobby de selección de juego (2026-08-20)

El usuario pidió que `CasinoFloor` deje de apilar las 7 mesas en una
pantalla larga y en su lugar sea "como un casino online": un lobby con
rejilla de tarjetas de juego, el jugador entra a una sala aislada por
juego, cada uno navega independiente de los demás, con HUD de meta
colectiva/batalla siempre visible. Decisiones confirmadas con el usuario
(detalle completo en la spec maestra, sección "Ampliación v1.2"):

- Sala aislada (no cámara sobre un suelo único) — al pulsar una tarjeta,
  esa mesa ocupa toda la pantalla, el resto se oculta.
- Cada jugador su sala, sin coordinación entre clientes — decisión 100%
  local, no hay RPC nuevo, no se sincroniza "quién está en qué sala".
- HUD persistente (meta colectiva / marcador de batalla) visible en el
  lobby y dentro de cualquier sala.

Cambio puramente de cliente/UI — no toca `GameLogic`/`TableState`/
`TableController` de ningún juego, ya que cada mesa ya difunde su estado
por RPC a todo `CasinoFloor` desde Plan 3. Creado `plan12-lobby`,
desbloqueado (sin dependencias pendientes, los 7 juegos ya están en
`main`).

## Ampliación v1.1: Dice/Crash/Mines/Plinko (2026-08-19)

Decisiones tomadas con el usuario antes de crear los agentes 8-11 (detalle
completo en la spec maestra, sección "Ampliación v1.1"):

- Cada uno es **ronda independiente por jugador contra la casa** (no mesa
  compartida con turnos como Blackjack/Ruleta/Póker).
- Margen de casa: **1%** en los cuatro, horneado en la fórmula de pago de
  cada juego (no un impuesto aparte).
- Orden: Dice primero (más simple), porque define la interfaz base que los
  otros tres reutilizan — evita que cada agente invente su propio patrón de
  "ronda independiente" y haya que unificar 4 interfaces distintas a mano
  después. Crash/Mines/Plinko van en paralelo una vez Dice esté en `main`.

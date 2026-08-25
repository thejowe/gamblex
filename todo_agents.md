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

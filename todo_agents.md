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

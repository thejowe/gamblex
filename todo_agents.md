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
| 8 | `plan8-dice` | Dice + define la interfaz base de "ronda independiente por jugador" | `feature/dice` | 🟢 Listo para arrancar |
| 9 | `plan9-crash` | Crash: multiplicador creciente + cash-out | `feature/crash` | 🔴 Bloqueado hasta que #8 esté en `main` |
| 10 | `plan10-mines` | Mines: grid con minas + cash-out progresivo | `feature/mines` | 🔴 Bloqueado hasta que #8 esté en `main` |
| 11 | `plan11-plinko` | Plinko: tablero de clavijas + tabla de multiplicadores | `feature/plinko` | 🔴 Bloqueado hasta que #8 esté en `main` |

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

**Bloqueador de entorno, no de código:** la GDExtension de GodotSteam
(`addons/godotsteam/win64/libgodotsteam.windows.template_debug.x86_64.dll`)
no carga en esta máquina — `Error 127` al abrir la librería dinámica. Nadie
lo ha investigado a fondo todavía. Bloquea probar Steam/multijugador real
hasta que se arregle (probable dependencia nativa faltante o mismatch de
build). No lo causó ningún merge de esta sesión.

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
4. Agente `plan8-dice` (siguiente, ya desbloqueado) — define la interfaz de
   ronda independiente por jugador que reutilizan los siguientes tres.
5. Agentes `plan9-crash`, `plan10-mines`, `plan11-plinko` en paralelo, cada
   uno en su rama (cuando #8 esté en `main`) — vuelve a esta sesión pilar
   cuando cada uno termine para que te diga cómo mergear sin conflictos.

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

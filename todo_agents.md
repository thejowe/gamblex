# Todo Agents — Casino Multijugador

Cómo funciona: esta sesión ("pilar") define qué hace cada agente. Tú abres
una sesión nueva de Claude Code por agente, en la misma carpeta del repo
(`C:\Users\Usuari\Downloads\gablex`), y le pegas el prompt de ese agente.
Cuando termine y haga commit/push, vuelves a esta sesión pilar y te digo
si el siguiente agente ya puede arrancar.

Repo: https://github.com/thejowe/gamblex (rama `main`)
Spec maestra: `docs/superpowers/specs/2026-08-17-casino-multiplayer-design.md`

Regla de oro: cada agente hace `git pull` al empezar y `git commit` +
`git push` frecuentes al terminar cada tarea del plan. Si dos agentes van
a trabajar en paralelo (ver Plan 4/5/6/7), cada uno en su propia rama
(`feature/<nombre>`) para no pisarse.

---

## Agente 1 — Blackjack en solitario

**Estado: LISTO PARA ARRANCAR AHORA**
**Rama:** `main` (nada en paralelo todavía, no hace falta rama aparte)

Prompt a pegar en la sesión nueva:

> Trabaja en el repo del casino multijugador (ya está clonado/conectado
> en esta carpeta). Ejecuta el plan `docs/superpowers/plans/2026-08-17-blackjack-solitario.md`
> tarea por tarea, usando el skill `superpowers:executing-plans` (o
> `superpowers:subagent-driven-development` si prefieres delegar cada
> tarea a un subagente). Sigue el plan al pie de la letra: cada task
> tiene sus tests, su implementación y su commit. Haz `git push` al
> terminar cada task. Al acabar el plan entero, confírmame con qué
> comando exacto verificaste que todos los tests pasan.

---

## Agente 2 — Integración Steam (GodotSteam + Lobbies)

**Estado: BLOQUEADO hasta que Agente 1 termine y pushee**
**Rama:** `main`

Prompt a pegar (cuando toque):

> Trabaja en el repo del casino multijugador, rama `main`, haz `git pull`
> primero. Lee la spec en `docs/superpowers/specs/2026-08-17-casino-multiplayer-design.md`
> y el código ya construido en `scripts/` y `scenes/` (Blackjack en
> solitario, Plan 1, ya mergeado). Usa el skill `superpowers:writing-plans`
> para crear el Plan 2: integración de GodotSteam (addon), creación/unión
> a lobbies de Steam, e invitación vía overlay — sin lógica de juego
> todavía, solo conexión de jugadores. Guárdalo como
> `docs/superpowers/plans/<fecha>-steam-lobbies.md`. Cuando yo apruebe el
> plan, ejecútalo con `superpowers:executing-plans`, con commits y push
> frecuentes.

---

## Agente 3 — CasinoFloor compartido + Blackjack multijugador

**Estado: BLOQUEADO hasta que Agente 2 termine y pushee**
**Rama:** `main`

Prompt a pegar (cuando toque):

> Trabaja en el repo del casino multijugador, rama `main`, haz `git pull`
> primero. Lee la spec y el código de Plan 1 (Blackjack en solitario) y
> Plan 2 (Steam/Lobbies), ya mergeados. Usa `superpowers:writing-plans`
> para crear el Plan 3: escena `CasinoFloor` compartida, `TableController`
> con autoridad en el host, sincronización RPC de la mesa de Blackjack a
> todos los presentes en el lobby (aunque no estén sentados en esa mesa).
> Este plan convierte el Blackjack en solitario del Plan 1 en el primer
> slice multijugador jugable completo. Guárdalo como
> `docs/superpowers/plans/<fecha>-casinofloor-multiplayer.md`. Tras mi
> aprobación, ejecútalo con commits y push frecuentes.

---

## Agente 4 — Modo batalla (MatchRules)

**Estado: BLOQUEADO hasta que Agente 3 termine y pushee**
**Rama:** `feature/battle-mode` (trabaja en paralelo con Agentes 5 y 6)

Prompt a pegar (cuando toque):

> Trabaja en el repo del casino multijugador. Haz `git checkout main &&
> git pull`, luego crea y muévete a la rama `feature/battle-mode`. Lee la
> spec y el código de Plan 3 (CasinoFloor multijugador), ya mergeado en
> `main`. Usa `superpowers:writing-plans` para crear el Plan 4: selección
> de modo 1v1/2v2/4v4 en `LobbyManager`, `ChipLedger` en modo pozo
> compartido por equipo, y `MatchRules` (meta de fichas, temporizador,
> bancarrota, condición de victoria — ver sección "Modo batalla" de la
> spec). Guárdalo como `docs/superpowers/plans/<fecha>-battle-mode.md`.
> Tras mi aprobación, ejecútalo con commits frecuentes en tu rama y push
> a `feature/battle-mode`. No mergees a `main` tú mismo — avísame cuando
> esté listo.

---

## Agente 5 — Módulo Ruleta

**Estado: BLOQUEADO hasta que Agente 3 termine y pushee**
**Rama:** `feature/roulette` (trabaja en paralelo con Agentes 4 y 6)

Prompt a pegar (cuando toque):

> Trabaja en el repo del casino multijugador. Haz `git checkout main &&
> git pull`, luego crea y muévete a la rama `feature/roulette`. Lee la
> spec y el código de Plan 3 (CasinoFloor multijugador) y del módulo
> Blackjack (Plan 1) como referencia de patrón (GameLogic +
> TableController). Usa `superpowers:writing-plans` para crear el Plan 5:
> lógica de Ruleta (números, tipos de apuesta, giro, cálculo de pago) +
> integración en `CasinoFloor` siguiendo el mismo patrón que Blackjack.
> Guárdalo como `docs/superpowers/plans/<fecha>-ruleta.md`. Tras mi
> aprobación, ejecútalo con commits frecuentes en tu rama y push a
> `feature/roulette`. No mergees a `main` tú mismo — avísame cuando esté
> listo.

---

## Agente 6 — Módulo Póker

**Estado: BLOQUEADO hasta que Agente 3 termine y pushee**
**Rama:** `feature/poker` (trabaja en paralelo con Agentes 4 y 5)

Prompt a pegar (cuando toque):

> Trabaja en el repo del casino multijugador. Haz `git checkout main &&
> git pull`, luego crea y muévete a la rama `feature/poker`. Lee la spec
> y el código de Plan 3 (CasinoFloor multijugador) y del módulo Blackjack
> (Plan 1) como referencia de patrón. Usa `superpowers:writing-plans`
> para crear el Plan 6: lógica de Póker (rondas de apuestas, reparto,
> evaluación de manos, showdown) + integración en `CasinoFloor`. Es el
> juego más complejo de los tres — tómate el tiempo necesario para
> descomponerlo bien en tareas pequeñas. Guárdalo como
> `docs/superpowers/plans/<fecha>-poker.md`. Tras mi aprobación,
> ejecútalo con commits frecuentes en tu rama y push a `feature/poker`.
> No mergees a `main` tú mismo — avísame cuando esté listo.

---

## Agente 7 — Modo libre (meta colectiva de grupo)

**Estado: BLOQUEADO hasta que Agente 3 termine y pushee**
**Rama:** `feature/free-mode` (puede ir en paralelo con Agentes 4, 5 y 6)

Prompt a pegar (cuando toque):

> Trabaja en el repo del casino multijugador. Haz `git checkout main &&
> git pull`, luego crea y muévete a la rama `feature/free-mode`. Lee la
> spec y el código de Plan 3 (CasinoFloor multijugador). Usa
> `superpowers:writing-plans` para crear el Plan 7: contador de meta
> colectiva compartida entre todos los presentes en modo libre (ver
> sección "Modo libre" de la spec) y desbloqueo al cumplirse. Guárdalo
> como `docs/superpowers/plans/<fecha>-modo-libre.md`. Tras mi
> aprobación, ejecútalo con commits frecuentes en tu rama y push a
> `feature/free-mode`. No mergees a `main` tú mismo — avísame cuando esté
> listo.

---

## Orden recomendado

1. Agente 1 (ahora)
2. Agente 2 (cuando Agente 1 esté en `main`)
3. Agente 3 (cuando Agente 2 esté en `main`)
4. Agentes 4, 5, 6 y 7 en paralelo, cada uno en su rama (cuando Agente 3
   esté en `main`) — vuelve a esta sesión pilar cuando cada uno termine
   para que te diga cómo mergear sin conflictos y qué toca después.

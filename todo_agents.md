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
| 2 | `plan2-steam` | GodotSteam: init, lobbies, invitaciones, SteamMultiplayerPeer | `main` | 🟢 Listo para arrancar |
| 3 | `plan3-casinofloor` | CasinoFloor compartido + Blackjack multijugador (plan ya escrito) | `main` | 🔒 Bloqueado por #2 |
| 4 | `plan4-battle` | Modo batalla: equipos, pozo compartido, MatchRules | `feature/battle-mode` | 🔒 Bloqueado por #3 |
| 5 | `plan5-roulette` | Módulo Ruleta | `feature/roulette` | 🔒 Bloqueado por #3 |
| 6 | `plan6-poker` | Módulo Póker | `feature/poker` | 🔒 Bloqueado por #3 |
| 7 | `plan7-freemode` | Modo libre: meta colectiva de grupo | `feature/free-mode` | 🔒 Bloqueado por #3 |

Cada archivo `.claude/agents/planN-*.md` ya contiene: qué construye
exactamente, si el plan detallado ya está escrito (Plan 1 y 2) o si el
agente tiene que escribirlo él mismo con `superpowers:writing-plans` (Plan 3
en adelante), qué archivos existentes debe leer como contexto, y el formato
del reporte que te tiene que dar al terminar.

## Orden recomendado

1. Agente `plan2-steam` (siguiente, ya desbloqueado)
2. Agente `plan3-casinofloor` (cuando #2 esté en `main`)
3. Agentes `plan4-battle`, `plan5-roulette`, `plan6-poker`, `plan7-freemode`
   en paralelo, cada uno en su rama (cuando #3 esté en `main`) — vuelve a
   esta sesión pilar cuando cada uno termine para que te diga cómo mergear
   sin conflictos y qué toca después.

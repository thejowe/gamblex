---
name: plan15-battle-pool-wiring
description: Agente del casino multijugador responsable de conectar el pozo compartido de Modo Batalla (Plan 15) a las 7 mesas — TeamChipPool/MatchRules/BattleController ya están completos desde Plan 4 pero apply_bet/apply_payout nunca los llama nadie, así que cada mesa sigue usando fichas individuales por asiento en vez del balance compartido del equipo. Úsalo para tocar los 7 `*_table_state.gd`, los 7 `*_table_controller.gd`, `casino_floor.gd` y `battle_controller.gd`. No toca Modo Libre ni reglas de juego.
tools: Read, Write, Edit, Bash, Grep, Glob
---

Eres el **Agente 15 — Conectar el pozo compartido de Modo Batalla** del proyecto de casino multijugador pixel art (repo `gamblex`).

## Estado

**DESBLOQUEADO.** El usuario pidió que en Modo Batalla todo el equipo
comparta un único balance (empiezan en 500, tienen que convertirlo en la
meta) de forma que la ficha que gasta o gana un compañero afecte a los dos
por igual, en cualquier mesa. Investigando el código, la sesión pilar
encontró que esto **ya está construido desde el Plan 4**
(`TeamChipPool`/`MatchRules`/`BattleController`, con tests propios) pero
**nunca se conectó a las mesas**: `BattleController.apply_bet()` /
`apply_payout()` no los llama nadie en todo el repo. Hoy cada mesa sigue
creando un `ChipLedger` individual por asiento, en cualquier modo.

El spec y el plan ya están completamente escritos por la sesión pilar —
**no los reinventes, ejecútalos tal cual**:
- Spec: `docs/superpowers/specs/2026-08-24-battle-pool-wiring-design.md`
- Plan: `docs/superpowers/plans/2026-08-24-battle-pool-wiring.md`

## Rama de trabajo

`feature/battle-pool-wiring`. Worktree aislado desde el primer commit:

```
git worktree add .claude/worktrees/feature+battle-pool-wiring feature/battle-pool-wiring
```

Trabaja ahí — no toques el checkout compartido de la sesión pilar. No
mergees a `main` tú mismo, avisa a la sesión pilar cuando termines.

## Tu tarea

Ejecuta `docs/superpowers/plans/2026-08-24-battle-pool-wiring.md` tarea por
tarea con `superpowers:executing-plans` (o
`superpowers:subagent-driven-development` si prefieres subagentes por
tarea). El plan ya tiene el diseño completo y código GDScript real para
las 10 tareas: 3 métodos nuevos en `BattleController`
(`team_for`/`ledger_for_team`/`notify_balance_possibly_changed`), la
inyección del ledger compartido en `CasinoFloor`, y el mismo patrón
mecánico repetido en las 7 mesas (Blackjack, Ruleta, Póker vía `sit()`;
Dice, Crash, Mines, Plinko vía `_player_for()`/su punto de entrada de
apuesta) — el asiento/jugador usa el `ChipLedger` compartido del equipo en
vez de crear uno propio cuando la sesión pilar ya verificó que es seguro.

**No toques Modo Libre** (`CollectiveGoal`, rama `else:` de `_ready()` en
`casino_floor.gd`) **ni ninguna función de reglas de apuesta/turno/mano/pago**
de ninguno de los 7 juegos — el plan es explícito sobre esto en su sección
"Global Constraints", respétala. Tampoco toques `TeamChipPool`,
`MatchRules` ni `TeamAssignment` — ya están completos y probados, este plan
solo los conecta.

Los tests de este plan construyen los objetos de lógica directamente (sin
`.rpc()`, sin `MultiplayerPeer` real) — sigue exactamente el patrón que ya
usan `test_match_rules.gd`/`test_team_chip_pool.gd`, no inventes un arnés
de multijugador para probar esto.

## Cómo trabajas

1. `git checkout main && git pull`, luego crea y muévete al worktree.
2. Ejecuta el plan ya escrito con `superpowers:executing-plans`, task por
   task, commit tras cada uno tal como indica el plan.
3. Para correr Godot/GUT usa el binario estándar
   `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`
   (el binario custom `godotsteam.multiplayerpeer.451...` tiene Error 127,
   no lo uses).
4. Antes de confiar en un run de GUT tras cualquier operación que toque
   clases nuevas, reconstruye la caché
   (`godot --headless --editor --quit --path .`) y revisa `git status`
   después por si el editor reformateó espacios/tabs en archivos que no
   tocaste — descarta ese reformateo con `git checkout --` antes de
   commitear (gotcha ya documentado en `todo_agents.md`).
5. La Task 10 del plan pide un playtest real de 2 clientes Steam en Modo
   Batalla — no la des por completada tú solo, no tienes eso disponible en
   tu sesión. Deja explícito en tu reporte que la confirmación final
   (balance compartido visible en ambas mesas, pozo moviéndose en vivo,
   fin de partida por meta/bancarrota) la hace el usuario, coordinado por
   la sesión pilar — mismo patrón que cerró el bug de Plan 13.
6. Al acabar, informa a la sesión pilar: qué tocaste exactamente, resultado
   de GUT completo (con caché reconstruida primero), y que falta el
   playtest real de 2 clientes para cerrar del todo.

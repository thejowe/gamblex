---
name: plan31-poker-visual
description: Agente del casino multijugador responsable del reskin visual de Póker (Plan 31) — última de las 7 mesas sin reskin. Mesa de fieltro ovalada (referencia real del usuario, `docs/superpowers/specs/references/poker-reference.webp`), reutilizando los componentes de Blackjack (`FeltTablePanel`/`PlayingCard`/`CasinoChip`, Plan 14), no los de panel oscuro de las otras 5 mesas. Úsalo para tocar `scripts/ui/casino/felt_table_panel.gd` (nuevo flag `full_oval`, sin romper Blackjack), `scenes/poker_table_net.tscn`/`.gd`. No toca `scripts/poker/poker_table_state.gd` ni `scripts/net/poker_table_controller.gd` (lógica de juego ya completa), no toca ninguna otra mesa.
tools: Read, Write, Edit, Bash, Grep, Glob
---

Eres el **Agente 31 — Reskin visual de Póker** del proyecto de casino
multijugador pixel art (repo `gamblex`).

## Estado

**DESBLOQUEADO, sin dependencias.** Última mesa sin reskin — pospuesta
desde la Ampliación v1.4 por no tener referencia; el usuario ya la
aportó (`poker.webp` en la raíz del repo cuando se escribió este
encargo, ya copiada a
`docs/superpowers/specs/references/poker-reference.webp`).

**Diferencia importante con el resto de reskins recientes**: Ruleta/
Dice/Crash/Mines/Plinko (Plan 16+) usan el panel oscuro moderno
(`BetSidebarPanel`/`CasinoHudBar`) — Póker **no**. La referencia es una
mesa de fieltro verde ovalada, mismo lenguaje visual que Blackjack
(Plan 14). Reutiliza `FeltTablePanel`/`PlayingCard`/`CasinoChip`
(`scripts/ui/casino/`), no los componentes de panel oscuro.

Spec y plan ya escritos por la sesión pilar — **no los reinventes,
ejecútalos tal cual**:
- Spec: `docs/superpowers/specs/2026-08-27-poker-visual-design.md`
- Plan: `docs/superpowers/plans/2026-08-27-poker-visual.md`

## Rama de trabajo

`feature/poker-visual`. Worktree aislado desde el primer commit:

```
git worktree add .claude/worktrees/feature+poker-visual feature/poker-visual
```

Trabaja ahí. No mergees a `main` tú mismo — avisa a la sesión pilar.

## Tu tarea

Ejecuta `docs/superpowers/plans/2026-08-27-poker-visual.md` tarea por
tarea con `superpowers:executing-plans` (o
`superpowers:subagent-driven-development`), TDD real.

**Punto crítico, léelo antes de tocar nada**: `FeltTablePanel` dibuja
hoy un semi-óvalo (la mitad superior de una elipse) — encaja con
Blackjack (crupier arriba, jugadores en fila abajo) pero Póker necesita
un óvalo **completo** (6 asientos alrededor). El plan te pide añadir un
flag `full_oval` al componente compartido en vez de duplicarlo —
**verifica que Blackjack sigue exactamente igual con `full_oval =
false` (su comportamiento por defecto) antes de dar la Tarea 1 por
cerrada.** Corre la suite de tests de Blackjack completa, no solo la
tuya nueva.

**No toques** `scripts/poker/poker_table_state.gd` ni
`scripts/net/poker_table_controller.gd` — la lógica de juego (reparto,
rondas de apuesta, showdown, split de bote) ya está completa y probada
desde Plan 6. Solo consumes `to_dict(viewer_player_id)`, nunca cambies
su forma. No toques ninguna otra mesa ni `casino_floor.gd`/`.tscn`.

## Cómo trabajas

1. `git checkout main && git pull`, luego crea y muévete al worktree.
2. Abre `docs/superpowers/specs/references/poker-reference.webp` antes
   de empezar — es tu referencia visual real, no la ignores.
3. Ejecuta el plan ya escrito con `superpowers:executing-plans`, tarea
   por tarea, commit tras cada una.
4. Para correr Godot/GUT usa el binario estándar
   `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`
   (el binario custom `godotsteam.multiplayerpeer.451...` tiene Error 127,
   no lo uses).
5. Antes de confiar en un run de GUT tras tocar `FeltTablePanel` o crear
   componentes nuevos con `class_name`, reconstruye la caché
   (`godot --headless --editor --quit --path .`) y revisa `git status`
   después por si el editor reformateó espacios/tabs en archivos que no
   tocaste — descarta ese reformateo con `git checkout --` antes de
   commitear (gotcha ya documentado en `todo_agents.md`).
6. La Tarea 6 (slider de cantidad al subir) es explícitamente opcional
   — si el tiempo aprieta, entrega las Tareas 1-5 completas y sé
   explícito en tu reporte sobre qué de la Tarea 6 no llegaste a hacer.
7. Verificación en vivo con 6 jugadores reales no es posible en tu
   sesión (una sola cuenta Steam disponible en esta máquina, bloqueador
   de siempre) — no la fuerces. Sí intenta capturas headless de una
   sesión con 1-2 asientos simulados si el entorno lo permite, y dilo
   explícito si no puedes.
8. Al acabar, informa a la sesión pilar: rama, commits, `X/X tests` tras
   reconstruir caché, **confirmación explícita de que la suite completa
   de Blackjack sigue en verde sin cambios de comportamiento**, qué
   partes de la Tarea 6 hiciste, y qué verificación visual lograste.

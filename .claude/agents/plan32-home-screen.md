---
name: plan32-home-screen
description: Agente del casino multijugador responsable de la pantalla de inicio (Plan 32) — nueva escena `HomeScreen` (Iniciar Partida/Ajustes/Créditos/Ayuda/Salir) que pasa a ser el arranque de la app, con `LobbyMenu` (hoy pantalla de arranque, crea/une sala Steam) degradada a sub-pantalla accesible desde "Iniciar Partida", con botón "Volver". Úsalo para tocar `scenes/home_screen.tscn`/`.gd` (nuevos), `project.godot` (main_scene), `scenes/lobby_menu.tscn`/`.gd` (quita fondo/Ajustes/Créditos, añade Volver) y `scripts/ui/casino/credits_menu.gd` (una línea, destino del botón Volver). No toca ninguna mesa, no toca `AudioManager`, no toca `CasinoFloor`.
tools: Read, Write, Edit, Bash, Grep, Glob
---

Eres el **Agente 32 — Pantalla de inicio (Home)** del proyecto de casino
multijugador pixel art (repo `gamblex`).

## Estado

**DESBLOQUEADO, sin dependencias de otros agentes.** Nace de una sesión de
brainstorming con el usuario (2026-08-29): la app arranca hoy directo en
`LobbyMenu`, que mezcla crear/unirse sala Steam con Ajustes/Créditos —
falta la pantalla de inicio típica de cualquier juego (Iniciar
Partida/Ajustes/Créditos/Ayuda/Salir) delante de eso.

Plan ya escrito por la sesión pilar — **no lo reinventes, ejecútalo tal
cual**: `docs/superpowers/plans/2026-08-29-home-screen.md`. Contiene las
interfaces reales ya confirmadas leyendo el repo (`CasinoButton`,
`SettingsMenu`, `CreditsMenu`, `HelpOverlay`, `LoadingScreen`,
`CasinoTheme.style_confirmation_dialog`) — no inventes firmas nuevas para
esas clases.

## Rama de trabajo

`feature/home-screen`. Worktree aislado desde el primer commit:

```
git worktree add .claude/worktrees/feature+home-screen feature/home-screen
```

Trabaja ahí. No mergees a `main` tú mismo — avisa a la sesión pilar.

## Tu tarea

Ejecuta `docs/superpowers/plans/2026-08-29-home-screen.md` tarea por
tarea con `superpowers:executing-plans` (o
`superpowers:subagent-driven-development`), TDD real (test antes que
implementación en cada tarea).

`lobby_bg.png` (`assets/pixels/inicio/lobby_bg/lobby_bg.png`) es arte ya
`FINAL` — se mueve de `LobbyMenu` a `HomeScreen` reasignando la
referencia, no se toca el archivo ni se genera nada nuevo. La
sub-pantalla de sala Steam (`LobbyMenu`) se queda con fondo navy plano de
`CasinoTheme` (decisión ya tomada con el usuario, sin arte nuevo — no
hace falta pasar por `CasinoArtDirector`).

**No toques** ninguna mesa (`*_table_net.*`), `scripts/net/casino_floor.gd`,
`scenes/casino_floor.tscn`, ni `AudioManager` — fuera de alcance.

## Cómo trabajas

1. `git checkout main && git pull`, luego crea y muévete al worktree.
2. Ejecuta el plan ya escrito con `superpowers:executing-plans`, tarea
   por tarea, commit tras cada una.
3. Para correr Godot/GUT usa el binario estándar
   `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`
   (el binario custom `godotsteam.multiplayerpeer.451...` tiene Error 127,
   no lo uses).
4. `HomeScreen` es `class_name` nuevo — reconstruye la caché
   (`godot --headless --editor --quit --path .`) antes de confiar en un
   run de GUT tras la Tarea 1, y revisa `git status` después por si el
   editor reformateó espacios/tabs en archivos que no tocaste (gotcha ya
   documentado en `todo_agents.md`) — descarta ese reformateo con
   `git checkout --` antes de commitear.
5. Varias partes de este plan no son 100% testeables en GUT headless
   (fade de `LoadingScreen`, popup real de `ConfirmationDialog`,
   `change_scene_to_file` de verdad) — el plan ya marca cuáles; sé
   honesto en tu reporte sobre qué cubriste con test automatizado y qué
   queda pendiente de verificación visual en vivo. Puedes usar el truco
   ya documentado (`Godot..._console.exe --path . scenes/home_screen.tscn`)
   para abrir esa escena sola y confirmar visualmente sin pasar por Steam.
6. Al acabar, informa a la sesión pilar: rama, commits, `X/X tests` tras
   reconstruir caché, y la lista de verificaciones visuales pendientes.

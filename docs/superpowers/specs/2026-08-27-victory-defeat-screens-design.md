# Spec: pantallas de victoria y derrota temporales — Ampliación v1.7, Agente 26

## Contexto

Auditoría de la sesión pilar (2026-08-27) contra estándar de juegos
casino/party exitosos encontró: **derrota** existe pero es pobre
(`DefeatOverlay` en `scripts/net/casino_floor.gd`/`scenes/casino_floor.tscn`
es un `ColorRect` liso + un `Label`, sin estilo, mostrado cuando
`state["bankrupt"]` es `true` en Modo Libre); **victoria** no existe en
absoluto — `assets/pixels/ASSETS.md` línea 70 lo confirma explícito: "hoy
no existe en el código, solo hay texto en una label en Modo Batalla"
(`_on_match_state_changed` solo actualiza `BattleStatusLabel` con texto
plano cuando `state["finished"]` es `true`).

Este agente construye ambas pantallas **de forma temporal/procedural**
(mismo criterio que Plan 14 usó para toda la capa visual: `_draw()` /
`StyleBoxFlat` / `Tween`, cero imágenes) — el arte real ya tiene carpeta
reservada (`assets/pixels/hud/defeat_bg/`, `assets/pixels/hud/victory_bg/`)
para cuando llegue una fase de pixel art futura; esto es un peldaño
intermedio, no el diseño final.

## Decisión de diseño

Ambos overlays son hijos de `Hud` (mismo patrón que `DefeatOverlay` ya
usa hoy), a pantalla completa, `mouse_filter = 2` (IGNORE) — **no
recibe clics propios**, el `BackButton` ya existente por debajo (visible
según `_refresh_room_visibility()`) sigue siendo el único control
clicable. Esto es a propósito: ya hubo un bug real arreglado (2026-08-24)
donde un overlay con `mouse_filter` en modo STOP absorbía todos los
clics de la ventana y dejaba al jugador sin forma de volver al lobby —
no lo reintroduzcas.

- **Derrota** (mejora de `DefeatOverlay` existente): panel dibujado con
  `StyleBoxFlat` sobre fondo `CasinoTheme.PANEL_NAVY_DARK` con borde
  `CasinoTheme.ACCENT_RED`, título grande + submensaje. Mensaje según
  modo:
  - Modo Libre: `"PERDISTE — el pozo compartido se agotó"` (texto ya
    existente, consérvalo).
  - Modo Batalla, equipo perdedor: `"Tu equipo perdió — %s" %
    _reason_label(state["reason"])`, con `_reason_label` traduciendo
    `"goal_reached"` (el otro equipo llegó a la meta primero) /
    `"bankrupt"` (tu equipo quebró) a texto legible.
- **Victoria** (nueva, `VictoryOverlay`): mismo tratamiento pero paleta
  de éxito (`CasinoTheme.ACCENT_GREEN`/`CasinoTheme.GOLD_ACCENT`),
  mensaje `"¡Tu equipo ganó! — %s" % _reason_label(state["reason"])`.
  Solo aplica a **Modo Batalla** — Modo Libre no tiene condición de fin
  de partida por victoria, solo el `UnlockedBanner` ya existente (la
  partida sigue después de desbloquear meta, eso no cambia). Se muestra
  únicamente al equipo cuyo `state["winning_team"]` coincide con
  `battle_controller.team_for(multiplayer.get_unique_id())` — el equipo
  perdedor ve la pantalla de derrota, no la de victoria.
- Ambas llaman **una vez** (no cada frame, no en cada refresco de
  estado) `AudioManager.play_sfx("lose")` / `AudioManager.play_sfx("win")`
  al pasar de oculto a visible — guarda un flag `_shown` (o compara
  contra el estado anterior) para no repetir el sonido en cada RPC de
  refresco de estado que llegue mientras el overlay ya está abierto.
- Celebración de victoria: efecto simple y procedural — pulso de
  brillo dorado (`Tween` oscilando `modulate`/`self_modulate` del panel
  2-3 veces) o unos pocos rectángulos "confeti" cayendo con `Tween`
  (posiciones aleatorias, caída + fade, 8-12 unidades, nada de
  `GPUParticles2D` con shaders — mantenlo simple, es temporal).

## Dependencia real: Agente 25 (audio) debe estar en `main` primero

Este agente llama `AudioManager.play_sfx("win"|"lose")` — esas funciones
solo existen tras mergear `feature/audio-foundation`. Está
**bloqueado** hasta que la sesión pilar confirme ese merge. Si arranca
antes por error, el propio agente debe frenar y avisar a pilar, no
inventar un `AudioManager` stub — eso duplicaría trabajo real y crearía
un conflicto de merge innecesario.

## Archivos que toca (y solo esos)

`scripts/net/casino_floor.gd`, `scenes/casino_floor.tscn`. Opcional: un
script reusable nuevo si conviene factorizar el dibujo del panel
(`scripts/ui/casino/result_overlay.gd` o similar) — decisión del
agente al escribir el plan de implementación, dentro de estas dos
ubicaciones. No toca ninguna mesa individual, no toca `AudioManager`
(solo lo consume), no toca `LobbyMenu`.

## Fuera de alcance

- Arte real de `defeat_bg`/`victory_bg` — fase de pixel art futura,
  sin fecha.
- Pantalla de "empate" — `MatchRules`/`BattleController` no modelan
  empates hoy (siempre hay un `winning_team`), no inventes ese caso.
- Menú de pausa / botón "reintentar" — fuera de alcance, eso es
  del sistema de pausa (agente aparte de esta misma ampliación).

## Verificación

- Tests GUT: overlay de derrota se muestra en Modo Libre al llegar a 0
  fichas (ya cubierto en parte por tests existentes de
  `_receive_goal_state`, ampliar si hace falta); overlay de victoria se
  muestra solo al equipo ganador cuando `state["finished"]` es `true` y
  `winning_team` coincide con el equipo local; overlay de derrota se
  muestra al equipo perdedor en el mismo evento; ninguno de los dos
  vuelve a sonar el SFX en un segundo refresco de estado con el overlay
  ya visible.
- Verificación visual real: pendiente del método headless/Win32 ya
  usado por sesiones pilar anteriores (`PrintWindow` sobre la ventana
  "Casino Pixel (DEBUG)"), o confirmación del usuario jugando en vivo —
  no bloqueante para cerrar la tarea, pero repórtalo explícito si no se
  pudo hacer.

# Spec: pantalla de ajustes + menú de pausa — Ampliación v1.7, Agente 29

## Contexto

Auditoría de la sesión pilar (2026-08-27): `project.godot` no define
ninguna `[input]` action (ni ESC, ni nada) — cero manejo de tecla de
pausa en todo el proyecto. No existe pantalla de ajustes en ningún
sitio: cero control de volumen visible al jugador, cero toggle pantalla
completa/ventana (hoy `window/size/mode=3` fullscreen hardcodeado en
`project.godot`, sin forma de cambiarlo en juego), cero forma limpia de
"salir a escritorio" con confirmación (solo cerrar la ventana del SO a
lo bruto).

**BLOQUEADO hasta que `plan25-audio-foundation` esté mergeado a
`main`.** Este agente llama al contrato público de `AudioManager` para
los sliders de volumen — sin ese autoload en `main`, los tests de este
plan no pueden pasar de verdad. La sesión pilar avisa cuándo arrancar.

## Contrato con plan25 (literal, no lo cambies)

```gdscript
AudioManager.set_bus_volume_db(bus_name: String, db: float) -> void   # bus_name en {"Master","Music","SFX"}
AudioManager.get_bus_volume_db(bus_name: String) -> float
AudioManager.set_bus_mute(bus_name: String, muted: bool) -> void
AudioManager.is_bus_muted(bus_name: String) -> bool
```

`AudioManager` ya persiste sus propios volúmenes en `user://settings.cfg`,
sección `[audio]` — **este agente no duplica esa persistencia**. Añade
su propia sección `[display]` al mismo archivo (mismo `ConfigFile`,
sección distinta — sin conflicto real porque `user://settings.cfg` es
un archivo de usuario en tiempo de ejecución, no del repo, así que
tampoco hay conflicto de git posible entre las dos ramas).

## Diseño

### 1. `SettingsMenu` (`scenes/ui/casino/settings_menu.tscn`/`.gd`)

Escena reusable, montable como overlay (dentro de `PauseMenu`) o
standalone (desde `LobbyMenu`). Contenido:
- 3 `HSlider` de volumen (Master/Music/SFX), rango `-40.0` a `0.0` dB
  (fuera de ese rango ya es prácticamente silencio o innecesariamente
  alto), inicializados con `AudioManager.get_bus_volume_db(bus)`, cada
  cambio llama `AudioManager.set_bus_volume_db(bus, value)`.
- 3 `CheckBox` de mute correspondientes, ligados a
  `AudioManager.set_bus_mute`/`is_bus_muted`.
- Toggle pantalla completa/ventana: `CheckBox` o `CasinoButton` de
  2 estados. API confirmada contra la documentación oficial de Godot
  4.7 (`class_window.html`) antes de escribir este spec:
  `Window.Mode` es un enum con `MODE_WINDOWED = 0`, `MODE_FULLSCREEN = 3`
  (coincide con el valor `3` que ya usa `window/size/mode` en
  `project.godot`). En tiempo de ejecución:
  `get_window().mode = Window.MODE_FULLSCREEN` /
  `get_window().mode = Window.MODE_WINDOWED`. Guarda la preferencia en
  `user://settings.cfg`, sección `[display]`, clave `fullscreen`
  (bool), y aplícala en `_ready()` de `SettingsMenu` o, mejor, en un
  punto de arranque temprano (`LobbyMenu._ready()`) para que la
  preferencia sobreviva a relanzar el juego sin esperar a que el
  jugador abra Ajustes.
- Botón "Salir al escritorio" (`CasinoButton`, variante `NEGATIVE`): abre
  un mini-diálogo de confirmación sí/no (`ConfirmationDialog` de Godot o
  un overlay propio simple, tu criterio) — **no debe salir con un solo
  clic accidental**. Solo al confirmar, `get_tree().quit()`.
- Botón "Cerrar"/"Volver" (`CasinoButton`): oculta `SettingsMenu`, sin
  tocar nada más.

### 2. Botón "Ajustes" en `LobbyMenu`

Cuarta opción junto a Crear/Invitar/Cancelar (`create_button`/
`invite_button`/`cancel_button` en `scenes/lobby_menu.gd`) — no rompe el
flujo de creación/unión a sala existente. Abre `SettingsMenu` en modo
standalone (superpuesto a `LobbyMenu`, no navega a otra escena).

### 3. `PauseMenu` (`scenes/ui/casino/pause_menu.tscn`/`.gd`)

Overlay dentro de `CasinoFloor.$Hud` (mismo `CanvasLayer` que ya aloja
`DefeatOverlay`/`UnlockedBanner`). Se activa con la acción de input
`ui_cancel` (ya viene predefinida por Godot por defecto, mapeada a ESC —
**se reutiliza en vez de crear una acción `pause` nueva**, porque
`ui_cancel` ya es estándar en todo motor Godot y no requiere tocar
`project.godot` `[input]` para nada; justificación: menos superficie de
configuración, mismo resultado). Contenido:
- "Reanudar" — oculta el overlay.
- "Ajustes" — abre `SettingsMenu` (instanciado dentro del propio
  `PauseMenu`, o como escena hija — tu criterio de composición).
- "Salir de la sala" — reutiliza el botón/lógica ya existente de Plan 24
  (`exit_room_button`/`_on_exit_room_pressed` en `casino_floor.gd`), NO
  dupliques esa lógica, solo dispara la señal/llamada existente desde el
  nuevo botón del menú de pausa.
- "Salir al escritorio" — mismo flujo de confirmación que en
  `SettingsMenu` (factoriza el diálogo de confirmación como componente
  compartido entre los dos si quieres, no es obligatorio).

**Decisión crítica, la parte más delicada de este agente: NO uses
`get_tree().paused = true`.** Esto es multijugador con autoridad en el
host — pausar el árbol de escena completo pararía el procesamiento de
red/RPCs para todos los presentes, no solo para quien abrió el menú.
`PauseMenu` es puramente un overlay visual local: tapa la pantalla,
bloquea la interacción del jugador que lo abrió con los controles de su
propia mesa (mismo patrón `mouse_filter=STOP` que ya usa `DefeatOverlay`
para taparlo todo, con cuidado de que los propios botones del menú de
pausa sí reciban clics — como ya se resolvió el bug de `DefeatOverlay`
bloqueando el botón "Volver al lobby", revisa ese fix antes de repetir
el error). El resto de la partida sigue corriendo en tiempo real para
todos — no hay forma de "pausar" una partida multijugador en curso sin
coordinar a todos los presentes, y eso es explícitamente fuera de
alcance de este agente.

## Fuera de alcance

- Pausa real sincronizada entre todos los jugadores (congelar la ronda
  para todos) — no se pide, y sería un cambio de diseño de red mucho
  mayor.
- Ajustes de idioma/controles/accesibilidad — solo audio + pantalla +
  salir, según lo que pidió el usuario.
- Logros/créditos — Agente 30.

## Verificación

- Tests GUT: `SettingsMenu` existe con los 3 sliders + 3 checkboxes +
  toggle de pantalla + botón salir; cambiar un slider llama
  `AudioManager.set_bus_volume_db` con el bus y valor correctos (usa el
  `AudioManager` real del autoload, no un mock — mismo patrón que el
  resto del proyecto). Persistencia de `[display]` en un `ConfigFile` de
  prueba (ruta temporal inyectable, no `user://settings.cfg` real en el
  test, mismo criterio que pidió plan25 para sí mismo). `PauseMenu` se
  abre/cierra con la acción `ui_cancel` simulada
  (`Input.action_press("ui_cancel")` en un test, si GUT lo permite de
  forma fiable en headless — si no, deja ese caso concreto como
  verificación manual y dilo explícito).
- Verificación en vivo: confirmar que abrir el menú de pausa durante una
  partida con 2 clientes Steam NO congela al otro jugador (prueba
  crítica, no te la saltes ni la des por sentada solo por el código).

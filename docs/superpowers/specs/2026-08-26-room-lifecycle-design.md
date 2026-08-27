# Diseño: ciclo de vida de sala + pantalla de inicio real

**Fecha:** 2026-08-26
**Autor:** sesión pilar
**Estado:** aprobado por el usuario, pendiente de plan de implementación

## Contexto

El usuario pidió pausar reskin visual (Póker queda pospuesto) y Plan de diseño,
y en su lugar "perfeccionar la aplicación base": crear salas / interfaces de
inicio de aplicación.

Investigando el repo antes de diseñar nada, esta sesión pilar encontró un
hallazgo real, no documentado en `todo_agents.md`: **la app empaquetada no
tiene forma de crear ni unirse a una sala Steam real.**

- `project.godot` (`run/main_scene`) arranca directo en
  `res://scenes/casino_floor.tscn`.
- `scenes/lobby_menu.tscn`/`.gd` — la única pantalla que llama
  `SteamManager.create_lobby()`/`join_lobby()` — no está referenciada desde
  ningún otro script del repo (`grep` confirmado). Es código huérfano.
- `NetworkManager._start_as_host()`/`_start_as_client()` (que crean el
  `SteamMultiplayerPeer` real y lo asignan a `multiplayer.multiplayer_peer`)
  solo se disparan desde `SteamManager.lobby_ready`, señal que solo emite
  `create_lobby`/`join_lobby` — o sea, solo `LobbyMenu` los dispara.
- Conclusión: sin `LobbyMenu` como punto de entrada, `CasinoFloor` arranca sin
  ningún peer real; `multiplayer.is_server()` es `true` por defecto (peer
  único sin conectar), así que la app corre en un modo "servidor solitario"
  local, nunca en una sala Steam de verdad. Los playtests con 2 cuentas
  documentados en `todo_agents.md` (Plan 13, barrida del 24-08, etc.)
  casi con certeza lanzaron `lobby_menu.tscn` a mano desde el editor (F6),
  no la app tal como arranca hoy.

Esto explica por qué el usuario siente que falta "la parte de crear salas":
literalmente no está conectada.

## Alcance de esta ronda

Confirmado con el usuario, pregunta por pregunta:

1. **Arreglar y completar `LobbyMenu`** como pantalla de inicio real (no
   solo conectar `main_scene` sin más, no rediseñar desde cero).
2. **Añadir "Salir de la sala"** desde `CasinoFloor` — hoy no existe forma de
   dejar una sala Steam en curso y volver a crear/unirse a otra sin cerrar
   la app entera.
3. **Mínimo de 2 jugadores para empezar partida se mantiene sin cambios** —
   el casino es multijugador por diseño, no se añade modo "jugar solo".
4. **Feedback de error visible + botón "Cancelar"** entran en alcance — hoy
   los fallos de Steam solo se ven en consola (`push_error`), y no hay forma
   de cancelar mientras el host espera invitados.

**Fuera de alcance, explícito:**
- Reskin visual de `LobbyMenu` (controles Godot por defecto, sin
  `CasinoTheme`/`BetSidebarPanel` — el usuario pidió pausar diseño).
- Póker (pospuesto, sin referencia visual todavía).
- Vaciado de asiento cuando un invitado se desconecta a mitad de partida
  (el host simplemente sigue jugando, comportamiento actual sin cambios) —
  es un problema de lógica de juego, no de pantalla de inicio.
- Lista/navegador de salas de amigos — se sigue dependiendo del overlay de
  invitación de Steam (`Steam.activateGameOverlayInviteDialog`) y de
  `Steam.join_requested`, ambos ya funcionan.

## Diseño

### Flujo general

```
project.godot main_scene → lobby_menu.tscn   (antes: casino_floor.tscn)

LobbyMenu (pantalla de inicio)
  ├─ Steam no listo → create_button deshabilitado, aviso en ErrorLabel
  ├─ elegir modo (Libre/1v1/2v2/4v4) + "Crear partida"
  │    → crea sala Steam, aparece "Cancelar", espera invitados (mínimo 2,
  │      sin cambios en esa regla)
  │    → al completarse el mínimo → change_scene_to_file(casino_floor.tscn)
  ├─ "Cancelar" (nuevo) → Steam.leaveLobby + reset de estado → vuelve a idle
  ├─ recibir invitación (overlay Steam, ya funciona) → se une → misma
  │    transición a CasinoFloor
  └─ fallo al crear/unir, o sala cerrada por el otro lado → ErrorLabel
       visible con el motivo, controles vuelven a idle (se puede reintentar)

CasinoFloor (mesas)
  └─ en la rejilla de selección de juego (nivel superior, hoy sin botón
     "atrás"): nuevo "Salir de la sala" → _leave_room() → limpia
     peer/Steam/estado → change_scene_to_file(lobby_menu.tscn)
  └─ "‹ Volver" existente (mesa → rejilla) sin cambios
  └─ invitado: si el host cierra la sala o crashea, Godot dispara
     multiplayer.server_disconnected → mismo _leave_room(), con motivo
     "El host cerró la sala."
```

### `LobbyMenu` (`scenes/lobby_menu.gd`/`.tscn`)

Nodos nuevos: `ErrorLabel` (oculto por defecto), `CancelButton` (oculto por
defecto, junto a `InviteButton`).

- `_ready()`: se conecta también a `SteamManager.steam_ready`. Si llega
  `ok == false` (o ya se sabe que falló, ver nota de timing abajo),
  `create_button.disabled = true` y `ErrorLabel.text = "Steam no está
  disponible ahora mismo"`. Si `SteamManager.last_disconnect_reason` no
  está vacío, lo muestra en `ErrorLabel` y lo limpia a `""` inmediatamente
  después de leerlo.
  - Nota de timing: `SteamManager` es autoload y su `_ready()` (que llama
    `steamInitEx` y emite `steam_ready`) corre antes que el de cualquier
    escena, así que `LobbyMenu` puede perderse la señal si ya se emitió.
    Exponer un campo `SteamManager.is_ready: bool` (guardado en el propio
    handler de `steam_ready`) para que `LobbyMenu._ready()` pueda
    consultar el estado ya resuelto en vez de depender solo de la señal.
- `_on_create_pressed()`: sin cambios de lógica, además hace
  `cancel_button.visible = true`.
- `_on_cancel_pressed()` (nuevo): `Steam.leaveLobby(SteamManager.current_lobby_id)`
  si `> 0`, `SteamManager.reset()`, y una función compartida
  `_reset_to_idle()` que: `create_button.disabled = false`,
  `invite_button.disabled = true`, `invite_button.visible = false`,
  `cancel_button.visible = false`, `members_label.text = "Jugadores: "`,
  `ErrorLabel.visible = false`.
- `_on_lobby_join_failed(reason)`: además del `push_error` que ya hace,
  `ErrorLabel.text = reason`, `ErrorLabel.visible = true`, llama
  `_reset_to_idle()`.

### `SteamManager` (`autoloads/steam_manager.gd`)

- Nueva var `is_ready: bool = false`, puesta en el handler existente de
  `steamInitEx` justo antes de `steam_ready.emit(ok)`.
- Nueva var `last_disconnect_reason: String = ""`.
- Nuevo método `reset() -> void`: `current_lobby_id = 0`,
  `chosen_match_type = -1`. (`last_disconnect_reason` NO se limpia aquí —
  lo limpia quien lo lee, `LobbyMenu._ready()`, para que sobreviva el
  cambio de escena.)

### `NetworkManager` (`autoloads/network_manager.gd`)

- Nuevo método `reset() -> void`: `peer_steam_ids.clear()`.

### `CasinoFloor` (`scripts/net/casino_floor.gd`, `scenes/casino_floor.tscn`)

- Nuevo nodo `ExitRoomButton` en el HUD/lobby, visible exactamente cuando
  `_lobby.is_in_lobby()` es verdadero — mismo interruptor que ya usa
  `_refresh_room_visibility()` (hoy, en ese estado, no se muestra ningún
  botón; pasa a mostrar este). `back_button` sigue con su visibilidad
  actual (`not _lobby.is_in_lobby()`), sin cambios.
- `_ready()`: se conecta a `multiplayer.server_disconnected` →
  `_leave_room("El host cerró la sala.")`.
- `_on_exit_room_pressed()` (nuevo) → `_leave_room("")`.
- `_leave_room(reason: String) -> void` (nuevo, compartida por ambos
  caminos):
  1. `if multiplayer.multiplayer_peer != null: multiplayer.multiplayer_peer.close()`
  2. `if SteamManager.current_lobby_id > 0: Steam.leaveLobby(SteamManager.current_lobby_id)`
  3. `SteamManager.reset()`
  4. `NetworkManager.reset()`
  5. `SteamManager.last_disconnect_reason = reason`
  6. `get_tree().change_scene_to_file("res://scenes/lobby_menu.tscn")`

## Testing

`SteamManager.reset()`/`is_ready`/`last_disconnect_reason` y
`NetworkManager.reset()` son manipulación de estado puro sobre autoloads —
testeables con GUT sin Steam real, mismo patrón que
`tests/unit/test_steam_manager.gd` ya usa para `parse_match_type`. Casos
nuevos:

- `test_reset_clears_current_lobby_id_and_match_type`
- `test_reset_does_not_clear_last_disconnect_reason` (documenta la decisión
  deliberada de que solo lo limpia quien lo lee)
- `test_network_manager_reset_clears_peer_steam_ids`

El resto (flujo real de botones de `LobbyMenu`, señales de Steam,
`server_disconnected`) no es testeable por GUT sin una sesión Steam en
vivo — igual que hoy, se apoya en verificación manual en vivo por parte de
esta sesión pilar y/o del usuario, no en tests nuevos de UI.

## Archivos tocados

- `project.godot` (`run/main_scene`)
- `scenes/lobby_menu.tscn`/`.gd`
- `autoloads/steam_manager.gd`
- `autoloads/network_manager.gd`
- `scripts/net/casino_floor.gd`, `scenes/casino_floor.tscn`
- `tests/unit/test_steam_manager.gd` (casos nuevos), nuevo
  `tests/unit/test_network_manager.gd`

No toca ningún `*_table_state.gd`/`*_table_controller.gd`/escena de mesa —
cero riesgo de conflicto con Póker o cualquier trabajo visual futuro.

# Integración Steam (Lobbies) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Conectar el proyecto a Steamworks vía el addon GodotSteam, permitir crear/unirse a lobbies de amigos, e invitar desde el overlay de Steam — sin lógica de juego todavía, solo la capa de conexión sobre la que Plan 3 construirá el `CasinoFloor` compartido.

**Architecture:** Dos autoloads (singletons): `SteamManager` (inicialización de Steam y gestión de lobby) y `NetworkManager` (envuelve `SteamMultiplayerPeer` y lo conecta al `MultiplayerAPI` nativo de Godot). Una escena `LobbyMenu` mínima para crear partida, invitar amigos y ver quién está conectado.

**Tech Stack:** Godot 4.4+, addon GDExtension GodotSteam (MIT, `addons/godotsteam/`), `SteamMultiplayerPeer` (parte del mismo addon) como `MultiplayerPeer` para el `MultiplayerAPI` de Godot.

**Spec:** `docs/superpowers/specs/2026-08-17-casino-multiplayer-design.md`

## Global Constraints

- Motor: Godot 4.4 o superior (la build del addon GodotSteam usada aquí, GDExtension 4.21, exige 4.4+; si el proyecto usa una versión anterior, hay que descargar la build del addon correspondiente en su lugar).
- Durante todo el desarrollo se usa el App ID de pruebas público de Valve, **480 (Spacewar)**, vía `steam_appid.txt`. El App ID real de 100 USD solo hace falta al publicar en Steam (spec: "Coste total real: 100 USD una vez").
- Emparejamiento por Steam Lobbies, no por código de sala manual (spec: "Conexión: host-cliente por código de sala" resuelta en la práctica con lobbies + invitación desde overlay).
- Sin persistencia entre partidas — nada de lo construido aquí debe guardar estado en disco.

## Nota sobre testing en este plan

A diferencia de Plan 1 (lógica pura, testeable con GUT sin dependencias externas), todo lo de este plan depende de un cliente de Steam real, con sesión iniciada, corriendo en la máquina. Eso no es automatizable en headless/CI, así que cada tarea termina en **verificación manual** (ejecutar el proyecto con Steam abierto y comprobar el resultado en el Output/consola) en vez de un test GUT en verde. Se necesitan **dos cuentas de Steam distintas** (o dos instancias del juego bajo cuentas distintas) para verificar las tareas de lobby y red.

---

## Task 1: Instalar GodotSteam y confirmar inicialización

**Files:**
- Create: `addons/godotsteam/` (addon GDExtension, descargado)
- Create: `steam_appid.txt`
- Create: `autoloads/steam_manager.gd`
- Modify: `project.godot` (añadir autoload)

**Interfaces:**
- Produce: autoload global `SteamManager` con señal `steam_ready(success: bool)`.

- [ ] **Step 1: Descargar e instalar el addon**

```bash
ASSET_JSON=$(curl -s "https://godotengine.org/asset-library/api/asset/2445")
DOWNLOAD_URL=$(echo "$ASSET_JSON" | grep -o '"download_url":"[^"]*"' | cut -d '"' -f4 | sed 's/\\\//\//g')
curl -L "$DOWNLOAD_URL" -o /tmp/godotsteam.zip
unzip -q /tmp/godotsteam.zip -d /tmp/godotsteam_extracted
mkdir -p addons
cp -r /tmp/godotsteam_extracted/*/addons/godotsteam addons/godotsteam
```

El asset 2445 es "GodotSteam GDExtension 4.4+" (MIT, ver https://godotengine.org/asset-library/asset/2445). Si el proyecto usa Godot 4.1–4.3, usar en su lugar el asset 3866; si usa 4.0, el asset 1768 (cambiar el `2445` del comando por el id correspondiente).

El zip descargado es un snapshot completo del repositorio, no solo el addon: verifica que tras el `cp` exista `addons/godotsteam/godotsteam.gdextension` — si la ruta interna difiere, ajusta el `cp` para localizar esa carpeta dentro de lo extraído. Este addon es un GDExtension puro: no necesita entrada en `[editor_plugins]` de `project.godot` ni activarse manualmente.

- [ ] **Step 2: Crear `steam_appid.txt`**

```
480
```

Guardar en la raíz del proyecto, sin salto de línea extra. Este archivo es solo para desarrollo — no se incluye en el build final que se sube a Steam.

- [ ] **Step 3: Implementar SteamManager**

```gdscript
extends Node

signal steam_ready(success: bool)

var steam_id: int = 0
var steam_username: String = ""

func _ready() -> void:
    var init_result: Dictionary = Steam.steamInitEx(480, true)
    var ok: bool = init_result["status"] == 0
    if not ok:
        push_error("Steam init failed (%d): %s" % [init_result["status"], init_result["verbal"]])
    else:
        steam_id = Steam.getSteamID()
        steam_username = Steam.getPersonaName()
        print("Steam initialized OK for user: %s (%d)" % [steam_username, steam_id])
    steam_ready.emit(ok)

func _process(_delta: float) -> void:
    Steam.run_callbacks()
```

Guardar en `autoloads/steam_manager.gd`.

- [ ] **Step 4: Registrar el autoload**

Añadir a `project.godot`, sección `[autoload]` (crearla si no existe):

```ini
[autoload]

SteamManager="*res://autoloads/steam_manager.gd"
```

- [ ] **Step 5: Verificación manual**

Con el cliente de Steam abierto y con sesión iniciada, ejecutar el proyecto (`godot --path . -e` y pulsar Play, o `godot --path .`). Comprobar en el Output/consola la línea `Steam initialized OK for user: <tu nombre> (<tu id>)`. Si aparece el error de `push_error`, confirmar que el cliente de Steam está realmente abierto y que `steam_appid.txt` está en la raíz del proyecto exportado/ejecutado.

- [ ] **Step 6: Commit**

```bash
git add addons/godotsteam steam_appid.txt autoloads/steam_manager.gd project.godot
git commit -m "feat: install GodotSteam addon and initialize Steam on boot"
```

---

## Task 2: Crear y unirse a lobbies

**Files:**
- Modify: `autoloads/steam_manager.gd`

**Interfaces:**
- Consume: `Steam.steamInitEx`, señal `steam_ready` (Task 1).
- Produce (añadido a `SteamManager`): `create_lobby(max_members: int) -> void`, `join_lobby(lobby_id: int) -> void`, señales `lobby_ready(lobby_id: int, is_owner: bool)`, `lobby_join_failed(reason: String)`.

- [ ] **Step 1: Añadir la gestión de lobby a SteamManager**

Añadir a `autoloads/steam_manager.gd`:

```gdscript
signal lobby_ready(lobby_id: int, is_owner: bool)
signal lobby_join_failed(reason: String)

var current_lobby_id: int = 0

func _ready() -> void:
    Steam.lobby_created.connect(_on_lobby_created)
    Steam.lobby_joined.connect(_on_lobby_joined)
    var init_result: Dictionary = Steam.steamInitEx(480, true)
    var ok: bool = init_result["status"] == 0
    if not ok:
        push_error("Steam init failed (%d): %s" % [init_result["status"], init_result["verbal"]])
    else:
        steam_id = Steam.getSteamID()
        steam_username = Steam.getPersonaName()
        print("Steam initialized OK for user: %s (%d)" % [steam_username, steam_id])
    steam_ready.emit(ok)

func create_lobby(max_members: int) -> void:
    Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, max_members)

func join_lobby(lobby_id: int) -> void:
    Steam.joinLobby(lobby_id)

func _on_lobby_created(connect_result: int, lobby_id: int) -> void:
    # connect_result usa los códigos EResult de Steamworks: 1 = k_EResultOK.
    # Ojo: es una escala distinta a la de steamInitEx (donde 0 = éxito).
    if connect_result != 1:
        lobby_join_failed.emit("No se pudo crear el lobby (código %d)" % connect_result)
        return
    current_lobby_id = lobby_id
    lobby_ready.emit(lobby_id, true)

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
    if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
        lobby_join_failed.emit("No se pudo unir al lobby (código %d)" % response)
        return
    current_lobby_id = lobby_id
    lobby_ready.emit(lobby_id, lobby_id == Steam.getLobbyOwner(lobby_id))
```

Nota: `_ready()` sustituye por completo a la versión de Task 1 (se añaden las conexiones de señal antes del `steamInitEx`), no se duplica.

- [ ] **Step 2: Verificación manual con dos cuentas**

Añadir temporalmente dos líneas de depuración en cualquier `_ready()` de la escena principal (o usar la consola remota de Godot):

```gdscript
SteamManager.lobby_ready.connect(func(id, is_owner): print("Lobby listo: %d (owner=%s)" % [id, is_owner]))
SteamManager.lobby_join_failed.connect(func(reason): print("Fallo de lobby: %s" % reason))
```

En la instancia A, llamar `SteamManager.create_lobby(4)` y anotar el `lobby_id` impreso. En la instancia B (cuenta de Steam distinta), llamar `SteamManager.join_lobby(<lobby_id de A>)`. Confirmar que ambas instancias imprimen `Lobby listo` con el mismo `lobby_id`, y que solo A tiene `owner=true`.

- [ ] **Step 3: Commit**

```bash
git add autoloads/steam_manager.gd
git commit -m "feat: add lobby creation and joining to SteamManager"
```

---

## Task 3: SteamMultiplayerPeer — lobby a sesión multijugador de Godot

**Files:**
- Create: `autoloads/network_manager.gd`
- Modify: `project.godot` (añadir autoload)

**Interfaces:**
- Consume: señal `SteamManager.lobby_ready(lobby_id: int, is_owner: bool)` (Task 2), `Steam.getLobbyOwner(lobby_id: int) -> int` (Task 2).
- Produce: autoload `NetworkManager`, método interno que deja `multiplayer.multiplayer_peer` listo para usar con el `MultiplayerAPI` estándar de Godot (`multiplayer.peer_connected`, `multiplayer.peer_disconnected`, RPCs) — es lo que Plan 3 (`CasinoFloor`/`TableController`) consumirá directamente.

- [ ] **Step 1: Implementar NetworkManager**

```gdscript
extends Node

func _ready() -> void:
    SteamManager.lobby_ready.connect(_on_lobby_ready)
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_lobby_ready(lobby_id: int, is_owner: bool) -> void:
    if is_owner:
        _start_as_host()
    else:
        var host_steam_id: int = Steam.getLobbyOwner(lobby_id)
        _start_as_client(host_steam_id)

func _start_as_host() -> void:
    var peer := SteamMultiplayerPeer.new()
    peer.create_host(0, [])
    multiplayer.multiplayer_peer = peer
    print("NetworkManager: host listo")

func _start_as_client(host_steam_id: int) -> void:
    var peer := SteamMultiplayerPeer.new()
    peer.create_client(host_steam_id, 0, [])
    multiplayer.multiplayer_peer = peer
    print("NetworkManager: conectando al host %d" % host_steam_id)

func _on_peer_connected(id: int) -> void:
    print("Peer conectado: %d" % id)

func _on_peer_disconnected(id: int) -> void:
    print("Peer desconectado: %d" % id)
```

Guardar en `autoloads/network_manager.gd`.

- [ ] **Step 2: Registrar el autoload**

Añadir a `project.godot`, dentro de `[autoload]` (debajo de `SteamManager`, el orden importa: `NetworkManager` debe cargar después):

```ini
NetworkManager="*res://autoloads/network_manager.gd"
```

- [ ] **Step 3: Verificación manual con dos cuentas**

Repetir el flujo de Task 2 (A crea lobby, B se une). Confirmar en consola de A: `NetworkManager: host listo` seguido de `Peer conectado: <id de B>`. Confirmar en consola de B: `NetworkManager: conectando al host <id de A>` seguido de `Peer conectado: <id de A>` (Godot también reporta la propia conexión al host en el cliente).

- [ ] **Step 4: Commit**

```bash
git add autoloads/network_manager.gd project.godot
git commit -m "feat: bridge Steam lobby into Godot MultiplayerAPI via SteamMultiplayerPeer"
```

---

## Task 4: Menú de lobby — crear, invitar, ver jugadores

**Files:**
- Create: `scenes/lobby_menu.tscn`
- Create: `scenes/lobby_menu.gd`

**Interfaces:**
- Consume: `SteamManager.create_lobby(int)`, `SteamManager.lobby_ready`, `SteamManager.current_lobby_id` (Task 1/2), `Steam.getNumLobbyMembers`, `Steam.getLobbyMemberByIndex`, `Steam.getFriendPersonaName`, `Steam.activateGameOverlayInviteDialog` (API de Steamworks estándar).

- [ ] **Step 1: Escribir el script de la escena**

```gdscript
extends Control

@onready var create_button: Button = $CreateButton
@onready var invite_button: Button = $InviteButton
@onready var members_label: Label = $MembersLabel

func _ready() -> void:
    create_button.pressed.connect(_on_create_pressed)
    invite_button.pressed.connect(_on_invite_pressed)
    invite_button.disabled = true
    SteamManager.lobby_ready.connect(_on_lobby_ready)
    Steam.lobby_chat_update.connect(_on_lobby_chat_update)

func _on_create_pressed() -> void:
    create_button.disabled = true
    SteamManager.create_lobby(4)

func _on_invite_pressed() -> void:
    Steam.activateGameOverlayInviteDialog(SteamManager.current_lobby_id)

func _on_lobby_ready(_lobby_id: int, _is_owner: bool) -> void:
    invite_button.disabled = false
    _refresh_members()

func _on_lobby_chat_update(_lobby_id: int, _change_id: int, _making_change_id: int, _chat_state: int) -> void:
    _refresh_members()

func _refresh_members() -> void:
    var lobby_id := SteamManager.current_lobby_id
    var names: Array[String] = []
    var count: int = Steam.getNumLobbyMembers(lobby_id)
    for i in range(count):
        var member_id: int = Steam.getLobbyMemberByIndex(lobby_id, i)
        names.append(Steam.getFriendPersonaName(member_id))
    members_label.text = "Jugadores: %s" % ", ".join(names)
```

Guardar en `scenes/lobby_menu.gd`.

- [ ] **Step 2: Crear la escena en el editor de Godot**

Crear escena nueva `Control` como raíz, guardar como `scenes/lobby_menu.tscn`. Añadir como hijos: `Button` llamado `CreateButton` (texto "Crear partida"), `Button` llamado `InviteButton` (texto "Invitar amigos"), `Label` llamado `MembersLabel`. Adjuntar `scenes/lobby_menu.gd` a la raíz.

- [ ] **Step 3: Verificación manual con dos cuentas (flujo completo)**

Instancia A: ejecutar `lobby_menu.tscn`, pulsar "Crear partida". Cuando `MembersLabel` muestre el propio nombre, pulsar "Invitar amigos" — se abre el overlay de Steam con la lista de amigos. Invitar a la cuenta B (tiene que ser un amigo real de Steam de la cuenta A para que aparezca en el overlay). Instancia B: aceptar la invitación desde el overlay/notificación de Steam (esto lanza el juego y lo une al lobby automáticamente si Steam está configurado para ello, o requiere llamar `SteamManager.join_lobby` con el id recibido en `Steam.lobby_invite` si se maneja manualmente — documentar cuál de los dos ocurre y ajustar si hace falta conectar la señal `Steam.lobby_invite`). Confirmar que `MembersLabel` en ambas instancias termina mostrando los dos nombres.

- [ ] **Step 4: Commit**

```bash
git add scenes/lobby_menu.tscn scenes/lobby_menu.gd
git commit -m "feat: add LobbyMenu scene for creating lobbies and inviting friends"
```

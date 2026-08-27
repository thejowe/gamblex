# Ciclo de vida de sala + pantalla de inicio real — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Conectar `LobbyMenu` (hoy huérfana) como pantalla de inicio real de la app, completarla con cancelar/errores visibles, y añadir una forma de salir de una sala Steam en curso (intencional o por desconexión del host) de vuelta a esa pantalla.

**Architecture:** Cambios acotados a 4 archivos de lógica (`SteamManager`, `NetworkManager`, `LobbyMenu`, `CasinoFloor`) más `project.godot`. Ningún cambio a `*_table_state.gd`/`*_table_controller.gd`/escenas de mesa — cero riesgo de conflicto con trabajo futuro de Póker o visual.

**Tech Stack:** Godot 4.7.1 (GDScript), GodotSteam, GUT (test framework).

**Spec:** `docs/superpowers/specs/2026-08-26-room-lifecycle-design.md`

## Global Constraints

- El mínimo de 2 jugadores para empezar partida NO cambia — no se añade modo "jugar solo" (decisión confirmada con el usuario).
- Sin reskin visual: controles Godot por defecto (`Button`/`Label`/`OptionButton`), sin `CasinoTheme`/`BetSidebarPanel` — el usuario pidió pausar diseño.
- El vaciado de asiento cuando un invitado se desconecta a mitad de partida queda fuera de alcance — el host simplemente sigue jugando, sin cambios.
- No tocar Póker ni ninguna mesa (`scripts/<juego>/`, `*_table_controller.gd`, `*_table_net.tscn`/`.gd`).
- Para correr Godot/GUT usa el binario estándar `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe` (el binario custom `godotsteam.multiplayerpeer.451...` tiene Error 127, no lo uses).
- Antes de confiar en un run de GUT tras tocar clases/nodos nuevos, reconstruye la caché (`godot --headless --editor --quit --path .`) y revisa `git status` después — descarta con `git checkout --` cualquier reformateo espacios/tabs en archivos que no tocaste (gotcha ya documentado en `todo_agents.md`, ha pasado repetidamente en `casino_floor.gd`/`poker_table_state.gd`).
- Estilo de indentación: tabs, no espacios (así está todo el código actual que tocas).

---

### Task 1: `SteamManager` — `is_ready`, `last_disconnect_reason`, `reset()`

**Files:**
- Modify: `autoloads/steam_manager.gd`
- Test: `tests/unit/test_steam_manager.gd`

**Interfaces:**
- Produces: `SteamManager.is_ready: bool` (refleja el resultado de `steamInitEx`), `SteamManager.last_disconnect_reason: String` (motivo de la última salida de sala, vacío si ninguno), `SteamManager.reset() -> void` (limpia `current_lobby_id`/`chosen_match_type`, deliberadamente NO toca `last_disconnect_reason`).

- [ ] **Step 1: Escribe los tests que fallan**

Añade al final de `tests/unit/test_steam_manager.gd`:

```gdscript
func test_reset_clears_current_lobby_id_and_match_type():
	SteamManager.current_lobby_id = 999
	SteamManager.chosen_match_type = 2
	SteamManager.reset()
	assert_eq(SteamManager.current_lobby_id, 0)
	assert_eq(SteamManager.chosen_match_type, -1)

func test_reset_does_not_clear_last_disconnect_reason():
	SteamManager.last_disconnect_reason = "El host cerró la sala."
	SteamManager.reset()
	assert_eq(SteamManager.last_disconnect_reason, "El host cerró la sala.")
	SteamManager.last_disconnect_reason = ""
```

- [ ] **Step 2: Confirma que fallan por falta de `reset()`/`last_disconnect_reason`**

Godot fallará al parsear el test (`Invalid call. Nonexistent function 'reset'` /
`Invalid get index 'last_disconnect_reason'`) porque `SteamManager` todavía no
los tiene. Ejecuta la suite completa (ver Task 6 para el comando exacto) y
confirma que estos dos tests concretos son los que fallan.

- [ ] **Step 3: Implementa en `autoloads/steam_manager.gd`**

El archivo hoy empieza así (líneas 1-24):

```gdscript
extends Node

signal steam_ready(success: bool)
signal lobby_ready(lobby_id: int, is_owner: bool)
signal lobby_join_failed(reason: String)

var steam_id: int = 0
var steam_username: String = ""
var current_lobby_id: int = 0
var chosen_match_type: int = -1

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_join_requested)
	var init_result: Dictionary = Steam.steamInitEx()
	var ok: bool = init_result["status"] == 0
	if not ok:
		push_error("Steam init failed (%d): %s" % [init_result["status"], init_result["verbal"]])
	else:
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()
		print("Steam initialized OK for user: %s (%d)" % [steam_username, steam_id])
	steam_ready.emit(ok)
```

Reemplázalo por:

```gdscript
extends Node

signal steam_ready(success: bool)
signal lobby_ready(lobby_id: int, is_owner: bool)
signal lobby_join_failed(reason: String)

var steam_id: int = 0
var steam_username: String = ""
var current_lobby_id: int = 0
var chosen_match_type: int = -1
var is_ready: bool = false
var last_disconnect_reason: String = ""

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_join_requested)
	var init_result: Dictionary = Steam.steamInitEx()
	var ok: bool = init_result["status"] == 0
	if not ok:
		push_error("Steam init failed (%d): %s" % [init_result["status"], init_result["verbal"]])
	else:
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()
		print("Steam initialized OK for user: %s (%d)" % [steam_username, steam_id])
	is_ready = ok
	steam_ready.emit(ok)

func reset() -> void:
	current_lobby_id = 0
	chosen_match_type = -1
```

El resto del archivo (`create_lobby`, `join_lobby`, `_on_join_requested`,
`_on_lobby_created`, `parse_match_type`, `_on_lobby_joined`) no cambia.

- [ ] **Step 4: Corre la suite y confirma que los dos tests nuevos pasan**

Ver Task 6 para el comando exacto de GUT. Confirma en la salida
`test_reset_clears_current_lobby_id_and_match_type` y
`test_reset_does_not_clear_last_disconnect_reason` en verde.

- [ ] **Step 5: Commit**

```bash
git add autoloads/steam_manager.gd tests/unit/test_steam_manager.gd
git commit -m "feat(steam-manager): add is_ready, last_disconnect_reason, reset()"
```

---

### Task 2: `NetworkManager` — `reset()`

**Files:**
- Modify: `autoloads/network_manager.gd`
- Test: Create `tests/unit/test_network_manager.gd`

**Interfaces:**
- Produces: `NetworkManager.reset() -> void` (vacía `peer_steam_ids`).

- [ ] **Step 1: Escribe el test nuevo**

Crea `tests/unit/test_network_manager.gd`:

```gdscript
extends GutTest

func test_reset_clears_peer_steam_ids():
	NetworkManager.peer_steam_ids[1] = 12345
	NetworkManager.reset()
	assert_eq(NetworkManager.peer_steam_ids.size(), 0)
```

- [ ] **Step 2: Confirma que falla**

Corre la suite (Task 6) — falla con `Nonexistent function 'reset'` porque
`NetworkManager` todavía no lo tiene.

- [ ] **Step 3: Implementa en `autoloads/network_manager.gd`**

Añade este método, en cualquier punto del archivo junto a los demás
`func`s de nivel superior (por ejemplo justo después de `_on_peer_disconnected`,
al final del archivo):

```gdscript
func reset() -> void:
	peer_steam_ids.clear()
```

- [ ] **Step 4: Corre la suite y confirma que pasa**

`test_reset_clears_peer_steam_ids` en verde.

- [ ] **Step 5: Commit**

```bash
git add autoloads/network_manager.gd tests/unit/test_network_manager.gd
git commit -m "feat(network-manager): add reset()"
```

---

### Task 3: `project.godot` — arrancar en `LobbyMenu`

**Files:**
- Modify: `project.godot`

**Interfaces:**
- Consumes: nada de tareas anteriores.
- Produces: la app empaquetada/ejecutada arranca en `lobby_menu.tscn` en vez de `casino_floor.tscn`.

- [ ] **Step 1: Cambia la línea de escena principal**

`project.godot` línea 18 hoy:

```
run/main_scene="res://scenes/casino_floor.tscn"
```

Cámbiala a:

```
run/main_scene="res://scenes/lobby_menu.tscn"
```

- [ ] **Step 2: Verifica que el proyecto carga sin errores de parseo**

```bash
"/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe" --headless --editor --quit --path .
```

Esto también reconstruye la caché de clases, útil antes de las tareas
siguientes. Revisa `git status` después — si el editor reformateó
espacios/tabs en archivos que no has tocado en esta tarea, descártalo con
`git checkout --` antes de seguir (no commitees ese ruido).

- [ ] **Step 3: Commit**

```bash
git add project.godot
git commit -m "feat(boot): start the app in LobbyMenu instead of CasinoFloor directly"
```

---

### Task 4: `LobbyMenu` — cancelar, errores visibles, Steam-no-listo

**Files:**
- Modify: `scenes/lobby_menu.tscn`
- Modify: `scenes/lobby_menu.gd`
- Test: Create `tests/unit/test_lobby_menu.gd`

**Interfaces:**
- Consumes: `SteamManager.is_ready`, `SteamManager.last_disconnect_reason`, `SteamManager.reset()` (Task 1).
- Produces: nodos `CancelButton`/`ErrorLabel` en la escena; métodos
  `LobbyMenu._reset_to_idle() -> void`, `LobbyMenu._show_error(message: String) -> void`,
  `LobbyMenu._on_steam_ready(ok: bool) -> void`, todos accesibles para test
  directo sobre la instancia (GDScript no oculta métodos `_prefijados`, solo
  es convención).

- [ ] **Step 1: Añade los nodos nuevos a `scenes/lobby_menu.tscn`**

El archivo completo hoy tiene 44 líneas, termina así (líneas 29-44):

```
[node name="InviteButton" type="Button" parent="."]
layout_mode = 0
offset_left = 220.0
offset_top = 60.0
offset_right = 400.0
offset_bottom = 96.0
text = "Invitar amigos"

[node name="MembersLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 20.0
offset_top = 116.0
offset_right = 500.0
offset_bottom = 140.0
text = "Jugadores: "
```

Reemplázalo por (añade `CancelButton` junto a `InviteButton` y `ErrorLabel`
debajo de `MembersLabel`):

```
[node name="InviteButton" type="Button" parent="."]
layout_mode = 0
offset_left = 220.0
offset_top = 60.0
offset_right = 400.0
offset_bottom = 96.0
text = "Invitar amigos"

[node name="CancelButton" type="Button" parent="."]
layout_mode = 0
offset_left = 410.0
offset_top = 60.0
offset_right = 590.0
offset_bottom = 96.0
text = "Cancelar"
visible = false

[node name="MembersLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 20.0
offset_top = 116.0
offset_right = 500.0
offset_bottom = 140.0
text = "Jugadores: "

[node name="ErrorLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 20.0
offset_top = 146.0
offset_right = 700.0
offset_bottom = 170.0
theme_override_colors/font_color = Color(1, 0.3, 0.3, 1)
text = ""
visible = false
```

- [ ] **Step 2: Escribe el test que falla**

Crea `tests/unit/test_lobby_menu.gd`:

```gdscript
extends GutTest

func test_scene_has_cancel_and_error_nodes():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	assert_not_null(root.get_node_or_null("CancelButton"), "falta el nodo CancelButton")
	assert_not_null(root.get_node_or_null("ErrorLabel"), "falta el nodo ErrorLabel")

func test_reset_to_idle_hides_cancel_and_error():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	root.get_node("CancelButton").visible = true
	root.get_node("ErrorLabel").visible = true
	root._reset_to_idle()
	assert_false(root.get_node("CancelButton").visible)
	assert_false(root.get_node("ErrorLabel").visible)

func test_show_error_sets_text_and_visible():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	root._show_error("mensaje de prueba")
	assert_eq(root.get_node("ErrorLabel").text, "mensaje de prueba")
	assert_true(root.get_node("ErrorLabel").visible)

func test_on_steam_ready_false_disables_create_and_shows_error():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	root._on_steam_ready(false)
	assert_true(root.get_node("CreateButton").disabled)
	assert_true(root.get_node("ErrorLabel").visible)

func test_on_steam_ready_true_enables_create():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	root._on_steam_ready(true)
	assert_false(root.get_node("CreateButton").disabled)
```

- [ ] **Step 3: Confirma que fallan**

`CancelButton`/`ErrorLabel` no existen todavía (falla el Step 1 si no se
hizo antes — asegúrate de haber aplicado el cambio al `.tscn` primero) y
`_reset_to_idle`/`_show_error`/`_on_steam_ready` no existen en el script
todavía. Corre la suite (Task 6) y confirma que estos 5 tests fallan.

- [ ] **Step 4: Reescribe `scenes/lobby_menu.gd` completo**

```gdscript
extends Control

@onready var create_button: Button = $CreateButton
@onready var invite_button: Button = $InviteButton
@onready var cancel_button: Button = $CancelButton
@onready var members_label: Label = $MembersLabel
@onready var match_type_option: OptionButton = $MatchTypeOption
@onready var error_label: Label = $ErrorLabel

var _transitioned: bool = false

const FREE_MODE_MAX_MEMBERS := 4

func _ready() -> void:
	match_type_option.add_item("Libre", -1)
	match_type_option.add_item("1v1", TeamAssignment.MatchType.ONE_V_ONE)
	match_type_option.add_item("2v2", TeamAssignment.MatchType.TWO_V_TWO)
	match_type_option.add_item("4v4", TeamAssignment.MatchType.FOUR_V_FOUR)
	create_button.pressed.connect(_on_create_pressed)
	invite_button.pressed.connect(_on_invite_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	SteamManager.lobby_ready.connect(_on_lobby_ready)
	SteamManager.lobby_join_failed.connect(_on_lobby_join_failed)
	SteamManager.steam_ready.connect(_on_steam_ready)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	_reset_to_idle()
	if not SteamManager.is_ready:
		_on_steam_ready(false)
	if not SteamManager.last_disconnect_reason.is_empty():
		_show_error(SteamManager.last_disconnect_reason)
		SteamManager.last_disconnect_reason = ""

func _on_steam_ready(ok: bool) -> void:
	create_button.disabled = not ok
	if not ok:
		_show_error("Steam no está disponible ahora mismo")

func _on_create_pressed() -> void:
	create_button.disabled = true
	cancel_button.visible = true
	var match_type: int = match_type_option.get_selected_id()
	SteamManager.chosen_match_type = match_type
	var max_members: int = FREE_MODE_MAX_MEMBERS if match_type == -1 else TeamAssignment.team_size_for(match_type) * 2
	SteamManager.create_lobby(max_members)

func _on_cancel_pressed() -> void:
	if SteamManager.current_lobby_id > 0:
		Steam.leaveLobby(SteamManager.current_lobby_id)
	SteamManager.reset()
	_reset_to_idle()

func _on_invite_pressed() -> void:
	Steam.activateGameOverlayInviteDialog(SteamManager.current_lobby_id)

func _on_lobby_ready(lobby_id: int, is_owner: bool) -> void:
	invite_button.disabled = false
	_refresh_members()
	print("LobbyMenu: lobby lista, id %d (compártelo si el overlay de invitar no sirve)" % lobby_id)
	if not is_owner:
		# El invitado ya llega acompañado del host, pasa directo a la mesa.
		_go_to_casino_floor()

func _on_lobby_join_failed(reason: String) -> void:
	push_error("LobbyMenu: %s" % reason)
	SteamManager.reset()
	_reset_to_idle()
	_show_error(reason)

func _on_lobby_chat_update(_lobby_id: int, _change_id: int, _making_change_id: int, _chat_state: int) -> void:
	_refresh_members()
	# El host espera aquí (con el botón de invitar visible) hasta que haya
	# suficiente gente: en modo libre, con que se una uno más ya alcanza;
	# en modo batalla espera a que ambos equipos estén completos.
	var min_members: int = 2 if SteamManager.chosen_match_type == -1 else TeamAssignment.team_size_for(SteamManager.chosen_match_type) * 2
	if Steam.getNumLobbyMembers(SteamManager.current_lobby_id) >= min_members:
		_go_to_casino_floor()

func _go_to_casino_floor() -> void:
	if _transitioned:
		return
	_transitioned = true
	get_tree().change_scene_to_file("res://scenes/casino_floor.tscn")

func _refresh_members() -> void:
	var lobby_id := SteamManager.current_lobby_id
	var names: Array[String] = []
	var count: int = Steam.getNumLobbyMembers(lobby_id)
	for i in range(count):
		var member_id: int = Steam.getLobbyMemberByIndex(lobby_id, i)
		names.append(Steam.getFriendPersonaName(member_id))
	members_label.text = "Jugadores: %s" % ", ".join(names)

func _reset_to_idle() -> void:
	create_button.disabled = false
	invite_button.disabled = true
	cancel_button.visible = false
	members_label.text = "Jugadores: "
	error_label.visible = false

func _show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true
```

Nota: `_ready()` llama `_on_steam_ready(false)` en vez de duplicar la lógica
de deshabilitar+mostrar error cuando `SteamManager.is_ready` ya es `false`
al montar la escena (por ejemplo, si Steam no estaba corriendo al arrancar
la app) — reutiliza el mismo camino que la señal en vivo.

- [ ] **Step 5: Corre la suite y confirma que los 5 tests nuevos pasan**

- [ ] **Step 6: Commit**

```bash
git add scenes/lobby_menu.tscn scenes/lobby_menu.gd tests/unit/test_lobby_menu.gd
git commit -m "feat(lobby-menu): add cancel, visible errors, and steam-not-ready handling"
```

---

### Task 5: `CasinoFloor` — salir de la sala

**Files:**
- Modify: `scenes/casino_floor.tscn`
- Modify: `scripts/net/casino_floor.gd`
- Test: Modify `tests/unit/test_casino_floor_scene_structure.gd`

**Interfaces:**
- Consumes: `SteamManager.reset()` (Task 1), `NetworkManager.reset()` (Task 2), `lobby_menu.tscn` como destino de escena (Task 3).
- Produces: nodo `ExitRoomButton` en `Hud`; `CasinoFloor._leave_room(reason: String) -> void`, `CasinoFloor._on_exit_room_pressed() -> void`, `CasinoFloor._on_server_disconnected() -> void`.

- [ ] **Step 1: Añade `ExitRoomButton` a `scenes/casino_floor.tscn`**

El bloque de `BackButton` hoy (líneas 211-223):

```
[node name="BackButton" type="Button" parent="Hud"]
anchor_left = 1.0
anchor_right = 1.0
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = -180.0
offset_top = -75.0
offset_right = -20.0
offset_bottom = -35.0
grow_horizontal = 0
grow_vertical = 0
text = "‹ Volver al lobby"
visible = false
```

Justo después (antes del bloque `[node name="DefeatOverlay" ...]`), añade:

```
[node name="ExitRoomButton" type="Button" parent="Hud"]
anchor_left = 1.0
anchor_right = 1.0
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = -180.0
offset_top = -75.0
offset_right = -20.0
offset_bottom = -35.0
grow_horizontal = 0
grow_vertical = 0
text = "Salir de la sala"
```

(Mismo rectángulo que `BackButton` — nunca son visibles a la vez, se
alternan en `_refresh_room_visibility()`.)

- [ ] **Step 2: Escribe los tests que fallan**

Añade al final de `tests/unit/test_casino_floor_scene_structure.gd`:

```gdscript
func test_scene_has_exit_room_button_node():
	var scene = load("res://scenes/casino_floor.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	var exit_button = root.get_node_or_null("Hud/ExitRoomButton")
	assert_not_null(exit_button, "falta el nodo Hud/ExitRoomButton")

func test_exit_room_button_visible_in_lobby_back_button_hidden():
	var scene = load("res://scenes/casino_floor.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	assert_true(root.get_node("Hud/ExitRoomButton").visible)
	assert_false(root.get_node("Hud/BackButton").visible)
```

- [ ] **Step 3: Confirma que fallan**

`Hud/ExitRoomButton` no existe todavía en el script (el nodo del `.tscn`
existe tras el Step 1, pero `_refresh_room_visibility()` no lo referencia
todavía, así que el segundo test falla por `visible` sin sincronizar —
en la práctica ambos tests fallarán si aplicaste el Step 1 sin el Step 4).

- [ ] **Step 4: Edita `scripts/net/casino_floor.gd`**

Añade el `@onready var` nuevo, junto a los demás (línea 26 hoy es
`@onready var back_button: Button = $Hud/BackButton`):

```gdscript
@onready var back_button: Button = $Hud/BackButton
@onready var exit_room_button: Button = $Hud/ExitRoomButton
```

En `_ready()`, la línea `back_button.pressed.connect(_on_back_pressed)`
(línea 43 hoy) gana dos conexiones más justo debajo:

```gdscript
	back_button.pressed.connect(_on_back_pressed)
	exit_room_button.pressed.connect(_on_exit_room_pressed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_refresh_room_visibility()
```

`_refresh_room_visibility()` (líneas 118-122 hoy):

```gdscript
func _refresh_room_visibility() -> void:
	lobby_view.visible = _lobby.is_in_lobby()
	back_button.visible = not _lobby.is_in_lobby()
	for table_name in _table_nodes:
		_table_nodes[table_name].visible = _lobby.is_active(table_name)
```

pasa a:

```gdscript
func _refresh_room_visibility() -> void:
	lobby_view.visible = _lobby.is_in_lobby()
	back_button.visible = not _lobby.is_in_lobby()
	exit_room_button.visible = _lobby.is_in_lobby()
	for table_name in _table_nodes:
		_table_nodes[table_name].visible = _lobby.is_active(table_name)
```

Y añade estas tres funciones nuevas, junto a `_on_back_pressed()`:

```gdscript
func _on_exit_room_pressed() -> void:
	_leave_room("")

func _on_server_disconnected() -> void:
	_leave_room("El host cerró la sala.")

func _leave_room(reason: String) -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	if SteamManager.current_lobby_id > 0:
		Steam.leaveLobby(SteamManager.current_lobby_id)
	SteamManager.reset()
	NetworkManager.reset()
	SteamManager.last_disconnect_reason = reason
	get_tree().change_scene_to_file("res://scenes/lobby_menu.tscn")
```

- [ ] **Step 5: Corre la suite y confirma que los 2 tests nuevos pasan**

- [ ] **Step 6: Commit**

```bash
git add scenes/casino_floor.tscn scripts/net/casino_floor.gd tests/unit/test_casino_floor_scene_structure.gd
git commit -m "feat(casino-floor): add exit-room flow and handle host disconnect"
```

---

### Task 6: Verificación final de la suite completa

**Files:** ninguno nuevo — solo verificación.

- [ ] **Step 1: Reconstruye la caché de clases**

```bash
"/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe" --headless --editor --quit --path .
```

- [ ] **Step 2: Revisa `git status` y descarta reformateo espurio**

Si aparece algún archivo modificado que no tocaste en este plan (típico:
`casino_floor.gd`/`poker_table_state.gd` con solo cambios de
espacios/tabs), confírmalo con `git diff --stat` y `git diff` línea por
línea antes de descartar — si el diff mezcla tu propio cambio real con
reformateo, no descartes a ciegas, deshaz solo la parte de reformateo a
mano.

- [ ] **Step 3: Corre la suite GUT completa**

```bash
"/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit --path .
```

Confirma que el conteo total de tests subió en
al menos 10 respecto al conteo previo a este plan (2 de Task 1, 1 de
Task 2, 5 de Task 4, 2 de Task 5) y que todos pasan.

- [ ] **Step 4: Verifica que ambas escenas cargan sin error**

```bash
"/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe" --headless --path . --quit
```

Revisa la salida por errores de parseo/nodo faltante en `lobby_menu.tscn`
o `casino_floor.tscn`. Repite el chequeo de `git status` por reformateo
espurio tras este comando también.

- [ ] **Step 5: Reporta a la sesión pilar**

No dev dar por cerrado el trabajo tú solo — informa exactamente:
- Conteo final de tests GUT (antes/después).
- Confirmación de que ambas escenas cargan sin error en headless.
- **Explícito y sin suavizar**: falta el playtest real con 2 clientes
  Steam (crear sala → invitar → jugar → uno sale con "Salir de la
  sala" → el otro ve que el host se fue si le tocó a él salir) — no
  está disponible en tu sesión, es responsabilidad de la sesión pilar
  o del usuario confirmarlo en vivo antes de cerrar el todo del todo.

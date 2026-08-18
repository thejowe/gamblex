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

# TEMP verificación manual Task 4 (Plan 2) — borrar antes de commitear.
# El overlay de Steam no abre dentro del editor (limitación conocida del addon),
# así que para probar la sincronización de MembersLabel sin exportar el juego,
# B se une a mano con la tecla J leyendo el lobby_id del portapapeles.
func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.echo:
		return
	if event is InputEventKey and event.keycode == KEY_J:
		var id_str := DisplayServer.clipboard_get().strip_edges()
		print("Uniendo a lobby %s (desde portapapeles)..." % id_str)
		SteamManager.join_lobby(int(id_str))

func _on_lobby_ready(lobby_id: int, _is_owner: bool) -> void:
	invite_button.disabled = false
	print("Lobby listo: %d" % lobby_id)  # TEMP verificación manual Task 4 — borrar antes de commitear.
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

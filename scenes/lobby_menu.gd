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

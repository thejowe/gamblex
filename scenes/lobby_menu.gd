extends Control

@onready var create_button: Button = $CreateButton
@onready var invite_button: Button = $InviteButton
@onready var members_label: Label = $MembersLabel
@onready var match_type_option: OptionButton = $MatchTypeOption

var _transitioned: bool = false

func _ready() -> void:
	match_type_option.add_item("1v1", TeamAssignment.MatchType.ONE_V_ONE)
	match_type_option.add_item("2v2", TeamAssignment.MatchType.TWO_V_TWO)
	match_type_option.add_item("4v4", TeamAssignment.MatchType.FOUR_V_FOUR)
	create_button.pressed.connect(_on_create_pressed)
	invite_button.pressed.connect(_on_invite_pressed)
	invite_button.disabled = true
	SteamManager.lobby_ready.connect(_on_lobby_ready)
	SteamManager.lobby_join_failed.connect(_on_lobby_join_failed)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)

func _on_create_pressed() -> void:
	create_button.disabled = true
	var match_type: int = match_type_option.get_selected_id()
	SteamManager.chosen_match_type = match_type
	SteamManager.create_lobby(TeamAssignment.team_size_for(match_type) * 2)

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

func _on_lobby_chat_update(_lobby_id: int, _change_id: int, _making_change_id: int, _chat_state: int) -> void:
	_refresh_members()
	# El host espera aquí (con el botón de invitar visible) hasta que se llene el equipo.
	var max_members: int = TeamAssignment.team_size_for(SteamManager.chosen_match_type) * 2
	if Steam.getNumLobbyMembers(SteamManager.current_lobby_id) >= max_members:
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

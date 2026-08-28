extends Control

@onready var create_button: Button = $CreateButton
@onready var invite_button: Button = $InviteButton
@onready var cancel_button: Button = $CancelButton
@onready var members_label: Label = $MembersLabel
@onready var match_type_option: OptionButton = $MatchTypeOption
@onready var error_label: Label = $ErrorLabel
@onready var credits_button: CasinoButton = $CreditsButton

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
	credits_button.pressed.connect(_on_credits_pressed)
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
	AudioManager.play_music("lobby")

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

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/casino/credits_menu.tscn")

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
	var loading: LoadingScreen = preload("res://scenes/ui/casino/loading_screen.tscn").instantiate()
	add_child(loading)
	loading.fade_and_change_scene("res://scenes/casino_floor.tscn")

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

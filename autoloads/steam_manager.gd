extends Node

signal steam_ready(success: bool)
signal lobby_ready(lobby_id: int, is_owner: bool)
signal lobby_join_failed(reason: String)

var steam_id: int = 0
var steam_username: String = ""
var current_lobby_id: int = 0
var chosen_match_type: int = TeamAssignment.MatchType.ONE_V_ONE

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

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func create_lobby(max_members: int) -> void:
	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, max_members)

func join_lobby(lobby_id: int) -> void:
	Steam.joinLobby(lobby_id)

func _on_join_requested(lobby_id: int, _steam_id: int) -> void:
	# Disparado por Steam (overlay/notificación/lista de amigos) cuando el
	# usuario pulsa "Unirse" a una partida de un amigo — la app no se une sola.
	print("SteamManager: join_requested recibido para lobby %d" % lobby_id)
	join_lobby(lobby_id)

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
	if lobby_id == current_lobby_id:
		# Steamworks dispara lobby_joined también para quien acaba de crear la lobby
		# (crearla implica entrar en ella) — _on_lobby_created ya emitió lobby_ready.
		return
	current_lobby_id = lobby_id
	lobby_ready.emit(lobby_id, Steam.getLobbyOwner(lobby_id) == steam_id)

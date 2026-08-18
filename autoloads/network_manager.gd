extends Node

signal identities_changed

# unique_id de red (int, asignado por SteamMultiplayerPeer) -> SteamID64 real.
# Necesario porque el unique_id de red no es el SteamID ni el AccountID de Steam,
# así que no se puede reconstruir matemáticamente para pedirle el nombre a Steam.
var peer_steam_ids: Dictionary = {}

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
	peer.create_host(0)
	multiplayer.multiplayer_peer = peer
	peer_steam_ids[multiplayer.get_unique_id()] = SteamManager.steam_id
	print("NetworkManager: host listo")

func _start_as_client(host_steam_id: int) -> void:
	var peer := SteamMultiplayerPeer.new()
	peer.create_client(host_steam_id, 0)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server, CONNECT_ONE_SHOT)
	print("NetworkManager: conectando al host %d" % host_steam_id)

func _on_connected_to_server() -> void:
	_announce_identity.rpc_id(1, SteamManager.steam_id)

@rpc("any_peer", "call_remote", "reliable")
func _announce_identity(steam_id: int) -> void:
	if not multiplayer.is_server():
		return
	peer_steam_ids[multiplayer.get_remote_sender_id()] = steam_id
	_receive_identities.rpc(peer_steam_ids)

@rpc("authority", "call_local", "reliable")
func _receive_identities(ids: Dictionary) -> void:
	peer_steam_ids = ids
	identities_changed.emit()

func _on_peer_connected(id: int) -> void:
	print("Peer conectado: %d" % id)

func _on_peer_disconnected(id: int) -> void:
	print("Peer desconectado: %d" % id)

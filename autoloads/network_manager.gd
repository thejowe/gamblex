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
	peer.create_host(0)
	multiplayer.multiplayer_peer = peer
	print("NetworkManager: host listo")

func _start_as_client(host_steam_id: int) -> void:
	var peer := SteamMultiplayerPeer.new()
	peer.create_client(host_steam_id, 0)
	multiplayer.multiplayer_peer = peer
	print("NetworkManager: conectando al host %d" % host_steam_id)

func _on_peer_connected(id: int) -> void:
	print("Peer conectado: %d" % id)

func _on_peer_disconnected(id: int) -> void:
	print("Peer desconectado: %d" % id)

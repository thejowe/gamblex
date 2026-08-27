extends GutTest

func test_reset_clears_peer_steam_ids():
	NetworkManager.peer_steam_ids[1] = 12345
	NetworkManager.reset()
	assert_eq(NetworkManager.peer_steam_ids.size(), 0)

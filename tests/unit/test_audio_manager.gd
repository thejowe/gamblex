extends GutTest

func test_three_buses_exist() -> void:
	assert_ne(AudioServer.get_bus_index("Music"), -1)
	assert_ne(AudioServer.get_bus_index("SFX"), -1)
	assert_ne(AudioServer.get_bus_index("Master"), -1)

func test_default_volumes_are_audible() -> void:
	assert_gt(AudioManager.get_bus_volume_db("Master"), -80.0)
	assert_gt(AudioManager.get_bus_volume_db("Music"), -80.0)
	assert_gt(AudioManager.get_bus_volume_db("SFX"), -80.0)

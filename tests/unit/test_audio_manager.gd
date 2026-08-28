extends GutTest

func test_three_buses_exist() -> void:
	assert_ne(AudioServer.get_bus_index("Music"), -1)
	assert_ne(AudioServer.get_bus_index("SFX"), -1)
	assert_ne(AudioServer.get_bus_index("Master"), -1)

func test_default_volumes_are_audible() -> void:
	assert_gt(AudioManager.get_bus_volume_db("Master"), -80.0)
	assert_gt(AudioManager.get_bus_volume_db("Music"), -80.0)
	assert_gt(AudioManager.get_bus_volume_db("SFX"), -80.0)

func test_volume_persists_across_reload() -> void:
	AudioManager.set_bus_volume_db("Music", -12.0)
	AudioManager._save_settings()
	AudioManager._load_settings()
	assert_almost_eq(AudioManager.get_bus_volume_db("Music"), -12.0, 0.01)

func test_save_settings_preserves_foreign_sections() -> void:
	var cfg := ConfigFile.new()
	cfg.load(AudioManager.SETTINGS_PATH)
	cfg.set_value("display", "fullscreen", true)
	cfg.save(AudioManager.SETTINGS_PATH)

	AudioManager.set_bus_volume_db("SFX", -6.0)
	AudioManager._save_settings()

	var check := ConfigFile.new()
	check.load(AudioManager.SETTINGS_PATH)
	assert_true(check.get_value("display", "fullscreen", false))

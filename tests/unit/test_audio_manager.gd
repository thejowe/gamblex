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

func test_play_sfx_known_name_no_error() -> void:
	AudioManager.play_sfx("click")
	AudioManager.play_sfx("chip")
	AudioManager.play_sfx("card")
	AudioManager.play_sfx("dice")
	AudioManager.play_sfx("spin")
	AudioManager.play_sfx("win")
	AudioManager.play_sfx("lose")
	pass_test("no crashea con ningún nombre válido")

func test_play_sfx_unknown_name_warns_no_crash() -> void:
	AudioManager.play_sfx("nombre_inventado")
	pass_test("no crashea con nombre desconocido")

func test_play_sfx_jackpot_no_error() -> void:
	AudioManager.play_sfx("jackpot")
	pass_test("no crashea con el arpegio de jackpot")

func test_play_win_sfx_lose_ignores_amounts() -> void:
	AudioManager.play_win_sfx(false, 500, 100)
	pass_test("no crashea al perder con payout alto")

func test_play_win_sfx_small_win_no_error() -> void:
	AudioManager.play_win_sfx(true, 20, 10)
	pass_test("no crashea con una victoria normal")

func test_play_win_sfx_big_payout_no_error() -> void:
	AudioManager.play_win_sfx(true, 1000, 10)
	pass_test("no crashea con un payout de jackpot (>=5x la apuesta)")

func test_play_music_no_error() -> void:
	AudioManager.play_music("lobby")
	AudioManager.play_music("table")
	pass_test("no crashea")

func test_play_music_same_track_is_noop() -> void:
	AudioManager.play_music("lobby")
	var player_before := AudioManager._current_music_player
	AudioManager.play_music("lobby")
	assert_eq(AudioManager._current_music_player, player_before)

func test_stop_music_no_error() -> void:
	AudioManager.play_music("table")
	AudioManager.stop_music()
	pass_test("no crashea al parar música")

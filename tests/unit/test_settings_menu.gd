extends GutTest

func test_volume_slider_calls_audio_manager() -> void:
	var menu := preload("res://scenes/ui/casino/settings_menu.tscn").instantiate()
	add_child_autofree(menu)
	menu.music_slider.value = -12.0
	menu._on_music_slider_changed(-12.0)
	assert_almost_eq(AudioManager.get_bus_volume_db("Music"), -12.0, 0.01)

func test_slider_initializes_from_current_volume() -> void:
	AudioManager.set_bus_volume_db("SFX", -8.0)
	var menu := preload("res://scenes/ui/casino/settings_menu.tscn").instantiate()
	add_child_autofree(menu)
	assert_almost_eq(menu.sfx_slider.value, -8.0, 0.01)

func test_mute_checkbox_calls_audio_manager() -> void:
	var menu := preload("res://scenes/ui/casino/settings_menu.tscn").instantiate()
	add_child_autofree(menu)
	menu.master_mute.button_pressed = true
	menu._on_master_mute_toggled(true)
	assert_true(AudioManager.is_bus_muted("Master"))
	AudioManager.set_bus_mute("Master", false)

func test_mute_checkbox_initializes_from_current_mute_state() -> void:
	AudioManager.set_bus_mute("SFX", true)
	var menu := preload("res://scenes/ui/casino/settings_menu.tscn").instantiate()
	add_child_autofree(menu)
	assert_true(menu.sfx_mute.button_pressed)
	AudioManager.set_bus_mute("SFX", false)

func test_fullscreen_preference_persists() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	var original_fullscreen: bool = cfg.get_value("display", "fullscreen", true)

	var menu := preload("res://scenes/ui/casino/settings_menu.tscn").instantiate()
	add_child_autofree(menu)
	menu._on_fullscreen_toggled(true)
	cfg.load("user://settings.cfg")
	assert_true(cfg.get_value("display", "fullscreen", false))
	menu._on_fullscreen_toggled(original_fullscreen)

func test_quit_button_requires_confirmation() -> void:
	var menu := preload("res://scenes/ui/casino/settings_menu.tscn").instantiate()
	add_child_autofree(menu)
	menu.quit_button.pressed.emit()
	assert_true(menu.quit_confirm.visible)

func test_close_button_hides_menu() -> void:
	var menu := preload("res://scenes/ui/casino/settings_menu.tscn").instantiate()
	add_child_autofree(menu)
	menu.visible = true
	menu.close_button.pressed.emit()
	assert_false(menu.visible)

extends GutTest

func _make() -> Control:
	var scene := load("res://scenes/home_screen.tscn")
	var instance: Control = scene.instantiate()
	add_child_autofree(instance)
	return instance

func test_has_five_buttons() -> void:
	var home := _make()
	assert_not_null(home.get_node("StartButton"))
	assert_not_null(home.get_node("SettingsButton"))
	assert_not_null(home.get_node("CreditsButton"))
	assert_not_null(home.get_node("HelpButton"))
	assert_not_null(home.get_node("QuitButton"))

func test_covers_full_screen() -> void:
	var home := _make()
	assert_eq(home.anchor_right, 1.0)
	assert_eq(home.anchor_bottom, 1.0)

func test_start_button_text() -> void:
	var home := _make()
	assert_eq(home.start_button.text, "Iniciar Partida")

func test_settings_button_opens_settings_menu() -> void:
	var home := _make()
	home.settings_button.pressed.emit()
	assert_true(home.settings_menu.visible)

func test_help_button_opens_help_overlay() -> void:
	var home := _make()
	home.help_button.pressed.emit()
	assert_true(home.help_overlay.visible)

func test_quit_button_triggers_confirm_dialog() -> void:
	var home := _make()
	assert_false(home.quit_confirm.visible)
	assert_true(home.quit_button.pressed.is_connected(home.quit_confirm.popup_centered))

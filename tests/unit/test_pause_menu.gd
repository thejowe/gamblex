extends GutTest

func test_pause_menu_does_not_block_own_buttons() -> void:
	var pause_menu := preload("res://scenes/ui/casino/pause_menu.tscn").instantiate()
	add_child_autofree(pause_menu)
	assert_ne(pause_menu.resume_button.mouse_filter, Control.MOUSE_FILTER_IGNORE)

func test_resume_button_hides_pause_menu() -> void:
	var pause_menu := preload("res://scenes/ui/casino/pause_menu.tscn").instantiate()
	add_child_autofree(pause_menu)
	pause_menu.visible = true
	pause_menu.resume_button.pressed.emit()
	assert_false(pause_menu.visible)

func test_settings_button_opens_settings_menu() -> void:
	var pause_menu := preload("res://scenes/ui/casino/pause_menu.tscn").instantiate()
	add_child_autofree(pause_menu)
	assert_false(pause_menu.settings_menu.visible)
	pause_menu.settings_button.pressed.emit()
	assert_true(pause_menu.settings_menu.visible)

func test_quit_button_requires_confirmation() -> void:
	var pause_menu := preload("res://scenes/ui/casino/pause_menu.tscn").instantiate()
	add_child_autofree(pause_menu)
	pause_menu.quit_button.pressed.emit()
	assert_true(pause_menu.quit_confirm.visible)

func test_exit_room_button_calls_provided_callback() -> void:
	var pause_menu := preload("res://scenes/ui/casino/pause_menu.tscn").instantiate()
	add_child_autofree(pause_menu)
	var called := [false]
	pause_menu.exit_room_requested.connect(func(): called[0] = true)
	pause_menu.exit_room_button.pressed.emit()
	assert_true(called[0])

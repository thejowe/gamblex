extends GutTest

func test_pause_menu_toggles_on_ui_cancel() -> void:
	var floor := preload("res://scenes/casino_floor.tscn").instantiate()
	add_child_autofree(floor)
	floor._toggle_pause_menu()
	assert_true(floor.pause_menu.visible)
	floor._toggle_pause_menu()
	assert_false(floor.pause_menu.visible)

func test_unhandled_input_ui_cancel_toggles_pause_menu() -> void:
	var floor := preload("res://scenes/casino_floor.tscn").instantiate()
	add_child_autofree(floor)
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	floor._unhandled_input(event)
	assert_true(floor.pause_menu.visible)

func test_pause_menu_exit_room_requested_calls_existing_exit_logic() -> void:
	var floor := preload("res://scenes/casino_floor.tscn").instantiate()
	add_child_autofree(floor)
	# _on_exit_room_pressed llama a Steam/multiplayer; en vez de disparar
	# esa cadena completa en un test unitario, confirmamos que la señal
	# del PauseMenu queda conectada exactamente a esa función existente.
	var connections := floor.pause_menu.exit_room_requested.get_connections()
	var found := false
	for c in connections:
		if c["callable"].get_method() == "_on_exit_room_pressed":
			found = true
	assert_true(found, "exit_room_requested del PauseMenu debe estar conectado a _on_exit_room_pressed existente")

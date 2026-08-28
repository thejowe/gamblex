extends GutTest

func test_scene_has_cancel_and_error_nodes():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	assert_not_null(root.get_node_or_null("CancelButton"), "falta el nodo CancelButton")
	assert_not_null(root.get_node_or_null("ErrorLabel"), "falta el nodo ErrorLabel")

func test_reset_to_idle_hides_cancel_and_error():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	root.get_node("CancelButton").visible = true
	root.get_node("ErrorLabel").visible = true
	root._reset_to_idle()
	assert_false(root.get_node("CancelButton").visible)
	assert_false(root.get_node("ErrorLabel").visible)

func test_show_error_sets_text_and_visible():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	root._show_error("mensaje de prueba")
	assert_eq(root.get_node("ErrorLabel").text, "mensaje de prueba")
	assert_true(root.get_node("ErrorLabel").visible)

func test_on_steam_ready_false_disables_create_and_shows_error():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	root._on_steam_ready(false)
	assert_true(root.get_node("CreateButton").disabled)
	assert_true(root.get_node("ErrorLabel").visible)

func test_on_steam_ready_true_enables_create():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	root._on_steam_ready(true)
	assert_false(root.get_node("CreateButton").disabled)

func test_go_to_casino_floor_instances_loading_screen():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	root._go_to_casino_floor()
	var found := false
	for child in root.get_children():
		if child is LoadingScreen:
			found = true
	assert_true(found, "falta un hijo LoadingScreen tras _go_to_casino_floor")

func test_go_to_casino_floor_is_idempotent():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	root._go_to_casino_floor()
	root._go_to_casino_floor()
	var count := 0
	for child in root.get_children():
		if child is LoadingScreen:
			count += 1
	assert_eq(count, 1, "una segunda llamada no debe instanciar otro LoadingScreen")

func test_settings_button_opens_settings_menu():
	var scene = load("res://scenes/lobby_menu.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	assert_false(root.settings_menu.visible)
	root.settings_button.pressed.emit()
	assert_true(root.settings_menu.visible)

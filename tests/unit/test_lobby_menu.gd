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

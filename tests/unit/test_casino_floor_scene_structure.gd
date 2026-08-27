extends GutTest

func test_scene_has_defeat_overlay_node_hidden_by_default():
	var scene = load("res://scenes/casino_floor.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	var overlay = root.get_node_or_null("Hud/DefeatOverlay")
	assert_not_null(overlay, "falta el nodo Hud/DefeatOverlay")
	assert_false(overlay.visible)

func test_scene_has_exit_room_button_node():
	var scene = load("res://scenes/casino_floor.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	var exit_button = root.get_node_or_null("Hud/ExitRoomButton")
	assert_not_null(exit_button, "falta el nodo Hud/ExitRoomButton")

func test_exit_room_button_visible_in_lobby_back_button_hidden():
	var scene = load("res://scenes/casino_floor.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	assert_true(root.get_node("Hud/ExitRoomButton").visible)
	assert_false(root.get_node("Hud/BackButton").visible)

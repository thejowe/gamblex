extends GutTest

func test_scene_has_defeat_overlay_node_hidden_by_default():
	var scene = load("res://scenes/casino_floor.tscn")
	var root = scene.instantiate()
	add_child_autofree(root)
	var overlay = root.get_node_or_null("Hud/DefeatOverlay")
	assert_not_null(overlay, "falta el nodo Hud/DefeatOverlay")
	assert_false(overlay.visible)

extends GutTest

func test_scene_has_expected_node_paths():
	var scene: PackedScene = load("res://scenes/roulette_table_net.tscn")
	var root: Node = scene.instantiate()
	add_child_autofree(root)
	for path in [
		"BetSidebarPanel", "RouletteWheelDisplay", "RouletteBettingGrid",
		"ResultsHistory", "SpinButton", "SitButton", "SeatsLabel", "TableController",
		"HelpButton", "HelpOverlay",
	]:
		assert_not_null(root.get_node_or_null(path), "falta el nodo %s" % path)

func test_help_button_opens_overlay():
	var scene: PackedScene = load("res://scenes/roulette_table_net.tscn")
	var root: Node = scene.instantiate()
	add_child_autofree(root)
	root.get_node("HelpButton").pressed.emit()
	assert_true(root.get_node("HelpOverlay").visible)

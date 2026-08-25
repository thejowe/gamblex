extends GutTest

func test_scene_has_expected_node_paths():
	var scene: PackedScene = load("res://scenes/mines_table_net.tscn")
	var root: Node = scene.instantiate()
	add_child_autofree(root)
	for path in [
		"BetSidebarPanel", "SizeOption", "MineCountEdit", "MineDensityLabel",
		"CashOutButton", "MinesGrid", "ResultFlash", "StatusLabel", "TableController",
	]:
		assert_not_null(root.get_node_or_null(path), "falta el nodo %s" % path)

extends GutTest

func test_scene_has_expected_node_paths():
	var scene: PackedScene = load("res://scenes/blackjack_table_net.tscn")
	var root := scene.instantiate()
	add_child_autofree(root)
	for path in [
		"FeltTablePanel", "DealerCards", "DealerValueLabel", "DeckIcon",
		"SeatsRoot", "SitButton", "BetSidebarPanel", "HitButton", "StandButton",
		"DoubleButton", "SplitButton", "CasinoHudBar", "TableController",
	]:
		assert_not_null(root.get_node_or_null(path), "falta el nodo %s" % path)

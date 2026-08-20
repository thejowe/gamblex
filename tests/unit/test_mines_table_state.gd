extends GutTest

func test_multiplier_matches_known_cases():
	# T=4, M=1: revelar 1 casilla segura -> 0.99 * 4/3 = 1.32
	assert_almost_eq(MinesTableState.multiplier(4, 1, 1), 1.32, 0.001)
	# revelar 2 -> 0.99 * (4/3)*(3/2) = 1.98
	assert_almost_eq(MinesTableState.multiplier(4, 1, 2), 1.98, 0.001)
	# revelar 3 (todas las seguras) -> 0.99 * (4/3)*(3/2)*(2/1) = 3.96
	assert_almost_eq(MinesTableState.multiplier(4, 1, 3), 3.96, 0.001)

func test_multiplier_at_zero_revealed_is_house_edge_baseline():
	assert_almost_eq(MinesTableState.multiplier(25, 3, 0), 0.99, 0.001)

func test_multiplier_default_grid_first_reveal():
	# T=25, M=3: 0.99 * 25/22
	assert_almost_eq(MinesTableState.multiplier(25, 3, 1), 1.125, 0.001)

func test_players_starts_empty():
	var table = MinesTableState.new()
	assert_eq(table.players.size(), 0)

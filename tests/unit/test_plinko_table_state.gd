extends GutTest

func test_comb_known_values():
	assert_eq(PlinkoTableState._comb(12, 0), 1)
	assert_eq(PlinkoTableState._comb(12, 6), 924)
	assert_eq(PlinkoTableState._comb(12, 12), 1)

func test_slot_multiplier_symmetric_and_edges_pay_more():
	var mult_edge = PlinkoTableState.slot_multiplier(12, 0)
	var mult_center = PlinkoTableState.slot_multiplier(12, 6)
	assert_true(mult_edge > mult_center)
	assert_almost_eq(mult_edge, PlinkoTableState.slot_multiplier(12, 12), 0.0001)
	assert_true(mult_center < 1.0)

func test_slot_multiplier_expected_return_is_99_percent():
	for rows in [8, 12, 16]:
		var expected_return := 0.0
		var total_outcomes: float = pow(2.0, rows)
		for slot in range(rows + 1):
			var probability: float = PlinkoTableState._comb(rows, slot) / total_outcomes
			expected_return += probability * PlinkoTableState.slot_multiplier(rows, slot)
		assert_almost_eq(expected_return, 0.99, 0.0001)

func test_players_starts_empty():
	var table = PlinkoTableState.new()
	assert_eq(table.players.size(), 0)

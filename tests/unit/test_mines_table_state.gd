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

func test_start_round_fails_on_invalid_mine_count():
	var table = MinesTableState.new()
	assert_false(table.start_round(111, 25, 0, 50))
	assert_false(table.start_round(111, 25, 25, 50))

func test_start_round_fails_on_insufficient_balance():
	var table = MinesTableState.new()
	var ok = table.start_round(111, 25, 3, 5000)
	assert_false(ok)
	assert_eq(table.players[111].ledger.balance, 500)

func test_start_round_creates_player_lazily_and_deducts_bet():
	var table = MinesTableState.new()
	table.start_round(111, 25, 3, 100)
	assert_true(table.players.has(111))
	assert_eq(table.players[111].ledger.balance, 400)

func test_start_round_fails_if_round_already_active():
	var table = MinesTableState.new()
	table.start_round(111, 25, 3, 100)
	var ok = table.start_round(111, 25, 3, 50)
	assert_false(ok)
	assert_eq(table.players[111].ledger.balance, 400)

func test_reveal_safe_cell_updates_multiplier_and_keeps_round_active():
	var roller = MinesRoller.new()
	roller.results = [[0, 1, 2]]
	var table = MinesTableState.new(roller)
	table.start_round(111, 25, 3, 100)
	var ok = table.reveal(111, 10)
	assert_true(ok)
	var round_data = table.players[111].active_round
	assert_eq(round_data["revealed"], [10])
	assert_almost_eq(round_data["multiplier"], MinesTableState.multiplier(25, 3, 1), 0.001)

func test_reveal_mine_ends_round_as_loss():
	var roller = MinesRoller.new()
	roller.results = [[0, 1, 2]]
	var table = MinesTableState.new(roller)
	table.start_round(111, 25, 3, 100)
	var ok = table.reveal(111, 0)
	assert_true(ok)
	assert_true(table.players[111].active_round.is_empty())
	assert_eq(table.players[111].ledger.balance, 400)
	assert_false(table.players[111].last_round["win"])

func test_reveal_fails_without_active_round():
	var table = MinesTableState.new()
	assert_false(table.reveal(111, 5))

func test_reveal_fails_on_out_of_range_index():
	var roller = MinesRoller.new()
	roller.results = [[0, 1, 2]]
	var table = MinesTableState.new(roller)
	table.start_round(111, 25, 3, 100)
	assert_false(table.reveal(111, 25))
	assert_false(table.reveal(111, -1))

func test_reveal_fails_on_already_revealed_index():
	var roller = MinesRoller.new()
	roller.results = [[0, 1, 2]]
	var table = MinesTableState.new(roller)
	table.start_round(111, 25, 3, 100)
	table.reveal(111, 10)
	assert_false(table.reveal(111, 10))

func test_reveal_all_safe_cells_auto_cashes_out_as_win():
	var roller = MinesRoller.new()
	roller.results = [[0]] # T=2, M=1: única casilla segura es el índice 1
	var table = MinesTableState.new(roller)
	table.start_round(111, 2, 1, 100)
	var ok = table.reveal(111, 1)
	assert_true(ok)
	assert_true(table.players[111].active_round.is_empty())
	assert_true(table.players[111].last_round["win"])
	# multiplicador tras revelar la única casilla segura: 0.99 * 2/1 = 1.98 -> payout int(100*1.98)=198
	assert_eq(table.players[111].ledger.balance, 500 - 100 + 198)

func test_reveal_does_not_emit_chips_won_on_loss():
	var roller = MinesRoller.new()
	roller.results = [[0, 1, 2]]
	var table = MinesTableState.new(roller)
	watch_signals(table)
	table.start_round(111, 25, 3, 100)
	table.reveal(111, 0)
	assert_signal_not_emitted(table, "chips_won")

func test_reveal_emits_chips_won_on_auto_cash_out_win():
	var roller = MinesRoller.new()
	roller.results = [[0]]
	var table = MinesTableState.new(roller)
	watch_signals(table)
	table.start_round(111, 2, 1, 100)
	table.reveal(111, 1)
	assert_signal_emitted_with_parameters(table, "chips_won", [111, 98])

func test_cash_out_fails_without_active_round():
	var table = MinesTableState.new()
	assert_false(table.cash_out(111))

func test_cash_out_fails_without_any_reveal():
	var table = MinesTableState.new()
	table.start_round(111, 25, 3, 100)
	assert_false(table.cash_out(111))
	assert_true(table.players[111].active_round.size() > 0)

func test_cash_out_pays_current_multiplier_and_ends_round():
	var roller = MinesRoller.new()
	roller.results = [[0, 1, 2]]
	var table = MinesTableState.new(roller)
	table.start_round(111, 25, 3, 100)
	table.reveal(111, 10)
	var mult = MinesTableState.multiplier(25, 3, 1)
	var ok = table.cash_out(111)
	assert_true(ok)
	assert_true(table.players[111].active_round.is_empty())
	var expected_payout = int(100 * mult)
	assert_eq(table.players[111].ledger.balance, 500 - 100 + expected_payout)
	assert_true(table.players[111].last_round["win"])

func test_cash_out_emits_chips_won_with_net_profit():
	var roller = MinesRoller.new()
	roller.results = [[0, 1, 2]]
	var table = MinesTableState.new(roller)
	watch_signals(table)
	table.start_round(111, 25, 3, 100)
	table.reveal(111, 10)
	var mult = MinesTableState.multiplier(25, 3, 1)
	var expected_payout = int(100 * mult)
	table.cash_out(111)
	assert_signal_emitted_with_parameters(table, "chips_won", [111, expected_payout - 100])

func test_rounds_independent_per_player():
	var roller = MinesRoller.new()
	roller.results = [[0, 1, 2], [5, 6, 7]]
	var table = MinesTableState.new(roller)
	table.start_round(111, 25, 3, 100)
	table.start_round(222, 25, 3, 100)
	table.reveal(111, 10)
	table.reveal(222, 5) # mina para 222
	assert_true(table.players[111].active_round.size() > 0)
	assert_true(table.players[222].active_round.is_empty())
	assert_eq(table.players[222].ledger.balance, 400)

func test_to_dict_hides_mine_positions_during_active_round():
	var roller = MinesRoller.new()
	roller.results = [[0, 1, 2]]
	var table = MinesTableState.new(roller)
	table.start_round(111, 25, 3, 100)
	table.reveal(111, 10)
	var data = table.to_dict()
	var active_round = data["players"][111]["active_round"]
	assert_false(active_round.has("mines"))
	assert_eq(active_round["revealed"], [10])
	assert_eq(active_round["total_cells"], 25)

func test_to_dict_reveals_mine_positions_only_after_round_ends():
	var roller = MinesRoller.new()
	roller.results = [[0, 1, 2]]
	var table = MinesTableState.new(roller)
	table.start_round(111, 25, 3, 100)
	table.reveal(111, 0) # mina -> game over
	var data = table.to_dict()
	assert_eq(data["players"][111]["last_round"]["mines"], [0, 1, 2])
	assert_true(data["players"][111]["active_round"].is_empty())

func test_to_dict_player_absent_until_first_action():
	var table = MinesTableState.new()
	assert_eq(table.players.size(), 0)
	assert_eq(table.to_dict()["players"].size(), 0)

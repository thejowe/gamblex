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

func test_roll_fails_on_rows_out_of_range():
	var table = PlinkoTableState.new()
	assert_false(table.roll(111, 7, 50))
	assert_false(table.roll(111, 17, 50))

func test_roll_succeeds_at_rows_boundaries():
	var roller = PlinkoRoller.new()
	var bounces_8: Array[bool] = [true, true, true, true, true, true, true, true]
	var bounces_16: Array[bool] = [true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true]
	roller.results = [bounces_8, bounces_16]
	var table = PlinkoTableState.new(roller)
	assert_true(table.roll(111, 8, 100))
	assert_true(table.roll(111, 16, 100))

func test_roll_fails_on_insufficient_balance():
	var table = PlinkoTableState.new()
	var ok = table.roll(111, 12, 5000)
	assert_false(ok)
	# _player_for crea la entrada perezosa (balance 500) antes de intentar el
	# place_bet de 5000; el jugador queda creado pero intacto, no se descuenta.
	assert_eq(table.players[111].ledger.balance, 500)

func test_roll_wins_edge_slot_pays_large_multiplier():
	var roller = PlinkoRoller.new()
	var bounces: Array[bool] = [true, true, true, true, true, true, true, true, true, true, true, true]
	roller.results = [bounces]
	var table = PlinkoTableState.new(roller)
	var ok = table.roll(111, 12, 100)
	assert_true(ok)
	# slot 12, multiplicador 0.99*4096/13/1 = 311.9261... -> payout roundi(100*311.9261...) = 31193
	assert_eq(table.players[111].ledger.balance, 500 - 100 + 31193)
	assert_true(table.players[111].last_round["win"])

func test_roll_loses_center_slot_partial_payout():
	var roller = PlinkoRoller.new()
	var bounces: Array[bool] = [true, false, true, false, true, false, true, false, true, false, true, false]
	roller.results = [bounces]
	var table = PlinkoTableState.new(roller)
	var ok = table.roll(111, 12, 100)
	assert_true(ok)
	# slot 6, multiplicador 0.99*4096/13/924 = 0.337588... -> payout roundi(100*0.337588...) = 34
	assert_eq(table.players[111].ledger.balance, 500 - 100 + 34)
	assert_false(table.players[111].last_round["win"])

func test_roll_emits_chips_won_with_net_profit_on_win():
	var roller = PlinkoRoller.new()
	var bounces: Array[bool] = [true, true, true, true, true, true, true, true, true, true, true, true]
	roller.results = [bounces]
	var table = PlinkoTableState.new(roller)
	watch_signals(table)
	table.roll(111, 12, 100)
	assert_signal_emitted_with_parameters(table, "chips_won", [111, 31093]) # 31193 payout - 100 apuesta

func test_roll_does_not_emit_chips_won_on_loss():
	var roller = PlinkoRoller.new()
	var bounces: Array[bool] = [true, false, true, false, true, false, true, false, true, false, true, false]
	roller.results = [bounces]
	var table = PlinkoTableState.new(roller)
	watch_signals(table)
	table.roll(111, 12, 100)
	assert_signal_not_emitted(table, "chips_won")

func test_roll_records_last_round_for_player():
	var roller = PlinkoRoller.new()
	var bounces: Array[bool] = [true, true, true, true, true, true, true, true, true, true, true, true]
	roller.results = [bounces]
	var table = PlinkoTableState.new(roller)
	table.roll(111, 12, 100)
	var last_round = table.players[111].last_round
	assert_eq(last_round["rows"], 12)
	assert_eq(last_round["amount"], 100)
	assert_eq(last_round["bounces"], bounces)
	assert_eq(last_round["slot"], 12)
	assert_eq(last_round["payout"], 31193)
	assert_true(last_round["win"])

func test_roll_independent_per_player():
	var roller = PlinkoRoller.new()
	var edge_bounces: Array[bool] = [true, true, true, true, true, true, true, true, true, true, true, true]
	var center_bounces: Array[bool] = [true, false, true, false, true, false, true, false, true, false, true, false]
	roller.results = [edge_bounces, center_bounces]
	var table = PlinkoTableState.new(roller)
	table.roll(111, 12, 100) # gana grande
	table.roll(222, 12, 100) # pierde parcial
	assert_eq(table.players[111].ledger.balance, 31593)
	assert_eq(table.players[222].ledger.balance, 434)

func test_to_dict_reflects_players_and_last_round():
	var roller = PlinkoRoller.new()
	var bounces: Array[bool] = [true, true, true, true, true, true, true, true, true, true, true, true]
	roller.results = [bounces]
	var table = PlinkoTableState.new(roller)
	table.roll(111, 12, 100)
	var data = table.to_dict()
	assert_eq(data["players"][111]["player_id"], 111)
	assert_eq(data["players"][111]["balance"], 31593)
	assert_eq(data["players"][111]["last_round"]["win"], true)

func test_roll_realized_rtp_is_close_to_99_percent_through_payout_path():
	var rows := 12
	var amount := 50
	var expected_return := 0.0
	var total_outcomes: float = pow(2.0, rows)
	for slot in range(rows + 1):
		var bounces: Array[bool] = []
		for i in range(slot):
			bounces.append(true)
		for i in range(rows - slot):
			bounces.append(false)
		var roller = PlinkoRoller.new()
		roller.results = [bounces]
		var table = PlinkoTableState.new(roller)
		table.roll(111, rows, amount)
		var payout: int = table.players[111].last_round["payout"]
		var probability: float = PlinkoTableState._comb(rows, slot) / total_outcomes
		expected_return += probability * (float(payout) / amount)
	assert_almost_eq(expected_return, 0.99, 0.02)

func test_roll_uses_external_ledger_for_new_player():
	var table = PlinkoTableState.new()
	var shared := ChipLedger.new(500)
	table.roll(111, 12, 100, shared)
	assert_eq(table.players[111].ledger, shared)

func test_roll_creates_individual_ledger_when_no_external_ledger_given():
	var table = PlinkoTableState.new()
	table.roll(111, 12, 100)
	assert_true(table.players.has(111))
	assert_ne(table.players[111].ledger, null)

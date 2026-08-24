extends GutTest

func test_players_starts_empty():
	var table = CrashTableState.new()
	assert_eq(table.players.size(), 0)

func test_multiplier_at_matches_formula():
	assert_almost_eq(CrashTableState.multiplier_at(0.0), 1.00, 0.001)
	# 1.00 + 0.02 * 7.072^2 ~= 2.00
	assert_almost_eq(CrashTableState.multiplier_at(7.072), 2.00, 0.01)

func test_place_bet_creates_player_lazily_with_starting_balance():
	var roller = CrashRoller.new()
	roller.results = [2.00] as Array[float]
	var table = CrashTableState.new(roller)
	var ok = table.place_bet(111, 100)
	assert_true(ok)
	assert_true(table.players.has(111))
	assert_eq(table.players[111].ledger.balance, 400)
	assert_true(table.players[111].is_active)

func test_place_bet_rejects_non_positive_amount():
	# El SpinBox de la UI limita el valor minimo del lado del cliente, pero
	# eso no es una frontera de seguridad: un cliente puede enviar cualquier
	# int via RPC. place_bet() debe rechazar montos <= 0 (ChipLedger.can_afford
	# exige amount > 0 and amount <= balance).
	var table = CrashTableState.new()
	assert_false(table.place_bet(111, 0))
	assert_false(table.place_bet(111, -100))
	assert_eq(table.players[111].ledger.balance, 500) # nada se descontó
	assert_false(table.players[111].is_active)

func test_place_bet_fails_on_insufficient_balance():
	var table = CrashTableState.new()
	var ok = table.place_bet(111, 5000)
	assert_false(ok)
	# _player_for crea la entrada perezosa (balance 500) antes del place_bet;
	# el jugador queda creado pero intacto, no se descuenta.
	assert_eq(table.players[111].ledger.balance, 500)
	assert_false(table.players[111].is_active)

func test_place_bet_fails_if_round_already_active():
	var roller = CrashRoller.new()
	roller.results = [2.00, 3.00] as Array[float]
	var table = CrashTableState.new(roller)
	table.place_bet(111, 100)
	var ok = table.place_bet(111, 50)
	assert_false(ok)
	# no se descontó la segunda apuesta
	assert_eq(table.players[111].ledger.balance, 400)

func test_cash_out_before_crash_pays_bet_times_current_multiplier():
	var roller = CrashRoller.new()
	roller.results = [5.00] as Array[float]
	var table = CrashTableState.new(roller)
	table.place_bet(111, 100)
	table.advance_time(7.072) # multiplicador actual ~2.00x
	var ok = table.cash_out(111)
	assert_true(ok)
	# payout = int(100 * 2.00) = 200
	assert_eq(table.players[111].ledger.balance, 500 - 100 + 200)
	assert_false(table.players[111].is_active)

func test_cash_out_emits_chips_won_with_net_profit():
	var roller = CrashRoller.new()
	roller.results = [5.00] as Array[float]
	var table = CrashTableState.new(roller)
	watch_signals(table)
	table.place_bet(111, 100)
	table.advance_time(7.072)
	table.cash_out(111)
	assert_signal_emitted_with_parameters(table, "chips_won", [111, 100]) # 200 payout - 100 apuesta

func test_cash_out_fails_if_no_active_round():
	var table = CrashTableState.new()
	assert_false(table.cash_out(111))

func test_advance_time_resolves_loss_when_multiplier_reaches_crash_point():
	var roller = CrashRoller.new()
	roller.results = [2.00] as Array[float]
	var table = CrashTableState.new(roller)
	watch_signals(table)
	table.place_bet(111, 100)
	var crashed = table.advance_time(7.072) # multiplicador llega a ~2.00x
	assert_eq(crashed, [111])
	assert_false(table.players[111].is_active)
	assert_eq(table.players[111].ledger.balance, 400) # perdió la apuesta
	assert_signal_not_emitted(table, "chips_won")

func test_cash_out_fails_after_round_already_crashed():
	var roller = CrashRoller.new()
	roller.results = [2.00] as Array[float]
	var table = CrashTableState.new(roller)
	table.place_bet(111, 100)
	table.advance_time(7.072)
	assert_false(table.cash_out(111)) # ya se resolvió como pérdida

func test_rounds_are_independent_per_player():
	var roller = CrashRoller.new()
	roller.results = [2.00, 10.00] as Array[float]
	var table = CrashTableState.new(roller)
	table.place_bet(111, 100) # explota en 2x
	table.place_bet(222, 100) # explota en 10x
	table.advance_time(7.072) # ~2.00x: 111 explota, 222 sigue activo
	assert_false(table.players[111].is_active)
	assert_true(table.players[222].is_active)

func test_to_dict_hides_crash_point_of_active_round():
	var roller = CrashRoller.new()
	roller.results = [3.00] as Array[float]
	var table = CrashTableState.new(roller)
	table.place_bet(111, 100)
	var data = table.to_dict()
	assert_true(data["players"][111]["is_active"])
	assert_false(data["players"][111].has("crash_point"))
	assert_eq(data["players"][111]["last_round"], {})

func test_to_dict_reveals_crash_point_after_round_resolves():
	var roller = CrashRoller.new()
	roller.results = [2.00] as Array[float]
	var table = CrashTableState.new(roller)
	table.place_bet(111, 100)
	table.advance_time(7.072)
	var data = table.to_dict()
	assert_false(data["players"][111]["is_active"])
	assert_eq(data["players"][111]["last_round"]["crash_point"], 2.00)
	assert_eq(data["players"][111]["last_round"]["win"], false)

func test_place_bet_uses_external_ledger_for_new_player():
	var table = CrashTableState.new()
	var shared := ChipLedger.new(500)
	table.place_bet(111, 100, shared)
	assert_eq(shared.balance, 400)

func test_place_bet_creates_individual_ledger_when_no_external_ledger_given():
	var table = CrashTableState.new()
	table.place_bet(111, 100)
	assert_eq(table.players[111].ledger.balance, 400)

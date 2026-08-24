extends GutTest

func test_win_chance_over():
    assert_eq(DiceTableState.win_chance(50, DiceTableState.Direction.OVER), 50.0)
    assert_eq(DiceTableState.win_chance(10, DiceTableState.Direction.OVER), 90.0)

func test_win_chance_under():
    assert_eq(DiceTableState.win_chance(50, DiceTableState.Direction.UNDER), 50.0)
    assert_eq(DiceTableState.win_chance(90, DiceTableState.Direction.UNDER), 90.0)

func test_multiplier_matches_known_cases():
    # umbral 50 "mayor que" -> ~2x (99/50 = 1.98)
    assert_almost_eq(DiceTableState.multiplier(50, DiceTableState.Direction.OVER), 1.98, 0.001)
    # umbral 10 "mayor que" -> ~1.1x (99/90 = 1.1)
    assert_almost_eq(DiceTableState.multiplier(10, DiceTableState.Direction.OVER), 1.1, 0.001)
    # umbral 90 "menor que" -> ~1.1x (99/90 = 1.1)
    assert_almost_eq(DiceTableState.multiplier(90, DiceTableState.Direction.UNDER), 1.1, 0.001)

func test_players_starts_empty():
    var table = DiceTableState.new()
    assert_eq(table.players.size(), 0)

func test_roll_fails_on_threshold_out_of_range():
    var table = DiceTableState.new()
    assert_false(table.roll(111, 0, DiceTableState.Direction.OVER, 50))
    assert_false(table.roll(111, 100, DiceTableState.Direction.OVER, 50))

func test_roll_fails_on_insufficient_balance():
    var table = DiceTableState.new()
    var ok = table.roll(111, 50, DiceTableState.Direction.OVER, 5000)
    assert_false(ok)
    # _player_for crea la entrada perezosa (balance 500) antes de intentar el
    # place_bet de 5000; el jugador queda creado pero intacto, no se descuenta.
    assert_eq(table.players[111].ledger.balance, 500)

func test_roll_creates_player_lazily_with_starting_balance():
    var roller = DiceRoller.new()
    var rolls: Array[float] = [25.0] # pierde con umbral 50 "mayor que"
    roller.results = rolls
    var table = DiceTableState.new(roller)
    table.roll(111, 50, DiceTableState.Direction.OVER, 100)
    assert_true(table.players.has(111))
    assert_eq(table.players[111].ledger.balance, 400)

func test_roll_wins_over_pays_correct_multiplier():
    var roller = DiceRoller.new()
    var rolls: Array[float] = [75.0] # > 50, gana
    roller.results = rolls
    var table = DiceTableState.new(roller)
    var ok = table.roll(111, 50, DiceTableState.Direction.OVER, 100)
    assert_true(ok)
    # multiplicador 99/50 = 1.98 -> payout int(100 * 1.98) = 198
    assert_eq(table.players[111].ledger.balance, 500 - 100 + 198)

func test_roll_loses_over():
    var roller = DiceRoller.new()
    var rolls: Array[float] = [25.0] # < 50, pierde
    roller.results = rolls
    var table = DiceTableState.new(roller)
    table.roll(111, 50, DiceTableState.Direction.OVER, 100)
    assert_eq(table.players[111].ledger.balance, 400)

func test_roll_wins_under_pays_correct_multiplier():
    var roller = DiceRoller.new()
    var rolls: Array[float] = [85.0] # < 90, gana
    roller.results = rolls
    var table = DiceTableState.new(roller)
    var ok = table.roll(111, 90, DiceTableState.Direction.UNDER, 100)
    assert_true(ok)
    # multiplicador 99/90 = 1.1 -> payout int(100 * 1.1) = 110
    assert_eq(table.players[111].ledger.balance, 500 - 100 + 110)

func test_roll_loses_under():
    var roller = DiceRoller.new()
    var rolls: Array[float] = [95.0] # > 90, pierde
    roller.results = rolls
    var table = DiceTableState.new(roller)
    table.roll(111, 90, DiceTableState.Direction.UNDER, 100)
    assert_eq(table.players[111].ledger.balance, 400)

func test_roll_emits_chips_won_with_net_profit_on_win():
    var roller = DiceRoller.new()
    var rolls: Array[float] = [75.0]
    roller.results = rolls
    var table = DiceTableState.new(roller)
    watch_signals(table)
    table.roll(111, 50, DiceTableState.Direction.OVER, 100)
    assert_signal_emitted_with_parameters(table, "chips_won", [111, 98]) # 198 payout - 100 apuesta

func test_roll_does_not_emit_chips_won_on_loss():
    var roller = DiceRoller.new()
    var rolls: Array[float] = [25.0]
    roller.results = rolls
    var table = DiceTableState.new(roller)
    watch_signals(table)
    table.roll(111, 50, DiceTableState.Direction.OVER, 100)
    assert_signal_not_emitted(table, "chips_won")

func test_roll_records_last_round_for_player():
    var roller = DiceRoller.new()
    var rolls: Array[float] = [75.0]
    roller.results = rolls
    var table = DiceTableState.new(roller)
    table.roll(111, 50, DiceTableState.Direction.OVER, 100)
    var last_round = table.players[111].last_round
    assert_eq(last_round["threshold"], 50)
    assert_eq(last_round["direction"], DiceTableState.Direction.OVER)
    assert_eq(last_round["amount"], 100)
    assert_eq(last_round["result"], 75.0)
    assert_true(last_round["win"])
    assert_eq(last_round["payout"], 198)

func test_roll_independent_per_player():
    var roller = DiceRoller.new()
    var rolls: Array[float] = [75.0, 25.0]
    roller.results = rolls
    var table = DiceTableState.new(roller)
    table.roll(111, 50, DiceTableState.Direction.OVER, 100) # gana
    table.roll(222, 50, DiceTableState.Direction.OVER, 100) # pierde
    assert_eq(table.players[111].ledger.balance, 598)
    assert_eq(table.players[222].ledger.balance, 400)

func test_to_dict_reflects_players_and_last_round():
    var roller = DiceRoller.new()
    var rolls: Array[float] = [75.0]
    roller.results = rolls
    var table = DiceTableState.new(roller)
    table.roll(111, 50, DiceTableState.Direction.OVER, 100)
    var data = table.to_dict()
    assert_eq(data["players"][111]["player_id"], 111)
    assert_eq(data["players"][111]["balance"], 598)
    assert_eq(data["players"][111]["last_round"]["win"], true)

func test_roll_uses_external_ledger_for_new_player():
    var table = DiceTableState.new()
    var shared := ChipLedger.new(500)
    table.roll(111, 40, DiceTableState.Direction.OVER, 100, shared)
    assert_eq(table.players[111].ledger, shared)

func test_roll_creates_individual_ledger_when_no_external_ledger_given():
    var table = DiceTableState.new()
    table.roll(111, 40, DiceTableState.Direction.OVER, 100)
    assert_true(table.players.has(111))
    assert_ne(table.players[111].ledger, null)

func test_shared_ledger_persists_after_first_roll_ignoring_later_argument():
    var table = DiceTableState.new()
    var shared := ChipLedger.new(500)
    table.roll(111, 40, DiceTableState.Direction.OVER, 100, shared)
    table.roll(111, 40, DiceTableState.Direction.OVER, 50) # sin external_ledger la 2a vez
    assert_eq(table.players[111].ledger, shared)

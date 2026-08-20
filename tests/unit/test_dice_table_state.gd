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

extends GutTest

var RouletteTableState = preload("res://scripts/roulette/roulette_table_state.gd")

func test_sit_occupies_empty_seat():
    var table = RouletteTableState.new()
    var ok = table.sit(0, 111)
    assert_true(ok)
    assert_eq(table.seats[0].player_id, 111)

func test_sit_fails_on_occupied_seat():
    var table = RouletteTableState.new()
    table.sit(0, 111)
    var ok = table.sit(0, 222)
    assert_false(ok)

func test_sit_fails_if_player_already_seated_elsewhere():
    var table = RouletteTableState.new()
    table.sit(0, 111)
    var ok = table.sit(1, 111)
    assert_false(ok)

func test_sit_fails_on_out_of_range_seat():
    var table = RouletteTableState.new()
    var ok = table.sit(4, 111)
    assert_false(ok)

func test_place_bet_deducts_balance_and_records_bet():
    var table = RouletteTableState.new()
    table.sit(0, 111)
    var ok = table.place_bet(0, 111, RouletteTableState.BetType.RED, -1, 50)
    assert_true(ok)
    assert_eq(table.seats[0].ledger.balance, 450)
    assert_eq(table.seats[0].bets.size(), 1)

func test_place_bet_allows_multiple_bets_same_seat():
    var table = RouletteTableState.new()
    table.sit(0, 111)
    table.place_bet(0, 111, RouletteTableState.BetType.RED, -1, 50)
    table.place_bet(0, 111, RouletteTableState.BetType.STRAIGHT, 7, 100)
    assert_eq(table.seats[0].ledger.balance, 350)
    assert_eq(table.seats[0].bets.size(), 2)

func test_place_bet_fails_for_unseated_or_wrong_player():
    var table = RouletteTableState.new()
    table.sit(0, 111)
    var ok = table.place_bet(0, 999, RouletteTableState.BetType.RED, -1, 50)
    assert_false(ok)
    assert_eq(table.seats[0].bets.size(), 0)

func test_place_bet_fails_on_insufficient_balance():
    var table = RouletteTableState.new()
    table.sit(0, 111)
    var ok = table.place_bet(0, 111, RouletteTableState.BetType.RED, -1, 5000)
    assert_false(ok)
    assert_eq(table.seats[0].ledger.balance, 500)

func test_place_bet_fails_on_invalid_bet_type():
    var table = RouletteTableState.new()
    table.sit(0, 111)
    var ok = table.place_bet(0, 111, 999, -1, 50)
    assert_false(ok)

func test_place_bet_straight_fails_on_out_of_range_number():
    var table = RouletteTableState.new()
    table.sit(0, 111)
    var ok = table.place_bet(0, 111, RouletteTableState.BetType.STRAIGHT, 37, 50)
    assert_false(ok)

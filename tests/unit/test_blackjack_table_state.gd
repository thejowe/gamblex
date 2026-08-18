extends GutTest

func test_sit_occupies_empty_seat():
    var table = BlackjackTableState.new()
    var ok = table.sit(0, 111)
    assert_true(ok)
    assert_eq(table.seats[0].player_id, 111)

func test_sit_fails_on_occupied_seat():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    var ok = table.sit(0, 222)
    assert_false(ok)

func test_sit_fails_if_player_already_seated_elsewhere():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    var ok = table.sit(1, 111)
    assert_false(ok)

func test_sit_fails_on_out_of_range_seat():
    var table = BlackjackTableState.new()
    var ok = table.sit(4, 111)
    assert_false(ok)

func test_round_does_not_start_until_all_seated_players_bet():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.place_bet(0, 111, 100)
    assert_false(table.round_active)
    table.place_bet(1, 222, 100)
    assert_true(table.round_active)

func test_place_bet_fails_for_unseated_or_wrong_player():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    var ok = table.place_bet(0, 999, 100)
    assert_false(ok)
    assert_false(table.round_active)

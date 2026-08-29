extends GutTest

var RouletteTableState = preload("res://scripts/roulette/roulette_table_state.gd")

func _force_round_end(table) -> void:
	table.advance_time(RouletteTableState.ROUND_DURATION_SEC)

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

func test_place_bet_fails_once_betting_closes():
	var table = RouletteTableState.new()
	table.sit(0, 111)
	_force_round_end(table)
	assert_eq(table.phase, RouletteTableState.Phase.RESULT)
	var ok = table.place_bet(0, 111, RouletteTableState.BetType.RED, -1, 50)
	assert_false(ok)

func test_advance_time_does_nothing_before_round_duration_elapses():
	var table = RouletteTableState.new()
	var changed = table.advance_time(1.0)
	assert_false(changed)
	assert_eq(table.phase, RouletteTableState.Phase.BETTING)

func test_advance_time_closes_betting_and_resolves_round():
	var wheel = RouletteWheel.new()
	wheel.results = [7]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.STRAIGHT, 7, 100)
	_force_round_end(table)
	assert_eq(table.last_result, 7)
	assert_eq(table.phase, RouletteTableState.Phase.RESULT)
	assert_eq(table.seats[0].ledger.balance, 500 - 100 + 3600) # 100 * 36

func test_advance_time_reopens_betting_after_result_duration():
	var table = RouletteTableState.new()
	_force_round_end(table)
	assert_eq(table.phase, RouletteTableState.Phase.RESULT)
	var changed = table.advance_time(RouletteTableState.RESULT_DURATION_SEC)
	assert_true(changed)
	assert_eq(table.phase, RouletteTableState.Phase.BETTING)
	assert_eq(table.phase_time_remaining, RouletteTableState.ROUND_DURATION_SEC)

func test_spin_resolves_straight_loss():
	var wheel = RouletteWheel.new()
	wheel.results = [8]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.STRAIGHT, 7, 100)
	_force_round_end(table)
	assert_eq(table.seats[0].ledger.balance, 400)

func test_ledger_is_not_bankrupt_while_all_in_bet_is_still_open():
	var wheel = RouletteWheel.new()
	wheel.results = [8]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.STRAIGHT, 7, 500)
	assert_eq(table.seats[0].ledger.balance, 0)
	assert_false(table.seats[0].ledger.is_bankrupt())
	_force_round_end(table)
	assert_true(table.seats[0].ledger.is_bankrupt())

func test_spin_resolves_color_bet_win_and_loss():
	var wheel = RouletteWheel.new()
	wheel.results = [1] # 1 es rojo
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.sit(1, 222)
	table.place_bet(0, 111, RouletteTableState.BetType.RED, -1, 50)
	table.place_bet(1, 222, RouletteTableState.BetType.BLACK, -1, 50)
	_force_round_end(table)
	assert_eq(table.seats[0].ledger.balance, 500 - 50 + 100) # gana 1:1
	assert_eq(table.seats[1].ledger.balance, 450) # pierde

func test_spin_resolves_even_odd_bet():
	var wheel = RouletteWheel.new()
	wheel.results = [4]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.sit(1, 222)
	table.place_bet(0, 111, RouletteTableState.BetType.EVEN, -1, 50)
	table.place_bet(1, 222, RouletteTableState.BetType.ODD, -1, 50)
	_force_round_end(table)
	assert_eq(table.seats[0].ledger.balance, 500 - 50 + 100)
	assert_eq(table.seats[1].ledger.balance, 450)

func test_spin_resolves_dozen_bet_at_2_to_1():
	var wheel = RouletteWheel.new()
	wheel.results = [15] # segunda docena, 13-24
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.DOZEN_2, -1, 50)
	_force_round_end(table)
	assert_eq(table.seats[0].ledger.balance, 500 - 50 + 150) # 50 * 3

func test_spin_resolves_column_bet_at_2_to_1():
	var wheel = RouletteWheel.new()
	wheel.results = [5] # columna 2 (2,5,8,...,35)
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.COLUMN_2, -1, 50)
	_force_round_end(table)
	assert_eq(table.seats[0].ledger.balance, 500 - 50 + 150) # 50 * 3

func test_spin_resolves_low_and_high_bets():
	var wheel = RouletteWheel.new()
	wheel.results = [30] # alto (19-36)
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.sit(1, 222)
	table.place_bet(0, 111, RouletteTableState.BetType.LOW, -1, 50) # pierde
	table.place_bet(1, 222, RouletteTableState.BetType.HIGH, -1, 50) # gana
	_force_round_end(table)
	assert_eq(table.seats[0].ledger.balance, 450)
	assert_eq(table.seats[1].ledger.balance, 500 - 50 + 100)

func test_spin_on_zero_only_straight_zero_wins():
	var wheel = RouletteWheel.new()
	wheel.results = [0]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.sit(1, 222)
	table.place_bet(0, 111, RouletteTableState.BetType.RED, -1, 50)
	table.place_bet(1, 222, RouletteTableState.BetType.STRAIGHT, 0, 50)
	_force_round_end(table)
	assert_eq(table.seats[0].ledger.balance, 450) # rojo pierde en el 0
	assert_eq(table.seats[1].ledger.balance, 500 - 50 + 1800) # pleno al 0 gana

func test_spin_resolves_multiple_bets_same_seat_independently():
	var wheel = RouletteWheel.new()
	wheel.results = [7] # rojo, impar
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.RED, -1, 50) # gana
	table.place_bet(0, 111, RouletteTableState.BetType.EVEN, -1, 50) # pierde
	_force_round_end(table)
	assert_eq(table.seats[0].ledger.balance, 500 - 100 + 100)

func test_spin_clears_bets_after_resolution():
	var wheel = RouletteWheel.new()
	wheel.results = [7]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.RED, -1, 50)
	_force_round_end(table)
	assert_eq(table.seats[0].bets.size(), 0)

func test_to_dict_reflects_seats_bets_last_result_and_phase():
	var wheel = RouletteWheel.new()
	wheel.results = [7]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.RED, -1, 50)
	_force_round_end(table)
	var data = table.to_dict()
	assert_eq(data["seats"][0]["player_id"], 111)
	assert_eq(data["seats"][1], null)
	assert_eq(data["last_result"], 7)
	assert_eq(data["seats"][0]["bets"].size(), 0)
	assert_eq(data["phase"], RouletteTableState.Phase.RESULT)
	assert_eq(data["phase_time_remaining"], RouletteTableState.RESULT_DURATION_SEC)

func test_last_round_reflects_winning_bet_payout():
	var wheel = RouletteWheel.new()
	wheel.results = [7]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.STRAIGHT, 7, 10)
	_force_round_end(table)
	var last_round: Dictionary = table.seats[0].last_round
	assert_true(last_round["win"])
	assert_eq(last_round["amount"], 10)
	assert_eq(last_round["payout"], 360) # 35 a 1 + la propia apuesta

func test_last_round_reflects_losing_bet():
	var wheel = RouletteWheel.new()
	wheel.results = [7]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.BLACK, -1, 50)
	_force_round_end(table)
	var last_round: Dictionary = table.seats[0].last_round
	assert_false(last_round["win"])
	assert_eq(last_round["amount"], 50)
	assert_eq(last_round["payout"], 0)

func test_last_round_stays_empty_when_seat_did_not_bet():
	var wheel = RouletteWheel.new()
	wheel.results = [7]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	_force_round_end(table)
	assert_true(table.seats[0].last_round.is_empty())

func test_last_round_nets_multiple_bets_in_the_same_round():
	var wheel = RouletteWheel.new()
	wheel.results = [7]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.STRAIGHT, 7, 10)
	table.place_bet(0, 111, RouletteTableState.BetType.BLACK, -1, 50) # 7 es rojo, esta pierde
	_force_round_end(table)
	var last_round: Dictionary = table.seats[0].last_round
	assert_true(last_round["win"])
	assert_eq(last_round["amount"], 60)
	assert_eq(last_round["payout"], 360)

func test_to_dict_exposes_last_round_per_seat():
	var wheel = RouletteWheel.new()
	wheel.results = [7]
	var table = RouletteTableState.new(wheel)
	table.sit(0, 111)
	table.place_bet(0, 111, RouletteTableState.BetType.RED, -1, 20)
	_force_round_end(table)
	var data = table.to_dict()
	assert_true(data["seats"][0]["last_round"]["win"])

func test_sit_uses_external_ledger_when_provided():
	var table = RouletteTableState.new()
	var shared := ChipLedger.new(500)
	table.sit(0, 111, shared)
	assert_eq(table.seats[0].ledger, shared)

func test_sit_creates_individual_ledger_when_no_external_ledger_given():
	var table = RouletteTableState.new()
	table.sit(0, 111)
	assert_eq(table.seats[0].ledger.balance, 500)

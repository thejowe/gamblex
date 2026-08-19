extends GutTest

func test_first_team_to_reach_goal_wins_immediately():
	var pools := [TeamChipPool.new(0, 900), TeamChipPool.new(1, 500)]
	var rules := MatchRules.new(pools, 1000, 600.0)
	pools[0].payout(150) # equipo 0 llega a 1050, por encima de la meta
	assert_true(rules.on_balance_changed())
	assert_true(rules.finished)
	assert_eq(rules.winning_team, 0)
	assert_eq(rules.reason, "goal_reached")

func test_timeout_without_goal_awards_highest_balance():
	var pools := [TeamChipPool.new(0, 700), TeamChipPool.new(1, 400)]
	var rules := MatchRules.new(pools, 2000, 60.0)
	assert_false(rules.advance_time(59.0))
	assert_true(rules.advance_time(1.0))
	assert_true(rules.finished)
	assert_eq(rules.winning_team, 0)
	assert_eq(rules.reason, "timeout_highest_balance")

func test_timeout_tie_is_a_draw():
	var pools := [TeamChipPool.new(0, 500), TeamChipPool.new(1, 500)]
	var rules := MatchRules.new(pools, 2000, 60.0)
	rules.advance_time(60.0)
	assert_eq(rules.winning_team, -1)
	assert_eq(rules.reason, "timeout_draw")

func test_bankruptcy_ends_match_immediately_for_the_other_team():
	var pools := [TeamChipPool.new(0, 500), TeamChipPool.new(1, 200)]
	var rules := MatchRules.new(pools, 2000, 600.0)
	pools[1].place_bet(200) # equipo 1 se queda a 0, bancarrota
	assert_true(rules.on_balance_changed())
	assert_eq(rules.winning_team, 0)
	assert_eq(rules.reason, "bankruptcy")

func test_bankruptcy_takes_priority_over_simultaneous_goal():
	# Mismo cambio de saldo: equipo 1 llega a la meta, pero equipo 0 se queda
	# sin fichas en el mismo instante — la spec exige que la bancarrota decida
	# de inmediato, sin esperar a la condición de meta.
	var pools := [TeamChipPool.new(0, 0), TeamChipPool.new(1, 1000)]
	var rules := MatchRules.new(pools, 1000, 600.0)
	assert_true(rules.on_balance_changed())
	assert_eq(rules.winning_team, 1)
	assert_eq(rules.reason, "bankruptcy")

func test_no_ops_once_finished():
	var pools := [TeamChipPool.new(0, 1000), TeamChipPool.new(1, 500)]
	var rules := MatchRules.new(pools, 1000, 60.0)
	rules.on_balance_changed() # equipo 0 ya arranca en la meta, termina el partido
	var reason_before := rules.reason
	pools[1].payout(9999)
	assert_false(rules.on_balance_changed())
	assert_false(rules.advance_time(1000.0))
	assert_eq(rules.reason, reason_before)

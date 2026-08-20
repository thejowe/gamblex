extends GutTest

func test_one_v_one_assigns_first_two_players_to_opposite_teams():
	var a := TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	assert_eq(a.join(111), 0)
	assert_eq(a.join(222), 1)
	assert_eq(a.team_for(111), 0)
	assert_eq(a.team_for(222), 1)

func test_one_v_one_rejects_third_player():
	var a := TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	a.join(111)
	a.join(222)
	assert_eq(a.join(333), -1)
	assert_true(a.is_full())

func test_two_v_two_balances_teams_as_players_join():
	var a := TeamAssignment.new(TeamAssignment.MatchType.TWO_V_TWO)
	assert_eq(a.join(1), 0)
	assert_eq(a.join(2), 1)
	assert_eq(a.join(3), 0)
	assert_eq(a.join(4), 1)
	assert_eq(a.join(5), -1)
	assert_true(a.is_full())
	assert_eq(a.teams[0], [1, 3])
	assert_eq(a.teams[1], [2, 4])

func test_four_v_four_team_size_and_max_players():
	var a := TeamAssignment.new(TeamAssignment.MatchType.FOUR_V_FOUR)
	assert_eq(a.team_size(), 4)
	assert_eq(a.max_players(), 8)

func test_join_is_idempotent_for_already_seated_player():
	var a := TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	a.join(111)
	assert_eq(a.join(111), -1)
	assert_eq(a.teams[0], [111])

func test_team_size_for_is_a_static_lookup():
	assert_eq(TeamAssignment.team_size_for(TeamAssignment.MatchType.TWO_V_TWO), 2)

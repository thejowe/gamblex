extends GutTest

func test_team_for_returns_minus_one_before_match_starts():
	var controller := BattleController.new()
	assert_eq(controller.team_for(999), -1)

func test_team_for_resolves_after_manual_assignment_setup():
	var controller := BattleController.new()
	controller.assignment = TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	controller.assignment.join(111)
	controller.assignment.join(222)
	assert_eq(controller.team_for(111), 0)
	assert_eq(controller.team_for(222), 1)
	assert_eq(controller.team_for(999), -1)

func test_ledger_for_team_returns_the_pool_ledger_object():
	var controller := BattleController.new()
	controller.pools = [TeamChipPool.new(0, 500), TeamChipPool.new(1, 500)]
	assert_eq(controller.ledger_for_team(0), controller.pools[0].ledger)
	assert_eq(controller.ledger_for_team(0).balance, 500)

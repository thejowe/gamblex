extends GutTest

func test_ledger_for_player_returns_null_outside_battle_mode():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor._is_battle_mode = false
	assert_eq(casino_floor._ledger_for_player(111), null)

func test_ledger_for_player_returns_team_pool_ledger_in_battle_mode():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor._is_battle_mode = true
	casino_floor.battle_controller = BattleController.new()
	casino_floor.battle_controller.assignment = TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	casino_floor.battle_controller.assignment.join(111)
	casino_floor.battle_controller.pools = [TeamChipPool.new(0, 500), TeamChipPool.new(1, 500)]
	var ledger = casino_floor._ledger_for_player(111)
	assert_eq(ledger, casino_floor.battle_controller.pools[0].ledger)

func test_ledger_for_player_returns_null_for_unassigned_player():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor._is_battle_mode = true
	casino_floor.battle_controller = BattleController.new()
	casino_floor.battle_controller.assignment = TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	assert_eq(casino_floor._ledger_for_player(999), null)

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

func test_ledger_for_player_returns_shared_pool_in_free_mode_for_any_player():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor._is_battle_mode = false
	casino_floor.shared_pool_ledger = ChipLedger.new(500)
	assert_eq(casino_floor._ledger_for_player(111), casino_floor.shared_pool_ledger)
	assert_eq(casino_floor._ledger_for_player(222), casino_floor.shared_pool_ledger)

func test_goal_state_dict_reflects_shared_pool_balance_and_target():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor.shared_pool_ledger = ChipLedger.new(500)
	casino_floor.shared_pool_ledger.payout(300)
	var state = casino_floor._goal_state_dict()
	assert_eq(state["balance"], 800)
	assert_eq(state["target"], 1000) # CasinoFloor.GOAL_TARGET, sin cambios en este plan
	assert_eq(state["unlocked"], false)
	assert_eq(state["bankrupt"], false)

func test_notify_free_mode_balance_changed_sets_unlocked_flag_at_target():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor._is_battle_mode = false
	casino_floor.shared_pool_ledger = ChipLedger.new(500)
	casino_floor.shared_pool_ledger.payout(600) # 1100, por encima de la meta de 1000
	casino_floor._pool_unlocked = false
	casino_floor._set_pool_unlocked_if_reached_goal()
	assert_true(casino_floor._pool_unlocked)

func test_goal_state_dict_reports_bankrupt_at_zero_balance():
	var casino_floor = load("res://scripts/net/casino_floor.gd").new()
	casino_floor.shared_pool_ledger = ChipLedger.new(500)
	casino_floor.shared_pool_ledger.place_bet(500)
	var state = casino_floor._goal_state_dict()
	assert_true(state["bankrupt"])

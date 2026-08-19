extends GutTest

func test_starts_at_zero_and_locked():
    var goal = CollectiveGoal.new(1000)
    assert_eq(goal.total, 0)
    assert_false(goal.unlocked)

func test_add_chips_accumulates_total():
    var goal = CollectiveGoal.new(1000)
    goal.add_chips(300)
    goal.add_chips(250)
    assert_eq(goal.total, 550)

func test_unlocks_when_target_reached():
    var goal = CollectiveGoal.new(500)
    goal.add_chips(500)
    assert_true(goal.unlocked)

func test_unlocks_when_target_exceeded():
    var goal = CollectiveGoal.new(500)
    goal.add_chips(700)
    assert_true(goal.unlocked)

func test_add_chips_returns_true_only_on_unlock_transition():
    var goal = CollectiveGoal.new(500)
    var before = goal.add_chips(300)
    assert_false(before)
    var at_unlock = goal.add_chips(200)
    assert_true(at_unlock)
    var after = goal.add_chips(100)
    assert_false(after)
    assert_true(goal.unlocked)

func test_ignores_non_positive_amounts():
    var goal = CollectiveGoal.new(500)
    var ok = goal.add_chips(0)
    assert_false(ok)
    assert_eq(goal.total, 0)
    var ok2 = goal.add_chips(-50)
    assert_false(ok2)
    assert_eq(goal.total, 0)

func test_multiple_players_contribute_to_shared_total():
    var goal = CollectiveGoal.new(300)
    goal.add_chips(100) # jugador A gana
    goal.add_chips(150) # jugador B gana
    assert_eq(goal.total, 250)
    assert_false(goal.unlocked)
    goal.add_chips(60) # jugador C gana, se cumple la meta
    assert_true(goal.unlocked)

func test_to_dict_reflects_state():
    var goal = CollectiveGoal.new(500)
    goal.add_chips(500)
    var data = goal.to_dict()
    assert_eq(data["total"], 500)
    assert_eq(data["target"], 500)
    assert_eq(data["unlocked"], true)

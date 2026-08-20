extends GutTest

func test_roll_returns_queued_result_in_order():
    var roller = DiceRoller.new()
    roller.results = [12.5, 87.3, 50.0]
    assert_eq(roller.roll(), 12.5)
    assert_eq(roller.roll(), 87.3)
    assert_eq(roller.roll(), 50.0)

func test_roll_without_queue_returns_number_in_range():
    var roller = DiceRoller.new()
    for i in range(50):
        var result = roller.roll()
        assert_true(result >= 0.0 and result < 100.0)

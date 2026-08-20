extends GutTest

func test_spin_returns_queued_result_in_order():
    var wheel = RouletteWheel.new()
    wheel.results = [7, 0, 36]
    assert_eq(wheel.spin(), 7)
    assert_eq(wheel.spin(), 0)
    assert_eq(wheel.spin(), 36)

func test_spin_without_queue_returns_number_in_range():
    var wheel = RouletteWheel.new()
    for i in range(50):
        var result = wheel.spin()
        assert_true(result >= 0 and result <= 36)

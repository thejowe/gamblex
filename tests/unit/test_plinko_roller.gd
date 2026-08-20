extends GutTest

func test_roll_returns_queued_bounces_in_order():
	var roller = PlinkoRoller.new()
	roller.results = [[true, false, true], [false, false, false]]
	assert_eq(roller.roll(3), [true, false, true])
	assert_eq(roller.roll(3), [false, false, false])

func test_roll_without_queue_returns_rows_bools():
	var roller = PlinkoRoller.new()
	var bounces = roller.roll(12)
	assert_eq(bounces.size(), 12)
	for bounced_right in bounces:
		assert_true(bounced_right is bool)

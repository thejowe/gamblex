extends GutTest

func test_roll_returns_queued_result_in_order():
	var roller = MinesRoller.new()
	roller.results = [[1, 5, 9], [0, 24]]
	assert_eq(roller.roll(25, 3), [1, 5, 9])
	assert_eq(roller.roll(25, 2), [0, 24])

func test_roll_without_queue_returns_correct_count_within_range():
	var roller = MinesRoller.new()
	var positions = roller.roll(25, 3)
	assert_eq(positions.size(), 3)
	for pos in positions:
		assert_true(pos >= 0 and pos < 25)

func test_roll_without_queue_returns_unique_positions():
	var roller = MinesRoller.new()
	var positions = roller.roll(25, 10)
	var unique := {}
	for pos in positions:
		unique[pos] = true
	assert_eq(unique.size(), positions.size())

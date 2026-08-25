extends GutTest

func _make_grid() -> RouletteBettingGrid:
	var grid: RouletteBettingGrid = load("res://scenes/ui/casino/roulette_betting_grid.tscn").instantiate()
	add_child_autofree(grid)
	return grid

func test_grid_creates_37_number_buttons():
	var grid := _make_grid()
	var count := 0
	for child in grid.get_children():
		if child is Button and child.text.is_valid_int():
			count += 1
	assert_eq(count, 37)

func test_number_press_emits_straight_bet_selected():
	var grid := _make_grid()
	watch_signals(grid)
	var fake_button := Button.new()
	grid.add_child(fake_button)
	grid._on_number_pressed(fake_button, 7)
	assert_signal_emitted_with_parameters(grid, "bet_selected", [RouletteTableState.BetType.STRAIGHT, 7])
	fake_button.queue_free()

func test_outside_bet_press_emits_bet_selected_with_no_number():
	var grid := _make_grid()
	watch_signals(grid)
	var fake_button := Button.new()
	grid.add_child(fake_button)
	grid._on_outside_bet_pressed(fake_button, RouletteTableState.BetType.RED, -1)
	assert_signal_emitted_with_parameters(grid, "bet_selected", [RouletteTableState.BetType.RED, -1])
	fake_button.queue_free()

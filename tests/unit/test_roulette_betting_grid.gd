extends GutTest

func _make_grid() -> RouletteBettingGrid:
	var grid: RouletteBettingGrid = load("res://scenes/ui/casino/roulette_betting_grid.tscn").instantiate()
	add_child_autofree(grid)
	return grid

func test_grid_creates_37_number_buttons():
	var grid := _make_grid()
	assert_eq(grid._number_grid.get_child_count(), 37)

func test_number_buttons_and_outside_bets_are_in_separate_containers():
	var grid := _make_grid()
	assert_eq(grid._outside_bets_row.get_child_count(), 7)
	for child in grid._number_grid.get_children():
		assert_true(child.text.is_valid_int(), "un botón de apuesta de fuera se coló en el grid de números")
	for child in grid._outside_bets_row.get_children():
		assert_false(child.text.is_valid_int(), "un botón de número se coló en la fila de apuestas de fuera")

func test_number_grid_and_outside_bets_row_fit_within_design_width():
	var grid := _make_grid()
	const DESIGN_WIDTH := 860.0 # ancho real del contenedor en roulette_table_net.tscn (880-20)
	var number_grid_width: float = grid._number_grid.columns * 48.0
	var outside_bets_width: float = grid._outside_bets_row.columns * 96.0
	assert_true(number_grid_width <= DESIGN_WIDTH, "el grid de números por sí solo ya no cabe")
	assert_true(outside_bets_width <= DESIGN_WIDTH, "la fila de apuestas de fuera por sí sola ya no cabe")

func test_number_grid_and_outside_bets_row_fit_within_design_height():
	var grid := _make_grid()
	const DESIGN_HEIGHT := 210.0 # alto real asignado a RouletteBettingGrid en roulette_table_net.tscn (570-360)
	assert_true(grid.get_combined_minimum_size().y <= DESIGN_HEIGHT, "el grid + fila de apuestas de fuera se salen del alto asignado e invaden el SeatsLabel de debajo")

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

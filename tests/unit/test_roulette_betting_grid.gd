extends GutTest

func _make_grid() -> RouletteBettingGrid:
	var grid: RouletteBettingGrid = load("res://scenes/ui/casino/roulette_betting_grid.tscn").instantiate()
	add_child_autofree(grid)
	return grid

func test_grid_creates_36_number_buttons_plus_separate_zero():
	var grid := _make_grid()
	assert_eq(grid._number_grid.get_child_count(), 36)
	assert_not_null(grid._zero_button)
	assert_eq(grid._zero_button.text, "0")

func test_number_grid_columns_are_classic_table_order_top_to_bottom():
	var grid := _make_grid()
	var children := grid._number_grid.get_children()
	# fila superior: 3,6,9..36 -- fila media: 2,5,8..35 -- fila inferior: 1,4,7..34
	assert_eq(children[0].text, "3")
	assert_eq(children[11].text, "36")
	assert_eq(children[12].text, "2")
	assert_eq(children[24].text, "1")
	assert_eq(children[35].text, "34")

func test_column_bets_row_has_three_buttons():
	var grid := _make_grid()
	assert_eq(grid._column_bets_box.get_child_count(), 3)

func test_dozens_row_has_three_buttons_beyond_the_zero_spacer():
	var grid := _make_grid()
	assert_eq(grid._dozens_row.get_child_count(), 4) # spacer + 1ra/2da/3ra 12

func test_outside_row_has_six_buttons_beyond_the_zero_spacer():
	var grid := _make_grid()
	assert_eq(grid._outside_row.get_child_count(), 7) # spacer + 1-18/par/rojo/negro/impar/19-36

func test_grid_fits_within_roulette_table_net_assigned_box():
	# mismo bug de Plan 22 (grid de Ruleta desbordaba el contenedor) -- esta
	# vez con contenedores anidados de ancho fijo en vez de columnas de
	# GridContainer compartidas, pero se verifica igual por si acaso.
	var grid := _make_grid()
	const DESIGN_WIDTH := 860.0 # 900 (viewport) - 20 - 20, roulette_table_net.tscn
	const DESIGN_HEIGHT := 230.0 # offset_bottom(590) - offset_top(360), roulette_table_net.tscn
	var min_size := grid.get_combined_minimum_size()
	assert_true(min_size.x <= DESIGN_WIDTH, "el grid de ruleta (%.0fpx) no cabe en el ancho asignado (%.0fpx)" % [min_size.x, DESIGN_WIDTH])
	assert_true(min_size.y <= DESIGN_HEIGHT, "el grid de ruleta (%.0fpx) no cabe en el alto asignado (%.0fpx)" % [min_size.y, DESIGN_HEIGHT])

func test_number_press_emits_straight_bet_selected():
	var grid := _make_grid()
	watch_signals(grid)
	var fake_button := Button.new()
	grid.add_child(fake_button)
	grid._on_number_pressed(fake_button, 7)
	assert_signal_emitted_with_parameters(grid, "bet_selected", [RouletteTableState.BetType.STRAIGHT, 7])
	fake_button.queue_free()

func test_zero_press_emits_straight_bet_selected_with_number_zero():
	var grid := _make_grid()
	watch_signals(grid)
	grid._on_number_pressed(grid._zero_button, 0)
	assert_signal_emitted_with_parameters(grid, "bet_selected", [RouletteTableState.BetType.STRAIGHT, 0])

func test_outside_bet_press_emits_bet_selected_with_no_number():
	var grid := _make_grid()
	watch_signals(grid)
	var fake_button := Button.new()
	grid.add_child(fake_button)
	grid._on_outside_bet_pressed(fake_button, RouletteTableState.BetType.RED, -1)
	assert_signal_emitted_with_parameters(grid, "bet_selected", [RouletteTableState.BetType.RED, -1])
	fake_button.queue_free()

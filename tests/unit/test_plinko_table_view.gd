extends GutTest

func _make_view():
	var scene: PackedScene = load("res://scenes/plinko_table_net.tscn")
	var view = scene.instantiate()
	add_child_autofree(view)
	return view

func test_set_rows_clamps_and_updates_board_and_label():
	var view = _make_view()
	view._set_rows(999)
	assert_eq(view.board.rows, PlinkoTableState.MAX_ROWS)
	assert_true(view.rows_label.text.contains(str(PlinkoTableState.MAX_ROWS)))
	view._set_rows(1)
	assert_eq(view.board.rows, PlinkoTableState.MIN_ROWS)

func test_bet_sidebar_press_calls_roll_with_current_rows():
	var view = _make_view()
	view.table_controller.table_state = PlinkoTableState.new()
	view._set_rows(10)
	view.bet_sidebar.amount = 25
	view.bet_sidebar.bet_pressed.emit(25)
	assert_true(view.table_controller.table_state.players.has(multiplayer.get_unique_id()))
	assert_eq(view.table_controller.table_state.players[multiplayer.get_unique_id()].last_round["rows"], 10)

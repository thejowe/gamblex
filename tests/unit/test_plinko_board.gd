extends GutTest

func _make_board() -> PlinkoBoard:
	var board: PlinkoBoard = load("res://scenes/ui/casino/plinko_board.tscn").instantiate()
	add_child_autofree(board)
	board.size = Vector2(800, 360)
	return board

func test_default_rows_matches_table_state_default():
	var board := _make_board()
	assert_eq(board.rows, PlinkoTableState.DEFAULT_ROWS)

func test_rows_setter_clamps_to_valid_range():
	var board := _make_board()
	board.rows = 3
	assert_eq(board.rows, PlinkoTableState.MIN_ROWS)
	board.rows = 99
	assert_eq(board.rows, PlinkoTableState.MAX_ROWS)

func test_slot_from_bounces_counts_right_bounces():
	assert_eq(PlinkoBoard.slot_from_bounces([true, false, true, true]), 3)
	assert_eq(PlinkoBoard.slot_from_bounces([false, false, false]), 0)
	assert_eq(PlinkoBoard.slot_from_bounces([]), 0)

func test_peg_position_last_row_spans_left_to_right():
	var board := _make_board()
	board.rows = 8
	var left := board.peg_position(7, 0)
	var right := board.peg_position(7, 7)
	assert_true(right.x > left.x)

func test_drop_ball_emits_ball_landed_with_correct_slot():
	var board := _make_board()
	board.rows = 4
	watch_signals(board)
	board.drop_ball([true, true, false, true])
	await wait_seconds(0.7)
	assert_signal_emitted_with_parameters(board, "ball_landed", [3])

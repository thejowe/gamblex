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

func test_controls_lock_while_ball_is_dropping_and_unlock_on_landing():
	var view = _make_view()
	var my_id := multiplayer.get_unique_id()
	var state := {
		"players": {
			my_id: {
				"player_id": my_id, "balance": 450,
				"last_round": {
					"rows": 12, "amount": 50, "bounces": [true, false, true],
					"slot": 2, "multiplier": 1.5, "payout": 75, "win": true,
				},
			},
		},
	}
	view._on_state_changed(state)
	assert_true(view._dropping, "cambiar de filas a mitad de caída desincroniza el tablero de la bola animando")
	assert_true(view.rows_minus_button.disabled)
	assert_true(view.rows_plus_button.disabled)
	assert_true(view.bet_sidebar.bet_button.disabled)
	await view.board.ball_landed
	assert_false(view._dropping)
	assert_false(view.rows_minus_button.disabled)
	assert_false(view.rows_plus_button.disabled)
	assert_false(view.bet_sidebar.bet_button.disabled)

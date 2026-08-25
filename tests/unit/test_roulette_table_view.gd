extends GutTest

func _make_view():
	var scene := load("res://scenes/roulette_table_net.tscn")
	var view = scene.instantiate()
	add_child_autofree(view)
	return view

func test_bet_selected_updates_pending_selection():
	var view = _make_view()
	view._on_bet_selected(RouletteTableState.BetType.BLACK, -1)
	assert_eq(view._selected_bet_type, RouletteTableState.BetType.BLACK)
	assert_eq(view._selected_number, -1)

func test_push_history_keeps_at_most_max_history_badges():
	var view = _make_view()
	for i in range(9):
		view._push_history(i % 37)
	assert_true(view.results_history.get_child_count() <= 8)

func test_bet_pressed_calls_place_bet_with_selected_type_and_number():
	var view = _make_view()
	view.table_controller.table_state = RouletteTableState.new()
	view.table_controller.table_state.sit(0, multiplayer.get_unique_id())
	view.my_seat_index = 0
	view._on_bet_selected(RouletteTableState.BetType.STRAIGHT, 7)
	view.bet_sidebar.amount = 100
	view.bet_sidebar.bet_pressed.emit(100)
	assert_eq(view.table_controller.table_state.seats[0].bets.size(), 1)
	assert_eq(view.table_controller.table_state.seats[0].bets[0].number, 7)

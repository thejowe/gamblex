extends GutTest

func _make_view():
	var scene: PackedScene = load("res://scenes/crash_table_net.tscn")
	var view = scene.instantiate()
	add_child_autofree(view)
	return view

func test_refresh_graph_idle_when_no_round_for_local_player():
	var view = _make_view()
	view._last_players = {}
	view._refresh_graph()
	assert_eq(view.crash_graph.state, CrashGraph.State.IDLE)
	assert_eq(view.crash_graph.elapsed, 0.0)

func test_refresh_graph_rising_while_round_active():
	var view = _make_view()
	var my_id := multiplayer.get_unique_id()
	view._last_players = {my_id: {"player_id": my_id, "balance": 400, "is_active": true, "elapsed": 2.5, "last_round": {}}}
	view._local_elapsed = {my_id: 2.5}
	view._refresh_graph()
	assert_eq(view.crash_graph.state, CrashGraph.State.RISING)
	assert_almost_eq(view.crash_graph.elapsed, 2.5, 0.001)

func test_bet_sidebar_press_calls_place_bet_with_amount():
	var view = _make_view()
	view.table_controller.table_state = CrashTableState.new()
	view.bet_sidebar.amount = 30
	view.bet_sidebar.bet_pressed.emit(30)
	assert_true(view.table_controller.table_state.players.has(multiplayer.get_unique_id()))
	assert_eq(view.table_controller.table_state.players[multiplayer.get_unique_id()].bet_amount, 30)

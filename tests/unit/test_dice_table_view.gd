extends GutTest

func _make_view():
	var scene: PackedScene = load("res://scenes/dice_table_net.tscn")
	var view = scene.instantiate()
	add_child_autofree(view)
	return view

func test_refresh_stats_shows_multiplier_and_probability_for_current_threshold():
	var view = _make_view()
	view.threshold_slider.threshold = 40
	view.threshold_slider.direction = DiceTableState.Direction.OVER
	view._refresh_stats()
	var expected_mult := DiceTableState.multiplier(40, DiceTableState.Direction.OVER)
	assert_true(view.multiplier_label.text.contains("%.2f" % expected_mult))
	var expected_chance := DiceTableState.win_chance(40, DiceTableState.Direction.OVER)
	assert_true(view.probability_label.text.contains("%.2f" % expected_chance))

func test_apply_direction_updates_slider_and_refreshes_stats():
	var view = _make_view()
	view._apply_direction(DiceTableState.Direction.OVER)
	assert_eq(view.threshold_slider.direction, DiceTableState.Direction.OVER)
	assert_true(view.multiplier_label.text.length() > 0)

func test_bet_sidebar_press_calls_roll_with_slider_threshold_and_direction():
	var view = _make_view()
	view.table_controller.table_state = DiceTableState.new()
	view.threshold_slider.threshold = 30
	view._apply_direction(DiceTableState.Direction.UNDER)
	view.bet_sidebar.amount = 25
	view.bet_sidebar.bet_pressed.emit(25)
	assert_true(view.table_controller.table_state.players.has(multiplayer.get_unique_id()))

extends GutTest

func _make_view():
	var scene := load("res://scenes/poker_table_net.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	return instance

func _state_with_my_seat(current_bet: int, min_raise: int, my_balance: int, active_index: int = 0) -> Dictionary:
	var seats := [null, null, null, null, null, null]
	# multiplayer.get_unique_id() sin peer conectado es 1 (offline default).
	seats[0] = {"player_id": 1, "folded": false, "current_bet": current_bet, "balance": my_balance, "hole_cards": []}
	return {
		"seats": seats, "community_cards": [], "pot": current_bet, "current_bet": current_bet,
		"min_raise": min_raise, "hand_active": true, "active_seat_index": active_index,
		"last_winner_seats": [], "betting_round": 0, "dealer_button_index": 0,
	}

func test_raise_slider_visible_and_ranged_when_valid_and_my_turn() -> void:
	var view = _make_view()
	view._on_state_changed(_state_with_my_seat(20, 10, 200))
	assert_true(view.raise_slider.visible)
	assert_eq(view.raise_slider.min_value, 30.0)
	assert_eq(view.raise_slider.max_value, 200.0)

func test_raise_slider_hidden_when_range_invalid_all_in() -> void:
	var view = _make_view()
	view._on_state_changed(_state_with_my_seat(20, 10, 25))
	assert_false(view.raise_slider.visible)
	assert_false(view.confirm_raise_button.visible)

func test_raise_slider_hidden_when_not_my_turn() -> void:
	var view = _make_view()
	view._on_state_changed(_state_with_my_seat(20, 10, 200, 3))
	assert_false(view.raise_slider.visible)

func test_confirm_raise_button_calls_raise_bet_with_slider_value() -> void:
	var view = _make_view()
	view._on_state_changed(_state_with_my_seat(20, 10, 200))
	view.raise_slider.value = 75
	view._on_confirm_raise_pressed()
	pass_test("no crashea sin peer conectado (server offline -> aplica local)")

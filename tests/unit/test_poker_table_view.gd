extends GutTest

func _make_view():
	var scene := load("res://scenes/poker_table_net.tscn")
	var view = scene.instantiate()
	add_child_autofree(view)
	return view

func _empty_seats() -> Array:
	return [null, null, null, null, null, null]

func _seated(player_id: int, current_bet: int = 0, balance: int = 500) -> Dictionary:
	return {
		"player_id": player_id, "folded": false, "current_bet": current_bet,
		"balance": balance, "hole_cards": [],
	}

func test_start_hand_button_disabled_with_fewer_than_two_seated():
	var view = _make_view()
	var seats := _empty_seats()
	seats[0] = _seated(111)
	view._on_state_changed({
		"seats": seats, "community_cards": [], "pot": 0, "current_bet": 0,
		"min_raise": 10, "hand_active": false, "active_seat_index": -1,
		"last_winner_seats": [], "betting_round": 0, "dealer_button_index": -1,
	})
	assert_true(view.start_hand_button.disabled, "Repartir debe quedar deshabilitado con menos de 2 sentados")

func test_start_hand_button_enabled_with_two_seated_and_no_active_hand():
	var view = _make_view()
	var seats := _empty_seats()
	seats[0] = _seated(111)
	seats[1] = _seated(222)
	view._on_state_changed({
		"seats": seats, "community_cards": [], "pot": 0, "current_bet": 0,
		"min_raise": 10, "hand_active": false, "active_seat_index": -1,
		"last_winner_seats": [], "betting_round": 0, "dealer_button_index": -1,
	})
	assert_false(view.start_hand_button.disabled)

func test_start_hand_button_disabled_while_hand_active():
	var view = _make_view()
	var seats := _empty_seats()
	seats[0] = _seated(111, 10, 490)
	seats[1] = _seated(222, 10, 490)
	view._on_state_changed({
		"seats": seats, "community_cards": [], "pot": 20, "current_bet": 10,
		"min_raise": 10, "hand_active": true, "active_seat_index": 0,
		"last_winner_seats": [], "betting_round": 0, "dealer_button_index": 0,
	})
	assert_true(view.start_hand_button.disabled, "Repartir debe quedar deshabilitado mientras hay mano en curso")

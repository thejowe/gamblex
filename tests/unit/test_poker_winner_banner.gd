extends GutTest

func test_show_winner_banner_no_crash() -> void:
	var scene := load("res://scenes/poker_table_net.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	instance._show_winner_banner(2, "jugador de prueba")
	pass_test("no crashea")

func test_maybe_show_winner_banner_triggers_only_on_transition_to_non_empty() -> void:
	var scene := load("res://scenes/poker_table_net.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	var seats := [null, null, null, null, null, null]
	seats[0] = {"player_id": 111, "folded": false, "current_bet": 0, "balance": 500, "hole_cards": []}
	var state := {
		"seats": seats, "community_cards": [], "pot": 0, "current_bet": 0,
		"min_raise": 10, "hand_active": false, "active_seat_index": -1,
		"last_winner_seats": [0], "betting_round": 4, "dealer_button_index": 0,
	}
	instance._on_state_changed(state)
	assert_not_null(instance._winner_banner)
	var first_banner = instance._winner_banner
	# El mismo resultado repetido (mismo last_winner_seats no vacio) no debe
	# crear un segundo banner.
	instance._on_state_changed(state)
	assert_eq(instance._winner_banner, first_banner)

extends GutTest

func _make_view():
	var container := Control.new()
	container.size = Vector2(900, 1080)
	add_child_autofree(container)
	var scene: PackedScene = load("res://scenes/blackjack_table_net.tscn")
	var view = scene.instantiate()
	container.add_child(view)
	return view

func test_seat_anchor_spreads_across_width_for_multiple_seats():
	var view = _make_view()
	var a0 = view.seat_anchor(0, 4)
	var a3 = view.seat_anchor(3, 4)
	assert_true(a3.x > a0.x)

func test_render_state_creates_one_card_node_per_seat_card():
	var view = _make_view()
	var state := {
		"seats": [
			{"player_id": 111, "balance": 450, "bet": 50, "hand_value": 20, "hand": [
				{"rank": 10, "suit": 2}, {"rank": 13, "suit": 1},
			]},
			null, null, null,
		],
		"dealer_value": 6,
		"dealer_hand": [{"rank": 6, "suit": 0}, {"hidden": true}],
		"active_seat_index": 0,
		"round_active": true,
	}
	view._render_state(state)
	assert_eq(view._seat_card_nodes[0].size(), 2)
	assert_eq(view._dealer_card_nodes.size(), 2)
	assert_false(view._dealer_card_nodes[1].face_up)

func test_render_state_removes_card_nodes_when_hand_shrinks():
	var view = _make_view()
	var state_with_cards := {
		"seats": [{"player_id": 111, "balance": 450, "bet": 50, "hand_value": 20, "hand": [
			{"rank": 10, "suit": 2}, {"rank": 13, "suit": 1},
		]}, null, null, null],
		"dealer_value": 0, "dealer_hand": [], "active_seat_index": 0, "round_active": true,
	}
	view._render_state(state_with_cards)
	var state_no_cards := {
		"seats": [{"player_id": 111, "balance": 450, "bet": 0, "hand_value": 0, "hand": []}, null, null, null],
		"dealer_value": 0, "dealer_hand": [], "active_seat_index": -1, "round_active": false,
	}
	view._render_state(state_no_cards)
	assert_eq(view._seat_card_nodes[0].size(), 0)

func test_dealer_value_label_shows_only_visible_card_while_hole_card_hidden():
	var view = _make_view()
	var state := {
		"seats": [null, null, null, null],
		"dealer_value": 20,
		"dealer_hand": [{"rank": 10, "suit": 2}, {"hidden": true}],
		"active_seat_index": -1,
		"round_active": true,
	}
	view._render_state(state)
	assert_eq(view.dealer_value_label.text, "10")

func test_hud_shows_balance_immediately_after_sitting():
	var view = _make_view()
	view._on_sit_pressed()
	assert_eq(view.hud_bar.balance_label.text, "BALANCE  $500")

func test_dealer_value_label_shows_full_value_after_round_resolves():
	var view = _make_view()
	var state := {
		"seats": [null, null, null, null],
		"dealer_value": 20,
		"dealer_hand": [{"rank": 10, "suit": 2}, {"rank": 10, "suit": 1}],
		"active_seat_index": -1,
		"round_active": false,
	}
	view._render_state(state)
	assert_eq(view.dealer_value_label.text, "20")

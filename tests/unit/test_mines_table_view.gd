extends GutTest

func _make_view() -> Control:
	var scene: PackedScene = load("res://scenes/mines_table_net.tscn")
	var view: Control = scene.instantiate()
	add_child_autofree(view)
	return view

func test_rebuild_grid_creates_one_cell_per_selected_size():
	var view = _make_view()
	view.size_option.select(0) # 5x5 = 25
	view._rebuild_grid()
	assert_eq(view.grid.get_child_count(), 25)
	assert_eq(view.grid.columns, 5)

func test_rebuild_grid_second_size_creates_sixty_four_cells():
	var view = _make_view()
	view.size_option.select(1) # 8x8 = 64
	view._rebuild_grid()
	assert_eq(view.grid.get_child_count(), 64)
	assert_eq(view.grid.columns, 8)

func test_render_state_marks_revealed_cells_safe_for_active_round():
	var view = _make_view()
	view.size_option.select(0)
	view._rebuild_grid()
	var state := {
		"players": {
			multiplayer.get_unique_id(): {
				"player_id": multiplayer.get_unique_id(),
				"balance": 400,
				"active_round": {"total_cells": 25, "mine_count": 3, "revealed": [0, 1], "amount": 50, "multiplier": 1.2},
				"last_round": {},
			},
		},
	}
	view._render_state(state)
	assert_eq(view.grid.get_child(0).state, MinesCell.State.SAFE)
	assert_eq(view.grid.get_child(2).state, MinesCell.State.HIDDEN)

func test_size_and_mine_count_lock_while_round_is_active():
	var view = _make_view()
	view.size_option.select(0)
	view._rebuild_grid()
	var state := {
		"players": {
			multiplayer.get_unique_id(): {
				"player_id": multiplayer.get_unique_id(),
				"balance": 400,
				"active_round": {"total_cells": 25, "mine_count": 3, "revealed": [], "amount": 50, "multiplier": 1.0},
				"last_round": {},
			},
		},
	}
	view._render_state(state)
	assert_true(view.size_option.disabled, "cambiar de tamaño a mitad de ronda desincroniza el grid")
	assert_false(view.mine_count_edit.editable)

func test_size_and_mine_count_unlock_once_round_ends():
	var view = _make_view()
	view.size_option.select(0)
	view._rebuild_grid()
	var my_id := multiplayer.get_unique_id()
	var state := {
		"players": {
			my_id: {
				"player_id": my_id, "balance": 450, "active_round": {},
				"last_round": {
					"win": true, "mine_count": 3, "total_cells": 25,
					"revealed": [0], "mines": [1, 2, 3],
				},
			},
		},
	}
	view._render_state(state)
	assert_false(view.size_option.disabled)
	assert_true(view.mine_count_edit.editable)

func test_bet_sidebar_press_starts_round_with_selected_size_and_mines():
	var view = _make_view()
	view.table_controller.table_state = MinesTableState.new()
	view.size_option.select(0) # 25 celdas
	view._rebuild_grid()
	view.mine_count_edit.text = "4"
	view.bet_sidebar.amount = 50
	view.bet_sidebar.bet_pressed.emit(50)
	var my_id := multiplayer.get_unique_id()
	assert_true(view.table_controller.table_state.players.has(my_id))
	assert_eq(view.table_controller.table_state.players[my_id].active_round["mine_count"], 4)

extends GutTest

func _make_cell() -> MinesCell:
	var cell: MinesCell = load("res://scenes/ui/casino/mines_cell.tscn").instantiate()
	add_child_autofree(cell)
	return cell

func test_default_state_is_hidden_and_interactive():
	var cell := _make_cell()
	assert_eq(cell.state, MinesCell.State.HIDDEN)
	assert_true(cell.interactive)

func test_pressing_hidden_interactive_cell_emits_cell_pressed():
	var cell := _make_cell()
	cell.index = 7
	watch_signals(cell)
	cell._on_gui_pressed()
	assert_signal_emitted_with_parameters(cell, "cell_pressed", [7])

func test_pressing_revealed_cell_does_not_emit():
	var cell := _make_cell()
	cell.state = MinesCell.State.SAFE
	watch_signals(cell)
	cell._on_gui_pressed()
	assert_signal_not_emitted(cell, "cell_pressed")

func test_pressing_non_interactive_cell_does_not_emit():
	var cell := _make_cell()
	cell.interactive = false
	watch_signals(cell)
	cell._on_gui_pressed()
	assert_signal_not_emitted(cell, "cell_pressed")

func test_compute_cell_states_active_round_marks_revealed_as_safe():
	var round_data := {"total_cells": 9, "revealed": [0, 4]}
	var states := MinesCell.compute_cell_states(round_data, true)
	assert_eq(states.size(), 9)
	assert_eq(states[0], MinesCell.State.SAFE)
	assert_eq(states[4], MinesCell.State.SAFE)
	assert_eq(states[1], MinesCell.State.HIDDEN)

func test_compute_cell_states_lost_round_marks_one_exploded_mine_and_dims_rest():
	var round_data := {
		"total_cells": 9, "revealed": [0, 1], "mines": [2, 5, 8], "win": false,
	}
	var states := MinesCell.compute_cell_states(round_data, false)
	assert_eq(states[0], MinesCell.State.SAFE)
	assert_eq(states[1], MinesCell.State.SAFE)
	var exploded_count := 0
	var dim_count := 0
	for s in [states[2], states[5], states[8]]:
		if s == MinesCell.State.MINE:
			exploded_count += 1
		elif s == MinesCell.State.MINE_DIM:
			dim_count += 1
	assert_eq(exploded_count, 1)
	assert_eq(dim_count, 2)

func test_compute_cell_states_won_round_dims_all_mines_none_exploded():
	var round_data := {
		"total_cells": 9, "revealed": [0, 1, 3], "mines": [2, 5, 8], "win": true,
	}
	var states := MinesCell.compute_cell_states(round_data, false)
	for i in [2, 5, 8]:
		assert_eq(states[i], MinesCell.State.MINE_DIM)

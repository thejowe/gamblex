extends GutTest

func _make_view():
	var scene := load("res://scenes/poker_table_net.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	return instance

func test_scene_has_expected_node_paths() -> void:
	var view = _make_view()
	assert_not_null(view.get_node("FeltTablePanel"))
	assert_true(view.get_node("FeltTablePanel").full_oval)
	var seats_root: Control = view.get_node("SeatsRoot")
	assert_not_null(seats_root)
	assert_eq(seats_root.get_child_count(), 6)
	assert_not_null(view.get_node("HelpButton"))
	assert_not_null(view.get_node("HelpOverlay"))
	assert_not_null(view.get_node("SitButton"))
	assert_not_null(view.get_node("StartHandButton"))
	assert_not_null(view.get_node("FoldButton"))
	assert_not_null(view.get_node("CheckButton"))
	assert_not_null(view.get_node("CallButton"))
	assert_not_null(view.get_node("RaiseButton"))

func test_each_seat_has_avatar_and_info_label() -> void:
	var view = _make_view()
	var seats_root: Control = view.get_node("SeatsRoot")
	for i in 6:
		var seat: Control = seats_root.get_node("Seat%d" % i)
		assert_not_null(seat.get_node("Avatar"))
		assert_not_null(seat.get_node("InfoLabel"))

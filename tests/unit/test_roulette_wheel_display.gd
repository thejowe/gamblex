extends GutTest

func _make_wheel() -> RouletteWheelDisplay:
	var wheel: RouletteWheelDisplay = load("res://scenes/ui/casino/roulette_wheel_display.tscn").instantiate()
	add_child_autofree(wheel)
	return wheel

func test_angle_for_result_zero_is_zero_plus_half_slice():
	var wheel := _make_wheel()
	var slice := TAU / RouletteWheelDisplay.WHEEL_ORDER.size()
	assert_almost_eq(wheel.angle_for_result(0), slice / 2.0, 0.0001)

func test_angle_for_result_is_within_full_circle():
	var wheel := _make_wheel()
	for result in [1, 17, 36]:
		var angle := wheel.angle_for_result(result)
		assert_true(angle >= 0.0 and angle < TAU)

func test_spin_to_eventually_sets_last_result():
	var wheel := _make_wheel()
	wheel.spin_to(23)
	await wheel.spin_finished
	assert_eq(wheel.last_result, 23)

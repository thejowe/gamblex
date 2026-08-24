extends GutTest

func _make_slider() -> DiceThresholdSlider:
	var slider: DiceThresholdSlider = load("res://scenes/ui/casino/dice_threshold_slider.tscn").instantiate()
	add_child_autofree(slider)
	slider.size = Vector2(600, 40)
	return slider

func test_default_threshold_is_fifty():
	var slider := _make_slider()
	assert_eq(slider.threshold, 50)

func test_set_threshold_from_x_clamps_to_one_and_ninety_nine():
	var slider := _make_slider()
	slider.set_threshold_from_x(-100.0)
	assert_eq(slider.threshold, 1)
	slider.set_threshold_from_x(10000.0)
	assert_eq(slider.threshold, 99)

func test_set_threshold_from_x_maps_middle_to_fifty():
	var slider := _make_slider()
	slider.set_threshold_from_x(300.0) # mitad de 600px de ancho
	assert_eq(slider.threshold, 50)

func test_set_threshold_from_x_emits_threshold_changed():
	var slider := _make_slider()
	watch_signals(slider)
	slider.set_threshold_from_x(0.0)
	assert_signal_emitted_with_parameters(slider, "threshold_changed", [1])

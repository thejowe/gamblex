extends GutTest

func test_covers_full_screen() -> void:
	var scene := load("res://scenes/ui/casino/loading_screen.tscn")
	var instance: Control = scene.instantiate()
	add_child_autofree(instance)
	assert_eq(instance.anchor_right, 1.0)
	assert_eq(instance.anchor_bottom, 1.0)

func test_starts_fully_transparent() -> void:
	var scene := load("res://scenes/ui/casino/loading_screen.tscn")
	var instance: Control = scene.instantiate()
	add_child_autofree(instance)
	assert_almost_eq(instance.modulate.a, 0.0, 0.01)

func test_indicator_dots_pulse_without_crash() -> void:
	var scene := load("res://scenes/ui/casino/loading_screen.tscn")
	var instance: LoadingScreen = scene.instantiate()
	add_child_autofree(instance)
	instance.indicator._process(0.1)
	pass_test("no crashea")

func test_fade_and_change_scene_animates_alpha() -> void:
	var scene := load("res://scenes/ui/casino/loading_screen.tscn")
	var instance: LoadingScreen = scene.instantiate()
	add_child_autofree(instance)
	var tween := instance.start_fade_in(0.1)
	assert_not_null(tween)

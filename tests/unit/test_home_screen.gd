extends GutTest

func _make() -> Control:
	var scene := load("res://scenes/home_screen.tscn")
	var instance: Control = scene.instantiate()
	add_child_autofree(instance)
	return instance

func test_has_five_buttons() -> void:
	var home := _make()
	assert_not_null(home.get_node("StartButton"))
	assert_not_null(home.get_node("SettingsButton"))
	assert_not_null(home.get_node("CreditsButton"))
	assert_not_null(home.get_node("HelpButton"))
	assert_not_null(home.get_node("QuitButton"))

func test_covers_full_screen() -> void:
	var home := _make()
	assert_eq(home.anchor_right, 1.0)
	assert_eq(home.anchor_bottom, 1.0)

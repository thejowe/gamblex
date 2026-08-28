extends GutTest

const CreditsMenuScene := preload("res://scenes/ui/casino/credits_menu.tscn")

func test_instantiates_without_error() -> void:
	var instance := CreditsMenuScene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance)

func test_back_button_exists() -> void:
	var instance := CreditsMenuScene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance.get_node("BackButton"))

extends GutTest

func test_starts_hidden() -> void:
	var overlay := preload("res://scenes/ui/casino/help_overlay.tscn").instantiate()
	add_child_autofree(overlay)
	assert_false(overlay.visible)

func test_set_rules_text_updates_label() -> void:
	var overlay := preload("res://scenes/ui/casino/help_overlay.tscn").instantiate()
	add_child_autofree(overlay)
	overlay.set_rules_text("Texto de prueba")
	assert_true(overlay.get_node("Panel/Margin/VBox/RulesLabel").text.contains("Texto de prueba"))

func test_open_shows_overlay() -> void:
	var overlay := preload("res://scenes/ui/casino/help_overlay.tscn").instantiate()
	add_child_autofree(overlay)
	overlay.open()
	assert_true(overlay.visible)

func test_close_button_hides_overlay() -> void:
	var overlay := preload("res://scenes/ui/casino/help_overlay.tscn").instantiate()
	add_child_autofree(overlay)
	overlay.open()
	overlay.get_node("Panel/Margin/VBox/CloseButton").pressed.emit()
	assert_false(overlay.visible)

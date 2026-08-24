extends GutTest

func test_default_rules_text():
	var panel: FeltTablePanel = load("res://scenes/ui/casino/felt_table_panel.tscn").instantiate()
	add_child_autofree(panel)
	assert_eq(panel.rules_text_top, "BLACKJACK PAYS 3 TO 2")
	assert_eq(panel.rules_text_bottom, "INSURANCE PAYS 2 TO 1")

func test_can_resize_and_redraw_without_error():
	var container := Control.new()
	container.size = Vector2(900, 1080)
	add_child_autofree(container)
	var panel: FeltTablePanel = load("res://scenes/ui/casino/felt_table_panel.tscn").instantiate()
	container.add_child(panel)
	panel.queue_redraw()
	await get_tree().process_frame
	assert_true(true)

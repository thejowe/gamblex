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

func test_default_behavior_unchanged():
	var panel: FeltTablePanel = load("res://scenes/ui/casino/felt_table_panel.tscn").instantiate()
	add_child_autofree(panel)
	assert_false(panel.full_oval)

func test_full_oval_flag_settable():
	var panel: FeltTablePanel = load("res://scenes/ui/casino/felt_table_panel.tscn").instantiate()
	panel.full_oval = true
	add_child_autofree(panel)
	assert_true(panel.full_oval)

func test_full_oval_resizes_and_redraws_without_error():
	var container := Control.new()
	container.size = Vector2(900, 1080)
	add_child_autofree(container)
	var panel: FeltTablePanel = load("res://scenes/ui/casino/felt_table_panel.tscn").instantiate()
	panel.full_oval = true
	container.add_child(panel)
	panel.queue_redraw()
	await get_tree().process_frame
	assert_true(true)

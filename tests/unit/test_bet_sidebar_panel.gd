extends GutTest

func _make_panel() -> BetSidebarPanel:
	var panel: BetSidebarPanel = load("res://scenes/ui/casino/bet_sidebar_panel.tscn").instantiate()
	add_child_autofree(panel)
	return panel

func test_default_amount_is_ten():
	var panel := _make_panel()
	assert_eq(panel.amount, 10)

func test_amount_setter_clamps_to_at_least_one():
	var panel := _make_panel()
	panel.amount = -5
	assert_eq(panel.amount, 1)

func test_amount_setter_clamps_to_max_amount():
	var panel := _make_panel()
	panel.max_amount = 200
	panel.amount = 9999
	assert_eq(panel.amount, 200)

func test_half_button_halves_amount_with_minimum_one():
	var panel := _make_panel()
	panel.amount = 10
	panel._on_half_pressed()
	assert_eq(panel.amount, 5)
	panel.amount = 1
	panel._on_half_pressed()
	assert_eq(panel.amount, 1)

func test_double_button_doubles_amount_clamped_to_max():
	var panel := _make_panel()
	panel.max_amount = 100
	panel.amount = 60
	panel._on_double_pressed()
	assert_eq(panel.amount, 100) # 120 clamped a max_amount

func test_max_button_sets_amount_to_max_amount():
	var panel := _make_panel()
	panel.max_amount = 300
	panel._on_max_pressed()
	assert_eq(panel.amount, 300)

func test_bet_button_emits_bet_pressed_with_current_amount():
	var panel := _make_panel()
	panel.amount = 42
	watch_signals(panel)
	panel._on_bet_pressed()
	assert_signal_emitted_with_parameters(panel, "bet_pressed", [42])

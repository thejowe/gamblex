extends GutTest

func test_set_balance_formats_label_text():
	var hud: CasinoHudBar = load("res://scenes/ui/casino/casino_hud_bar.tscn").instantiate()
	add_child_autofree(hud)
	hud.set_balance(1234)
	assert_eq(hud.balance_label.text, "BALANCE  $1234")

func test_set_bet_formats_label_text():
	var hud: CasinoHudBar = load("res://scenes/ui/casino/casino_hud_bar.tscn").instantiate()
	add_child_autofree(hud)
	hud.set_bet(50)
	assert_eq(hud.bet_label.text, "APUESTA  $50")

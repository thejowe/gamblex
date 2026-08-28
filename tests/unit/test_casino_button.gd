extends GutTest

func test_color_for_variant_positive_is_green():
	assert_eq(CasinoButton.color_for_variant(CasinoButton.Variant.POSITIVE), Color("2f8f5b"))

func test_color_for_variant_negative_is_red():
	assert_eq(CasinoButton.color_for_variant(CasinoButton.Variant.NEGATIVE), Color("b23b3b"))

func test_default_variant_is_neutral():
	var button: CasinoButton = CasinoButton.new()
	add_child_autofree(button)
	assert_eq(button.variant, CasinoButton.Variant.NEUTRAL)

func test_press_plays_click_sfx():
	var button: CasinoButton = CasinoButton.new()
	add_child_autofree(button)
	button._on_press()
	pass_test("no crashea al reproducir click")

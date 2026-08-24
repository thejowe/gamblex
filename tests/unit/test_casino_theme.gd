extends GutTest

func test_chip_color_known_denomination_returns_expected_color():
	assert_eq(CasinoTheme.chip_color(50), Color("e07b1f"))

func test_chip_color_unknown_denomination_returns_fallback_purple():
	assert_eq(CasinoTheme.chip_color(9999), Color("9b59b6"))

func test_palette_constants_are_colors():
	assert_true(CasinoTheme.FELT_GREEN_LIGHT is Color)
	assert_true(CasinoTheme.WOOD_BROWN_LIGHT is Color)
	assert_true(CasinoTheme.GOLD_ACCENT is Color)
	assert_true(CasinoTheme.CARD_WHITE is Color)
	assert_true(CasinoTheme.TEXT_CREAM is Color)

extends GutTest

func test_default_size_matches_radius():
	var chip: CasinoChip = CasinoChip.new()
	assert_eq(chip.custom_minimum_size, Vector2(CasinoChip.RADIUS * 2, CasinoChip.RADIUS * 2))
	chip.free()

func test_denomination_defaults_to_50():
	var chip: CasinoChip = CasinoChip.new()
	assert_eq(chip.denomination, 50)
	chip.free()

func test_setting_denomination_does_not_error():
	var chip: CasinoChip = CasinoChip.new()
	add_child_autofree(chip)
	chip.denomination = 100
	assert_eq(chip.denomination, 100)

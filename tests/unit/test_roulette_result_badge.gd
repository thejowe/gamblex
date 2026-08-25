extends GutTest

func test_default_size_is_diameter_of_radius():
	var badge: RouletteResultBadge = RouletteResultBadge.new()
	assert_eq(badge.custom_minimum_size, Vector2(RouletteResultBadge.RADIUS * 2, RouletteResultBadge.RADIUS * 2))
	badge.free()

func test_setting_number_does_not_error():
	var badge: RouletteResultBadge = RouletteResultBadge.new()
	add_child_autofree(badge)
	badge.number = 32
	assert_eq(badge.number, 32)

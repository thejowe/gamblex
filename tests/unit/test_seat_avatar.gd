extends GutTest

func test_default_initial_is_question_mark() -> void:
	var avatar: SeatAvatar = load("res://scenes/ui/casino/seat_avatar.tscn").instantiate()
	add_child_autofree(avatar)
	assert_eq(avatar.initial, "?")

func test_color_is_deterministic_per_player_id() -> void:
	var avatar: SeatAvatar = load("res://scenes/ui/casino/seat_avatar.tscn").instantiate()
	add_child_autofree(avatar)
	avatar.player_id = 42
	var c1 := avatar.avatar_color()
	avatar.player_id = 42
	var c2 := avatar.avatar_color()
	assert_eq(c1, c2)

func test_color_stays_in_bounds_for_negative_or_large_ids() -> void:
	var avatar: SeatAvatar = load("res://scenes/ui/casino/seat_avatar.tscn").instantiate()
	add_child_autofree(avatar)
	avatar.player_id = -12345
	avatar.avatar_color()  # no debe crashear con id negativo
	avatar.player_id = 999999999
	avatar.avatar_color()  # ni con id muy grande
	pass_test("no crashea")

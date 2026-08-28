extends GutTest

func test_parse_match_type_empty_string_is_free_mode():
    assert_eq(SteamManager.parse_match_type(""), -1)

func test_parse_match_type_minus_one_is_free_mode():
    assert_eq(SteamManager.parse_match_type("-1"), -1)

func test_parse_match_type_zero_is_1v1():
    assert_eq(SteamManager.parse_match_type("0"), 0)

func test_parse_match_type_two_is_4v4():
    assert_eq(SteamManager.parse_match_type("2"), 2)

func test_reset_clears_current_lobby_id_and_match_type():
    SteamManager.current_lobby_id = 999
    SteamManager.chosen_match_type = 2
    SteamManager.reset()
    assert_eq(SteamManager.current_lobby_id, 0)
    assert_eq(SteamManager.chosen_match_type, -1)

func test_reset_does_not_clear_last_disconnect_reason():
    SteamManager.last_disconnect_reason = "El host cerró la sala."
    SteamManager.reset()
    assert_eq(SteamManager.last_disconnect_reason, "El host cerró la sala.")
    SteamManager.last_disconnect_reason = ""

func test_unlock_achievement_noop_when_steam_not_ready():
    var original_ready: bool = SteamManager.is_ready
    SteamManager.is_ready = false
    SteamManager.unlock_achievement("TEST_ACHIEVEMENT")
    SteamManager.is_ready = original_ready
    pass_test("no crashea sin Steam listo")

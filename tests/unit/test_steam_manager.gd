extends GutTest

func test_parse_match_type_empty_string_is_free_mode():
    assert_eq(SteamManager.parse_match_type(""), -1)

func test_parse_match_type_minus_one_is_free_mode():
    assert_eq(SteamManager.parse_match_type("-1"), -1)

func test_parse_match_type_zero_is_1v1():
    assert_eq(SteamManager.parse_match_type("0"), 0)

func test_parse_match_type_two_is_4v4():
    assert_eq(SteamManager.parse_match_type("2"), 2)

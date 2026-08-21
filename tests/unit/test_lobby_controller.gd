extends GutTest

func test_starts_in_lobby():
    var lobby = LobbyController.new()
    assert_true(lobby.is_in_lobby())

func test_no_table_is_active_while_in_lobby():
    var lobby = LobbyController.new()
    assert_false(lobby.is_active("BlackjackTableNet"))
    assert_false(lobby.is_active("DiceTableNet"))

func test_select_leaves_lobby_and_activates_table():
    var lobby = LobbyController.new()
    lobby.select("BlackjackTableNet")
    assert_false(lobby.is_in_lobby())
    assert_true(lobby.is_active("BlackjackTableNet"))

func test_only_selected_table_is_active():
    var lobby = LobbyController.new()
    lobby.select("DiceTableNet")
    assert_true(lobby.is_active("DiceTableNet"))
    assert_false(lobby.is_active("BlackjackTableNet"))
    assert_false(lobby.is_active("CrashTableNet"))

func test_selecting_another_table_switches_active_table():
    var lobby = LobbyController.new()
    lobby.select("BlackjackTableNet")
    lobby.select("PlinkoTableNet")
    assert_true(lobby.is_active("PlinkoTableNet"))
    assert_false(lobby.is_active("BlackjackTableNet"))

func test_return_to_lobby_resets_state():
    var lobby = LobbyController.new()
    lobby.select("PokerTableNet")
    lobby.return_to_lobby()
    assert_true(lobby.is_in_lobby())
    assert_false(lobby.is_active("PokerTableNet"))

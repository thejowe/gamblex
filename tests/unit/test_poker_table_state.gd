extends GutTest

func _stub_deck(draw_order: Array) -> Deck:
    var deck = Deck.new()
    var ordered: Array[Card] = []
    for card in draw_order:
        ordered.append(card)
    ordered.reverse()
    deck.cards = ordered
    return deck

func test_sit_occupies_empty_seat():
    var table = PokerTableState.new()
    var ok = table.sit(0, 111)
    assert_true(ok)
    assert_eq(table.seats[0].player_id, 111)

func test_sit_fails_on_occupied_seat():
    var table = PokerTableState.new()
    table.sit(0, 111)
    var ok = table.sit(0, 222)
    assert_false(ok)

func test_sit_fails_if_player_already_seated_elsewhere():
    var table = PokerTableState.new()
    table.sit(0, 111)
    var ok = table.sit(1, 111)
    assert_false(ok)

func test_start_hand_fails_with_fewer_than_two_seated():
    var table = PokerTableState.new()
    table.sit(0, 111)
    var ok = table.start_hand()
    assert_false(ok)

func test_start_hand_fails_if_seated_player_below_big_blind():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.seats[1].ledger.balance = 5
    var ok = table.start_hand()
    assert_false(ok)

func test_heads_up_blinds_and_first_to_act():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    var ok = table.start_hand()
    assert_true(ok)
    assert_eq(table.dealer_button_index, 0)
    assert_eq(table.seats[0].current_bet, PokerTableState.SMALL_BLIND)
    assert_eq(table.seats[1].current_bet, PokerTableState.BIG_BLIND)
    assert_eq(table.seats[0].ledger.balance, 500 - PokerTableState.SMALL_BLIND)
    assert_eq(table.seats[1].ledger.balance, 500 - PokerTableState.BIG_BLIND)
    assert_eq(table.pot, PokerTableState.SMALL_BLIND + PokerTableState.BIG_BLIND)
    assert_eq(table.current_bet, PokerTableState.BIG_BLIND)
    # en heads-up el boton (ciega chica) actua primero preflop
    assert_eq(table.active_seat_index, 0)
    assert_eq(table.seats[0].hole_cards.size(), 2)
    assert_eq(table.seats[1].hole_cards.size(), 2)
    assert_eq(table.betting_round, PokerTableState.BettingRound.PREFLOP)
    assert_true(table.hand_active)

func test_three_handed_dealer_rotates_each_hand():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.sit(2, 333)
    table.start_hand()
    assert_eq(table.dealer_button_index, 0)
    assert_eq(table.seats[1].current_bet, PokerTableState.SMALL_BLIND)
    assert_eq(table.seats[2].current_bet, PokerTableState.BIG_BLIND)
    # a 3 manos el primero en actuar preflop es el propio boton
    assert_eq(table.active_seat_index, 0)

    # fin de mano forzado a mano para poder repartir de nuevo dentro del test
    # (Task 4 no incluye aun ninguna accion que cierre una mano)
    table.hand_active = false
    table.start_hand()
    assert_eq(table.dealer_button_index, 1)

func test_start_hand_deals_deterministic_hole_cards_from_stub_deck():
    var deck = _stub_deck([
        Card.new(2, Card.Suit.HEARTS),   # sb hole 1
        Card.new(3, Card.Suit.HEARTS),   # bb hole 1
        Card.new(4, Card.Suit.HEARTS),   # sb hole 2
        Card.new(5, Card.Suit.HEARTS),   # bb hole 2
    ])
    var table = PokerTableState.new(deck)
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    assert_eq(table.seats[0].hole_cards[0].rank, 2)
    assert_eq(table.seats[1].hole_cards[0].rank, 3)
    assert_eq(table.seats[0].hole_cards[1].rank, 4)
    assert_eq(table.seats[1].hole_cards[1].rank, 5)

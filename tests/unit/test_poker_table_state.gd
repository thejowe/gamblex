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

func test_check_fails_when_amount_owed():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    # heads-up: activo es el asiento 0 (ciega chica), debe 5 para igualar la ciega grande
    var ok = table.check(0, 111)
    assert_false(ok)

func test_call_then_bb_option_check_advances_to_flop():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    assert_true(table.call_bet(0, 111))
    assert_eq(table.seats[0].current_bet, PokerTableState.BIG_BLIND)
    assert_eq(table.pot, PokerTableState.BIG_BLIND * 2)
    # la ciega grande aun no ha actuado esta ronda -> le toca el turno, no avanza aun
    assert_eq(table.betting_round, PokerTableState.BettingRound.PREFLOP)
    assert_eq(table.active_seat_index, 1)

    assert_true(table.check(1, 222))
    assert_eq(table.betting_round, PokerTableState.BettingRound.FLOP)
    assert_eq(table.community_cards.size(), 3)
    assert_eq(table.seats[0].current_bet, 0)
    assert_eq(table.seats[1].current_bet, 0)
    assert_eq(table.current_bet, 0)
    # en heads-up, postflop actua primero quien no tiene el boton (la ciega grande)
    assert_eq(table.active_seat_index, 1)

func test_raise_resets_other_seats_has_acted_and_updates_min_raise():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    assert_true(table.raise_bet(0, 111, 30)) # sube a 30 (incremento 20 sobre la ciega grande de 10)
    assert_eq(table.current_bet, 30)
    assert_eq(table.min_raise, 20)
    assert_eq(table.seats[0].current_bet, 30)
    assert_eq(table.pot, 30 + PokerTableState.BIG_BLIND)
    assert_eq(table.active_seat_index, 1)
    assert_false(table.seats[1].has_acted)

func test_raise_below_min_raise_rejected():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    var ok = table.raise_bet(0, 111, 15) # incremento de solo 5, menor que la ciega grande (10)
    assert_false(ok)
    assert_eq(table.current_bet, PokerTableState.BIG_BLIND)

func test_call_bet_fails_when_cannot_afford():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    table.seats[0].ledger.balance = 2 # menos que lo que le falta para igualar (5)
    var ok = table.call_bet(0, 111)
    assert_false(ok)
    assert_eq(table.seats[0].current_bet, PokerTableState.SMALL_BLIND)

func test_fold_awards_pot_uncontested():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    var pot_before: int = table.pot
    assert_true(table.fold(0, 111))
    assert_false(table.hand_active)
    assert_eq(table.pot, 0)
    assert_eq(table.last_winner_seats, [1])
    assert_eq(table.seats[1].ledger.balance, 500 - PokerTableState.BIG_BLIND + pot_before)

func test_actions_rejected_when_not_your_turn_or_not_your_seat():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    var ok = table.check(1, 222) # no es su turno (activo es el asiento 0)
    assert_false(ok)
    var ok2 = table.call_bet(0, 999) # no es el jugador de ese asiento
    assert_false(ok2)

func test_full_hand_to_showdown_awards_pot_to_best_hand():
    var deck = _stub_deck([
        Card.new(13, Card.Suit.HEARTS),   # seat0 hole1: K de corazones
        Card.new(10, Card.Suit.SPADES),   # seat1 hole1: 10 de picas
        Card.new(13, Card.Suit.CLUBS),    # seat0 hole2: K de treboles
        Card.new(5, Card.Suit.DIAMONDS),  # seat1 hole2: 5 de diamantes
        Card.new(13, Card.Suit.DIAMONDS), # flop1: K de diamantes
        Card.new(2, Card.Suit.CLUBS),     # flop2
        Card.new(7, Card.Suit.HEARTS),    # flop3
        Card.new(9, Card.Suit.CLUBS),     # turn
        Card.new(4, Card.Suit.SPADES),    # river
    ])
    var table = PokerTableState.new(deck)
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    assert_true(table.call_bet(0, 111))
    assert_true(table.check(1, 222)) # cierra preflop -> flop
    assert_true(table.check(1, 222)) # postflop actua primero el asiento 1
    assert_true(table.check(0, 111)) # cierra flop -> turn
    assert_true(table.check(1, 222))
    assert_true(table.check(0, 111)) # cierra turn -> river
    assert_true(table.check(1, 222))
    assert_true(table.check(0, 111)) # cierra river -> showdown

    assert_eq(table.betting_round, PokerTableState.BettingRound.SHOWDOWN)
    assert_false(table.hand_active)
    # seat0 tiene trio de reyes (K-K de mano + K de mesa); seat1 solo carta alta
    assert_eq(table.last_winner_seats, [0])
    assert_eq(table.pot, 0)
    # bote total 20 (5+10 de ciegas + 5 de igualar la ciega grande); seat0 lo
    # gana entero: aporto 10 en total (500-10+20=510); seat1 aporto 10 y pierde (500-10=490)
    assert_eq(table.seats[0].ledger.balance, 510)
    assert_eq(table.seats[1].ledger.balance, 490)

func test_to_dict_hides_other_players_hole_cards_before_showdown():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    var data_for_111 = table.to_dict(111)
    var data_for_222 = table.to_dict(222)
    assert_eq(data_for_111["seats"][0]["hole_cards"].size(), 2) # su propia mano
    assert_eq(data_for_111["seats"][1]["hole_cards"].size(), 0) # mano ajena oculta
    assert_eq(data_for_222["seats"][0]["hole_cards"].size(), 0)
    assert_eq(data_for_222["seats"][1]["hole_cards"].size(), 2)

func test_to_dict_reveals_non_folded_hands_at_showdown():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    table.call_bet(0, 111)
    table.check(1, 222) # flop
    table.check(1, 222)
    table.check(0, 111) # turn
    table.check(1, 222)
    table.check(0, 111) # river
    table.check(1, 222)
    table.check(0, 111) # showdown

    var data = table.to_dict(999) # espectador ajeno a la mano
    assert_eq(data["seats"][0]["hole_cards"].size(), 2)
    assert_eq(data["seats"][1]["hole_cards"].size(), 2)

func test_to_dict_never_reveals_folded_hand():
    var table = PokerTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.start_hand()
    table.fold(0, 111)
    var data = table.to_dict(999)
    assert_eq(data["seats"][0]["hole_cards"].size(), 0)

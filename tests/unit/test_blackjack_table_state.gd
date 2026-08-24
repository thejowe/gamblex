extends GutTest

func test_sit_occupies_empty_seat():
    var table = BlackjackTableState.new()
    var ok = table.sit(0, 111)
    assert_true(ok)
    assert_eq(table.seats[0].player_id, 111)

func test_sit_fails_on_occupied_seat():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    var ok = table.sit(0, 222)
    assert_false(ok)

func test_sit_fails_if_player_already_seated_elsewhere():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    var ok = table.sit(1, 111)
    assert_false(ok)

func test_sit_fails_on_out_of_range_seat():
    var table = BlackjackTableState.new()
    var ok = table.sit(4, 111)
    assert_false(ok)

func test_round_does_not_start_until_all_seated_players_bet():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.place_bet(0, 111, 100)
    assert_false(table.round_active)
    table.place_bet(1, 222, 100)
    assert_true(table.round_active)

func test_place_bet_fails_for_unseated_or_wrong_player():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    var ok = table.place_bet(0, 999, 100)
    assert_false(ok)
    assert_false(table.round_active)

func _stub_deck(draw_order: Array) -> Deck:
    var deck = Deck.new()
    var ordered: Array[Card] = []
    for card in draw_order:
        ordered.append(card)
    ordered.reverse()
    deck.cards = ordered
    return deck

func test_full_round_multiple_seats_resolve_independently():
    var deck = _stub_deck([
        Card.new(10, Card.Suit.HEARTS),   # seat0 card1
        Card.new(10, Card.Suit.DIAMONDS), # seat1 card1
        Card.new(9, Card.Suit.HEARTS),    # dealer card1
        Card.new(10, Card.Suit.SPADES),   # seat0 card2 -> seat0 = 20
        Card.new(9, Card.Suit.SPADES),    # seat1 card2 -> seat1 = 19
        Card.new(8, Card.Suit.SPADES),    # dealer card2 -> dealer = 17
        Card.new(5, Card.Suit.CLUBS),     # seat1 hit -> 24 bust
    ])
    var table = BlackjackTableState.new(deck)
    table.sit(0, 111)
    table.sit(1, 222)
    table.place_bet(0, 111, 100)
    table.place_bet(1, 222, 50)
    assert_true(table.round_active)
    assert_eq(table.active_seat_index, 0)

    assert_true(table.stand(0, 111))
    assert_eq(table.active_seat_index, 1)

    assert_true(table.hit(1, 222))
    assert_false(table.round_active) # los dos asientos se resolvieron, ronda cerrada

    assert_eq(table.seats[0].ledger.balance, 600) # 500 - 100 + 200 (gana 20 vs 17)
    assert_eq(table.seats[1].ledger.balance, 450) # 500 - 50, bust, sin pago

func test_actions_rejected_when_not_your_turn_or_not_your_seat():
    var deck = _stub_deck([
        Card.new(10, Card.Suit.HEARTS),
        Card.new(6, Card.Suit.SPADES),
        Card.new(9, Card.Suit.HEARTS),
        Card.new(9, Card.Suit.SPADES),
        Card.new(7, Card.Suit.SPADES),
        Card.new(8, Card.Suit.SPADES),
    ])
    var table = BlackjackTableState.new(deck)
    table.sit(0, 111)
    table.sit(1, 222)
    table.place_bet(0, 111, 100)
    table.place_bet(1, 222, 100)
    # el turno activo es el asiento 0 (jugador 111); el asiento 1 intenta jugar fuera de turno
    var ok = table.hit(1, 222)
    assert_false(ok)
    assert_eq(table.active_seat_index, 0)
    # alguien que no ocupa el asiento 0 intenta actuar en su nombre
    var ok2 = table.stand(0, 999)
    assert_false(ok2)
    assert_eq(table.active_seat_index, 0)

func test_to_dict_reflects_seat_and_dealer_state():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    var data = table.to_dict()
    assert_eq(data["seats"][0]["player_id"], 111)
    assert_eq(data["seats"][1], null)
    assert_eq(data["round_active"], false)

func test_chips_won_emitted_only_for_winning_seat():
    var deck = _stub_deck([
        Card.new(10, Card.Suit.HEARTS),   # seat0 card1
        Card.new(10, Card.Suit.DIAMONDS), # seat1 card1
        Card.new(9, Card.Suit.HEARTS),    # dealer card1
        Card.new(10, Card.Suit.SPADES),   # seat0 card2 -> seat0 = 20
        Card.new(9, Card.Suit.SPADES),    # seat1 card2 -> seat1 = 19
        Card.new(8, Card.Suit.SPADES),    # dealer card2 -> dealer = 17
        Card.new(5, Card.Suit.CLUBS),     # seat1 hit -> 24 bust
    ])
    var table = BlackjackTableState.new(deck)
    table.sit(0, 111)
    table.sit(1, 222)
    table.place_bet(0, 111, 100)
    table.place_bet(1, 222, 50)
    watch_signals(table)

    table.stand(0, 111)
    table.hit(1, 222) # bust, resuelve la ronda

    assert_signal_emitted_with_parameters(table, "chips_won", [111, 100])
    assert_signal_emit_count(table, "chips_won", 1) # seat1 quebró, no emite

func test_chips_won_not_emitted_on_tie():
    var deck = _stub_deck([
        Card.new(10, Card.Suit.HEARTS), # seat0 card1
        Card.new(9, Card.Suit.HEARTS),  # dealer card1
        Card.new(7, Card.Suit.SPADES),  # seat0 card2 -> 17
        Card.new(8, Card.Suit.SPADES),  # dealer card2 -> 17 (empate)
    ])
    var table = BlackjackTableState.new(deck)
    table.sit(0, 111)
    table.place_bet(0, 111, 100)
    watch_signals(table)

    table.stand(0, 111) # única silla ocupada, resuelve la ronda

    assert_signal_not_emitted(table, "chips_won")
    assert_eq(table.seats[0].ledger.balance, 500) # -100 + 100 (empate, ganancia neta 0)

func test_chips_won_emitted_when_dealer_busts():
    var deck = _stub_deck([
        Card.new(10, Card.Suit.HEARTS),  # seat0 card1
        Card.new(2, Card.Suit.HEARTS),   # dealer card1
        Card.new(8, Card.Suit.SPADES),   # seat0 card2 -> seat0 = 18
        Card.new(2, Card.Suit.SPADES),   # dealer card2 -> dealer = 4 (< 17, must keep drawing)
        Card.new(10, Card.Suit.CLUBS),   # dealer draw -> 14 (still < 17)
        Card.new(10, Card.Suit.DIAMONDS),# dealer draw -> 24 (>= 17, stop; bust)
    ])
    var table = BlackjackTableState.new(deck)
    table.sit(0, 111)
    table.place_bet(0, 111, 100)
    watch_signals(table)

    table.stand(0, 111) # only seat occupied, resolves the round immediately

    assert_signal_emitted_with_parameters(table, "chips_won", [111, 100])
    assert_eq(table.seats[0].ledger.balance, 600) # 500 - 100 + 200 (dealer bust, full payout)

func test_to_dict_exposes_seat_hand_cards():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    table.sit(1, 222)
    table.place_bet(0, 111, 50)
    table.place_bet(1, 222, 50)
    var state = table.to_dict()
    var hand = state["seats"][0]["hand"]
    assert_eq(hand.size(), 2)
    assert_true(hand[0].has("rank"))
    assert_true(hand[0].has("suit"))

func test_to_dict_hides_second_dealer_card_while_round_active():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    table.place_bet(0, 111, 50)
    var state = table.to_dict()
    assert_true(state["round_active"])
    var dealer_hand = state["dealer_hand"]
    assert_eq(dealer_hand.size(), 2)
    assert_true(dealer_hand[0].has("rank"))
    assert_true(dealer_hand[1].has("hidden"))
    assert_eq(dealer_hand[1]["hidden"], true)

func test_to_dict_reveals_dealer_hand_after_round_resolves():
    var table = BlackjackTableState.new()
    table.sit(0, 111)
    table.place_bet(0, 111, 50)
    table.stand(0, 111)
    var state = table.to_dict()
    assert_false(state["round_active"])
    var dealer_hand = state["dealer_hand"]
    for card_data in dealer_hand:
        assert_true(card_data.has("rank"))
        assert_false(card_data.has("hidden"))

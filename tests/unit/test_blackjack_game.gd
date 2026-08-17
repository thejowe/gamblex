extends GutTest

func _stub_deck(draw_order: Array[Card]) -> Deck:
    var deck = Deck.new()
    deck.cards = draw_order.duplicate()
    deck.cards.reverse()
    return deck

func test_start_round_deducts_bet_and_deals_two_cards_each():
    var ledger = ChipLedger.new(500)
    var deck = _stub_deck([
        Card.new(9, Card.Suit.HEARTS),   # player card 1
        Card.new(6, Card.Suit.SPADES),   # dealer card 1
        Card.new(8, Card.Suit.CLUBS),    # player card 2
        Card.new(7, Card.Suit.DIAMONDS), # dealer card 2
    ])
    var game = BlackjackGame.new(ledger, deck)
    var ok = game.start_round(100)
    assert_true(ok)
    assert_eq(ledger.balance, 400)
    assert_eq(game.player_hand.value(), 17)
    assert_eq(game.dealer_hand.value(), 13)
    assert_eq(game.state, BlackjackGame.State.PLAYER_TURN)

func test_start_round_fails_when_bet_exceeds_balance():
    var ledger = ChipLedger.new(50)
    var deck = _stub_deck([
        Card.new(9, Card.Suit.HEARTS),
        Card.new(6, Card.Suit.SPADES),
        Card.new(8, Card.Suit.CLUBS),
        Card.new(7, Card.Suit.DIAMONDS),
    ])
    var game = BlackjackGame.new(ledger, deck)
    var ok = game.start_round(100)
    assert_false(ok)
    assert_eq(ledger.balance, 50)
    assert_eq(game.state, BlackjackGame.State.BETTING)

func test_natural_blackjack_resolves_immediately():
    var ledger = ChipLedger.new(500)
    var deck = _stub_deck([
        Card.new(1, Card.Suit.HEARTS),   # player card 1 (As)
        Card.new(6, Card.Suit.SPADES),   # dealer card 1
        Card.new(13, Card.Suit.CLUBS),   # player card 2 (K) -> blackjack natural
        Card.new(7, Card.Suit.DIAMONDS), # dealer card 2 -> dealer 13
    ])
    var game = BlackjackGame.new(ledger, deck)
    game.start_round(100)
    assert_eq(game.state, BlackjackGame.State.ROUND_OVER)
    assert_eq(ledger.balance, 600) # 500 - 100 apuesta + 200 pago (blackjack vs no-blackjack)

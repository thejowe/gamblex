extends GutTest

func test_value_counts_number_cards():
    var hand = Hand.new()
    hand.add_card(Card.new(5, Card.Suit.HEARTS))
    hand.add_card(Card.new(7, Card.Suit.SPADES))
    assert_eq(hand.value(), 12)

func test_face_cards_count_as_ten():
    var hand = Hand.new()
    hand.add_card(Card.new(11, Card.Suit.HEARTS)) # Jack
    hand.add_card(Card.new(13, Card.Suit.SPADES)) # King
    assert_eq(hand.value(), 20)

func test_ace_counts_as_11_when_it_fits():
    var hand = Hand.new()
    hand.add_card(Card.new(1, Card.Suit.HEARTS))
    hand.add_card(Card.new(9, Card.Suit.SPADES))
    assert_eq(hand.value(), 20)

func test_ace_counts_as_1_when_11_would_bust():
    var hand = Hand.new()
    hand.add_card(Card.new(1, Card.Suit.HEARTS))
    hand.add_card(Card.new(9, Card.Suit.SPADES))
    hand.add_card(Card.new(5, Card.Suit.CLUBS))
    assert_eq(hand.value(), 15)

func test_is_bust_above_21():
    var hand = Hand.new()
    hand.add_card(Card.new(10, Card.Suit.HEARTS))
    hand.add_card(Card.new(10, Card.Suit.SPADES))
    hand.add_card(Card.new(5, Card.Suit.CLUBS))
    assert_true(hand.is_bust())

func test_is_blackjack_with_ace_and_ten_card():
    var hand = Hand.new()
    hand.add_card(Card.new(1, Card.Suit.HEARTS))
    hand.add_card(Card.new(13, Card.Suit.SPADES))
    assert_true(hand.is_blackjack())

func test_is_not_blackjack_with_three_cards_totaling_21():
    var hand = Hand.new()
    hand.add_card(Card.new(7, Card.Suit.HEARTS))
    hand.add_card(Card.new(7, Card.Suit.SPADES))
    hand.add_card(Card.new(7, Card.Suit.CLUBS))
    assert_false(hand.is_blackjack())

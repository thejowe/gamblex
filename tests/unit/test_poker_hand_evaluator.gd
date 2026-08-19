extends GutTest

func test_four_of_a_kind():
    var cards: Array[Card] = [
        Card.new(10, Card.Suit.HEARTS),
        Card.new(10, Card.Suit.DIAMONDS),
        Card.new(10, Card.Suit.CLUBS),
        Card.new(10, Card.Suit.SPADES),
        Card.new(3, Card.Suit.HEARTS),
    ]
    var hand = PokerHandEvaluator.evaluate_five(cards)
    assert_eq(hand["category"], PokerHandEvaluator.Category.FOUR_OF_A_KIND)
    assert_eq(hand["tiebreakers"], [10, 3])

func test_full_house():
    var cards: Array[Card] = [
        Card.new(10, Card.Suit.HEARTS),
        Card.new(10, Card.Suit.DIAMONDS),
        Card.new(10, Card.Suit.CLUBS),
        Card.new(5, Card.Suit.SPADES),
        Card.new(5, Card.Suit.HEARTS),
    ]
    var hand = PokerHandEvaluator.evaluate_five(cards)
    assert_eq(hand["category"], PokerHandEvaluator.Category.FULL_HOUSE)
    assert_eq(hand["tiebreakers"], [10, 5])

func test_three_of_a_kind():
    var cards: Array[Card] = [
        Card.new(10, Card.Suit.HEARTS),
        Card.new(10, Card.Suit.DIAMONDS),
        Card.new(10, Card.Suit.CLUBS),
        Card.new(7, Card.Suit.SPADES),
        Card.new(3, Card.Suit.HEARTS),
    ]
    var hand = PokerHandEvaluator.evaluate_five(cards)
    assert_eq(hand["category"], PokerHandEvaluator.Category.THREE_OF_A_KIND)
    assert_eq(hand["tiebreakers"], [10, 7, 3])

func test_two_pair():
    var cards: Array[Card] = [
        Card.new(10, Card.Suit.HEARTS),
        Card.new(10, Card.Suit.DIAMONDS),
        Card.new(7, Card.Suit.CLUBS),
        Card.new(7, Card.Suit.SPADES),
        Card.new(3, Card.Suit.HEARTS),
    ]
    var hand = PokerHandEvaluator.evaluate_five(cards)
    assert_eq(hand["category"], PokerHandEvaluator.Category.TWO_PAIR)
    assert_eq(hand["tiebreakers"], [10, 7, 3])

func test_one_pair():
    var cards: Array[Card] = [
        Card.new(10, Card.Suit.HEARTS),
        Card.new(10, Card.Suit.DIAMONDS),
        Card.new(7, Card.Suit.CLUBS),
        Card.new(5, Card.Suit.SPADES),
        Card.new(3, Card.Suit.HEARTS),
    ]
    var hand = PokerHandEvaluator.evaluate_five(cards)
    assert_eq(hand["category"], PokerHandEvaluator.Category.PAIR)
    assert_eq(hand["tiebreakers"], [10, 7, 5, 3])

func test_high_card():
    var cards: Array[Card] = [
        Card.new(10, Card.Suit.HEARTS),
        Card.new(8, Card.Suit.DIAMONDS),
        Card.new(6, Card.Suit.CLUBS),
        Card.new(4, Card.Suit.SPADES),
        Card.new(2, Card.Suit.HEARTS),
    ]
    var hand = PokerHandEvaluator.evaluate_five(cards)
    assert_eq(hand["category"], PokerHandEvaluator.Category.HIGH_CARD)
    assert_eq(hand["tiebreakers"], [10, 8, 6, 4, 2])

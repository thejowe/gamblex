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

func test_flush_not_straight():
    var cards: Array[Card] = [
        Card.new(13, Card.Suit.SPADES),
        Card.new(11, Card.Suit.SPADES),
        Card.new(9, Card.Suit.SPADES),
        Card.new(5, Card.Suit.SPADES),
        Card.new(2, Card.Suit.SPADES),
    ]
    var hand = PokerHandEvaluator.evaluate_five(cards)
    assert_eq(hand["category"], PokerHandEvaluator.Category.FLUSH)
    assert_eq(hand["tiebreakers"], [13, 11, 9, 5, 2])

func test_straight_not_flush():
    var cards: Array[Card] = [
        Card.new(9, Card.Suit.HEARTS),
        Card.new(8, Card.Suit.SPADES),
        Card.new(7, Card.Suit.HEARTS),
        Card.new(6, Card.Suit.CLUBS),
        Card.new(5, Card.Suit.DIAMONDS),
    ]
    var hand = PokerHandEvaluator.evaluate_five(cards)
    assert_eq(hand["category"], PokerHandEvaluator.Category.STRAIGHT)
    assert_eq(hand["tiebreakers"], [9])

func test_straight_flush():
    var cards: Array[Card] = [
        Card.new(9, Card.Suit.HEARTS),
        Card.new(8, Card.Suit.HEARTS),
        Card.new(7, Card.Suit.HEARTS),
        Card.new(6, Card.Suit.HEARTS),
        Card.new(5, Card.Suit.HEARTS),
    ]
    var hand = PokerHandEvaluator.evaluate_five(cards)
    assert_eq(hand["category"], PokerHandEvaluator.Category.STRAIGHT_FLUSH)
    assert_eq(hand["tiebreakers"], [9])

func test_wheel_straight_ace_low():
    var cards: Array[Card] = [
        Card.new(1, Card.Suit.HEARTS),
        Card.new(2, Card.Suit.SPADES),
        Card.new(3, Card.Suit.HEARTS),
        Card.new(4, Card.Suit.CLUBS),
        Card.new(5, Card.Suit.DIAMONDS),
    ]
    var hand = PokerHandEvaluator.evaluate_five(cards)
    assert_eq(hand["category"], PokerHandEvaluator.Category.STRAIGHT)
    assert_eq(hand["tiebreakers"], [5])

func test_broadway_straight_ace_high():
    var cards: Array[Card] = [
        Card.new(1, Card.Suit.HEARTS),
        Card.new(13, Card.Suit.SPADES),
        Card.new(12, Card.Suit.HEARTS),
        Card.new(11, Card.Suit.CLUBS),
        Card.new(10, Card.Suit.DIAMONDS),
    ]
    var hand = PokerHandEvaluator.evaluate_five(cards)
    assert_eq(hand["category"], PokerHandEvaluator.Category.STRAIGHT)
    assert_eq(hand["tiebreakers"], [14])

func test_compare_different_categories():
    var four_kind = {"category": PokerHandEvaluator.Category.FOUR_OF_A_KIND, "tiebreakers": [2, 3]}
    var full_house = {"category": PokerHandEvaluator.Category.FULL_HOUSE, "tiebreakers": [13, 12]}
    assert_eq(PokerHandEvaluator.compare(four_kind, full_house), 1)
    assert_eq(PokerHandEvaluator.compare(full_house, four_kind), -1)

func test_compare_same_category_by_tiebreakers():
    var pair_of_kings = {"category": PokerHandEvaluator.Category.PAIR, "tiebreakers": [13, 9, 7, 3]}
    var pair_of_queens = {"category": PokerHandEvaluator.Category.PAIR, "tiebreakers": [12, 10, 8, 4]}
    assert_eq(PokerHandEvaluator.compare(pair_of_kings, pair_of_queens), 1)

func test_compare_identical_hands_ties():
    var a = {"category": PokerHandEvaluator.Category.STRAIGHT, "tiebreakers": [9]}
    var b = {"category": PokerHandEvaluator.Category.STRAIGHT, "tiebreakers": [9]}
    assert_eq(PokerHandEvaluator.compare(a, b), 0)

func test_best_hand_picks_quads_over_board_pair_using_both_hole_cards():
    var seven: Array[Card] = [
        Card.new(1, Card.Suit.SPADES),   # hole: As de picas
        Card.new(1, Card.Suit.HEARTS),   # hole: As de corazones
        Card.new(1, Card.Suit.DIAMONDS), # board: As de diamantes
        Card.new(1, Card.Suit.CLUBS),    # board: As de treboles
        Card.new(13, Card.Suit.SPADES),  # board: Rey
        Card.new(7, Card.Suit.HEARTS),   # board
        Card.new(2, Card.Suit.CLUBS),    # board
    ]
    var hand = PokerHandEvaluator.best_hand(seven)
    assert_eq(hand["category"], PokerHandEvaluator.Category.FOUR_OF_A_KIND)
    assert_eq(hand["tiebreakers"], [14, 13])

func test_best_hand_finds_straight_across_hole_and_board():
    var seven: Array[Card] = [
        Card.new(9, Card.Suit.SPADES),   # hole
        Card.new(8, Card.Suit.HEARTS),   # hole
        Card.new(7, Card.Suit.DIAMONDS), # board
        Card.new(6, Card.Suit.CLUBS),    # board
        Card.new(5, Card.Suit.SPADES),   # board
        Card.new(13, Card.Suit.HEARTS),  # board (no participa)
        Card.new(3, Card.Suit.CLUBS),    # board (no participa)
    ]
    var hand = PokerHandEvaluator.best_hand(seven)
    assert_eq(hand["category"], PokerHandEvaluator.Category.STRAIGHT)
    assert_eq(hand["tiebreakers"], [9])

func test_best_hand_with_exactly_five_cards():
    var five: Array[Card] = [
        Card.new(10, Card.Suit.HEARTS),
        Card.new(8, Card.Suit.DIAMONDS),
        Card.new(6, Card.Suit.CLUBS),
        Card.new(4, Card.Suit.SPADES),
        Card.new(2, Card.Suit.HEARTS),
    ]
    var hand = PokerHandEvaluator.best_hand(five)
    assert_eq(hand["category"], PokerHandEvaluator.Category.HIGH_CARD)
    assert_eq(hand["tiebreakers"], [10, 8, 6, 4, 2])

extends GutTest

func test_new_deck_has_52_cards():
    var deck = Deck.new()
    assert_eq(deck.cards_remaining(), 52)

func test_draw_card_reduces_remaining():
    var deck = Deck.new()
    deck.draw_card()
    assert_eq(deck.cards_remaining(), 51)

func test_draw_card_returns_a_card():
    var deck = Deck.new()
    var card = deck.draw_card()
    assert_true(card is Card)

func test_shuffle_keeps_same_card_count():
    var deck = Deck.new()
    var rng = RandomNumberGenerator.new()
    rng.seed = 42
    deck.shuffle_deck(rng)
    assert_eq(deck.cards_remaining(), 52)

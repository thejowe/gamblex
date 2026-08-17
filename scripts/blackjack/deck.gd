class_name Deck
extends RefCounted

var cards: Array[Card] = []

func _init() -> void:
    _build()

func _build() -> void:
    cards.clear()
    for suit in range(4):
        for rank in range(1, 14):
            cards.append(Card.new(rank, suit))

func shuffle_deck(rng: RandomNumberGenerator) -> void:
    for i in range(cards.size() - 1, 0, -1):
        var j = rng.randi_range(0, i)
        var tmp = cards[i]
        cards[i] = cards[j]
        cards[j] = tmp

func draw_card() -> Card:
    return cards.pop_back()

func cards_remaining() -> int:
    return cards.size()

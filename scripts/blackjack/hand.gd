class_name Hand
extends RefCounted

var cards: Array[Card] = []

func add_card(card: Card) -> void:
    cards.append(card)

func value() -> int:
    var total := 0
    var aces := 0
    for card in cards:
        total += card.blackjack_value()
        if card.is_ace():
            aces += 1
    while total > 21 and aces > 0:
        total -= 10
        aces -= 1
    return total

func is_bust() -> bool:
    return value() > 21

func is_blackjack() -> bool:
    return cards.size() == 2 and value() == 21

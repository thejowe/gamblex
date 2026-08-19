class_name PokerHandEvaluator
extends RefCounted

enum Category {
    HIGH_CARD = 0,
    PAIR = 1,
    TWO_PAIR = 2,
    THREE_OF_A_KIND = 3,
    STRAIGHT = 4,
    FLUSH = 5,
    FULL_HOUSE = 6,
    FOUR_OF_A_KIND = 7,
    STRAIGHT_FLUSH = 8,
}

static func _poker_value(card: Card) -> int:
    return 14 if card.rank == 1 else card.rank

static func _values_with_count(counts: Dictionary, n: int) -> Array:
    var result := []
    for v in counts.keys():
        if counts[v] == n:
            result.append(v)
    result.sort()
    result.reverse()
    return result

static func _highest_not_in(values: Array, excluded: Array) -> int:
    for v in values:
        if not excluded.has(v):
            return v
    return -1

static func _kickers_excluding(values: Array, excluded: Array, count: int) -> Array:
    var result := []
    for v in values:
        if excluded.has(v):
            continue
        result.append(v)
        if result.size() == count:
            break
    return result

# Categoriza exactamente 5 cartas. Por ahora solo recuentos (pareja, dos
# pares, trío, full, póker) — escalera y color se añaden en Task 2.
static func evaluate_five(cards: Array[Card]) -> Dictionary:
    var values := []
    for card in cards:
        values.append(_poker_value(card))
    values.sort()
    values.reverse()

    var counts := {}
    for v in values:
        counts[v] = counts.get(v, 0) + 1

    var quads := _values_with_count(counts, 4)
    if quads.size() > 0:
        var kicker := _highest_not_in(values, quads)
        return {"category": Category.FOUR_OF_A_KIND, "tiebreakers": [quads[0], kicker]}

    var trips := _values_with_count(counts, 3)
    var pairs := _values_with_count(counts, 2)
    if trips.size() > 0 and pairs.size() > 0:
        return {"category": Category.FULL_HOUSE, "tiebreakers": [trips[0], pairs[0]]}

    if trips.size() > 0:
        var kickers := _kickers_excluding(values, trips, 2)
        return {"category": Category.THREE_OF_A_KIND, "tiebreakers": [trips[0]] + kickers}

    if pairs.size() >= 2:
        var kicker := _highest_not_in(values, pairs)
        return {"category": Category.TWO_PAIR, "tiebreakers": [pairs[0], pairs[1], kicker]}

    if pairs.size() == 1:
        var kickers := _kickers_excluding(values, pairs, 3)
        return {"category": Category.PAIR, "tiebreakers": [pairs[0]] + kickers}

    return {"category": Category.HIGH_CARD, "tiebreakers": values}

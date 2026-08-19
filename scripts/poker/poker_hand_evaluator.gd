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

static func _straight_high(unique_values_desc: Array) -> int:
    for i in range(unique_values_desc.size() - 4):
        var high = unique_values_desc[i]
        var consecutive := true
        for k in range(1, 5):
            if unique_values_desc[i + k] != high - k:
                consecutive = false
                break
        if consecutive:
            return high
    # escalera A-2-3-4-5 ("wheel"): el As no es consecutivo con el 5 en la
    # escala normal (14 vs 5), se comprueba aparte
    if unique_values_desc.has(14) and unique_values_desc.has(5) and unique_values_desc.has(4) and unique_values_desc.has(3) and unique_values_desc.has(2):
        return 5
    return -1

static func evaluate_five(cards: Array[Card]) -> Dictionary:
    var values := []
    for card in cards:
        values.append(_poker_value(card))
    values.sort()
    values.reverse()

    var counts := {}
    for v in values:
        counts[v] = counts.get(v, 0) + 1

    var is_flush := true
    for card in cards:
        if card.suit != cards[0].suit:
            is_flush = false
            break

    var unique_values := []
    for v in values:
        if not unique_values.has(v):
            unique_values.append(v)
    var straight_high := _straight_high(unique_values)
    var is_straight := straight_high != -1

    if is_straight and is_flush:
        return {"category": Category.STRAIGHT_FLUSH, "tiebreakers": [straight_high]}

    var quads := _values_with_count(counts, 4)
    if quads.size() > 0:
        var kicker := _highest_not_in(values, quads)
        return {"category": Category.FOUR_OF_A_KIND, "tiebreakers": [quads[0], kicker]}

    var trips := _values_with_count(counts, 3)
    var pairs := _values_with_count(counts, 2)
    if trips.size() > 0 and pairs.size() > 0:
        return {"category": Category.FULL_HOUSE, "tiebreakers": [trips[0], pairs[0]]}

    if is_flush:
        return {"category": Category.FLUSH, "tiebreakers": values}

    if is_straight:
        return {"category": Category.STRAIGHT, "tiebreakers": [straight_high]}

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

static func compare(a: Dictionary, b: Dictionary) -> int:
    if a["category"] != b["category"]:
        return 1 if a["category"] > b["category"] else -1
    var ta: Array = a["tiebreakers"]
    var tb: Array = b["tiebreakers"]
    for i in range(min(ta.size(), tb.size())):
        if ta[i] != tb[i]:
            return 1 if ta[i] > tb[i] else -1
    return 0

static func best_hand(cards: Array[Card]) -> Dictionary:
    var indices := range(cards.size())
    var best = null
    for combo in _combinations(indices, 5):
        var five: Array[Card] = []
        for i in combo:
            five.append(cards[i])
        var hand := evaluate_five(five)
        if best == null or compare(hand, best) > 0:
            best = hand
    return best

static func _combinations(items: Array, k: int) -> Array:
    if k == 0:
        return [[]]
    if items.size() < k:
        return []
    var result := []
    var first = items[0]
    var rest = items.slice(1)
    for combo in _combinations(rest, k - 1):
        result.append([first] + combo)
    result.append_array(_combinations(rest, k))
    return result

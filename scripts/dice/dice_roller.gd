class_name DiceRoller
extends RefCounted

var results: Array[float] = []

func roll() -> float:
    if not results.is_empty():
        return results.pop_front()
    return randf() * 100.0

class_name RouletteWheel
extends RefCounted

var results: Array = []

func spin() -> int:
    if not results.is_empty():
        return results.pop_front()
    return randi() % 37

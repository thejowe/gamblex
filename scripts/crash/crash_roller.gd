class_name CrashRoller
extends RefCounted

var results: Array[float] = []

func roll() -> float:
	if not results.is_empty():
		return results.pop_front()
	var r := randf()
	while r <= 0.0:
		r = randf()
	return crash_point_for(r)

static func crash_point_for(r: float) -> float:
	return max(1.00, floor(100.0 * 0.99 / (1.0 - r)) / 100.0)

class_name PlinkoRoller
extends RefCounted

var results: Array = []

func roll(rows: int) -> Array:
	if not results.is_empty():
		return results.pop_front()
	var bounces: Array[bool] = []
	for i in range(rows):
		bounces.append(randf() < 0.5)
	return bounces

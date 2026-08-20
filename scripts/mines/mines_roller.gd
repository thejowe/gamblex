class_name MinesRoller
extends RefCounted

var results: Array = []

func roll(total_cells: int, mine_count: int) -> Array:
	if not results.is_empty():
		return results.pop_front()
	var positions: Array = range(total_cells)
	positions.shuffle()
	return positions.slice(0, mine_count)

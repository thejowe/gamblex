class_name MinesCell
extends Control

enum State { HIDDEN, SAFE, MINE, MINE_DIM }

signal cell_pressed(index: int)

@export var index: int = -1
@export var interactive: bool = true
@export var state: State = State.HIDDEN:
	set(value):
		var was_safe := state == State.SAFE
		state = value
		queue_redraw()
		if state == State.SAFE and not was_safe and is_inside_tree():
			_animate_reveal()

func _init() -> void:
	custom_minimum_size = Vector2(48, 48)
	pivot_offset = Vector2(24, 24)

func _animate_reveal() -> void:
	scale = Vector2(0.8, 0.8)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_gui_pressed()

func _on_gui_pressed() -> void:
	if state == State.HIDDEN and interactive:
		cell_pressed.emit(index)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	match state:
		State.HIDDEN:
			draw_rect(rect, CasinoTheme.PANEL_NAVY_MID)
			draw_rect(rect, CasinoTheme.PANEL_NAVY_LIGHT, false, 1.5)
		State.SAFE:
			draw_rect(rect, CasinoTheme.PANEL_NAVY_MID)
			_draw_diamond(CasinoTheme.ACCENT_GREEN, 1.0)
		State.MINE:
			draw_rect(rect, CasinoTheme.PANEL_NAVY_MID)
			draw_circle(size / 2.0, size.x * 0.28, CasinoTheme.ACCENT_RED)
		State.MINE_DIM:
			draw_rect(rect, CasinoTheme.PANEL_NAVY_MID)
			draw_circle(size / 2.0, size.x * 0.28, Color(CasinoTheme.ACCENT_RED, 0.4))

func _draw_diamond(color: Color, alpha: float) -> void:
	var c := size / 2.0
	var r := size.x * 0.32
	var points := PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0),
	])
	draw_colored_polygon(points, Color(color, alpha))

static func compute_cell_states(round_data: Dictionary, is_active: bool) -> Array:
	var total_cells: int = round_data.get("total_cells", 0)
	var result := []
	for i in range(total_cells):
		result.append(State.HIDDEN)
	var revealed: Array = round_data.get("revealed", [])
	for i in revealed:
		result[i] = State.SAFE
	if is_active:
		return result
	var mines: Array = round_data.get("mines", [])
	var win: bool = round_data.get("win", true)
	var exploded_marked := false
	for m in mines:
		if revealed.has(m):
			continue
		if not win and not exploded_marked:
			result[m] = State.MINE
			exploded_marked = true
		else:
			result[m] = State.MINE_DIM
	return result

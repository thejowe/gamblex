class_name MinesCell
extends Control

enum State { HIDDEN, SAFE, MINE, MINE_DIM }

signal cell_pressed(index: int)

@export var index: int = -1
@export var interactive: bool = true
@export var state: State = State.HIDDEN:
	set(value):
		var was_safe := state == State.SAFE
		var was_mine := state == State.MINE
		state = value
		queue_redraw()
		if is_inside_tree():
			if state == State.SAFE and not was_safe:
				_animate_reveal()
			elif state == State.MINE and not was_mine:
				_animate_explosion()

const STATE_TEXTURE_PATHS := {
	State.HIDDEN: "res://assets/pixels/mines/mines_cell_hidden/mines_cell_hidden.png",
	State.SAFE: "res://assets/pixels/mines/mines_cell_safe/mines_cell_safe.png",
	State.MINE: "res://assets/pixels/mines/mines_cell_mine/mines_cell_mine.png",
	State.MINE_DIM: "res://assets/pixels/mines/mines_cell_mine_dim/mines_cell_mine_dim.png",
}

func _init() -> void:
	custom_minimum_size = Vector2(48, 48)
	pivot_offset = Vector2(24, 24)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _animate_reveal() -> void:
	scale = Vector2(0.8, 0.8)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

# La casilla que revela la mina que termina la ronda no tenía ningún énfasis
# — el mismo cambio de textura silencioso que cualquier otra casilla, pese a
# ser el momento de "perdiste" de toda la ronda.
func _animate_explosion() -> void:
	scale = Vector2(1.4, 1.4)
	var scale_tween := create_tween()
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var base_position := position
	var shake_tween := create_tween()
	for i in range(4):
		var offset := Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		shake_tween.tween_property(self, "position", base_position + offset, 0.03)
	shake_tween.tween_property(self, "position", base_position, 0.03)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_gui_pressed()

func _on_gui_pressed() -> void:
	if state == State.HIDDEN and interactive:
		cell_pressed.emit(index)

func _draw() -> void:
	var tex := load(STATE_TEXTURE_PATHS[state])
	draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)

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

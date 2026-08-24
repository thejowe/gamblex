class_name PlinkoBoard
extends Control

signal ball_landed(slot: int)

const PEG_RADIUS := 3.0
const BALL_RADIUS := 7.0
const TOP_MARGIN := 20.0
const BOTTOM_MARGIN := 44.0
const STEP_DURATION := 0.12

@export var rows: int = PlinkoTableState.DEFAULT_ROWS:
	set(value):
		rows = clampi(value, PlinkoTableState.MIN_ROWS, PlinkoTableState.MAX_ROWS)
		queue_redraw()

var _ball_visible: bool = false
var _ball_position: Vector2 = Vector2.ZERO

func _init() -> void:
	custom_minimum_size = Vector2(0, 360)

static func slot_from_bounces(bounces: Array) -> int:
	var slot := 0
	for bounced_right in bounces:
		if bounced_right:
			slot += 1
	return slot

func _row_step() -> float:
	return size.x / float(rows + 2)

func peg_position(row: int, index_in_row: int) -> Vector2:
	var step := _row_step()
	var center_x := size.x / 2.0
	var row_width := float(row) * step
	var x := center_x - row_width / 2.0 + float(index_in_row) * step
	var usable_height := size.y - TOP_MARGIN - BOTTOM_MARGIN
	var y := TOP_MARGIN + (float(row) / float(max(rows - 1, 1))) * usable_height
	return Vector2(x, y)

func _draw() -> void:
	for row in range(rows):
		for i in range(row + 1):
			draw_circle(peg_position(row, i), PEG_RADIUS, CasinoTheme.TEXT_MUTED)
	_draw_multiplier_row()
	if _ball_visible:
		draw_circle(_ball_position, BALL_RADIUS, CasinoTheme.TEXT_LIGHT)

func _draw_multiplier_row() -> void:
	var step := _row_step()
	var center_x := size.x / 2.0
	var slot_count := rows + 1
	var row_width := float(rows) * step
	var y := size.y - BOTTOM_MARGIN / 2.0
	var max_mult: float = PlinkoTableState.slot_multiplier(rows, 0)
	var min_mult: float = PlinkoTableState.slot_multiplier(rows, rows / 2)
	var font := ThemeDB.fallback_font
	for slot in range(slot_count):
		var mult: float = PlinkoTableState.slot_multiplier(rows, slot)
		var x := center_x - row_width / 2.0 + float(slot) * step
		var t: float = clampf(inverse_lerp(min_mult, max_mult, mult), 0.0, 1.0)
		var color: Color = CasinoTheme.PANEL_NAVY_LIGHT.lerp(CasinoTheme.ACCENT_GREEN, t)
		draw_rect(Rect2(x - step / 2.0 + 2.0, y - 12.0, step - 4.0, 24.0), color)
		var text := "%.2f" % mult
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
		draw_string(font, Vector2(x - text_size.x / 2.0, y + 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, CasinoTheme.TEXT_LIGHT)

func drop_ball(bounces: Array) -> void:
	var step := _row_step()
	var center_x := size.x / 2.0
	var usable_height := size.y - TOP_MARGIN - BOTTOM_MARGIN
	_ball_visible = true
	_ball_position = Vector2(center_x, TOP_MARGIN)
	queue_redraw()
	var tween := create_tween()
	var rights := 0
	var current_pos := Vector2(center_x, TOP_MARGIN)
	for row in range(bounces.size()):
		if bounces[row]:
			rights += 1
		var lefts := row + 1 - rights
		var x_offset := (float(rights) - float(lefts)) * step / 2.0
		var target := Vector2(center_x + x_offset, TOP_MARGIN + (float(row + 1) / float(max(rows, 1))) * usable_height)
		tween.tween_method(_set_ball_position, current_pos, target, STEP_DURATION)
		current_pos = target
	tween.finished.connect(func():
		ball_landed.emit(slot_from_bounces(bounces))
	)

func _set_ball_position(pos: Vector2) -> void:
	_ball_position = pos
	queue_redraw()

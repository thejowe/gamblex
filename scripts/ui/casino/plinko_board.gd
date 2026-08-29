class_name PlinkoBoard
extends Control

signal ball_landed(slot: int)

const PEG_RADIUS := 3.0
const BALL_RADIUS := 7.0
const TOP_MARGIN := 20.0
const BOTTOM_MARGIN := 44.0
const STEP_DURATION := 0.12
const ROW_HEIGHT_RATIO := 0.87
const PEG_TEXTURE_PATH := "res://assets/pixels/plinko/plinko_peg/plinko_peg.png"
const BALL_TEXTURE_PATH := "res://assets/pixels/plinko/plinko_ball/plinko_ball.png"
const SLOT_BG_TEXTURE_PATH := "res://assets/pixels/plinko/plinko_slot_bg/plinko_slot_bg.png"

@export var rows: int = PlinkoTableState.DEFAULT_ROWS:
	set(value):
		rows = clampi(value, PlinkoTableState.MIN_ROWS, PlinkoTableState.MAX_ROWS)
		queue_redraw()

var _ball_visible: bool = false
var _ball_position: Vector2 = Vector2.ZERO

func _init() -> void:
	custom_minimum_size = Vector2(0, 360)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func slot_from_bounces(bounces: Array) -> int:
	var slot := 0
	for bounced_right in bounces:
		if bounced_right:
			slot += 1
	return slot

func _pitch() -> float:
	var horizontal_pitch := size.x / float(rows + 2)
	var usable_height := size.y - TOP_MARGIN - BOTTOM_MARGIN
	var row_gaps := float(max(rows - 1, 1))
	var vertical_pitch_limit := (usable_height / row_gaps) / ROW_HEIGHT_RATIO
	return min(horizontal_pitch, vertical_pitch_limit)

func _vertical_step() -> float:
	return _pitch() * ROW_HEIGHT_RATIO

func _board_top() -> float:
	var usable_height := size.y - TOP_MARGIN - BOTTOM_MARGIN
	var total_height := _vertical_step() * float(max(rows - 1, 1))
	return TOP_MARGIN + max(usable_height - total_height, 0.0) / 2.0

func peg_position(row: int, index_in_row: int) -> Vector2:
	var pitch := _pitch()
	var center_x := size.x / 2.0
	var row_width := float(row) * pitch
	var x := center_x - row_width / 2.0 + float(index_in_row) * pitch
	var y := _board_top() + float(row) * _vertical_step()
	return Vector2(x, y)

func _draw() -> void:
	var peg_tex := load(PEG_TEXTURE_PATH)
	var peg_size: Vector2 = peg_tex.get_size()
	for row in range(rows):
		for i in range(row + 1):
			var pos := peg_position(row, i)
			draw_texture_rect(peg_tex, Rect2(pos - peg_size / 2.0, peg_size), false)
	_draw_multiplier_row()
	if _ball_visible:
		var ball_tex := load(BALL_TEXTURE_PATH)
		var ball_size: Vector2 = ball_tex.get_size()
		draw_texture_rect(ball_tex, Rect2(_ball_position - ball_size / 2.0, ball_size), false)

func _draw_multiplier_row() -> void:
	var pitch := _pitch()
	var center_x := size.x / 2.0
	var slot_count := rows + 1
	var row_width := float(rows) * pitch
	var y := size.y - BOTTOM_MARGIN / 2.0
	var max_mult: float = PlinkoTableState.slot_multiplier(rows, 0)
	var min_mult: float = PlinkoTableState.slot_multiplier(rows, rows / 2)
	var font := ThemeDB.fallback_font
	var slot_bg_tex := load(SLOT_BG_TEXTURE_PATH)
	for slot in range(slot_count):
		var mult: float = PlinkoTableState.slot_multiplier(rows, slot)
		var x := center_x - row_width / 2.0 + float(slot) * pitch
		var t: float = clampf(inverse_lerp(min_mult, max_mult, mult), 0.0, 1.0)
		var tint: Color = CasinoTheme.PANEL_NAVY_LIGHT.lerp(CasinoTheme.ACCENT_GREEN, t)
		var slot_rect := Rect2(x - pitch / 2.0 + 2.0, y - 12.0, pitch - 4.0, 24.0)
		draw_texture_rect(slot_bg_tex, slot_rect, false, tint)
		var text := ("%.0f" if mult >= 100.0 else "%.1f" if mult >= 10.0 else "%.2f") % mult
		var font_size := clampi(int(pitch * 0.42), 8, 11)
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, Vector2(x - text_size.x / 2.0, y + 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, CasinoTheme.TEXT_LIGHT)

func drop_ball(bounces: Array) -> void:
	var pitch := _pitch()
	var center_x := size.x / 2.0
	var top := _board_top()
	var vstep := _vertical_step()
	_ball_visible = true
	_ball_position = Vector2(center_x, top)
	queue_redraw()
	var tween := create_tween()
	var rights := 0
	var current_pos := Vector2(center_x, top)
	for row in range(bounces.size()):
		if bounces[row]:
			rights += 1
		var lefts := row + 1 - rights
		var x_offset := (float(rights) - float(lefts)) * pitch / 2.0
		var target := Vector2(center_x + x_offset, top + float(row + 1) * vstep)
		tween.tween_method(_set_ball_position, current_pos, target, STEP_DURATION)
		current_pos = target
	tween.finished.connect(func():
		ball_landed.emit(slot_from_bounces(bounces))
	)

func _set_ball_position(pos: Vector2) -> void:
	_ball_position = pos
	queue_redraw()

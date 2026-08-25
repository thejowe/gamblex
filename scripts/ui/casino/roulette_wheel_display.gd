class_name RouletteWheelDisplay
extends Control

signal spin_finished

const RADIUS := 130.0
const BALL_TRACK_RADIUS := RADIUS - 18.0
const BALL_RADIUS := 6.0
const NUMBER_LABEL_RADIUS := RADIUS * 0.68
const WHEEL_ORDER := [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]

@export var last_result: int = -1:
	set(value):
		last_result = value
		queue_redraw()

@export var ball_angle: float = 0.0:
	set(value):
		ball_angle = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2, RADIUS * 2)

func _color_for_number(n: int) -> Color:
	if n == 0:
		return CasinoTheme.ACCENT_GREEN
	if n in RouletteTableState.RED_NUMBERS:
		return CasinoTheme.CARD_RED
	return CasinoTheme.CARD_BLACK

func _draw() -> void:
	var center := size / 2.0
	var slice_angle := TAU / WHEEL_ORDER.size()
	var font := ThemeDB.fallback_font
	var font_size := 9
	for i in range(WHEEL_ORDER.size()):
		var n: int = WHEEL_ORDER[i]
		var start_angle := i * slice_angle
		var points := PackedVector2Array()
		points.append(center)
		var steps := 6
		for s in range(steps + 1):
			var a := start_angle + slice_angle * float(s) / float(steps)
			points.append(center + Vector2(cos(a), sin(a)) * RADIUS)
		draw_colored_polygon(points, _color_for_number(n))
	draw_arc(center, RADIUS, 0, TAU, 64, CasinoTheme.TEXT_LIGHT, 2.0)
	for i in range(WHEEL_ORDER.size()):
		var n: int = WHEEL_ORDER[i]
		var mid_angle := i * slice_angle + slice_angle / 2.0
		var label_pos := center + Vector2(cos(mid_angle), sin(mid_angle)) * NUMBER_LABEL_RADIUS
		var text := str(n)
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, label_pos - text_size / 2.0 + Vector2(0, text_size.y * 0.3), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, CasinoTheme.TEXT_LIGHT)
	var ball_pos := center + Vector2(cos(ball_angle), sin(ball_angle)) * BALL_TRACK_RADIUS
	draw_circle(ball_pos, BALL_RADIUS, CasinoTheme.TEXT_LIGHT)

func angle_for_result(result: int) -> float:
	var index := WHEEL_ORDER.find(result)
	var slice_angle := TAU / WHEEL_ORDER.size()
	return index * slice_angle + slice_angle / 2.0

func spin_to(result: int) -> void:
	var target_angle := angle_for_result(result) + TAU * 4.0
	var tween := create_tween()
	tween.tween_property(self, "ball_angle", target_angle, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		last_result = result
		ball_angle = wrapf(ball_angle, 0.0, TAU)
		spin_finished.emit()
	)

class_name CrashGraph
extends Control

enum State { IDLE, RISING, CRASHED, CASHED_OUT }

const TIME_WINDOW_SEC := 12.0
const MULTIPLIER_CEIL := 3.0

@export var elapsed: float = 0.0:
	set(value):
		elapsed = value
		queue_redraw()
@export var state: int = State.IDLE:
	set(value):
		state = value
		queue_redraw()

static func curve_points(elapsed_time: float, sample_count: int = 40) -> PackedVector2Array:
	var points := PackedVector2Array()
	var capped := clampf(elapsed_time, 0.0, TIME_WINDOW_SEC)
	for i in range(sample_count + 1):
		var t: float = capped * float(i) / float(sample_count)
		points.append(Vector2(t, CrashTableState.multiplier_at(t)))
	return points

func current_multiplier() -> float:
	return CrashTableState.multiplier_at(elapsed)

func _to_screen(p: Vector2) -> Vector2:
	var x := (p.x / TIME_WINDOW_SEC) * size.x
	var normalized := (clampf(p.y, 1.0, MULTIPLIER_CEIL) - 1.0) / (MULTIPLIER_CEIL - 1.0)
	var y := size.y - normalized * size.y
	return Vector2(x, y)

const Y_TICKS := [1.0, 1.5, 2.0, 2.5, 3.0]
const X_TICK_STEP_SEC := 2.0

func _draw_axes() -> void:
	var font := ThemeDB.fallback_font
	var tick_font_size := 11
	for m in Y_TICKS:
		var y := _to_screen(Vector2(0.0, m)).y
		draw_line(Vector2(0, y), Vector2(size.x, y), CasinoTheme.PANEL_NAVY_MID, 1.0)
		draw_string(font, Vector2(2.0, y - 3.0), "%.2fx" % m, HORIZONTAL_ALIGNMENT_LEFT, -1, tick_font_size, CasinoTheme.TEXT_MUTED)
	var t := 0.0
	while t <= TIME_WINDOW_SEC:
		var x := _to_screen(Vector2(t, 1.0)).x
		draw_string(font, Vector2(x - 8.0, size.y + 16.0), "%ds" % int(t), HORIZONTAL_ALIGNMENT_LEFT, -1, tick_font_size, CasinoTheme.TEXT_MUTED)
		t += X_TICK_STEP_SEC
	draw_line(Vector2(0, size.y), Vector2(size.x, size.y), CasinoTheme.PANEL_NAVY_LIGHT, 1.0)
	draw_line(Vector2(0, 0), Vector2(0, size.y), CasinoTheme.PANEL_NAVY_LIGHT, 1.0)

func _draw() -> void:
	_draw_axes()
	var raw_points := curve_points(elapsed)
	var line_color := CasinoTheme.ACCENT_RED if state == State.CRASHED else CasinoTheme.ACCENT_GREEN
	if elapsed > 0.0:
		var screen_points := PackedVector2Array()
		for p in raw_points:
			screen_points.append(_to_screen(p))
		var fill_points := screen_points.duplicate()
		fill_points.append(Vector2(screen_points[screen_points.size() - 1].x, size.y))
		fill_points.append(Vector2(screen_points[0].x, size.y))
		draw_colored_polygon(fill_points, Color(line_color, 0.14))
		draw_polyline(screen_points, line_color, 3.0, true)
		var tip := screen_points[screen_points.size() - 1]
		draw_circle(tip, 11.0, Color(line_color, 0.22))
		draw_circle(tip, 6.0, line_color)
	var font := ThemeDB.fallback_font
	var text := "%.2fx" % current_multiplier()
	var font_size := 48
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, size / 2.0 - text_size / 2.0, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, line_color)

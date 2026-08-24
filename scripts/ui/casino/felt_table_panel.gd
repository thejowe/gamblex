class_name FeltTablePanel
extends Control

@export var rules_text_top: String = "BLACKJACK PAYS 3 TO 2"
@export var rules_text_bottom: String = "INSURANCE PAYS 2 TO 1"

func _draw() -> void:
	var center := Vector2(size.x / 2.0, size.y * 0.18)
	var radius := Vector2(size.x * 0.46, size.y * 0.42)
	_draw_wood_rail(center, radius)
	_draw_felt(center, radius)
	_draw_curved_text(rules_text_top, center, radius.y * 0.55, PI * 0.5 - 0.6, PI * 0.5 + 0.6, 18)
	_draw_curved_text(rules_text_bottom, center, radius.y * 0.75, PI * 0.5 - 0.45, PI * 0.5 + 0.45, 14)

func _arc_points(center: Vector2, radius: Vector2, expand: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps) * PI
		points.append(center + Vector2(cos(t) * (radius.x + expand), sin(t) * (radius.y + expand)))
	return points

func _draw_wood_rail(center: Vector2, radius: Vector2) -> void:
	var outer := _arc_points(center, radius, 26.0, 64)
	var inner := _arc_points(center, radius, -4.0, 64)
	inner.reverse()
	var points := PackedVector2Array()
	points.append_array(outer)
	points.append_array(inner)
	draw_colored_polygon(points, CasinoTheme.WOOD_BROWN_LIGHT)

func _draw_felt(center: Vector2, radius: Vector2) -> void:
	var points := _arc_points(center, radius, 0.0, 64)
	points.append(Vector2(center.x - radius.x, center.y))
	draw_colored_polygon(points, CasinoTheme.FELT_GREEN_LIGHT)
	draw_polyline(_arc_points(center, radius, 0.0, 64), CasinoTheme.FELT_GREEN_DARK, 3.0, true)

func _draw_curved_text(text: String, center: Vector2, radius: float, start_angle: float, end_angle: float, font_size: int) -> void:
	if text.is_empty():
		return
	var font := ThemeDB.fallback_font
	var char_widths: Array[float] = []
	var total_width := 0.0
	for c in text:
		var w := font.get_string_size(c, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
		char_widths.append(w)
		total_width += w
	var angle_span := end_angle - start_angle
	var angle := start_angle
	for i in range(text.length()):
		var pos := center + Vector2(cos(angle), sin(angle)) * radius
		draw_set_transform(pos, angle + PI / 2.0, Vector2.ONE)
		draw_string(font, Vector2(-char_widths[i] / 2.0, 0), text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, CasinoTheme.TEXT_CREAM)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if total_width > 0.0:
			angle += (char_widths[i] / total_width) * angle_span

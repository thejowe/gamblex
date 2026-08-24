class_name RouletteResultBadge
extends Control

const RADIUS := 16.0

@export var number: int = 0:
	set(value):
		number = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2, RADIUS * 2)

func _color_for_number() -> Color:
	if number == 0:
		return CasinoTheme.ACCENT_GREEN
	if number in RouletteTableState.RED_NUMBERS:
		return CasinoTheme.CARD_RED
	return CasinoTheme.CARD_BLACK

func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, RADIUS, _color_for_number())
	draw_arc(center, RADIUS, 0, TAU, 24, CasinoTheme.TEXT_LIGHT, 1.5)
	var font := ThemeDB.fallback_font
	var text := str(number)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	draw_string(font, center - text_size / 2.0 + Vector2(0, text_size.y * 0.3), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, CasinoTheme.TEXT_LIGHT)

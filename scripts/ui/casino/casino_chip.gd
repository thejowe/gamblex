class_name CasinoChip
extends Control

const RADIUS := 24.0
const NOTCH_COUNT := 12
const KNOWN_DENOMINATIONS := [1, 5, 10, 25, 50, 100]

@export var denomination: int = 50:
	set(value):
		denomination = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2, RADIUS * 2)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	if denomination in KNOWN_DENOMINATIONS:
		var tex := load("res://assets/pixels/common/chips/chip_%d/chip_%d.png" % [denomination, denomination])
		draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)
		return
	_draw_vector_fallback()

func _draw_vector_fallback() -> void:
	var center := size / 2.0
	var color := CasinoTheme.chip_color(denomination)
	draw_circle(center, RADIUS, color)
	draw_arc(center, RADIUS, 0, TAU, 32, CasinoTheme.TEXT_CREAM, 2.0)
	for i in range(NOTCH_COUNT):
		if i % 2 != 0:
			continue
		var angle := TAU * float(i) / float(NOTCH_COUNT)
		var notch_center := center + Vector2(cos(angle), sin(angle)) * (RADIUS - 4.0)
		draw_circle(notch_center, 3.0, CasinoTheme.TEXT_CREAM)
	draw_circle(center, RADIUS * 0.55, color.darkened(0.15))
	var font := ThemeDB.fallback_font
	var text := str(denomination)
	var font_size := 14
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, center - text_size / 2.0 + Vector2(0, text_size.y * 0.3), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, CasinoTheme.TEXT_CREAM)

class_name RoundTimerBadge
extends Control

const RADIUS := 34.0
const RING_WIDTH := 6.0

@export var seconds_remaining: float = 0.0:
	set(value):
		seconds_remaining = value
		queue_redraw()

@export var total_seconds: float = 1.0:
	set(value):
		total_seconds = maxf(value, 0.01)
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2, RADIUS * 2)

func _draw() -> void:
	var center := size / 2.0
	draw_arc(center, RADIUS, 0, TAU, 48, CasinoTheme.PANEL_NAVY_LIGHT, RING_WIDTH)
	var fraction := clampf(seconds_remaining / total_seconds, 0.0, 1.0)
	if fraction > 0.0:
		var start_angle := -PI / 2.0
		draw_arc(center, RADIUS, start_angle, start_angle + TAU * fraction, 48, CasinoTheme.GOLD_ACCENT, RING_WIDTH)
	var font := ThemeDB.fallback_font
	var text := str(ceili(seconds_remaining))
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
	draw_string(font, center - text_size / 2.0 + Vector2(0, text_size.y * 0.3), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, CasinoTheme.TEXT_LIGHT)

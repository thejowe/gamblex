class_name SeatAvatar
extends Control

const RADIUS := 28.0
const AVATAR_COLORS := [
	Color("c0392b"), Color("2e6da4"), Color("2f8f5b"), Color("8e44ad"),
	Color("e07b1f"), Color("16a085"), Color("d35400"), Color("34495e"),
]

@export var initial: String = "?":
	set(value):
		initial = value
		queue_redraw()
@export var player_id: int = 0:
	set(value):
		player_id = value
		queue_redraw()
@export var is_active_turn: bool = false:
	set(value):
		is_active_turn = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2, RADIUS * 2)

func avatar_color() -> Color:
	return AVATAR_COLORS[absi(player_id) % AVATAR_COLORS.size()]

func _draw() -> void:
	var center := size / 2.0
	var color := avatar_color()
	draw_circle(center, RADIUS, color)
	# Sin esto no había forma de saber a quién le toca solo mirando la mesa
	# ovalada — había que leer el StatusLabel de texto en otra parte de la
	# pantalla.
	if is_active_turn:
		draw_arc(center, RADIUS + 4.0, 0, TAU, 32, CasinoTheme.GOLD_ACCENT, 3.0)
	draw_arc(center, RADIUS, 0, TAU, 32, CasinoTheme.TEXT_CREAM, 2.0)
	var font := ThemeDB.fallback_font
	var font_size := 22
	var text_size := font.get_string_size(initial, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, center - text_size / 2.0 + Vector2(0, text_size.y * 0.3), initial, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, CasinoTheme.TEXT_CREAM)

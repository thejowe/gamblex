class_name DiceThresholdSlider
extends Control

signal threshold_changed(value: int)

const HANDLE_RADIUS := 12.0
const TRACK_HEIGHT := 10.0

@export var threshold: int = 50:
	set(value):
		threshold = clampi(value, 1, 99)
		queue_redraw()
# DiceTableState.Direction.UNDER (el enum es { OVER, UNDER }, así que
# UNDER = 1) — se pone aquí como valor literal porque los componentes de
# `scripts/ui/casino/` no dependen de clases de un juego concreto salvo
# donde es inevitable (aquí sí lo es, `DiceThresholdSlider` es específico
# de Dice); el valor 1 y `DiceTableState.Direction.UNDER` son
# intercambiables, usa el enum con nombre en cualquier código nuevo que
# escribas para evitar el número mágico.
@export var direction: int = DiceTableState.Direction.UNDER:
	set(value):
		direction = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(0, 40)

func set_threshold_from_x(local_x: float) -> void:
	var ratio: float = clampf(local_x / size.x, 0.0, 1.0)
	threshold = clampi(roundi(1.0 + ratio * 98.0), 1, 99)
	threshold_changed.emit(threshold)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		set_threshold_from_x(event.position.x)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		set_threshold_from_x(event.position.x)

func _draw() -> void:
	var track_y := size.y / 2.0
	var handle_x := (float(threshold - 1) / 98.0) * size.x
	# UNDER gana tirando por debajo del umbral -> la zona ganadora (verde)
	# es la izquierda del tirador; OVER gana por encima -> verde a la derecha.
	var win_is_left := direction == DiceTableState.Direction.UNDER
	var left_color := CasinoTheme.ACCENT_GREEN if win_is_left else CasinoTheme.ACCENT_RED
	var right_color := CasinoTheme.ACCENT_RED if win_is_left else CasinoTheme.ACCENT_GREEN
	draw_rect(Rect2(0, track_y - TRACK_HEIGHT / 2.0, handle_x, TRACK_HEIGHT), left_color)
	draw_rect(Rect2(handle_x, track_y - TRACK_HEIGHT / 2.0, size.x - handle_x, TRACK_HEIGHT), right_color)
	draw_circle(Vector2(handle_x, track_y), HANDLE_RADIUS, CasinoTheme.TEXT_LIGHT)
	draw_arc(Vector2(handle_x, track_y), HANDLE_RADIUS, 0, TAU, 24, CasinoTheme.PANEL_NAVY_LIGHT, 2.0)

class_name DiceThresholdSlider
extends Control

signal threshold_changed(value: int)

const HANDLE_RADIUS := 12.0
const TRACK_HEIGHT := 10.0
const HANDLE_TEXTURE_PATH := "res://assets/pixels/dice/dice_slider_handle/dice_slider_handle.png"
const TRACK_WIN_TEXTURE_PATH := "res://assets/pixels/dice/dice_slider_track_win/dice_slider_track_win.png"
const TRACK_LOSE_TEXTURE_PATH := "res://assets/pixels/dice/dice_slider_track_lose/dice_slider_track_lose.png"

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

var _handle_scale: float = 1.0

func _init() -> void:
	custom_minimum_size = Vector2(0, 40)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)

func set_threshold_from_x(local_x: float) -> void:
	var ratio: float = clampf(local_x / size.x, 0.0, 1.0)
	threshold = clampi(roundi(1.0 + ratio * 98.0), 1, 99)
	threshold_changed.emit(threshold)

# El tirador no daba ningún feedback al agarrarlo, a diferencia de cualquier
# botón del resto de la UI (todos crecen un poco al pulsarlos).
func _set_handle_grabbed(grabbed: bool) -> void:
	var tween := create_tween()
	tween.tween_method(_set_handle_scale, _handle_scale, 1.3 if grabbed else 1.0, 0.1)

func _set_handle_scale(value: float) -> void:
	_handle_scale = value
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_set_handle_grabbed(event.pressed)
		if event.pressed:
			set_threshold_from_x(event.position.x)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		set_threshold_from_x(event.position.x)

func _draw() -> void:
	var track_y := size.y / 2.0
	var handle_x := (float(threshold - 1) / 98.0) * size.x
	# UNDER gana tirando por debajo del umbral -> la zona ganadora (verde)
	# es la izquierda del tirador; OVER gana por encima -> verde a la derecha.
	var win_is_left := direction == DiceTableState.Direction.UNDER
	var left_tex := load(TRACK_WIN_TEXTURE_PATH if win_is_left else TRACK_LOSE_TEXTURE_PATH)
	var right_tex := load(TRACK_LOSE_TEXTURE_PATH if win_is_left else TRACK_WIN_TEXTURE_PATH)
	draw_texture_rect(left_tex, Rect2(0, track_y - TRACK_HEIGHT / 2.0, handle_x, TRACK_HEIGHT), true)
	draw_texture_rect(right_tex, Rect2(handle_x, track_y - TRACK_HEIGHT / 2.0, size.x - handle_x, TRACK_HEIGHT), true)
	var handle_tex := load(HANDLE_TEXTURE_PATH)
	var handle_size: Vector2 = handle_tex.get_size() * _handle_scale
	draw_texture_rect(handle_tex, Rect2(Vector2(handle_x, track_y) - handle_size / 2.0, handle_size), false)

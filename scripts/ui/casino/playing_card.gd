class_name PlayingCard
extends Control

signal flip_completed

const CARD_SIZE := Vector2(52, 86)  # tamaño real de card_*.png (FASE 4)
const SUIT_NAMES := {
	0: "hearts", 1: "diamonds", 2: "clubs", 3: "spades",
}
const RANK_LABELS := {
	1: "A", 11: "J", 12: "Q", 13: "K",
}

@export var rank: int = 1:
	set(value):
		rank = value
		queue_redraw()
@export var suit: int = 3:
	set(value):
		suit = value
		queue_redraw()
@export var face_up: bool = true:
	set(value):
		face_up = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = CARD_SIZE
	pivot_offset = CARD_SIZE / 2.0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func rank_label() -> String:
	return RANK_LABELS.get(rank, str(rank))

func _is_red() -> bool:
	return suit == 0 or suit == 1

func _texture_path() -> String:
	if not face_up:
		return "res://assets/pixels/common/cards/card_back/card_back.png"
	var suit_name: String = SUIT_NAMES[suit]
	var rank_name := rank_label()
	return "res://assets/pixels/common/cards/card_%s_%s/card_%s_%s.png" % [suit_name, rank_name, suit_name, rank_name]

func _draw() -> void:
	var tex := load(_texture_path())
	draw_texture_rect(tex, Rect2(Vector2.ZERO, CARD_SIZE), false)

func flip() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.15)
	tween.tween_callback(func(): face_up = not face_up)
	tween.tween_property(self, "scale:x", 1.0, 0.15)
	tween.finished.connect(func(): flip_completed.emit())

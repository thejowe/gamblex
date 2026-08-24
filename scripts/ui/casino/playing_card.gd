class_name PlayingCard
extends Control

signal flip_completed

const CARD_SIZE := Vector2(70, 100)
const SUIT_SYMBOLS := {
	0: "♥",  # Card.Suit.HEARTS
	1: "♦",  # Card.Suit.DIAMONDS
	2: "♣",  # Card.Suit.CLUBS
	3: "♠",  # Card.Suit.SPADES
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

func rank_label() -> String:
	return RANK_LABELS.get(rank, str(rank))

func _is_red() -> bool:
	return suit == 0 or suit == 1

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, CARD_SIZE)
	if face_up:
		draw_rect(rect, CasinoTheme.CARD_WHITE)
		draw_rect(rect, CasinoTheme.CARD_BLACK, false, 1.5)
		var color := CasinoTheme.CARD_RED if _is_red() else CasinoTheme.CARD_BLACK
		var font := ThemeDB.fallback_font
		var symbol: String = SUIT_SYMBOLS[suit]
		draw_string(font, Vector2(6, 16), rank_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		draw_string(font, Vector2(6, 32), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		var big_size := font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 28)
		draw_string(font, CARD_SIZE / 2.0 - big_size / 2.0 + Vector2(0, big_size.y * 0.3), symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 28, color)
	else:
		draw_rect(rect, Color("1c3f6e"))
		draw_rect(rect, CasinoTheme.CARD_WHITE, false, 1.5)
		var step := 10
		var x := step
		while x < CARD_SIZE.x:
			draw_line(Vector2(x, 0), Vector2(x, CARD_SIZE.y), Color("2a5490"), 1.0)
			x += step

func flip() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.15)
	tween.tween_callback(func(): face_up = not face_up)
	tween.tween_property(self, "scale:x", 1.0, 0.15)
	tween.finished.connect(func(): flip_completed.emit())

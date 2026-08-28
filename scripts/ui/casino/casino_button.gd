class_name CasinoButton
extends Button

enum Variant { NEUTRAL, POSITIVE, NEGATIVE }

const VARIANT_COLORS := {
	Variant.NEUTRAL: Color("4a4a4a"),
	Variant.POSITIVE: Color("2f8f5b"),
	Variant.NEGATIVE: Color("b23b3b"),
}

@export var variant: Variant = Variant.NEUTRAL:
	set(value):
		variant = value
		_apply_styles()

static func color_for_variant(v: int) -> Color:
	return VARIANT_COLORS[v]

func _ready() -> void:
	_apply_styles()
	pivot_offset = size / 2.0
	mouse_entered.connect(_on_hover_start)
	mouse_exited.connect(_on_hover_end)
	button_down.connect(_on_press)
	button_up.connect(_on_release)

func _apply_styles() -> void:
	var base_color := color_for_variant(variant)
	add_theme_stylebox_override("normal", _style(base_color))
	add_theme_stylebox_override("hover", _style(base_color.lightened(0.15)))
	add_theme_stylebox_override("pressed", _style(base_color.darkened(0.2)))
	add_theme_stylebox_override("disabled", _style(base_color.darkened(0.4), 0.5))

func _style(color: Color, alpha: float = 1.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(color.r, color.g, color.b, alpha)
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.corner_radius_bottom_left = 6
	box.corner_radius_bottom_right = 6
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.border_color = CasinoTheme.TEXT_CREAM
	return box

func _on_hover_start() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_hover_end() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _on_press() -> void:
	AudioManager.play_sfx("click")
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)

func _on_release() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.05)

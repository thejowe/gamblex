class_name CasinoButton
extends Button

enum Variant { NEUTRAL, POSITIVE, NEGATIVE }

const VARIANT_COLORS := {
	Variant.NEUTRAL: Color("4a4a4a"),
	Variant.POSITIVE: Color("2f8f5b"),
	Variant.NEGATIVE: Color("b23b3b"),
}

const VARIANT_NAMES := {
	Variant.NEUTRAL: "neutral",
	Variant.POSITIVE: "positive",
	Variant.NEGATIVE: "negative",
}

const STATES := ["normal", "hover", "pressed", "disabled"]

static var _style_cache: Dictionary = {}

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
	var variant_name: String = VARIANT_NAMES[variant]
	for state in STATES:
		add_theme_stylebox_override(state, _texture_style(variant_name, state))

func _texture_style(variant_name: String, state: String) -> StyleBoxTexture:
	var key := "%s_%s" % [variant_name, state]
	if not _style_cache.has(key):
		var box := StyleBoxTexture.new()
		box.texture = load("res://assets/pixels/common/buttons/button_%s/button_%s.png" % [key, key])
		_style_cache[key] = box
	return _style_cache[key]

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

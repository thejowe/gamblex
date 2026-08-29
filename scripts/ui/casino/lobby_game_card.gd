class_name LobbyGameCard
extends TextureButton

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pivot_offset = size / 2.0
	mouse_entered.connect(_on_hover_start)
	mouse_exited.connect(_on_hover_end)
	button_down.connect(_on_press)
	button_up.connect(_on_release)

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

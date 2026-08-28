class_name LoadingScreen
extends Control

@onready var background: ColorRect = $Background
@onready var indicator: Control = $Indicator

func _ready() -> void:
	modulate.a = 0.0
	background.color = CasinoTheme.PANEL_NAVY_DARK
	mouse_filter = Control.MOUSE_FILTER_STOP

func start_fade_in(fade_sec: float = 0.4) -> Tween:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_sec)
	return tween

func fade_and_change_scene(path: String, fade_sec: float = 0.4) -> void:
	var tween := start_fade_in(fade_sec)
	await tween.finished
	get_tree().change_scene_to_file(path)

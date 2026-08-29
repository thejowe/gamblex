class_name AchievementToast
extends Control

const DISPLAY_NAMES := {
	"HIGH_ROLLER": "Alto Postor — apostaste 100 fichas o más",
	"MINES_SURVIVOR": "Superviviente — 5 casillas seguras en una ronda de Mines",
	"BATTLE_MODE_WIN": "Victoria de Equipo — ganaste una partida de Modo Batalla",
	"FREE_MODE_GOAL_REACHED": "Meta Colectiva — el grupo alcanzó la meta de Modo Libre",
}

const SHOW_DURATION_SEC := 3.0

@onready var label: Label = $Panel/Margin/Label

var _queue: Array[String] = []
var _showing: bool = false

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = CasinoTheme.PANEL_NAVY_DARK
	box.border_color = CasinoTheme.GOLD_ACCENT
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	$Panel.add_theme_stylebox_override("panel", box)
	label.add_theme_color_override("font_color", CasinoTheme.GOLD_ACCENT)
	SteamManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(achievement_api_name: String) -> void:
	_queue.append(DISPLAY_NAMES.get(achievement_api_name, achievement_api_name))
	_maybe_show_next()

func _maybe_show_next() -> void:
	if _showing or _queue.is_empty():
		return
	_showing = true
	var text: String = _queue.pop_front()
	AudioManager.play_sfx("win")
	label.text = "Logro desbloqueado: %s" % text
	visible = true
	position.y = -80.0
	var tween := create_tween()
	tween.tween_property(self, "position:y", 20.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(SHOW_DURATION_SEC)
	tween.tween_property(self, "position:y", -80.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		visible = false
		_showing = false
		_maybe_show_next()
	)

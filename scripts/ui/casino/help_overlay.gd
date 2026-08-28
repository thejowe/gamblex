class_name HelpOverlay
extends Control

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Panel
@onready var rules_label: Label = $Panel/Margin/VBox/RulesLabel
@onready var close_button: CasinoButton = $Panel/Margin/VBox/CloseButton

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.color = Color(CasinoTheme.PANEL_NAVY_DARK, 0.85)
	var box := StyleBoxFlat.new()
	box.bg_color = CasinoTheme.PANEL_NAVY_MID
	box.border_color = CasinoTheme.GOLD_ACCENT
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_left = 10
	box.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", box)
	rules_label.add_theme_color_override("font_color", CasinoTheme.TEXT_LIGHT)
	close_button.pressed.connect(close)

func set_rules_text(text: String) -> void:
	rules_label.text = text

func open() -> void:
	visible = true

func close() -> void:
	visible = false

class_name PauseMenu
extends Control

signal exit_room_requested

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Panel
@onready var resume_button: CasinoButton = $Panel/Margin/VBox/ResumeButton
@onready var settings_button: CasinoButton = $Panel/Margin/VBox/SettingsButton
@onready var exit_room_button: CasinoButton = $Panel/Margin/VBox/ExitRoomButton
@onready var quit_button: CasinoButton = $Panel/Margin/VBox/QuitButton
@onready var quit_confirm: ConfirmationDialog = $QuitConfirm
@onready var settings_menu: SettingsMenu = $SettingsMenu

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.color = Color(CasinoTheme.PANEL_NAVY_DARK, 0.85)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(CasinoTheme.PANEL_NAVY_MID, 0.0) # el fondo real lo pinta PanelBackground (pixel art)
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

	resume_button.pressed.connect(func(): visible = false)
	settings_button.pressed.connect(func(): settings_menu.visible = true)
	exit_room_button.pressed.connect(func(): exit_room_requested.emit())
	quit_button.pressed.connect(quit_confirm.popup_centered)
	quit_confirm.confirmed.connect(func(): get_tree().quit())
	visibility_changed.connect(func():
		if visible:
			CasinoTheme.play_modal_pop_in(panel)
			CasinoTheme.play_modal_pop_in($PanelBackground)
	)

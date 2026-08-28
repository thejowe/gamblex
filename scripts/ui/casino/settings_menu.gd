class_name SettingsMenu
extends Control

const MIN_DB := -40.0
const MAX_DB := 0.0

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Panel
@onready var master_slider: HSlider = $Panel/Margin/VBox/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Panel/Margin/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/Margin/VBox/SfxRow/SfxSlider
@onready var master_mute: CheckBox = $Panel/Margin/VBox/MasterRow/MasterMute
@onready var music_mute: CheckBox = $Panel/Margin/VBox/MusicRow/MusicMute
@onready var sfx_mute: CheckBox = $Panel/Margin/VBox/SfxRow/SfxMute
@onready var fullscreen_toggle: CheckBox = $Panel/Margin/VBox/FullscreenToggle
@onready var close_button: CasinoButton = $Panel/Margin/VBox/CloseButton
@onready var quit_button: CasinoButton = $Panel/Margin/VBox/QuitButton
@onready var quit_confirm: ConfirmationDialog = $QuitConfirm

func _ready() -> void:
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

	for s in [master_slider, music_slider, sfx_slider]:
		s.min_value = MIN_DB
		s.max_value = MAX_DB
	master_slider.value = AudioManager.get_bus_volume_db("Master")
	music_slider.value = AudioManager.get_bus_volume_db("Music")
	sfx_slider.value = AudioManager.get_bus_volume_db("SFX")
	master_mute.button_pressed = AudioManager.is_bus_muted("Master")
	music_mute.button_pressed = AudioManager.is_bus_muted("Music")
	sfx_mute.button_pressed = AudioManager.is_bus_muted("SFX")
	fullscreen_toggle.button_pressed = get_window().mode == Window.MODE_FULLSCREEN

	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	master_mute.toggled.connect(_on_master_mute_toggled)
	music_mute.toggled.connect(_on_music_mute_toggled)
	sfx_mute.toggled.connect(_on_sfx_mute_toggled)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	close_button.pressed.connect(func(): visible = false)
	quit_button.pressed.connect(quit_confirm.popup_centered)
	quit_confirm.confirmed.connect(func(): get_tree().quit())

func _on_master_slider_changed(v: float) -> void:
	AudioManager.set_bus_volume_db("Master", v)

func _on_music_slider_changed(v: float) -> void:
	AudioManager.set_bus_volume_db("Music", v)

func _on_sfx_slider_changed(v: float) -> void:
	AudioManager.set_bus_volume_db("SFX", v)

func _on_master_mute_toggled(on: bool) -> void:
	AudioManager.set_bus_mute("Master", on)

func _on_music_mute_toggled(on: bool) -> void:
	AudioManager.set_bus_mute("Music", on)

func _on_sfx_mute_toggled(on: bool) -> void:
	AudioManager.set_bus_mute("SFX", on)

func _on_fullscreen_toggled(on: bool) -> void:
	get_window().mode = Window.MODE_FULLSCREEN if on else Window.MODE_WINDOWED
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("display", "fullscreen", on)
	cfg.save("user://settings.cfg")

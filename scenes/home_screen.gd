class_name HomeScreen
extends Control

@onready var start_button: CasinoButton = $StartButton
@onready var settings_button: CasinoButton = $SettingsButton
@onready var credits_button: CasinoButton = $CreditsButton
@onready var help_button: CasinoButton = $HelpButton
@onready var quit_button: CasinoButton = $QuitButton
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var help_overlay: HelpOverlay = $HelpOverlay
@onready var quit_confirm: ConfirmationDialog = $QuitConfirm

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	var loading: LoadingScreen = preload("res://scenes/ui/casino/loading_screen.tscn").instantiate()
	add_child(loading)
	loading.fade_and_change_scene("res://scenes/lobby_menu.tscn")

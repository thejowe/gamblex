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
	pass # wiring en tareas siguientes

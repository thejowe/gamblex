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

const HELP_TEXT := """Cómo jugar
Crea una sala e invita a tus amigos de Steam, o únete a la suya.
Elige Modo Libre (todos comparten una meta de fichas colectiva) o
Modo Batalla (equipos 1v1/2v2/4v4 compiten por vaciar el pozo rival).
Cada mesa tiene su propio botón de ayuda (?) con las reglas concretas
de ese juego."""

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(func(): settings_menu.visible = true)
	help_button.pressed.connect(func(): help_overlay.set_rules_text(HELP_TEXT); help_overlay.open())
	credits_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/casino/credits_menu.tscn"))
	quit_button.pressed.connect(quit_confirm.popup_centered)
	quit_confirm.confirmed.connect(func(): get_tree().quit())

func _on_start_pressed() -> void:
	var loading: LoadingScreen = preload("res://scenes/ui/casino/loading_screen.tscn").instantiate()
	add_child(loading)
	loading.fade_and_change_scene("res://scenes/lobby_menu.tscn")

class_name BetSidebarPanel
extends PanelContainer

signal bet_pressed(amount: int)

@onready var amount_edit: LineEdit = $Margin/VBox/AmountRow/AmountEdit
@onready var bet_button: CasinoButton = $Margin/VBox/BetButton

@export var max_amount: int = 500

@export var amount: int = 10:
	set(value):
		amount = clampi(value, 1, max_amount)
		if is_inside_tree():
			amount_edit.text = str(amount)

func _ready() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(CasinoTheme.PANEL_NAVY_MID, 0.0)
	add_theme_stylebox_override("panel", box)
	CasinoTheme.style_line_edit(amount_edit)
	amount_edit.text = str(amount)
	amount_edit.text_submitted.connect(_commit_typed_amount)
	amount_edit.focus_exited.connect(func(): _commit_typed_amount(amount_edit.text))
	bet_button.pressed.connect(_on_bet_pressed)
	$Margin/VBox/AmountRow/HalfButton.pressed.connect(_on_half_pressed)
	$Margin/VBox/AmountRow/DoubleButton.pressed.connect(_on_double_pressed)
	$Margin/VBox/AmountRow/MaxButton.pressed.connect(_on_max_pressed)

func set_max_amount(value: int) -> void:
	max_amount = value
	amount = amount # re-clamp contra el nuevo tope

func _on_half_pressed() -> void:
	amount = amount / 2

func _on_double_pressed() -> void:
	amount = amount * 2

func _on_max_pressed() -> void:
	amount = max_amount

func _on_bet_pressed() -> void:
	AudioManager.play_sfx("chip")
	if amount >= 100:
		SteamManager.unlock_achievement("HIGH_ROLLER")
	bet_pressed.emit(amount)

func _commit_typed_amount(new_text: String) -> void:
	if new_text.is_valid_int():
		amount = int(new_text)
	else:
		amount_edit.text = str(amount)

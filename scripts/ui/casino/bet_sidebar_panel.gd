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
	box.bg_color = CasinoTheme.PANEL_NAVY_MID
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", box)
	amount_edit.text = str(amount)
	amount_edit.text_submitted.connect(func(new_text: String): amount = int(new_text))
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
	bet_pressed.emit(amount)

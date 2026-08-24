class_name CasinoHudBar
extends PanelContainer

@onready var balance_label: Label = $Margin/HBox/BalanceLabel
@onready var bet_label: Label = $Margin/HBox/BetLabel

func _ready() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.078, 0.078, 0.059, 0.92)
	box.border_width_top = 2
	box.border_color = CasinoTheme.GOLD_ACCENT
	add_theme_stylebox_override("panel", box)
	balance_label.add_theme_color_override("font_color", CasinoTheme.GOLD_ACCENT)
	bet_label.add_theme_color_override("font_color", CasinoTheme.GOLD_ACCENT)

func set_balance(amount: int) -> void:
	balance_label.text = "BALANCE  $%d" % amount

func set_bet(amount: int) -> void:
	bet_label.text = "APUESTA  $%d" % amount

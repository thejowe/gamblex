class_name CasinoHudBar
extends PanelContainer

@onready var balance_label: Label = $Margin/HBox/BalanceLabel
@onready var bet_label: Label = $Margin/HBox/BetLabel

var _last_balance: int = -1
var _last_bet: int = -1

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
	if _last_balance != -1 and amount > _last_balance:
		_punch(balance_label)
	_last_balance = amount

# Solo un flash de escala, no un tween del número: los tests de este
# componente comprueban el texto sincrónicamente justo después de llamar a
# set_balance, así que el propio valor no puede quedar animado a medias.
func _punch(label: Label) -> void:
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(1.35, 1.35)
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_bet(amount: int) -> void:
	bet_label.text = "APUESTA  $%d" % amount
	if _last_bet != -1 and amount > _last_bet:
		_punch(bet_label)
	_last_bet = amount

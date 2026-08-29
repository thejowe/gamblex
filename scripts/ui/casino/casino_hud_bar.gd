class_name CasinoHudBar
extends PanelContainer

@onready var balance_label: Label = $Margin/HBox/BalanceLabel
@onready var bet_label: Label = $Margin/HBox/BetLabel

var _last_balance: int = -1
var _last_bet: int = -1

const PANEL_BORDER_TEXTURE_PATH := "res://assets/pixels/common/panels/panel_border/panel_border.png"

func _ready() -> void:
	# panel_border ya estaba FINAL en el registro (mismo lote que
	# bet_sidebar_bg) pero ningún nodo lo consumía — este panel seguía con
	# un StyleBoxFlat dibujado a mano en vez del pixel art ya aprobado.
	var box := StyleBoxTexture.new()
	box.texture = load(PANEL_BORDER_TEXTURE_PATH)
	box.texture_margin_left = 16
	box.texture_margin_right = 16
	box.texture_margin_top = 16
	box.texture_margin_bottom = 16
	add_theme_stylebox_override("panel", box)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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

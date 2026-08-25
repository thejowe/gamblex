class_name RouletteBettingGrid
extends VBoxContainer

signal bet_selected(bet_type: int, number: int)

const CasinoButtonScene := preload("res://scenes/ui/casino/casino_button.tscn")
const NUMBER_CELL_SIZE := Vector2(48, 36)
const OUTSIDE_BET_CELL_SIZE := Vector2(96, 36)

var _selected_button: Control = null
var _number_grid: GridContainer
var _outside_bets_row: GridContainer

func _ready() -> void:
	_number_grid = GridContainer.new()
	_number_grid.columns = 12
	add_child(_number_grid)
	for number in range(37):
		var button := Button.new()
		button.text = str(number)
		button.custom_minimum_size = NUMBER_CELL_SIZE
		_number_grid.add_child(button)
		_style_number_button(button, number)
		button.pressed.connect(_on_number_pressed.bind(button, number))

	_outside_bets_row = GridContainer.new()
	_outside_bets_row.columns = 7
	add_child(_outside_bets_row)
	_add_outside_bet_button("Rojo", RouletteTableState.BetType.RED)
	_add_outside_bet_button("Negro", RouletteTableState.BetType.BLACK)
	_add_outside_bet_button("Par", RouletteTableState.BetType.EVEN)
	_add_outside_bet_button("Impar", RouletteTableState.BetType.ODD)
	_add_outside_bet_button("1 a 12", RouletteTableState.BetType.DOZEN_1)
	_add_outside_bet_button("13 a 24", RouletteTableState.BetType.DOZEN_2)
	_add_outside_bet_button("25 a 36", RouletteTableState.BetType.DOZEN_3)

func _style_number_button(button: Button, number: int) -> void:
	var color := CasinoTheme.ACCENT_GREEN
	if number != 0:
		color = CasinoTheme.CARD_RED if number in RouletteTableState.RED_NUMBERS else CasinoTheme.CARD_BLACK
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = 4
	box.corner_radius_top_right = 4
	box.corner_radius_bottom_left = 4
	box.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_color_override("font_color", CasinoTheme.TEXT_LIGHT)

func _add_outside_bet_button(label: String, bet_type: int) -> void:
	var button: CasinoButton = CasinoButtonScene.instantiate()
	button.text = label
	button.custom_minimum_size = OUTSIDE_BET_CELL_SIZE
	_outside_bets_row.add_child(button)
	button.pressed.connect(_on_outside_bet_pressed.bind(button, bet_type, -1))

func _on_number_pressed(button: Control, number: int) -> void:
	_select(button)
	bet_selected.emit(RouletteTableState.BetType.STRAIGHT, number)

func _on_outside_bet_pressed(button: Control, bet_type: int, number: int) -> void:
	_select(button)
	bet_selected.emit(bet_type, number)

func _select(button: Control) -> void:
	if _selected_button != null and is_instance_valid(_selected_button):
		_selected_button.modulate = Color.WHITE
	_selected_button = button
	button.modulate = Color(1.3, 1.3, 0.7)

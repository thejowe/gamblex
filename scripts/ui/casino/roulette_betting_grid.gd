class_name RouletteBettingGrid
extends VBoxContainer

signal bet_selected(bet_type: int, number: int)

const CasinoButtonScene := preload("res://scenes/ui/casino/casino_button.tscn")
const CELL_TEXTURE_RED := preload("res://assets/pixels/roulette/roulette_grid_cell_red/roulette_grid_cell_red.png")
const CELL_TEXTURE_BLACK := preload("res://assets/pixels/roulette/roulette_grid_cell_black/roulette_grid_cell_black.png")
const CELL_TEXTURE_GREEN := preload("res://assets/pixels/roulette/roulette_grid_cell_green/roulette_grid_cell_green.png")
const NUMBER_CELL_SIZE := Vector2(48, 36)
const ZERO_CELL_SIZE := Vector2(36, 116) # 3*36 + 2*separation(2)
const COLUMN_BET_SIZE := Vector2(64, 36)
const DOZEN_CELL_SIZE := Vector2(192, 36) # (12 columnas * 48) / 3 docenas
const SPLIT_CELL_SIZE := Vector2(96, 36) # (12 columnas * 48) / 6 celdas

var _selected_button: Control = null
var _number_grid: GridContainer
var _zero_button: Button
var _column_bets_box: VBoxContainer
var _dozens_row: HBoxContainer
var _outside_row: HBoxContainer

func _ready() -> void:
	add_theme_constant_override("separation", 4)

	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 2)
	add_child(main_row)

	_zero_button = Button.new()
	_zero_button.text = "0"
	_zero_button.custom_minimum_size = ZERO_CELL_SIZE
	main_row.add_child(_zero_button)
	_style_cell_texture(_zero_button, CELL_TEXTURE_GREEN)
	_zero_button.pressed.connect(_on_number_pressed.bind(_zero_button, 0))

	_number_grid = GridContainer.new()
	_number_grid.columns = 12
	_number_grid.add_theme_constant_override("h_separation", 2)
	_number_grid.add_theme_constant_override("v_separation", 2)
	main_row.add_child(_number_grid)
	for row in range(3):
		for col in range(1, 13):
			var number: int = col * 3 - row
			var button := Button.new()
			button.text = str(number)
			button.custom_minimum_size = NUMBER_CELL_SIZE
			_number_grid.add_child(button)
			_style_number_button(button, number)
			button.pressed.connect(_on_number_pressed.bind(button, number))

	_column_bets_box = VBoxContainer.new()
	_column_bets_box.add_theme_constant_override("separation", 2)
	main_row.add_child(_column_bets_box)
	_add_outside_bet_button(_column_bets_box, "2 a 1", RouletteTableState.BetType.COLUMN_3, COLUMN_BET_SIZE)
	_add_outside_bet_button(_column_bets_box, "2 a 1", RouletteTableState.BetType.COLUMN_2, COLUMN_BET_SIZE)
	_add_outside_bet_button(_column_bets_box, "2 a 1", RouletteTableState.BetType.COLUMN_1, COLUMN_BET_SIZE)

	_dozens_row = HBoxContainer.new()
	_dozens_row.add_theme_constant_override("separation", 2)
	add_child(_dozens_row)
	_dozens_row.add_child(_spacer(ZERO_CELL_SIZE.x))
	_add_outside_bet_button(_dozens_row, "1ra 12", RouletteTableState.BetType.DOZEN_1, DOZEN_CELL_SIZE)
	_add_outside_bet_button(_dozens_row, "2da 12", RouletteTableState.BetType.DOZEN_2, DOZEN_CELL_SIZE)
	_add_outside_bet_button(_dozens_row, "3ra 12", RouletteTableState.BetType.DOZEN_3, DOZEN_CELL_SIZE)

	_outside_row = HBoxContainer.new()
	_outside_row.add_theme_constant_override("separation", 2)
	add_child(_outside_row)
	_outside_row.add_child(_spacer(ZERO_CELL_SIZE.x))
	_add_outside_bet_button(_outside_row, "1 a 18", RouletteTableState.BetType.LOW, SPLIT_CELL_SIZE)
	_add_outside_bet_button(_outside_row, "Par", RouletteTableState.BetType.EVEN, SPLIT_CELL_SIZE)
	_add_color_bet_button(_outside_row, "Rojo", RouletteTableState.BetType.RED, CasinoTheme.CARD_RED, SPLIT_CELL_SIZE)
	_add_color_bet_button(_outside_row, "Negro", RouletteTableState.BetType.BLACK, CasinoTheme.CARD_BLACK, SPLIT_CELL_SIZE)
	_add_outside_bet_button(_outside_row, "Impar", RouletteTableState.BetType.ODD, SPLIT_CELL_SIZE)
	_add_outside_bet_button(_outside_row, "19 a 36", RouletteTableState.BetType.HIGH, SPLIT_CELL_SIZE)

func _spacer(width: float) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(width, 1)
	return box

func _style_cell(button: Button, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = 4
	box.corner_radius_top_right = 4
	box.corner_radius_bottom_left = 4
	box.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_color_override("font_color", CasinoTheme.TEXT_LIGHT)

func _style_cell_texture(button: Button, texture: Texture2D) -> void:
	var box := StyleBoxTexture.new()
	box.texture = texture
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", box)
	button.add_theme_stylebox_override("pressed", box)
	button.add_theme_color_override("font_color", CasinoTheme.TEXT_LIGHT)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _style_number_button(button: Button, number: int) -> void:
	var texture := CELL_TEXTURE_RED if number in RouletteTableState.RED_NUMBERS else CELL_TEXTURE_BLACK
	_style_cell_texture(button, texture)

func _add_outside_bet_button(parent: Container, label: String, bet_type: int, cell_size: Vector2) -> void:
	var button: CasinoButton = CasinoButtonScene.instantiate()
	button.text = label
	button.custom_minimum_size = cell_size
	parent.add_child(button)
	button.pressed.connect(_on_outside_bet_pressed.bind(button, bet_type, -1))

func _add_color_bet_button(parent: Container, label: String, bet_type: int, color: Color, cell_size: Vector2) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = cell_size
	parent.add_child(button)
	_style_cell(button, color)
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

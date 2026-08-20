extends Control

@onready var table_controller: RouletteTableController = $TableController
@onready var seats_label: Label = $SeatsLabel
@onready var result_label: Label = $ResultLabel
@onready var sit_button: Button = $SitButton
@onready var bet_red_button: Button = $BetRedButton
@onready var bet_black_button: Button = $BetBlackButton
@onready var bet_even_button: Button = $BetEvenButton
@onready var bet_odd_button: Button = $BetOddButton
@onready var bet_straight_button: Button = $BetStraightButton
@onready var spin_button: Button = $SpinButton

var my_seat_index: int = -1
var _last_seats: Array = []

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	table_controller.state_changed.connect(_on_state_changed)
	sit_button.pressed.connect(_on_sit_pressed)
	bet_red_button.pressed.connect(func(): _place_bet(RouletteTableState.BetType.RED, -1, 50))
	bet_black_button.pressed.connect(func(): _place_bet(RouletteTableState.BetType.BLACK, -1, 50))
	bet_even_button.pressed.connect(func(): _place_bet(RouletteTableState.BetType.EVEN, -1, 50))
	bet_odd_button.pressed.connect(func(): _place_bet(RouletteTableState.BetType.ODD, -1, 50))
	bet_straight_button.pressed.connect(func(): _place_bet(RouletteTableState.BetType.STRAIGHT, 7, 100))
	spin_button.pressed.connect(_on_spin_pressed)
	NetworkManager.identities_changed.connect(_refresh_seats_label)
	# Mismo gotcha que blackjack_table_net.gd: un cliente recién llegado a esta
	# escena puede que aún no tenga el SteamMultiplayerPeer en CONNECTED —
	# bloquear "Sentarse" hasta entonces evita el rpc_id() fallido.
	if not multiplayer.is_server():
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			sit_button.disabled = true
			multiplayer.connected_to_server.connect(func():
				sit_button.disabled = false
				table_controller.request_state()
			)
		else:
			table_controller.request_state()

func _on_sit_pressed() -> void:
	var seat_index := 0
	for i in range(_last_seats.size()):
		if _last_seats[i] == null:
			seat_index = i
			break
	table_controller.sit(seat_index)
	my_seat_index = seat_index

func _place_bet(bet_type: int, number: int, amount: int) -> void:
	table_controller.place_bet(my_seat_index, bet_type, number, amount)

func _on_spin_pressed() -> void:
	table_controller.spin(my_seat_index)

func _on_state_changed(state: Dictionary) -> void:
	_last_seats = state["seats"]
	result_label.text = "Último número: %d" % state["last_result"]
	_refresh_seats_label()

func _refresh_seats_label() -> void:
	var lines: Array[String] = []
	for i in range(_last_seats.size()):
		var seat = _last_seats[i]
		if seat == null:
			lines.append("Asiento %d: libre" % i)
		else:
			lines.append("Asiento %d: %s — fichas %d — apuestas activas %d" % [
				i, _display_name(seat["player_id"]), seat["balance"], seat["bets"].size()
			])
	seats_label.text = "\n".join(lines)

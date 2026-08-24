extends Control

@onready var table_controller: TableController = $TableController
@onready var felt_panel: FeltTablePanel = $FeltTablePanel
@onready var hud_bar: CasinoHudBar = $CasinoHudBar
@onready var sit_button: Button = $SitButton
@onready var bet_button: Button = $BetButton
@onready var hit_button: Button = $HitButton
@onready var stand_button: Button = $StandButton
@onready var double_button: Button = $DoubleButton
@onready var split_button: Button = $SplitButton
@onready var dealer_cards: Control = $DealerCards
@onready var dealer_value_label: Label = $DealerValueLabel
@onready var deck_icon: Control = $DeckIcon
@onready var seats_root: Control = $SeatsRoot

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
	bet_button.pressed.connect(_on_bet_pressed)
	hit_button.pressed.connect(_on_hit_pressed)
	stand_button.pressed.connect(_on_stand_pressed)
	# El host actúa localmente (sin RPC), pero un cliente recién llegado a esta
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
	# Sentarse en el primer asiento libre según el último estado conocido; un
	# selector de asiento por UI queda fuera de alcance de este plan.
	var seat_index := 0
	for i in range(_last_seats.size()):
		if _last_seats[i] == null:
			seat_index = i
			break
	table_controller.sit(seat_index)
	my_seat_index = seat_index

func _on_bet_pressed() -> void:
	table_controller.bet(my_seat_index, 50)

func _on_hit_pressed() -> void:
	table_controller.hit(my_seat_index)

func _on_stand_pressed() -> void:
	table_controller.stand(my_seat_index)

func _on_state_changed(state: Dictionary) -> void:
	_last_seats = state["seats"]
	dealer_value_label.text = "%d" % state["dealer_value"]
	if my_seat_index >= 0 and my_seat_index < _last_seats.size() and _last_seats[my_seat_index] != null:
		bet_button.disabled = _last_seats[my_seat_index]["bet"] > 0

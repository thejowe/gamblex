extends Control

@onready var table_controller: PokerTableController = $PokerTableController
@onready var seats_label: Label = $SeatsLabel
@onready var community_label: Label = $CommunityLabel
@onready var pot_label: Label = $PotLabel
@onready var status_label: Label = $StatusLabel
@onready var sit_button: Button = $SitButton
@onready var start_hand_button: Button = $StartHandButton
@onready var fold_button: Button = $FoldButton
@onready var check_button: Button = $CheckButton
@onready var call_button: Button = $CallButton
@onready var raise_button: Button = $RaiseButton

var my_seat_index: int = -1
var _last_state: Dictionary = {}

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _card_name(card: Dictionary) -> String:
	var ranks := ["", "As", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
	var suits := ["Corazones", "Diamantes", "Treboles", "Picas"]
	return "%s de %s" % [ranks[card["rank"]], suits[card["suit"]]]

func _ready() -> void:
	table_controller.state_changed.connect(_on_state_changed)
	sit_button.pressed.connect(_on_sit_pressed)
	start_hand_button.pressed.connect(_on_start_hand_pressed)
	fold_button.pressed.connect(_on_fold_pressed)
	check_button.pressed.connect(_on_check_pressed)
	call_button.pressed.connect(_on_call_pressed)
	raise_button.pressed.connect(_on_raise_pressed)
	NetworkManager.identities_changed.connect(_refresh_seats_label)
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
	var seats: Array = _last_state.get("seats", [])
	var seat_index := 0
	for i in range(seats.size()):
		if seats[i] == null:
			seat_index = i
			break
	table_controller.sit(seat_index)

func _on_start_hand_pressed() -> void:
	table_controller.start_hand()

func _on_fold_pressed() -> void:
	table_controller.fold(my_seat_index)

func _on_check_pressed() -> void:
	table_controller.check(my_seat_index)

func _on_call_pressed() -> void:
	table_controller.call_bet(my_seat_index)

func _on_raise_pressed() -> void:
	var current_bet: int = _last_state.get("current_bet", 0)
	var min_raise_increment: int = _last_state.get("min_raise", 10)
	table_controller.raise_bet(my_seat_index, current_bet + min_raise_increment)

func _on_state_changed(state: Dictionary) -> void:
	_last_state = state

	# La fuente de verdad de mi asiento es el estado autoritativo del host, no
	# la asignacion optimista de _on_sit_pressed (que puede perder una carrera
	# por el mismo asiento contra otro cliente).
	var seats: Array = state.get("seats", [])
	var my_id := multiplayer.get_unique_id()
	my_seat_index = -1
	for i in range(seats.size()):
		var seat = seats[i]
		if seat != null and seat["player_id"] == my_id:
			my_seat_index = i
			break

	_refresh_seats_label()
	var community: Array = state.get("community_cards", [])
	var community_names: Array[String] = []
	for card in community:
		community_names.append(_card_name(card))
	community_label.text = "Mesa: %s" % ", ".join(community_names)
	pot_label.text = "Bote: %d" % state.get("pot", 0)

	var hand_active: bool = state.get("hand_active", false)
	var active_seat_index: int = state.get("active_seat_index", -1)
	if hand_active:
		var turn_text := "Asiento %d" % active_seat_index
		if active_seat_index >= 0 and active_seat_index < seats.size() and seats[active_seat_index] != null:
			turn_text = _display_name(seats[active_seat_index]["player_id"])
		status_label.text = "Turno: %s" % turn_text
	else:
		var winners: Array = state.get("last_winner_seats", [])
		if winners.size() > 0:
			var winner_strs: Array[String] = []
			for w in winners:
				winner_strs.append(str(w))
			status_label.text = "Ganador: Asiento %s" % ", ".join(winner_strs)
		else:
			status_label.text = "Esperando reparto"

	var is_my_turn: bool = my_seat_index != -1 and hand_active and active_seat_index == my_seat_index
	fold_button.disabled = not is_my_turn
	check_button.disabled = not is_my_turn
	call_button.disabled = not is_my_turn
	raise_button.disabled = not is_my_turn

func _refresh_seats_label() -> void:
	var seats: Array = _last_state.get("seats", [])
	var lines: Array[String] = []
	for i in range(seats.size()):
		var seat = seats[i]
		if seat == null:
			lines.append("Asiento %d: libre" % i)
			continue
		var hole_names: Array[String] = []
		for card in seat["hole_cards"]:
			hole_names.append(_card_name(card))
		var hole_text := ", ".join(hole_names) if hole_names.size() > 0 else "?? ??"
		var status := " (retirado)" if seat["folded"] else ""
		lines.append("Asiento %d: %s%s — fichas %d — apuesta %d — %s" % [
			i, _display_name(seat["player_id"]), status, seat["balance"], seat["current_bet"], hole_text
		])
	seats_label.text = "\n".join(lines)

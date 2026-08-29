extends Control

const PlayingCardScene := preload("res://scenes/ui/casino/playing_card.tscn")
const CasinoChipScene := preload("res://scenes/ui/casino/casino_chip.tscn")
const CARD_SPACING := 24.0
const RULES_TEXT := "Blackjack: pide cartas para acercarte a 21 sin pasarte. Ganas si tu mano vale mas que la del crupier sin pasarte de 21 — cobras el doble de tu apuesta. Empate (mismo valor): recuperas tu apuesta. Si te pasas de 21 pierdes la apuesta. El crupier pide carta mientras su mano valga menos de 17 y se planta a partir de ahi."

@onready var table_controller: TableController = $TableController
@onready var felt_panel: FeltTablePanel = $FeltTablePanel
@onready var hud_bar: CasinoHudBar = $CasinoHudBar
@onready var sit_button: Button = $SitButton
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var hit_button: Button = $HitButton
@onready var stand_button: Button = $StandButton
@onready var double_button: Button = $DoubleButton
@onready var split_button: Button = $SplitButton
@onready var dealer_cards: Control = $DealerCards
@onready var dealer_value_label: Label = $DealerValueLabel
@onready var deck_icon: Control = $DeckIcon
@onready var seats_root: Control = $SeatsRoot
@onready var help_button: CasinoButton = $HelpButton
@onready var help_overlay: HelpOverlay = $HelpOverlay

var my_seat_index: int = -1
var _last_state: Dictionary = {"seats": [null, null, null, null], "dealer_hand": []}
var _seat_card_nodes: Array = [[], [], [], []]
var _dealer_card_nodes: Array = []
var _seat_chip_nodes: Array = [null, null, null, null]
var _seat_value_badges: Array = [null, null, null, null]

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	_force_full_rect_size()
	visibility_changed.connect(_on_visibility_changed)
	table_controller.state_changed.connect(_on_state_changed)
	table_controller.chips_won.connect(_on_chips_won)
	sit_button.pressed.connect(_on_sit_pressed)
	bet_sidebar.bet_pressed.connect(_on_bet_pressed)
	hit_button.pressed.connect(_on_hit_pressed)
	stand_button.pressed.connect(_on_stand_pressed)
	help_button.pressed.connect(func(): help_overlay.set_rules_text(RULES_TEXT); help_overlay.open())
	double_button.disabled = true
	split_button.disabled = true
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

func _on_visibility_changed() -> void:
	if not visible:
		return
	_force_full_rect_size()

func _force_full_rect_size() -> void:
	# BlackjackTableNet sits under CasinoFloor, a Node2D. Control's anchor
	# system resolves the "parent area" against the nearest CanvasItem
	# ancestor (Node2D included) rather than falling back to the viewport,
	# so full-rect anchors alone never produce a non-zero size here — size
	# must be forced directly against the actual viewport.
	anchor_right = 0.0
	anchor_bottom = 0.0
	size = get_viewport_rect().size
	felt_panel.anchor_right = 0.0
	felt_panel.anchor_bottom = 0.0
	felt_panel.size = size
	felt_panel.queue_redraw()

func _on_sit_pressed() -> void:
	var seats: Array = _last_state.get("seats", [null, null, null, null])
	var seat_index := 0
	for i in range(seats.size()):
		if seats[i] == null:
			seat_index = i
			break
	my_seat_index = seat_index
	table_controller.sit(seat_index)

func _on_bet_pressed(amount: int) -> void:
	table_controller.bet(my_seat_index, amount)

func _on_hit_pressed() -> void:
	table_controller.hit(my_seat_index)

func _on_stand_pressed() -> void:
	table_controller.stand(my_seat_index)

func seat_anchor(seat_index: int, seat_count: int) -> Vector2:
	if seat_count <= 1:
		return Vector2(size.x / 2.0, size.y * 0.5)
	var usable_width := size.x * 0.7
	var start_x := size.x * 0.15
	var step := usable_width / float(seat_count - 1)
	return Vector2(start_x + step * seat_index, size.y * 0.5)

func _on_state_changed(state: Dictionary) -> void:
	_render_state(state)

func _render_state(state: Dictionary) -> void:
	var previous := _last_state
	var seats: Array = state["seats"]
	var previous_seats: Array = previous.get("seats", [null, null, null, null])
	_render_dealer(state.get("dealer_hand", []), state["dealer_value"])
	for i in range(seats.size()):
		var previous_seat = previous_seats[i] if i < previous_seats.size() else null
		_render_seat(i, seats[i], previous_seat, seats.size())
	_last_state = state
	if my_seat_index >= 0 and my_seat_index < seats.size() and seats[my_seat_index] != null:
		bet_sidebar.bet_button.disabled = seats[my_seat_index]["bet"] > 0
		hud_bar.set_balance(seats[my_seat_index]["balance"])
		hud_bar.set_bet(seats[my_seat_index]["bet"])
	var is_my_turn: bool = my_seat_index >= 0 and state.get("active_seat_index", -1) == my_seat_index
	hit_button.disabled = not is_my_turn
	stand_button.disabled = not is_my_turn

func _render_dealer(hand_data: Array, dealer_value: int) -> void:
	var has_hidden_card := hand_data.any(func(c): return c.has("hidden"))
	dealer_value_label.text = str(_visible_hand_value(hand_data)) if has_hidden_card else str(dealer_value)
	_sync_hand_visual(dealer_cards, _dealer_card_nodes, hand_data, Vector2(size.x / 2.0, size.y * 0.22))

func _visible_hand_value(hand_data: Array) -> int:
	var total := 0
	var aces := 0
	for card_data in hand_data:
		if card_data.has("hidden"):
			continue
		var rank: int = card_data["rank"]
		if rank == 1:
			total += 11
			aces += 1
		elif rank >= 10:
			total += 10
		else:
			total += rank
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total

func _render_seat(seat_index: int, seat, previous_seat, seat_count: int) -> void:
	var anchor := seat_anchor(seat_index, seat_count)
	var hand_data: Array = seat["hand"] if seat != null else []
	_sync_hand_visual(seats_root, _seat_card_nodes[seat_index], hand_data, anchor)
	_sync_chip(seat_index, seat, anchor)
	_sync_value_badge(seat_index, seat, anchor)

func _sync_value_badge(seat_index: int, seat, anchor: Vector2) -> void:
	var hand: Array = seat["hand"] if seat != null else []
	var badge = _seat_value_badges[seat_index]
	if hand.is_empty():
		if badge != null:
			badge.visible = false
		return
	if badge == null:
		badge = PanelContainer.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.1, 0.08, 0.05, 0.85)
		box.corner_radius_top_left = 16
		box.corner_radius_top_right = 16
		box.corner_radius_bottom_left = 16
		box.corner_radius_bottom_right = 16
		box.content_margin_left = 10
		box.content_margin_right = 10
		box.content_margin_top = 4
		box.content_margin_bottom = 4
		badge.add_theme_stylebox_override("panel", box)
		var label := Label.new()
		label.name = "ValueLabel"
		label.add_theme_color_override("font_color", CasinoTheme.TEXT_CREAM)
		badge.add_child(label)
		seats_root.add_child(badge)
		_seat_value_badges[seat_index] = badge
	badge.visible = true
	badge.get_node("ValueLabel").text = str(seat["hand_value"])
	badge.position = anchor + Vector2(-70, -20)

func _sync_hand_visual(container: Control, nodes: Array, hand_data: Array, anchor: Vector2) -> void:
	while nodes.size() > hand_data.size():
		var node = nodes.pop_back()
		node.queue_free()
	for i in range(hand_data.size()):
		var card_data = hand_data[i]
		var is_new := i >= nodes.size()
		var card: PlayingCard
		if is_new:
			card = PlayingCardScene.instantiate()
			container.add_child(card)
			card.position = deck_icon.position
			nodes.append(card)
		else:
			card = nodes[i]
		if card_data.has("hidden"):
			card.face_up = false
		elif not is_new and not card.face_up:
			# La carta ya estaba en la mesa boca abajo (la carta tapada del
			# crupier) y ahora se revela — un volteo real en vez del salto
			# instantáneo a la cara visible.
			card.rank = card_data["rank"]
			card.suit = card_data["suit"]
			card.flip()
		else:
			card.rank = card_data["rank"]
			card.suit = card_data["suit"]
			card.face_up = true
		var target := anchor + Vector2(i * CARD_SPACING - hand_data.size() * CARD_SPACING * 0.5, 0)
		if is_new:
			var tween := create_tween()
			tween.tween_property(card, "position", target, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			card.position = target

func _sync_chip(seat_index: int, seat, anchor: Vector2) -> void:
	var chip_anchor := anchor + Vector2(0, 60)
	var existing = _seat_chip_nodes[seat_index]
	var bet: int = seat["bet"] if seat != null else 0
	if bet <= 0:
		if existing != null:
			_seat_chip_nodes[seat_index] = null
			var sweep_tween := create_tween()
			sweep_tween.set_parallel(true)
			sweep_tween.tween_property(existing, "position", hud_bar.position, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			sweep_tween.tween_property(existing, "modulate:a", 0.0, 0.25)
			sweep_tween.chain().tween_callback(existing.queue_free)
		return
	if existing == null:
		var chip: CasinoChip = CasinoChipScene.instantiate()
		seats_root.add_child(chip)
		chip.position = hud_bar.position
		_seat_chip_nodes[seat_index] = chip
		existing = chip
		var tween := create_tween()
		tween.tween_property(chip, "position", chip_anchor, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	existing.denomination = bet

func _on_chips_won(player_id: int, amount: int) -> void:
	var seats: Array = _last_state.get("seats", [])
	for i in range(seats.size()):
		var seat = seats[i]
		if seat != null and seat["player_id"] == player_id:
			_celebrate_seat(i, seats.size())
			return

func _celebrate_seat(seat_index: int, seat_count: int) -> void:
	AudioManager.play_sfx("win")
	var anchor := seat_anchor(seat_index, seat_count)
	var particles := CPUParticles2D.new()
	particles.position = anchor
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 24
	particles.lifetime = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, 200)
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 160.0
	particles.color = CasinoTheme.GOLD_ACCENT
	add_child(particles)
	get_tree().create_timer(1.2).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)
	for card in _seat_card_nodes[seat_index]:
		var tween := create_tween()
		tween.tween_property(card, "modulate", CasinoTheme.GOLD_ACCENT, 0.15)
		tween.tween_property(card, "modulate", Color.WHITE, 0.35)

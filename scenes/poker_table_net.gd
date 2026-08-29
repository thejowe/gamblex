extends Control

const PlayingCardScene := preload("res://scenes/ui/casino/playing_card.tscn")
const CasinoChipScene := preload("res://scenes/ui/casino/casino_chip.tscn")
const CARD_SPACING := 24.0
const COMMUNITY_CARD_SPACING := 78.0
const SEAT_COUNT := 6
const RULES_TEXT := "Poker: Texas Hold'em estandar, 6 asientos, ciegas 5/10. Cada jugador recibe 2 cartas propias y comparte 5 cartas comunes repartidas en fases (flop, turn, river). En cada ronda de apuestas puedes pasar, igualar, subir o retirarte. En el showdown gana quien forme la mejor mano de 5 cartas combinando las suyas con las comunes."

@onready var table_controller: PokerTableController = $PokerTableController
@onready var felt_panel: FeltTablePanel = $FeltTablePanel
@onready var seats_root: Control = $SeatsRoot
@onready var community_root: Control = $CommunityRoot
@onready var pot_label: Label = $PotLabel
@onready var status_label: Label = $StatusLabel
@onready var sit_button: Button = $SitButton
@onready var start_hand_button: Button = $StartHandButton
@onready var fold_button: Button = $FoldButton
@onready var check_button: Button = $CheckButton
@onready var call_button: Button = $CallButton
@onready var raise_button: Button = $RaiseButton
@onready var raise_slider: HSlider = $RaiseSlider
@onready var raise_value_label: Label = $RaiseValueLabel
@onready var confirm_raise_button: Button = $ConfirmRaiseButton
@onready var help_button: CasinoButton = $HelpButton
@onready var help_overlay: HelpOverlay = $HelpOverlay

var my_seat_index: int = -1
var _last_state: Dictionary = {}
var _seat_containers: Array = []
var _seat_avatars: Array = []
var _seat_info_labels: Array = []
var _seat_card_nodes: Array = [[], [], [], [], [], []]
var _seat_chip_nodes: Array = [null, null, null, null, null, null]
var _community_card_nodes: Array = []
var _dealer_badge: Control = null
var _winner_banner: Control = null

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	for i in range(SEAT_COUNT):
		var container: Control = seats_root.get_node("Seat%d" % i)
		_seat_containers.append(container)
		_seat_avatars.append(container.get_node("Avatar"))
		var info_label: Label = container.get_node("InfoLabel")
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_label.add_theme_color_override("font_color", CasinoTheme.TEXT_CREAM)
		_seat_info_labels.append(info_label)
	pot_label.add_theme_color_override("font_color", CasinoTheme.GOLD_ACCENT)
	pot_label.add_theme_font_size_override("font_size", 24)
	status_label.add_theme_color_override("font_color", CasinoTheme.TEXT_CREAM)
	raise_value_label.add_theme_color_override("font_color", CasinoTheme.TEXT_CREAM)
	CasinoTheme.style_slider(raise_slider)

	_force_full_rect_size()
	visibility_changed.connect(_on_visibility_changed)
	table_controller.state_changed.connect(_on_state_changed)
	sit_button.pressed.connect(_on_sit_pressed)
	start_hand_button.pressed.connect(_on_start_hand_pressed)
	fold_button.pressed.connect(_on_fold_pressed)
	check_button.pressed.connect(_on_check_pressed)
	call_button.pressed.connect(_on_call_pressed)
	raise_button.pressed.connect(_on_raise_pressed)
	raise_slider.value_changed.connect(_on_raise_slider_changed)
	confirm_raise_button.pressed.connect(_on_confirm_raise_pressed)
	help_button.pressed.connect(func(): help_overlay.set_rules_text(RULES_TEXT); help_overlay.open())
	NetworkManager.identities_changed.connect(_refresh_seat_labels)
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
	# PokerTableNet sits under CasinoFloor, a Node2D. Control's anchor system
	# resolves the "parent area" against the nearest CanvasItem ancestor
	# (Node2D included) rather than falling back to the viewport, so
	# full-rect anchors alone never produce a non-zero size here — size must
	# be forced directly against the actual viewport (mismo gotcha que
	# Blackjack, Plan 14).
	anchor_right = 0.0
	anchor_bottom = 0.0
	size = get_viewport_rect().size
	felt_panel.anchor_right = 0.0
	felt_panel.anchor_bottom = 0.0
	felt_panel.size = size
	felt_panel.queue_redraw()
	pot_label.position = Vector2(size.x / 2.0 - 70.0, size.y * 0.42 - 70.0)
	status_label.position = Vector2(size.x / 2.0 - 120.0, size.y * 0.42 + 60.0)

func seat_anchor_oval(seat_index: int, seat_count: int) -> Vector2:
	var center := Vector2(size.x / 2.0, size.y * 0.42)
	var radius := Vector2(size.x * 0.42, size.y * 0.32)
	# Empieza en la parte inferior-central (hueco para tus propias cartas,
	# igual que la referencia) y reparte el resto en sentido horario.
	var start_angle := PI / 2.0 + (PI / float(seat_count))
	var angle := start_angle + TAU * float(seat_index) / float(seat_count)
	return center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)

func _oval_center() -> Vector2:
	return Vector2(size.x / 2.0, size.y * 0.42)

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
	AudioManager.play_sfx("chip")
	table_controller.call_bet(my_seat_index)

func _on_raise_pressed() -> void:
	AudioManager.play_sfx("chip")
	var current_bet: int = _last_state.get("current_bet", 0)
	var min_raise_increment: int = _last_state.get("min_raise", 10)
	table_controller.raise_bet(my_seat_index, current_bet + min_raise_increment)

func _on_raise_slider_changed(value: float) -> void:
	raise_value_label.text = "Subir a: %d" % int(value)

func _on_confirm_raise_pressed() -> void:
	AudioManager.play_sfx("chip")
	table_controller.raise_bet(my_seat_index, int(raise_slider.value))

func _find_seat_index(state: Dictionary, player_id: int) -> int:
	var seats: Array = state.get("seats", [])
	for i in range(seats.size()):
		var seat = seats[i]
		if seat != null and seat["player_id"] == player_id:
			return i
	return -1

func _on_state_changed(state: Dictionary) -> void:
	var previous := _last_state
	_maybe_play_audio_cues(previous, state)

	var my_id := multiplayer.get_unique_id()
	my_seat_index = _find_seat_index(state, my_id)

	_render_state(state)
	_last_state = state

func _maybe_play_audio_cues(previous: Dictionary, state: Dictionary) -> void:
	if previous.is_empty():
		return
	var my_id := multiplayer.get_unique_id()
	var prev_my_seat := _find_seat_index(previous, my_id)
	var cur_my_seat := _find_seat_index(state, my_id)

	var prev_community: Array = previous.get("community_cards", [])
	var cur_community: Array = state.get("community_cards", [])
	var prev_hole: Array = previous["seats"][prev_my_seat].get("hole_cards", []) if prev_my_seat != -1 else []
	var cur_hole: Array = state["seats"][cur_my_seat].get("hole_cards", []) if cur_my_seat != -1 else []
	if cur_community.size() > prev_community.size() or cur_hole.size() > prev_hole.size():
		AudioManager.play_sfx("card")

	var hand_active: bool = state.get("hand_active", false)
	var prev_hand_active: bool = previous.get("hand_active", false)
	if prev_hand_active and not hand_active and cur_my_seat != -1:
		var winners: Array = state.get("last_winner_seats", [])
		var my_seat_data: Dictionary = state["seats"][cur_my_seat]
		if winners.has(cur_my_seat):
			AudioManager.play_sfx("win")
		elif not my_seat_data.get("folded", false):
			AudioManager.play_sfx("lose")

func _render_state(state: Dictionary) -> void:
	var seats: Array = state.get("seats", [null, null, null, null, null, null])
	var hand_active: bool = state.get("hand_active", false)
	var dealer_index: int = state.get("dealer_button_index", -1)

	for i in range(seats.size()):
		_render_seat(i, seats[i], hand_active)

	_render_dealer_badge(dealer_index)
	_render_community(state)

	pot_label.text = "Bote: %d" % state.get("pot", 0)

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
	_update_raise_slider(state, is_my_turn)

	var occupied_seats := 0
	for seat in seats:
		if seat != null:
			occupied_seats += 1
	start_hand_button.disabled = hand_active or occupied_seats < 2

	_maybe_show_winner_banner(state)

func _update_raise_slider(state: Dictionary, is_my_turn: bool) -> void:
	var min_amount: int = state.get("current_bet", 0) + state.get("min_raise", 10)
	var seats: Array = state.get("seats", [])
	var balance := 0
	if my_seat_index != -1 and my_seat_index < seats.size() and seats[my_seat_index] != null:
		balance = seats[my_seat_index]["balance"]
	# Rango invalido (jugador all-in o casi) -> oculta el slider, el boton
	# "Subir" de incremento fijo se queda como fallback.
	var valid := is_my_turn and balance > min_amount
	raise_slider.visible = valid
	raise_value_label.visible = valid
	confirm_raise_button.visible = valid
	confirm_raise_button.disabled = not valid
	if not valid:
		return
	raise_slider.min_value = min_amount
	raise_slider.max_value = balance
	raise_slider.step = 1
	if raise_slider.value < min_amount or raise_slider.value > balance:
		raise_slider.value = min_amount
	raise_value_label.text = "Subir a: %d" % int(raise_slider.value)

func _render_seat(seat_index: int, seat, hand_active: bool) -> void:
	var container := _seat_containers[seat_index] as Control
	var avatar := _seat_avatars[seat_index] as SeatAvatar
	var info_label := _seat_info_labels[seat_index] as Label
	container.position = seat_anchor_oval(seat_index, SEAT_COUNT)

	if seat == null:
		avatar.visible = false
		info_label.visible = false
		container.modulate = Color.WHITE
		_sync_hand_visual(container, _seat_card_nodes[seat_index], [], Vector2(0, 55), CARD_SPACING)
		_sync_chip(seat_index, 0, container, Vector2(45, -10))
		return

	avatar.visible = true
	info_label.visible = true
	var display_name := _display_name(seat["player_id"])
	avatar.player_id = seat["player_id"]
	avatar.initial = display_name.substr(0, 1).to_upper()
	info_label.text = "%s\n%d fichas" % [display_name, seat["balance"]]
	container.modulate = Color(1, 1, 1, 0.4) if seat["folded"] else Color.WHITE

	var hole_cards: Array = seat["hole_cards"]
	var hand_data: Array = hole_cards
	if hole_cards.is_empty() and hand_active and not seat["folded"]:
		hand_data = [{"hidden": true}, {"hidden": true}]
	_sync_hand_visual(container, _seat_card_nodes[seat_index], hand_data, Vector2(0, 55), CARD_SPACING)
	_sync_chip(seat_index, seat["current_bet"], container, Vector2(45, -10))

func _render_dealer_badge(dealer_index: int) -> void:
	if dealer_index < 0 or dealer_index >= SEAT_COUNT:
		if _dealer_badge != null:
			_dealer_badge.visible = false
		return
	if _dealer_badge == null:
		_dealer_badge = _make_round_badge("D", CasinoTheme.GOLD_ACCENT, CasinoTheme.CARD_BLACK)
		seats_root.add_child(_dealer_badge)
	_dealer_badge.visible = true
	var seat_anchor := seat_anchor_oval(dealer_index, SEAT_COUNT)
	_dealer_badge.position = seat_anchor.lerp(_oval_center(), 0.3) - _dealer_badge.size / 2.0

func _make_round_badge(text: String, bg_color: Color, text_color: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(28, 28)
	var box := StyleBoxFlat.new()
	box.bg_color = bg_color
	box.corner_radius_top_left = 14
	box.corner_radius_top_right = 14
	box.corner_radius_bottom_left = 14
	box.corner_radius_bottom_right = 14
	badge.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", text_color)
	badge.add_child(label)
	return badge

func _render_community(state: Dictionary) -> void:
	var community: Array = state.get("community_cards", [])
	_sync_hand_visual(community_root, _community_card_nodes, community, _oval_center(), COMMUNITY_CARD_SPACING)

func _sync_hand_visual(container: Control, nodes: Array, hand_data: Array, anchor: Vector2, spacing: float) -> void:
	while nodes.size() > hand_data.size():
		var node = nodes.pop_back()
		node.queue_free()
	for i in range(hand_data.size()):
		var card_data: Dictionary = hand_data[i]
		var is_new := i >= nodes.size()
		var card: PlayingCard
		if is_new:
			card = PlayingCardScene.instantiate()
			container.add_child(card)
			nodes.append(card)
		else:
			card = nodes[i]
		if card_data.has("hidden"):
			card.face_up = false
		elif not is_new and not card.face_up:
			# Cartas comunitarias o manos rivales que estaban boca abajo y
			# se revelan en el showdown — volteo real en vez de salto.
			card.rank = card_data["rank"]
			card.suit = card_data["suit"]
			card.flip()
		else:
			card.rank = card_data["rank"]
			card.suit = card_data["suit"]
			card.face_up = true
		card.position = anchor + Vector2(i * spacing - hand_data.size() * spacing * 0.5, -card.CARD_SIZE.y / 2.0)

func _sync_chip(seat_index: int, bet: int, container: Control, chip_anchor: Vector2) -> void:
	var existing = _seat_chip_nodes[seat_index]
	if bet <= 0:
		if existing != null:
			existing.queue_free()
			_seat_chip_nodes[seat_index] = null
		return
	if existing == null:
		var chip: CasinoChip = CasinoChipScene.instantiate()
		container.add_child(chip)
		_seat_chip_nodes[seat_index] = chip
		existing = chip
	existing.position = chip_anchor
	existing.denomination = bet

func _maybe_show_winner_banner(state: Dictionary) -> void:
	var winners: Array = state.get("last_winner_seats", [])
	var previous_winners: Array = _last_state.get("last_winner_seats", [])
	if winners.is_empty() or not previous_winners.is_empty():
		return
	var seats: Array = state.get("seats", [])
	var winner_seat = winners[0]
	if winner_seat == null or winner_seat < 0 or winner_seat >= seats.size() or seats[winner_seat] == null:
		return
	_show_winner_banner(winner_seat, _display_name(seats[winner_seat]["player_id"]))
	_celebrate_seat(winner_seat)

func _show_winner_banner(seat_index: int, player_name: String) -> void:
	if _winner_banner != null and is_instance_valid(_winner_banner):
		_winner_banner.queue_free()
	var banner := _make_round_badge("", CasinoTheme.GOLD_ACCENT, CasinoTheme.CARD_BLACK)
	banner.custom_minimum_size = Vector2(160, 32)
	var label: Label = banner.get_child(0)
	label.text = "¡Gana %s!" % player_name
	label.add_theme_color_override("font_color", CasinoTheme.CARD_BLACK)
	seats_root.add_child(banner)
	var anchor := seat_anchor_oval(seat_index, SEAT_COUNT)
	banner.position = anchor - Vector2(80, 60)
	banner.modulate.a = 0.0
	_winner_banner = banner
	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.0)
	tween.tween_property(banner, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(banner):
			banner.queue_free()
	)

func _celebrate_seat(seat_index: int) -> void:
	var anchor := seat_anchor_oval(seat_index, SEAT_COUNT)
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
	seats_root.add_child(particles)
	get_tree().create_timer(1.2).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)

func _refresh_seat_labels() -> void:
	if _last_state.is_empty():
		return
	_render_state(_last_state)

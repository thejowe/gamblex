extends Control

const RouletteResultBadgeScene := preload("res://scenes/ui/casino/roulette_result_badge.tscn")
const MAX_HISTORY := 8
const RULES_TEXT := "Ruleta: apuesta a lo que crees que saldra mientras las apuestas estan abiertas (20 segundos, todos los sentados pueden apostar a la vez). Al agotarse el tiempo la mesa gira sola y reparte a todos. A un numero exacto (pago 35 a 1 mas tu apuesta), a una columna o docena (pago 2 a 1 mas tu apuesta), o a rojo/negro, par/impar, 1-18/19-36 (pago 1 a 1 mas tu apuesta). La bola cae en un numero del 0 al 36."

@onready var table_controller: RouletteTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var wheel: RouletteWheelDisplay = $RouletteWheelDisplay
@onready var betting_grid: RouletteBettingGrid = $RouletteBettingGrid
@onready var results_history: HBoxContainer = $ResultsHistory
@onready var round_timer_badge: RoundTimerBadge = $RoundTimerBadge
@onready var phase_label: Label = $PhaseLabel
@onready var sit_button: Button = $SitButton
@onready var seats_label: Label = $SeatsLabel
@onready var help_button: CasinoButton = $HelpButton
@onready var help_overlay: HelpOverlay = $HelpOverlay

var my_seat_index: int = -1
var _last_seats: Array = []
var _last_seen_result: int = -1
var _selected_bet_type: int = RouletteTableState.BetType.RED
var _selected_number: int = -1
var _history: Array = []
var _phase: int = RouletteTableState.Phase.BETTING
var _phase_time_remaining: float = RouletteTableState.ROUND_DURATION_SEC
var _last_round_seen: Dictionary = {}

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	table_controller.state_changed.connect(_on_state_changed)
	bet_sidebar.bet_pressed.connect(_on_bet_pressed)
	betting_grid.bet_selected.connect(_on_bet_selected)
	sit_button.pressed.connect(_on_sit_pressed)
	help_button.pressed.connect(func(): help_overlay.set_rules_text(RULES_TEXT); help_overlay.open())
	NetworkManager.identities_changed.connect(_refresh_seats_label)
	round_timer_badge.total_seconds = RouletteTableState.ROUND_DURATION_SEC
	round_timer_badge.seconds_remaining = RouletteTableState.ROUND_DURATION_SEC
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

# Cuenta atrás local entre broadcasts del host (que solo llegan cuando la
# fase cambia, no cada frame) -- mismo criterio de extrapolación barata que
# crash_table_net.gd. _on_state_changed resincroniza el valor real en cada
# broadcast, así que un pequeño desfase por latencia nunca se acumula.
func _process(delta: float) -> void:
	_phase_time_remaining = maxf(_phase_time_remaining - delta, 0.0)
	round_timer_badge.total_seconds = RouletteTableState.ROUND_DURATION_SEC if _phase == RouletteTableState.Phase.BETTING else RouletteTableState.RESULT_DURATION_SEC
	round_timer_badge.seconds_remaining = _phase_time_remaining

func _on_sit_pressed() -> void:
	var seat_index := 0
	for i in range(_last_seats.size()):
		if _last_seats[i] == null:
			seat_index = i
			break
	table_controller.sit(seat_index)
	my_seat_index = seat_index

func _on_bet_selected(bet_type: int, number: int) -> void:
	_selected_bet_type = bet_type
	_selected_number = number
	table_controller.place_bet(my_seat_index, bet_type, number, bet_sidebar.amount)

func _on_bet_pressed(amount: int) -> void:
	table_controller.place_bet(my_seat_index, _selected_bet_type, _selected_number, amount)

func _on_state_changed(state: Dictionary) -> void:
	_last_seats = state["seats"]
	_refresh_seats_label()
	_phase = state["phase"]
	_phase_time_remaining = state["phase_time_remaining"]
	_set_betting_enabled(_phase == RouletteTableState.Phase.BETTING)
	var is_betting := _phase == RouletteTableState.Phase.BETTING
	phase_label.text = "Apuestas abiertas" if is_betting else "Girando la ruleta..."
	phase_label.add_theme_color_override("font_color", CasinoTheme.ACCENT_GREEN if is_betting else CasinoTheme.GOLD_ACCENT)
	var new_result: int = state["last_result"]
	if new_result != -1 and new_result != _last_seen_result:
		_last_seen_result = new_result
		wheel.spin_to(new_result)
		wheel.spin_finished.connect(func():
			_push_history(new_result)
			betting_grid.flash_winning_number(new_result)
			_maybe_play_round_result_sfx()
		, CONNECT_ONE_SHOT)

# Ruleta es la única mesa sin un last_round expuesto hasta ahora — sin esto
# nunca sonaba nada al resolverse una apuesta, ni tampoco distinguía un
# premio grande (número exacto, pago 35 a 1) del resto.
func _maybe_play_round_result_sfx() -> void:
	if my_seat_index < 0 or my_seat_index >= _last_seats.size():
		return
	var seat = _last_seats[my_seat_index]
	if seat == null:
		return
	var last_round: Dictionary = seat.get("last_round", {})
	if last_round.is_empty():
		return
	if _last_round_seen.get(my_seat_index, {}) == last_round:
		return
	_last_round_seen[my_seat_index] = last_round
	AudioManager.play_win_sfx(last_round["win"], last_round.get("payout", 0), last_round.get("amount", 0))

func _set_betting_enabled(enabled: bool) -> void:
	bet_sidebar.bet_button.disabled = not enabled
	for button in betting_grid.find_children("*", "BaseButton", true, false):
		button.disabled = not enabled

func _push_history(result: int) -> void:
	_history.push_front(result)
	if _history.size() > MAX_HISTORY:
		_history.resize(MAX_HISTORY)
	for child in results_history.get_children():
		child.free()
	for i in range(_history.size()):
		var badge: RouletteResultBadge = RouletteResultBadgeScene.instantiate()
		results_history.add_child(badge)
		badge.number = _history[i]
		if i == 0:
			badge.pivot_offset = badge.size / 2.0
			badge.scale = Vector2.ZERO
			var tween := create_tween()
			tween.tween_property(badge, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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

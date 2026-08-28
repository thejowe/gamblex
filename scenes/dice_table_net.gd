extends Control

const RULES_TEXT := "Dice: elige un umbral y si el resultado (0-100) sera mayor o menor que ese umbral. Cuanto mas dificil el umbral que elijas, menor la probabilidad de acertar y mayor el multiplicador — la formula es 99 / probabilidad%, con el margen de la casa ya descontado. Aciertas: ganas tu apuesta multiplicada por ese factor. Fallas: pierdes la apuesta."

@onready var table_controller: DiceTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var over_button: Button = $OverButton
@onready var under_button: Button = $UnderButton
@onready var multiplier_label: Label = $MultiplierLabel
@onready var probability_label: Label = $ProbabilityLabel
@onready var threshold_slider: DiceThresholdSlider = $ThresholdSlider
@onready var result_flash: ColorRect = $ResultFlash
@onready var players_label: Label = $PlayersLabel
@onready var help_button: CasinoButton = $HelpButton
@onready var help_overlay: HelpOverlay = $HelpOverlay

var _last_players: Dictionary = {}
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
	help_button.pressed.connect(func(): help_overlay.set_rules_text(RULES_TEXT); help_overlay.open())
	threshold_slider.threshold_changed.connect(func(_value): _refresh_stats())
	over_button.pressed.connect(func(): _apply_direction(DiceTableState.Direction.OVER))
	under_button.pressed.connect(func(): _apply_direction(DiceTableState.Direction.UNDER))
	NetworkManager.identities_changed.connect(_refresh_players_label)
	_apply_direction(DiceTableState.Direction.UNDER)
	if not multiplayer.is_server():
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			bet_sidebar.bet_button.disabled = true
			multiplayer.connected_to_server.connect(func():
				bet_sidebar.bet_button.disabled = false
				table_controller.request_state()
			)
		else:
			table_controller.request_state()

func _apply_direction(new_direction: int) -> void:
	threshold_slider.direction = new_direction
	over_button.variant = CasinoButton.Variant.POSITIVE if new_direction == DiceTableState.Direction.OVER else CasinoButton.Variant.NEUTRAL
	under_button.variant = CasinoButton.Variant.POSITIVE if new_direction == DiceTableState.Direction.UNDER else CasinoButton.Variant.NEUTRAL
	_refresh_stats()

func _refresh_stats() -> void:
	var threshold := threshold_slider.threshold
	var direction := threshold_slider.direction
	var mult := DiceTableState.multiplier(threshold, direction)
	var chance := DiceTableState.win_chance(threshold, direction)
	multiplier_label.text = "Multiplicador: %.2fx" % mult
	probability_label.text = "Probabilidad: %.2f%%" % chance

func _on_bet_pressed(amount: int) -> void:
	table_controller.roll(threshold_slider.threshold, threshold_slider.direction, amount)

func _on_state_changed(state: Dictionary) -> void:
	_last_players = state["players"]
	_refresh_players_label()
	_maybe_flash_result()

func _maybe_flash_result() -> void:
	var my_id := multiplayer.get_unique_id()
	if not _last_players.has(my_id):
		return
	var last_round: Dictionary = _last_players[my_id]["last_round"]
	if last_round.is_empty():
		return
	if _last_round_seen.get(my_id, {}) == last_round:
		return
	_last_round_seen[my_id] = last_round
	var flash_color: Color = CasinoTheme.ACCENT_GREEN if last_round["win"] else CasinoTheme.ACCENT_RED
	var tween := create_tween()
	result_flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.35)
	tween.tween_property(result_flash, "color:a", 0.0, 0.6)

func _refresh_players_label() -> void:
	if _last_players.is_empty():
		players_label.text = "Nadie ha tirado todavía."
		return
	var lines: Array[String] = []
	for player_id in _last_players:
		var player = _last_players[player_id]
		var line := "%s — fichas %d" % [_display_name(player["player_id"]), player["balance"]]
		var last_round = player["last_round"]
		if not last_round.is_empty():
			var direction_text := "mayor que" if last_round["direction"] == DiceTableState.Direction.OVER else "menor que"
			var outcome_text := "ganó" if last_round["win"] else "perdió"
			line += " — última tirada %.2f (umbral %d %s, %s)" % [
				last_round["result"], last_round["threshold"], direction_text, outcome_text
			]
		lines.append(line)
	players_label.text = "\n".join(lines)

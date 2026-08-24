extends Control

@onready var table_controller: DiceTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var over_button: Button = $OverButton
@onready var under_button: Button = $UnderButton
@onready var multiplier_label: Label = $MultiplierLabel
@onready var probability_label: Label = $ProbabilityLabel
@onready var threshold_slider: DiceThresholdSlider = $ThresholdSlider
@onready var result_flash: ColorRect = $ResultFlash
@onready var players_label: Label = $PlayersLabel

var _last_players: Dictionary = {}

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	table_controller.state_changed.connect(_on_state_changed)
	NetworkManager.identities_changed.connect(_refresh_players_label)

func _on_state_changed(state: Dictionary) -> void:
	_last_players = state["players"]
	_refresh_players_label()

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

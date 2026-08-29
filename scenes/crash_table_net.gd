extends Control

const RULES_TEXT := "Crash: apuestas antes de que despegue el multiplicador. En cuanto empieza, sube en tiempo real desde 1.00x. Retira tus fichas cuando quieras para cobrar al multiplicador actual — pero el juego 'explota' en un punto aleatorio decidido al apostar, oculto hasta que ocurre. Si explota antes de que retires, pierdes toda la apuesta."

@onready var table_controller: CrashTableController = $TableController
@onready var bet_sidebar: BetSidebarPanel = $BetSidebarPanel
@onready var cash_out_button: CasinoButton = $CashOutButton
@onready var crash_graph: CrashGraph = $CrashGraph
@onready var players_label: Label = $PlayersLabel
@onready var help_button: CasinoButton = $HelpButton
@onready var help_overlay: HelpOverlay = $HelpOverlay

var _last_players: Dictionary = {}
var _local_elapsed: Dictionary = {} # player_id -> float, extrapolación local desde el último broadcast
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
	cash_out_button.pressed.connect(func(): table_controller.cash_out())
	help_button.pressed.connect(func(): help_overlay.set_rules_text(RULES_TEXT); help_overlay.open())
	NetworkManager.identities_changed.connect(_refresh_players_label)
	cash_out_button.disabled = true
	# Mismo gotcha que blackjack_table_net.gd/roulette_table_net.gd/dice_table_net.gd: un
	# cliente recién llegado a esta escena puede que aún no tenga el
	# SteamMultiplayerPeer en CONNECTED — bloquear la apuesta hasta entonces evita el
	# rpc_id() fallido.
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

func _on_bet_pressed(amount: int) -> void:
	table_controller.place_bet(amount)

func _process(delta: float) -> void:
	var any_active := false
	for player_id in _last_players:
		if _last_players[player_id]["is_active"]:
			_local_elapsed[player_id] = _local_elapsed.get(player_id, 0.0) + delta
			any_active = true
	if any_active:
		_refresh_players_label()
		_refresh_graph()

func _on_state_changed(state: Dictionary) -> void:
	_last_players = state["players"]
	for player_id in _last_players:
		_local_elapsed[player_id] = _last_players[player_id]["elapsed"]
	var my_id := multiplayer.get_unique_id()
	var mine: Dictionary = _last_players.get(my_id, {})
	var mine_active: bool = mine.get("is_active", false)
	cash_out_button.disabled = not mine_active
	if not (not multiplayer.is_server() and multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED):
		bet_sidebar.bet_button.disabled = mine_active
	_refresh_players_label()
	_refresh_graph()
	_maybe_flash_result(mine)

func _refresh_graph() -> void:
	var my_id := multiplayer.get_unique_id()
	var mine: Dictionary = _last_players.get(my_id, {})
	if mine.is_empty():
		crash_graph.state = CrashGraph.State.IDLE
		crash_graph.elapsed = 0.0
		return
	crash_graph.elapsed = _local_elapsed.get(my_id, mine["elapsed"])
	if mine["is_active"]:
		crash_graph.state = CrashGraph.State.RISING

func _maybe_flash_result(mine: Dictionary) -> void:
	if mine.is_empty():
		return
	var last_round: Dictionary = mine["last_round"]
	if last_round.is_empty():
		return
	var my_id := multiplayer.get_unique_id()
	if _last_round_seen.get(my_id, {}) == last_round:
		return
	_last_round_seen[my_id] = last_round
	crash_graph.state = CrashGraph.State.CASHED_OUT if last_round["win"] else CrashGraph.State.CRASHED
	AudioManager.play_win_sfx(last_round["win"], last_round.get("payout", 0), last_round.get("bet_amount", 0))

func _refresh_players_label() -> void:
	if _last_players.is_empty():
		players_label.text = "Nadie ha apostado todavía."
		return
	var lines: Array[String] = []
	for player_id in _last_players:
		var player = _last_players[player_id]
		var line := "%s — fichas %d" % [_display_name(player["player_id"]), player["balance"]]
		if player["is_active"]:
			var t: float = _local_elapsed.get(player_id, player["elapsed"])
			var current := CrashTableState.multiplier_at(t)
			line += " — en juego, multiplicador %.2fx" % current
		else:
			var last_round = player["last_round"]
			if not last_round.is_empty():
				if last_round["win"]:
					line += " — última ronda: retiró en %.2fx" % last_round["cashed_out_at"]
				else:
					line += " — última ronda: explotó en %.2fx" % last_round["crash_point"]
		lines.append(line)
	players_label.text = "\n".join(lines)

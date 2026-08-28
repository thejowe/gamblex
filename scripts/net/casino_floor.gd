extends Node2D

const GOAL_TARGET := 1000
const FREE_MODE_STARTING_BALANCE := 500
const BATTLE_GOAL_BALANCE := 2000
const BATTLE_TIME_LIMIT_SEC := 600.0
const BATTLE_STARTING_BALANCE := 500

const TABLE_NODE_NAMES := [
    "BlackjackTableNet",
    "RouletteTableNet",
    "PokerTableNet",
    "DiceTableNet",
    "CrashTableNet",
    "MinesTableNet",
    "PlinkoTableNet",
]

@onready var goal_label: Label = $Hud/GoalLabel
@onready var unlocked_banner: Label = $Hud/UnlockedBanner
@onready var defeat_overlay: Control = $Hud/DefeatOverlay
@onready var victory_overlay: Control = $Hud/VictoryOverlay
@onready var battle_controller: BattleController = $BattleController
@onready var battle_status_label: Label = $Hud/BattleStatusLabel
@onready var lobby_view: Control = $TablesLayer/Lobby
@onready var card_grid: GridContainer = $TablesLayer/Lobby/CardGrid
@onready var back_button: Button = $Hud/BackButton
@onready var exit_room_button: Button = $Hud/ExitRoomButton

var shared_pool_ledger: ChipLedger
var _pool_unlocked: bool = false
var _is_battle_mode: bool
var _teams_line: String = ""
var _state_line: String = ""

var _lobby := LobbyController.new()
var _table_nodes: Dictionary = {}

func _ready() -> void:
    for table_name in TABLE_NODE_NAMES:
        _table_nodes[table_name] = get_node("TablesLayer/" + table_name)
    for card in card_grid.get_children():
        if card is BaseButton:
            card.pressed.connect(_on_card_pressed.bind(card.name))
    back_button.pressed.connect(_on_back_pressed)
    exit_room_button.pressed.connect(_on_exit_room_pressed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    _refresh_room_visibility()

    _is_battle_mode = SteamManager.chosen_match_type != -1
    goal_label.visible = not _is_battle_mode
    unlocked_banner.visible = false
    battle_status_label.visible = _is_battle_mode
    if _is_battle_mode:
        battle_controller.teams_changed.connect(_on_teams_changed)
        battle_controller.match_state_changed.connect(_on_match_state_changed)
    if multiplayer.is_server():
        if _is_battle_mode:
            battle_controller.start_match(SteamManager.chosen_match_type, BATTLE_GOAL_BALANCE, BATTLE_TIME_LIMIT_SEC, BATTLE_STARTING_BALANCE)
            battle_controller.join(multiplayer.get_unique_id())
        else:
            shared_pool_ledger = ChipLedger.new(FREE_MODE_STARTING_BALANCE)
            _broadcast_goal_state()
        _inject_shared_ledger_providers()
    else:
        var peer := multiplayer.multiplayer_peer
        if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
            multiplayer.connected_to_server.connect(_on_connected_to_server)
        else:
            _on_connected_to_server()

func _on_connected_to_server() -> void:
    if _is_battle_mode:
        battle_controller.join(multiplayer.get_unique_id())
        battle_controller.request_state()
    else:
        request_goal_state()

func _ledger_for_player(player_id: int) -> ChipLedger:
    if _is_battle_mode:
        var team_id := battle_controller.team_for(player_id)
        if team_id == -1:
            return null
        return battle_controller.ledger_for_team(team_id)
    return shared_pool_ledger

const CONTROLLER_CLASS_NAMES := [
    "TableController", "RouletteTableController", "PokerTableController",
    "DiceTableController", "CrashTableController", "MinesTableController",
    "PlinkoTableController",
]

func _inject_shared_ledger_providers() -> void:
    for controller_class in CONTROLLER_CLASS_NAMES:
        for controller in find_children("*", controller_class, true, false):
            controller.shared_ledger_provider = _ledger_for_player
            if _is_battle_mode:
                controller.on_shared_ledger_changed = battle_controller.notify_balance_possibly_changed
            else:
                controller.on_shared_ledger_changed = _notify_free_mode_balance_changed

# El botón "Máx" del panel de apuesta usa `max_amount`, que si no se
# sincroniza aquí se queda pegado en el valor por defecto (500) en vez de
# reflejar cuántas fichas quedan de verdad en el pozo compartido/de equipo.
func _sync_bet_sidebars_max_amount(balance: int) -> void:
    for sidebar in find_children("*", "BetSidebarPanel", true, false):
        sidebar.set_max_amount(balance)

# ---- lobby: navegación local entre sala y mesas (sin red) ----

func _on_card_pressed(card_name: String) -> void:
    var table_name: String = card_name.replace("Card", "TableNet")
    if not _table_nodes.has(table_name):
        return
    _lobby.select(table_name)
    _refresh_room_visibility()
    AudioManager.play_music("table")

func _on_back_pressed() -> void:
    _lobby.return_to_lobby()
    _refresh_room_visibility()
    AudioManager.play_music("lobby")

func _on_exit_room_pressed() -> void:
    _leave_room("")

func _on_server_disconnected() -> void:
    _leave_room("El host cerró la sala.")

func _leave_room(reason: String) -> void:
    if multiplayer.multiplayer_peer != null:
        multiplayer.multiplayer_peer.close()
    if SteamManager.current_lobby_id > 0:
        Steam.leaveLobby(SteamManager.current_lobby_id)
    SteamManager.reset()
    NetworkManager.reset()
    SteamManager.last_disconnect_reason = reason
    get_tree().change_scene_to_file("res://scenes/lobby_menu.tscn")

func _refresh_room_visibility() -> void:
    lobby_view.visible = _lobby.is_in_lobby()
    back_button.visible = not _lobby.is_in_lobby()
    exit_room_button.visible = _lobby.is_in_lobby()
    for table_name in _table_nodes:
        _table_nodes[table_name].visible = _lobby.is_active(table_name)

# ---- modo libre: pozo compartido ----

func _set_pool_unlocked_if_reached_goal() -> void:
    if shared_pool_ledger.balance >= GOAL_TARGET:
        if not _pool_unlocked:
            SteamManager.unlock_achievement("FREE_MODE_GOAL_REACHED")
        _pool_unlocked = true

func _notify_free_mode_balance_changed() -> void:
    _set_pool_unlocked_if_reached_goal()
    _broadcast_goal_state()

func _goal_state_dict() -> Dictionary:
    return {
        "balance": shared_pool_ledger.balance,
        "target": GOAL_TARGET,
        "unlocked": _pool_unlocked,
        "bankrupt": shared_pool_ledger.is_bankrupt(),
    }

# Un cliente que entra a CasinoFloor después de que ya hubo apuestas no
# recibe nada por su cuenta: el host solo retransmite _receive_goal_state
# cuando el pozo cambia, nunca al conectar (mismo gotcha que
# TableController.request_state en Plan 3). Sin este pedido explícito el
# cliente se queda con el pozo en el balance inicial para siempre.
func request_goal_state() -> void:
    if multiplayer.is_server():
        return
    _request_goal_state.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_goal_state() -> void:
    if not multiplayer.is_server():
        return
    _receive_goal_state.rpc_id(multiplayer.get_remote_sender_id(), _goal_state_dict())

func _broadcast_goal_state() -> void:
    _receive_goal_state.rpc(_goal_state_dict())

@rpc("authority", "call_local", "reliable")
func _receive_goal_state(state: Dictionary) -> void:
    goal_label.text = "Meta colectiva: %d / %d fichas" % [state["balance"], state["target"]]
    unlocked_banner.visible = state["unlocked"]
    if state["bankrupt"]:
        _show_result_overlay(defeat_overlay, "PERDISTE", "el pozo compartido se agotó")
    else:
        defeat_overlay.visible = false
    _sync_bet_sidebars_max_amount(state["balance"])

# ---- modo batalla ----

func _on_teams_changed(teams: Array) -> void:
    _teams_line = "Equipo A: %s | Equipo B: %s" % [str(teams[0]), str(teams[1])]
    _refresh_battle_label()

func _on_match_state_changed(state: Dictionary) -> void:
    var msg := "Pozo A: %d | Pozo B: %d" % [state["pool_balances"][0], state["pool_balances"][1]]
    var my_team := battle_controller.team_for(multiplayer.get_unique_id())
    if state["finished"]:
        msg += " — FIN (equipo %d, %s)" % [state["winning_team"], state["reason"]]
        if my_team == state["winning_team"]:
            _show_result_overlay(victory_overlay, "¡GANASTE!", "Tu equipo ganó — %s" % _reason_label(state["reason"], true))
            SteamManager.unlock_achievement("BATTLE_MODE_WIN")
        elif my_team != -1:
            _show_result_overlay(defeat_overlay, "PERDISTE", "Tu equipo perdió — %s" % _reason_label(state["reason"], false))
    _state_line = msg
    _refresh_battle_label()
    if my_team != -1:
        _sync_bet_sidebars_max_amount(state["pool_balances"][my_team])

func _refresh_battle_label() -> void:
    battle_status_label.text = _teams_line + "\n" + _state_line

# ---- pantallas de resultado (victoria/derrota) ----

# Puede llegar más de una vez por RPCs de refresco mientras el estado sigue
# igual (bankrupt/finished en true) — solo mostramos/sonamos la primera vez
# que el overlay pasa de oculto a visible, nunca en cada refresco.
func _show_result_overlay(overlay: Control, title: String, message: String) -> void:
    if overlay.visible:
        return
    overlay.visible = true
    overlay.get_node("TitleLabel").text = title
    overlay.get_node("MessageLabel").text = message
    AudioManager.play_sfx("lose" if overlay == defeat_overlay else "win")
    if overlay == victory_overlay:
        _play_victory_pulse(overlay.get_node("Panel"))

func _reason_label(reason: String, i_won: bool) -> String:
    match reason:
        "goal_reached": return "tu equipo llegó antes a la meta" if i_won else "el equipo rival llegó antes a la meta"
        "bankrupt": return "el equipo rival se quedó sin fichas" if i_won else "tu equipo se quedó sin fichas"
        _: return reason

func _play_victory_pulse(panel: Control) -> void:
    var tween := create_tween().set_loops(3)
    tween.tween_property(panel, "modulate", CasinoTheme.GOLD_ACCENT, 0.3)
    tween.tween_property(panel, "modulate", Color.WHITE, 0.3)

extends Node2D

const GOAL_TARGET := 1000

@onready var goal_label: Label = $GoalLabel
@onready var unlocked_banner: Label = $UnlockedBanner

var goal: CollectiveGoal

func _ready() -> void:
    unlocked_banner.visible = false
    if multiplayer.is_server():
        goal = CollectiveGoal.new(GOAL_TARGET)
        for controller in find_children("*", "TableController", true, false):
            controller.chips_won.connect(_on_chips_won)
        _broadcast_goal_state()
    else:
        var peer := multiplayer.multiplayer_peer
        if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
            multiplayer.connected_to_server.connect(func(): request_goal_state())
        else:
            request_goal_state()

func _on_chips_won(_player_id: int, amount: int) -> void:
    goal.add_chips(amount)
    _broadcast_goal_state()

# Un cliente que entra a CasinoFloor después de que ya hubo ganancias no
# recibe nada por su cuenta: el host solo retransmite _receive_goal_state
# cuando el contador cambia, nunca al conectar (mismo gotcha que
# TableController.request_state en Plan 3). Sin este pedido explícito el
# cliente se queda con el contador en 0 para siempre.
func request_goal_state() -> void:
    if multiplayer.is_server():
        return
    _request_goal_state.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_goal_state() -> void:
    if not multiplayer.is_server():
        return
    _receive_goal_state.rpc_id(multiplayer.get_remote_sender_id(), goal.to_dict())

func _broadcast_goal_state() -> void:
    _receive_goal_state.rpc(goal.to_dict())

@rpc("authority", "call_local", "reliable")
func _receive_goal_state(state: Dictionary) -> void:
    goal_label.text = "Meta colectiva: %d / %d fichas" % [state["total"], state["target"]]
    unlocked_banner.visible = state["unlocked"]

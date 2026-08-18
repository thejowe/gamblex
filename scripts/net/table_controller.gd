class_name TableController
extends Node

signal state_changed(state: Dictionary)

var table_state: BlackjackTableState

func _ready() -> void:
    if multiplayer.is_server():
        table_state = BlackjackTableState.new()

@rpc("any_peer", "call_remote", "reliable")
func request_sit(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    var player_id := multiplayer.get_remote_sender_id()
    if table_state.sit(seat_index, player_id):
        _broadcast_state()

@rpc("any_peer", "call_remote", "reliable")
func request_bet(seat_index: int, amount: int) -> void:
    if not multiplayer.is_server():
        return
    var player_id := multiplayer.get_remote_sender_id()
    if table_state.place_bet(seat_index, player_id, amount):
        _broadcast_state()

@rpc("any_peer", "call_remote", "reliable")
func request_hit(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    var player_id := multiplayer.get_remote_sender_id()
    if table_state.hit(seat_index, player_id):
        _broadcast_state()

@rpc("any_peer", "call_remote", "reliable")
func request_stand(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    var player_id := multiplayer.get_remote_sender_id()
    if table_state.stand(seat_index, player_id):
        _broadcast_state()

func _broadcast_state() -> void:
    _receive_state.rpc(table_state.to_dict())

@rpc("authority", "call_local", "reliable")
func _receive_state(state: Dictionary) -> void:
    state_changed.emit(state)

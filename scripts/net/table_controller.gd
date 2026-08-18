class_name TableController
extends Node

signal state_changed(state: Dictionary)

var table_state: BlackjackTableState

func _ready() -> void:
    if multiplayer.is_server():
        table_state = BlackjackTableState.new()

# Puntos de entrada para la UI local (host o cliente). El host actúa directo
# sobre table_state; un rpc_id(1, ...) a sí mismo lo rechaza el MultiplayerAPI
# ("call_remote" no permite invocarse a uno mismo), así que el host no puede
# pasar por las RPCs request_* para sus propias acciones.
func sit(seat_index: int) -> void:
    if multiplayer.is_server():
        _apply_sit(seat_index, multiplayer.get_unique_id())
    else:
        print("TableController: cliente pide sentarse seat=%d (unique_id local=%d)" % [seat_index, multiplayer.get_unique_id()])
        request_sit.rpc_id(1, seat_index)

func bet(seat_index: int, amount: int) -> void:
    if multiplayer.is_server():
        _apply_bet(seat_index, amount, multiplayer.get_unique_id())
    else:
        print("TableController: cliente pide apostar seat=%d amount=%d" % [seat_index, amount])
        request_bet.rpc_id(1, seat_index, amount)

func hit(seat_index: int) -> void:
    if multiplayer.is_server():
        _apply_hit(seat_index, multiplayer.get_unique_id())
    else:
        request_hit.rpc_id(1, seat_index)

func stand(seat_index: int) -> void:
    if multiplayer.is_server():
        _apply_stand(seat_index, multiplayer.get_unique_id())
    else:
        request_stand.rpc_id(1, seat_index)

@rpc("any_peer", "call_remote", "reliable")
func request_sit(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    var sender_id := multiplayer.get_remote_sender_id()
    print("TableController: host recibió sentarse de peer=%d seat=%d" % [sender_id, seat_index])
    _apply_sit(seat_index, sender_id)

@rpc("any_peer", "call_remote", "reliable")
func request_bet(seat_index: int, amount: int) -> void:
    if not multiplayer.is_server():
        return
    var sender_id := multiplayer.get_remote_sender_id()
    print("TableController: host recibió apuesta de peer=%d seat=%d amount=%d" % [sender_id, seat_index, amount])
    _apply_bet(seat_index, amount, sender_id)

@rpc("any_peer", "call_remote", "reliable")
func request_hit(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    _apply_hit(seat_index, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func request_stand(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    _apply_stand(seat_index, multiplayer.get_remote_sender_id())

func _apply_sit(seat_index: int, player_id: int) -> void:
    var ok := table_state.sit(seat_index, player_id)
    print("TableController: sit seat=%d player=%d resultado=%s" % [seat_index, player_id, ok])
    if ok:
        _broadcast_state()

func _apply_bet(seat_index: int, amount: int, player_id: int) -> void:
    var ok := table_state.place_bet(seat_index, player_id, amount)
    print("TableController: place_bet seat=%d player=%d amount=%d resultado=%s" % [seat_index, player_id, amount, ok])
    if ok:
        _broadcast_state()

func _apply_hit(seat_index: int, player_id: int) -> void:
    if table_state.hit(seat_index, player_id):
        _broadcast_state()

func _apply_stand(seat_index: int, player_id: int) -> void:
    if table_state.stand(seat_index, player_id):
        _broadcast_state()

func _broadcast_state() -> void:
    _receive_state.rpc(table_state.to_dict())

@rpc("authority", "call_local", "reliable")
func _receive_state(state: Dictionary) -> void:
    print("TableController: _receive_state en peer local=%d, seats=%s" % [multiplayer.get_unique_id(), state["seats"]])
    state_changed.emit(state)

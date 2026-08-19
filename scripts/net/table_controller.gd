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
        request_sit.rpc_id(1, seat_index)

func bet(seat_index: int, amount: int) -> void:
    if multiplayer.is_server():
        _apply_bet(seat_index, amount, multiplayer.get_unique_id())
    else:
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

# Un cliente que entra a la mesa después de que ya hubo cambios (alguien
# sentado, apuestas hechas) no recibe nada por su cuenta: el host solo
# retransmite _receive_state cuando algo cambia, nunca al conectar. Sin este
# pedido explícito el cliente se queda con el estado en blanco para siempre.
func request_state() -> void:
    if multiplayer.is_server():
        return
    _request_state.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_state() -> void:
    if not multiplayer.is_server():
        return
    _receive_state.rpc_id(multiplayer.get_remote_sender_id(), table_state.to_dict())

@rpc("any_peer", "call_remote", "reliable")
func request_sit(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    _apply_sit(seat_index, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func request_bet(seat_index: int, amount: int) -> void:
    if not multiplayer.is_server():
        return
    _apply_bet(seat_index, amount, multiplayer.get_remote_sender_id())

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
    if table_state.sit(seat_index, player_id):
        _broadcast_state()

func _apply_bet(seat_index: int, amount: int, player_id: int) -> void:
    if table_state.place_bet(seat_index, player_id, amount):
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
    state_changed.emit(state)

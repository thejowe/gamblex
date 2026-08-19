class_name PokerTableController
extends Node

signal state_changed(state: Dictionary)

var table_state: PokerTableState

func _ready() -> void:
    if multiplayer.is_server():
        table_state = PokerTableState.new()

func sit(seat_index: int) -> void:
    if multiplayer.is_server():
        _apply_sit(seat_index, multiplayer.get_unique_id())
    else:
        request_sit.rpc_id(1, seat_index)

func start_hand() -> void:
    if multiplayer.is_server():
        _apply_start_hand()
    else:
        request_start_hand.rpc_id(1)

func fold(seat_index: int) -> void:
    if multiplayer.is_server():
        _apply_fold(seat_index, multiplayer.get_unique_id())
    else:
        request_fold.rpc_id(1, seat_index)

func check(seat_index: int) -> void:
    if multiplayer.is_server():
        _apply_check(seat_index, multiplayer.get_unique_id())
    else:
        request_check.rpc_id(1, seat_index)

func call_bet(seat_index: int) -> void:
    if multiplayer.is_server():
        _apply_call_bet(seat_index, multiplayer.get_unique_id())
    else:
        request_call_bet.rpc_id(1, seat_index)

func raise_bet(seat_index: int, raise_to: int) -> void:
    if multiplayer.is_server():
        _apply_raise(seat_index, raise_to, multiplayer.get_unique_id())
    else:
        request_raise.rpc_id(1, seat_index, raise_to)

func request_state() -> void:
    if multiplayer.is_server():
        return
    _request_state.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_state() -> void:
    if not multiplayer.is_server():
        return
    var requester_id := multiplayer.get_remote_sender_id()
    _receive_state.rpc_id(requester_id, table_state.to_dict(requester_id))

@rpc("any_peer", "call_remote", "reliable")
func request_sit(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    _apply_sit(seat_index, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func request_start_hand() -> void:
    if not multiplayer.is_server():
        return
    _apply_start_hand()

@rpc("any_peer", "call_remote", "reliable")
func request_fold(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    _apply_fold(seat_index, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func request_check(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    _apply_check(seat_index, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func request_call_bet(seat_index: int) -> void:
    if not multiplayer.is_server():
        return
    _apply_call_bet(seat_index, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func request_raise(seat_index: int, raise_to: int) -> void:
    if not multiplayer.is_server():
        return
    _apply_raise(seat_index, raise_to, multiplayer.get_remote_sender_id())

func _apply_sit(seat_index: int, player_id: int) -> void:
    if table_state.sit(seat_index, player_id):
        _broadcast_state()

func _apply_start_hand() -> void:
    if table_state.start_hand():
        _broadcast_state()

func _apply_fold(seat_index: int, player_id: int) -> void:
    if table_state.fold(seat_index, player_id):
        _broadcast_state()

func _apply_check(seat_index: int, player_id: int) -> void:
    if table_state.check(seat_index, player_id):
        _broadcast_state()

func _apply_call_bet(seat_index: int, player_id: int) -> void:
    if table_state.call_bet(seat_index, player_id):
        _broadcast_state()

func _apply_raise(seat_index: int, raise_to: int, player_id: int) -> void:
    if table_state.raise_bet(seat_index, player_id, raise_to):
        _broadcast_state()

# A diferencia de TableController de Blackjack (que retransmite el mismo
# Dictionary a todos con un unico .rpc()), en Poker cada asiento tiene cartas
# ocultas: el host construye un Dictionary distinto por jugador
# (to_dict(viewer_id), Task 6) y lo manda con rpc_id a cada peer por
# separado. El propio host se actualiza emitiendo la senal directo, sin pasar
# por RPC (mismo motivo que el wrapper de sit/fold/etc. — un rpc_id(1, ...)
# contra uno mismo falla).
func _broadcast_state() -> void:
    state_changed.emit(table_state.to_dict(multiplayer.get_unique_id()))
    for peer_id in multiplayer.get_peers():
        _receive_state.rpc_id(peer_id, table_state.to_dict(peer_id))

@rpc("authority", "call_remote", "reliable")
func _receive_state(state: Dictionary) -> void:
    state_changed.emit(state)

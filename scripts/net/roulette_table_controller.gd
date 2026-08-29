class_name RouletteTableController
extends Node

signal state_changed(state: Dictionary)

var table_state: RouletteTableState
var shared_ledger_provider: Callable = Callable()
var on_shared_ledger_changed: Callable = Callable()

func _ready() -> void:
    if multiplayer.is_server():
        table_state = RouletteTableState.new()

# Solo el host hace avanzar el temporizador de ronda -- es la única
# autoridad sobre cuándo cierra la mesa a apuestas y gira sola. Mismo
# patrón que CrashTableController: solo se retransmite el estado cuando la
# fase acaba de cambiar (BETTING->RESULT o RESULT->BETTING), no cada frame.
func _process(delta: float) -> void:
    if table_state == null or not multiplayer.is_server():
        return
    if table_state.advance_time(delta):
        _broadcast_state()

# Puntos de entrada para la UI local (host o cliente). El host actúa directo
# sobre table_state; un rpc_id(1, ...) a sí mismo lo rechaza el MultiplayerAPI
# ("call_remote" no permite invocarse a uno mismo), así que el host no puede
# pasar por las RPCs request_* para sus propias acciones.
func sit(seat_index: int) -> void:
    if multiplayer.is_server():
        _apply_sit(seat_index, multiplayer.get_unique_id())
    else:
        request_sit.rpc_id(1, seat_index)

func place_bet(seat_index: int, bet_type: int, number: int, amount: int) -> void:
    if multiplayer.is_server():
        _apply_bet(seat_index, bet_type, number, amount, multiplayer.get_unique_id())
    else:
        request_bet.rpc_id(1, seat_index, bet_type, number, amount)

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
func request_bet(seat_index: int, bet_type: int, number: int, amount: int) -> void:
    if not multiplayer.is_server():
        return
    _apply_bet(seat_index, bet_type, number, amount, multiplayer.get_remote_sender_id())

func _apply_sit(seat_index: int, player_id: int) -> void:
    var external_ledger: ChipLedger = shared_ledger_provider.call(player_id) if shared_ledger_provider.is_valid() else null
    if table_state.sit(seat_index, player_id, external_ledger):
        _broadcast_state()

func _apply_bet(seat_index: int, bet_type: int, number: int, amount: int, player_id: int) -> void:
    if table_state.place_bet(seat_index, player_id, bet_type, number, amount):
        _broadcast_state()

func _broadcast_state() -> void:
    _receive_state.rpc(table_state.to_dict())
    if on_shared_ledger_changed.is_valid():
        on_shared_ledger_changed.call()

@rpc("authority", "call_local", "reliable")
func _receive_state(state: Dictionary) -> void:
    state_changed.emit(state)

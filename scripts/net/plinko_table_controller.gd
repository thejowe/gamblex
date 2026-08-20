class_name PlinkoTableController
extends Node

signal state_changed(state: Dictionary)
signal chips_won(player_id: int, amount: int)

var table_state: PlinkoTableState

func _ready() -> void:
	if multiplayer.is_server():
		table_state = PlinkoTableState.new()
		table_state.chips_won.connect(_on_table_chips_won)

# Puntos de entrada para la UI local (host o cliente). El host actúa directo
# sobre table_state; un rpc_id(1, ...) a sí mismo lo rechaza el MultiplayerAPI
# ("call_remote" no permite invocarse a uno mismo), así que el host no puede
# pasar por las RPCs request_* para sus propias acciones.
func roll(rows: int, amount: int) -> void:
	if multiplayer.is_server():
		_apply_roll(rows, amount, multiplayer.get_unique_id())
	else:
		request_roll.rpc_id(1, rows, amount)

# Un cliente que entra a la mesa después de que ya hubo tiradas no recibe
# nada por su cuenta: el host solo retransmite _receive_state cuando algo
# cambia, nunca al conectar (mismo gotcha que TableController.request_state
# en Plan 3). Sin este pedido explícito el cliente se queda con el estado en
# blanco para siempre.
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
func request_roll(rows: int, amount: int) -> void:
	if not multiplayer.is_server():
		return
	_apply_roll(rows, amount, multiplayer.get_remote_sender_id())

func _apply_roll(rows: int, amount: int, player_id: int) -> void:
	if table_state.roll(player_id, rows, amount):
		_broadcast_state()

func _broadcast_state() -> void:
	_receive_state.rpc(table_state.to_dict())

# Broadcast a TODOS los presentes en CasinoFloor, no solo a quien tiró — la
# spec pide visibilidad compartida de las rondas de los demás aunque nadie
# más participe en ellas.
@rpc("authority", "call_local", "reliable")
func _receive_state(state: Dictionary) -> void:
	state_changed.emit(state)

func _on_table_chips_won(player_id: int, amount: int) -> void:
	chips_won.emit(player_id, amount)

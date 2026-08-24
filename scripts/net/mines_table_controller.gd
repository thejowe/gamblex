class_name MinesTableController
extends Node

signal state_changed(state: Dictionary)
signal chips_won(player_id: int, amount: int)

var table_state: MinesTableState
var shared_ledger_provider: Callable = Callable()
var on_shared_ledger_changed: Callable = Callable()

func _ready() -> void:
	if multiplayer.is_server():
		table_state = MinesTableState.new()
		table_state.chips_won.connect(_on_table_chips_won)

# Puntos de entrada para la UI local (host o cliente). El host actúa directo
# sobre table_state; un rpc_id(1, ...) a sí mismo lo rechaza el MultiplayerAPI
# ("call_remote" no permite invocarse a uno mismo), así que el host no puede
# pasar por las RPCs request_* para sus propias acciones. Mismo patrón que
# DiceTableController, con tres acciones en vez de una porque la ronda de
# Mines es multi-paso.
func start_round(total_cells: int, mine_count: int, amount: int) -> void:
	if multiplayer.is_server():
		_apply_start_round(total_cells, mine_count, amount, multiplayer.get_unique_id())
	else:
		request_start_round.rpc_id(1, total_cells, mine_count, amount)

func reveal(index: int) -> void:
	if multiplayer.is_server():
		_apply_reveal(index, multiplayer.get_unique_id())
	else:
		request_reveal.rpc_id(1, index)

func cash_out() -> void:
	if multiplayer.is_server():
		_apply_cash_out(multiplayer.get_unique_id())
	else:
		request_cash_out.rpc_id(1)

# Un cliente que entra a la mesa después de que ya hubo rondas no recibe
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
func request_start_round(total_cells: int, mine_count: int, amount: int) -> void:
	if not multiplayer.is_server():
		return
	_apply_start_round(total_cells, mine_count, amount, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func request_reveal(index: int) -> void:
	if not multiplayer.is_server():
		return
	_apply_reveal(index, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func request_cash_out() -> void:
	if not multiplayer.is_server():
		return
	_apply_cash_out(multiplayer.get_remote_sender_id())

func _apply_start_round(total_cells: int, mine_count: int, amount: int, player_id: int) -> void:
	var external_ledger: ChipLedger = shared_ledger_provider.call(player_id) if shared_ledger_provider.is_valid() else null
	if table_state.start_round(player_id, total_cells, mine_count, amount, external_ledger):
		_broadcast_state()

func _apply_reveal(index: int, player_id: int) -> void:
	if table_state.reveal(player_id, index):
		_broadcast_state()

func _apply_cash_out(player_id: int) -> void:
	if table_state.cash_out(player_id):
		_broadcast_state()

func _broadcast_state() -> void:
	_receive_state.rpc(table_state.to_dict())
	if on_shared_ledger_changed.is_valid():
		on_shared_ledger_changed.call()

# Broadcast a TODOS los presentes en CasinoFloor, no solo a quien jugó — la
# spec pide visibilidad compartida de las rondas de los demás aunque nadie
# más participe en ellas. La única información que nunca llega por aquí
# mientras la ronda sigue activa son las posiciones de las minas — eso lo
# garantiza table_state.to_dict(), no este controlador.
@rpc("authority", "call_local", "reliable")
func _receive_state(state: Dictionary) -> void:
	state_changed.emit(state)

func _on_table_chips_won(player_id: int, amount: int) -> void:
	chips_won.emit(player_id, amount)

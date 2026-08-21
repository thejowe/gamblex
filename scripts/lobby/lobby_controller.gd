class_name LobbyController
extends RefCounted

var _active_id: String = ""

func is_in_lobby() -> bool:
    return _active_id == ""

func select(id: String) -> void:
    _active_id = id

func return_to_lobby() -> void:
    _active_id = ""

func is_active(id: String) -> bool:
    return not is_in_lobby() and _active_id == id

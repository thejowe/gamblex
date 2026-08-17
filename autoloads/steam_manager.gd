extends Node

signal steam_ready(success: bool)

var steam_id: int = 0
var steam_username: String = ""

func _ready() -> void:
	var init_result: Dictionary = Steam.steamInitEx()
	var ok: bool = init_result["status"] == 0
	if not ok:
		push_error("Steam init failed (%d): %s" % [init_result["status"], init_result["verbal"]])
	else:
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()
		print("Steam initialized OK for user: %s (%d)" % [steam_username, steam_id])
	steam_ready.emit(ok)

func _process(_delta: float) -> void:
	Steam.run_callbacks()

extends Node

const BUS_NAMES := ["Master", "Music", "SFX"]
const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	_ensure_buses()
	_load_settings()

func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

func set_bus_volume_db(bus_name: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("AudioManager: bus desconocido '%s'" % bus_name)
		return
	AudioServer.set_bus_volume_db(idx, db)
	_save_settings()

func get_bus_volume_db(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 0.0
	return AudioServer.get_bus_volume_db(idx)

func set_bus_mute(bus_name: String, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, muted)
	_save_settings()

func is_bus_muted(bus_name: String) -> bool:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return false
	return AudioServer.is_bus_mute(idx)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	for bus_name in BUS_NAMES:
		cfg.set_value("audio", bus_name.to_lower() + "_db", get_bus_volume_db(bus_name))
		cfg.set_value("audio", bus_name.to_lower() + "_muted", is_bus_muted(bus_name))
	cfg.save(SETTINGS_PATH)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for bus_name in BUS_NAMES:
		var db: float = cfg.get_value("audio", bus_name.to_lower() + "_db", get_bus_volume_db(bus_name))
		var muted: bool = cfg.get_value("audio", bus_name.to_lower() + "_muted", false)
		var idx := AudioServer.get_bus_index(bus_name)
		if idx != -1:
			AudioServer.set_bus_volume_db(idx, db)
			AudioServer.set_bus_mute(idx, muted)

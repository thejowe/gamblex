extends Node

const BUS_NAMES := ["Master", "Music", "SFX"]
const SETTINGS_PATH := "user://settings.cfg"

const SFX_MIX_RATE := 44100.0
const SFX_POOL_SIZE := 6
const SFX_FREQUENCIES := {
	"click": 880.0, "chip": 660.0, "card": 990.0,
	"dice": 440.0, "spin": 523.0, "win": 784.0, "lose": 220.0,
}
const SFX_DURATION := {
	"win": 0.5, "lose": 0.6,
}

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_next := 0

func _ready() -> void:
	_ensure_buses()
	_load_settings()
	_build_sfx_pool()

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

func _build_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = SFX_MIX_RATE
		gen.buffer_length = 0.7
		player.stream = gen
		add_child(player)
		_sfx_pool.append(player)

func play_sfx(sfx_name: String) -> void:
	if not SFX_FREQUENCIES.has(sfx_name):
		push_warning("AudioManager: SFX desconocido '%s'" % sfx_name)
		return
	var player := _sfx_pool[_sfx_pool_next]
	_sfx_pool_next = (_sfx_pool_next + 1) % _sfx_pool.size()
	player.play()
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	if playback == null:
		return
	_fill_tone(playback, SFX_FREQUENCIES[sfx_name], SFX_DURATION.get(sfx_name, 0.15), SFX_MIX_RATE)

func _fill_tone(playback: AudioStreamGeneratorPlayback, freq: float, duration: float, mix_rate: float) -> void:
	var total_frames := int(mix_rate * duration)
	var frames_written := 0
	var phase := 0.0
	var increment := freq / mix_rate
	while frames_written < total_frames and playback.get_frames_available() > 0:
		var t := float(frames_written) / float(total_frames)
		var envelope := 1.0 if t < 0.1 else clampf(1.0 - (t - 0.1) / 0.9, 0.0, 1.0)
		var sample := sin(phase * TAU) * envelope * 0.4
		playback.push_frame(Vector2(sample, sample))
		phase = fmod(phase + increment, 1.0)
		frames_written += 1

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

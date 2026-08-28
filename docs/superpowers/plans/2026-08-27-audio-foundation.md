# Plan: fundación de audio (música + SFX) — Agente 25

Lee primero `docs/superpowers/specs/2026-08-27-audio-foundation-design.md`
— este plan lo implementa tal cual, no repitas el porqué de las
decisiones, solo el cómo. TDD: test antes que implementación en cada
tarea, `godot --headless --editor --quit --path .` para reconstruir la
caché de clases tras crear `AudioManager` (tiene `class_name` implícito
por ser autoload, pero cualquier `class_name` que uses en scripts nuevos
sí lo necesita) antes de correr GUT.

## Tarea 1 — `AudioManager` esqueleto + buses de audio

**Test primero** (`tests/unit/test_audio_manager.gd`):

```gdscript
extends GutTest

func test_three_buses_exist() -> void:
	assert_ne(AudioServer.get_bus_index("Music"), -1)
	assert_ne(AudioServer.get_bus_index("SFX"), -1)
	assert_ne(AudioServer.get_bus_index("Master"), -1)

func test_default_volumes_are_audible() -> void:
	assert_gt(AudioManager.get_bus_volume_db("Master"), -80.0)
	assert_gt(AudioManager.get_bus_volume_db("Music"), -80.0)
	assert_gt(AudioManager.get_bus_volume_db("SFX"), -80.0)
```

**Implementación** (`autoloads/audio_manager.gd`):

```gdscript
extends Node

const BUS_NAMES := ["Master", "Music", "SFX"]

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
```

`add_bus()` añade al final con volumen 0dB (audible) por defecto — no
hace falta fijar volumen inicial explícito salvo que quieras uno
distinto de 0dB. Verifica el nombre exacto de estas llamadas
(`AudioServer.add_bus`, `set_bus_name`, `set_bus_send`,
`set_bus_volume_db`, `get_bus_volume_db`, `set_bus_mute`, `is_bus_mute`)
contra la documentación de Godot 4.7 antes de dar la tarea por cerrada —
son API core estable, pero confírmalo tú mismo, no asumas que este plan
las tiene perfectas.

## Tarea 2 — persistencia de volumen (`user://settings.cfg`, sección `[audio]`)

**Test primero:**

```gdscript
func test_volume_persists_across_reload() -> void:
	AudioManager.set_bus_volume_db("Music", -12.0)
	AudioManager._save_settings()
	AudioManager._load_settings()  # simula relanzar el juego
	assert_almost_eq(AudioManager.get_bus_volume_db("Music"), -12.0, 0.01)
```

**Implementación**, añadido a `audio_manager.gd`:

```gdscript
const SETTINGS_PATH := "user://settings.cfg"

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # conserva otras secciones (p.ej. [display] de plan29)
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
```

`cfg.load(SETTINGS_PATH)` dentro de `_save_settings()` antes de escribir
es importante: sin eso, guardar audio pisaría cualquier sección
`[display]` que plan29 ya hubiera guardado. Test de convivencia
(opcional pero recomendado): guarda una clave falsa en `[display]` a
mano con `ConfigFile`, llama `_save_settings()`, confirma que la clave de
`[display]` sigue ahí después.

## Tarea 3 — SFX proceduales

**Test primero:**

```gdscript
func test_play_sfx_known_name_no_error() -> void:
	AudioManager.play_sfx("click")
	AudioManager.play_sfx("chip")
	AudioManager.play_sfx("card")
	AudioManager.play_sfx("dice")
	AudioManager.play_sfx("spin")
	AudioManager.play_sfx("win")
	AudioManager.play_sfx("lose")
	pass_test("no crashea con ningún nombre válido")

func test_play_sfx_unknown_name_warns_no_crash() -> void:
	AudioManager.play_sfx("nombre_inventado")
	pass_test("no crashea con nombre desconocido")
```

**Implementación** — un pool pequeño de `AudioStreamPlayer` (polifonía,
para que dos SFX solapados no se corten uno a otro) con
`AudioStreamGenerator` cada uno, generando un tono corto con envolvente:

```gdscript
const SFX_POOL_SIZE := 6
const SFX_FREQUENCIES := {
	"click": 880.0, "chip": 660.0, "card": 990.0,
	"dice": 440.0, "spin": 523.0, "win": 784.0, "lose": 220.0,
}
const SFX_DURATION := {
	"win": 0.5, "lose": 0.6,
}  # default 0.15s si no está en este diccionario

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_next := 0

func _ready() -> void:
	_ensure_buses()
	_load_settings()
	_build_sfx_pool()

func _build_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = 44100.0
		gen.buffer_length = 0.3
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
	_fill_tone(playback, SFX_FREQUENCIES[sfx_name], SFX_DURATION.get(sfx_name, 0.15), gen.mix_rate)

func _fill_tone(playback: AudioStreamGeneratorPlayback, freq: float, duration: float, mix_rate: float) -> void:
	var total_frames := int(mix_rate * duration)
	var frames_written := 0
	var phase := 0.0
	var increment := freq / mix_rate
	while frames_written < total_frames and playback.get_frames_available() > 0:
		var t := float(frames_written) / float(total_frames)
		var envelope := 1.0 if t < 0.1 else clampf(1.0 - (t - 0.1) / 0.9, 0.0, 1.0)  # ataque instantáneo, decay lineal
		var sample := sin(phase * TAU) * envelope * 0.4
		playback.push_frame(Vector2(sample, sample))
		phase = fmod(phase + increment, 1.0)
		frames_written += 1
```

Nota de implementación: `gen.mix_rate` en `play_sfx` se refiere a la
variable local `gen` de `_build_sfx_pool`, que no existe en el scope de
`play_sfx` — guarda el `AudioStreamGenerator` de cada player (o su
`mix_rate`, que siempre es 44100.0 fijo aquí) en vez de reusar la
variable de otro método; ajusta al escribir el código real, esto es guía
de forma/API, no un diff para copiar-pegar literal. Si `buffer_length`
de 0.3s se queda corto para el SFX de 0.5-0.6s, súbelo a 0.7 en el
generador.

Timbre por SFX (ajustable a tu criterio, no hace falta que sea exacto):
tono simple (seno) para la mayoría; considera un "blip" de dos tonos
rápidos para "win" (ánimo) y un tono descendente para "lose" (glissando:
interpolar `freq` de alto a bajo dentro de `_fill_tone` si quieres algo
más expresivo que un seno plano — opcional, no bloqueante).

## Tarea 4 — música procedural con crossfade

**Test primero:**

```gdscript
func test_play_music_no_error() -> void:
	AudioManager.play_music("lobby")
	AudioManager.play_music("table")
	pass_test("no crashea")

func test_play_music_same_track_is_noop() -> void:
	AudioManager.play_music("lobby")
	var player_before := AudioManager._current_music_player
	AudioManager.play_music("lobby")
	assert_eq(AudioManager._current_music_player, player_before)
```

**Implementación**: dos `AudioStreamPlayer` en bus `"Music"` (para poder
cruzar volumen entre el que sale y el que entra), cada uno con su propio
`AudioStreamGenerator` largo (`buffer_length` alto, p.ej. 2.0s, relleno
en `_process()` mientras `get_frames_available() > 0` — no de una sola
vez como el SFX corto, porque un loop debe generarse de forma continua
mientras suena). Patrón sugerido: arpegio simple de 3-4 notas
repitiéndose (p.ej. acorde mayor: fundamental, tercera, quinta) con
volumen bajo (`-18dB` aprox., dentro del bus `Music`, no compite con
SFX). "table" puede ser el mismo patrón con notas distintas o tempo
distinto — no hace falta gran composición, es relleno ambiental.

```gdscript
var _current_music_player: AudioStreamPlayer = null
var _current_track_name := ""

func play_music(track_name: String, fade_in_sec: float = 1.0) -> void:
	if track_name == _current_track_name:
		return
	# fade out del anterior, fade in del nuevo, swap de referencia
	...
	_current_track_name = track_name

func stop_music(fade_out_sec: float = 1.0) -> void:
	...
```

Implementa el crossfade con `create_tween().tween_property(player,
"volume_db", ...)` (patrón ya usado en el proyecto, ver
`casino_button.gd` para el estilo de tween). El relleno continuo del
buffer del `AudioStreamGenerator` de música necesita un `_process(delta)`
en `AudioManager` que, si hay un player de música activo, siga
empujando frames mientras `get_frames_available() > 0` — factorízalo en
un método propio, reutilizado por ambos players de música.

## Tarea 5 — enganche de "click" en `CasinoButton`

**Test primero** (`tests/unit/test_casino_button.gd`, añade si no existe
ya un test de este archivo — revisa antes de crear uno nuevo):

```gdscript
func test_press_plays_click_sfx() -> void:
	# si AudioManager.play_sfx no es fácilmente espiable, verifica al menos
	# que _on_press() no lanza error al llamarlo con AudioManager real
	# (autoload disponible en cualquier test GUT del proyecto)
	var button := CasinoButton.new()
	add_child_autofree(button)
	button._on_press()
	pass_test("no crashea al reproducir click")
```

**Implementación**, una línea en `scripts/ui/casino/casino_button.gd`,
dentro de `_on_press()`:

```gdscript
func _on_press() -> void:
	AudioManager.play_sfx("click")
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
```

## Tarea 6 — enganche de música en `LobbyMenu` y `CasinoFloor`

- `scenes/lobby_menu.gd`, al final de `_ready()`:
  `AudioManager.play_music("lobby")`.
- `scripts/net/casino_floor.gd`: al entrar a una mesa (donde ya exista la
  lógica de "sala aislada" de Plan 12 — busca el método que oculta el
  lobby y muestra la mesa elegida), `AudioManager.play_music("table")`;
  al volver a la rejilla de 7 tarjetas, `AudioManager.play_music("lobby")`.
  Revisa el nombre exacto de esos métodos en el archivo real antes de
  añadir la llamada — no está documentado en este plan porque
  `casino_floor.gd` ha cambiado mucho entre agentes, lee el archivo tal
  como está hoy.

**No toques** `defeat_overlay`/`_on_match_state_changed`/goal de
victoria — eso es de plan26, que llamará `AudioManager.play_sfx("win"/
"lose")` por su cuenta una vez esta rama esté en `main`.

## Tarea 7 — hooks de SFX de eventos de mesa (opcional si el tiempo aprieta, no bloqueante)

Uno o dos SFX más allá del click son suficientes para "sentirse vivo" —
si el tiempo aprieta, prioriza click+ficha+música por encima de cubrir
las 7 mesas una por una. Sugerencias de dónde enganchar si tienes tiempo:

- `bet_sidebar_panel.gd`, señal `bet_pressed` → `AudioManager.play_sfx("chip")`.
- `roulette_wheel_display.gd::spin_to()` → `AudioManager.play_sfx("spin")`
  al empezar a girar.
- `dice_threshold_slider.gd` o donde Dice resuelve la tirada →
  `AudioManager.play_sfx("dice")`.
- Reparto de carta en Blackjack/Póker (busca la animación de reparto de
  Plan 14) → `AudioManager.play_sfx("card")`.

No inventes nombres de señales/funciones que no existan — lee el archivo
real de cada mesa antes de engancharte a él.

## Reporte final a pilar

Al terminar: rama, commits, `X/X tests` tras reconstruir caché de clases,
qué SFX/música quedaron enganchados de verdad (Tarea 7 es best-effort,
di explícitamente qué cubriste y qué no), y confirma que
`AudioManager.play_sfx`/`play_music`/`set_bus_volume_db`/
`get_bus_volume_db`/`set_bus_mute`/`is_bus_muted` existen con esos
nombres exactos — plan26 a plan30 dependen de ese contrato literal.

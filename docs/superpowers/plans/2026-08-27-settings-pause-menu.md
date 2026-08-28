# Plan: pantalla de ajustes + menú de pausa — Agente 29

Lee primero `docs/superpowers/specs/2026-08-27-settings-pause-menu-design.md`
— este plan lo implementa tal cual. TDD: test antes que implementación en
cada tarea. Reconstruye la caché de clases
(`godot --headless --editor --quit --path .`) tras crear los `class_name`
nuevos, antes de correr GUT.

**No arranques esta implementación hasta que `plan25-audio-foundation`
esté mergeado a `main`** (necesitas `AudioManager` real, no un stub).

## Tarea 1 — `SettingsMenu`: sliders de volumen

**Test primero** (`tests/unit/test_settings_menu.gd`):

```gdscript
extends GutTest

func test_volume_slider_calls_audio_manager() -> void:
	var menu := preload("res://scenes/ui/casino/settings_menu.tscn").instantiate()
	add_child_autofree(menu)
	menu.music_slider.value = -12.0
	menu._on_music_slider_changed(-12.0)
	assert_almost_eq(AudioManager.get_bus_volume_db("Music"), -12.0, 0.01)

func test_slider_initializes_from_current_volume() -> void:
	AudioManager.set_bus_volume_db("SFX", -8.0)
	var menu := preload("res://scenes/ui/casino/settings_menu.tscn").instantiate()
	add_child_autofree(menu)
	assert_almost_eq(menu.sfx_slider.value, -8.0, 0.01)
```

**Implementación** (`scripts/ui/casino/settings_menu.gd` +
`scenes/ui/casino/settings_menu.tscn`):

```gdscript
extends Control

const MIN_DB := -40.0
const MAX_DB := 0.0

@onready var master_slider: HSlider = $Panel/VBox/MasterSlider
@onready var music_slider: HSlider = $Panel/VBox/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBox/SfxSlider
@onready var master_mute: CheckBox = $Panel/VBox/MasterMute
@onready var music_mute: CheckBox = $Panel/VBox/MusicMute
@onready var sfx_mute: CheckBox = $Panel/VBox/SfxMute
@onready var fullscreen_toggle: CheckBox = $Panel/VBox/FullscreenToggle
@onready name close_button: CasinoButton = $Panel/VBox/CloseButton
@onready var quit_button: CasinoButton = $Panel/VBox/QuitButton
@onready var quit_confirm: ConfirmationDialog = $QuitConfirm

func _ready() -> void:
	for s in [master_slider, music_slider, sfx_slider]:
		s.min_value = MIN_DB
		s.max_value = MAX_DB
	master_slider.value = AudioManager.get_bus_volume_db("Master")
	music_slider.value = AudioManager.get_bus_volume_db("Music")
	sfx_slider.value = AudioManager.get_bus_volume_db("SFX")
	master_mute.button_pressed = AudioManager.is_bus_muted("Master")
	music_mute.button_pressed = AudioManager.is_bus_muted("Music")
	sfx_mute.button_pressed = AudioManager.is_bus_muted("SFX")
	fullscreen_toggle.button_pressed = get_window().mode == Window.MODE_FULLSCREEN
	master_slider.value_changed.connect(func(v): AudioManager.set_bus_volume_db("Master", v))
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(func(v): AudioManager.set_bus_volume_db("SFX", v))
	master_mute.toggled.connect(func(on): AudioManager.set_bus_mute("Master", on))
	music_mute.toggled.connect(func(on): AudioManager.set_bus_mute("Music", on))
	sfx_mute.toggled.connect(func(on): AudioManager.set_bus_mute("SFX", on))
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	close_button.pressed.connect(func(): visible = false)
	quit_button.pressed.connect(quit_confirm.popup_centered)
	quit_confirm.confirmed.connect(func(): get_tree().quit())

func _on_music_slider_changed(v: float) -> void:
	AudioManager.set_bus_volume_db("Music", v)
```

Corrige el typo `@onready name` → `@onready var` al escribir el código
real (dejado a propósito en este plan, no lo copies literal). Los nodos
`Panel/VBox/...` son un layout de ejemplo — usa la jerarquía real que
construyas en el `.tscn`, ajusta los `@onready` a tus rutas reales.

## Tarea 2 — persistencia `[display]` en `user://settings.cfg`

**Test primero:**

```gdscript
func test_fullscreen_preference_persists() -> void:
	var menu := preload("res://scenes/ui/casino/settings_menu.tscn").instantiate()
	add_child_autofree(menu)
	menu._on_fullscreen_toggled(true)
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	assert_true(cfg.get_value("display", "fullscreen", false))
```

**Implementación:**

```gdscript
func _on_fullscreen_toggled(on: bool) -> void:
	get_window().mode = Window.MODE_FULLSCREEN if on else Window.MODE_WINDOWED
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")  # conserva la sección [audio] de AudioManager
	cfg.set_value("display", "fullscreen", on)
	cfg.save("user://settings.cfg")
```

Y en `scenes/lobby_menu.gd::_ready()`, aplica la preferencia guardada al
arrancar (antes de que el jugador abra Ajustes):

```gdscript
func _apply_saved_display_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK:
		return
	var fullscreen: bool = cfg.get_value("display", "fullscreen", true)  # true = coincide con el default actual del proyecto
	get_window().mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
```

## Tarea 3 — botón "Ajustes" en `LobbyMenu`

**Test primero** (`tests/unit/test_lobby_menu.gd`, añade si el archivo
ya existe — revisa antes de crear uno duplicado):

```gdscript
func test_settings_button_opens_settings_menu() -> void:
	var lobby := preload("res://scenes/lobby_menu.tscn").instantiate()
	add_child_autofree(lobby)
	lobby.settings_button.pressed.emit()
	assert_true(lobby.settings_menu.visible)
```

**Implementación**: botón `CasinoButton` nuevo junto a
`create_button`/`invite_button`/`cancel_button`, instancia
`SettingsMenu` como hijo oculto por defecto, `pressed.connect(func():
settings_menu.visible = true)`.

## Tarea 4 — `PauseMenu`: activación con ESC (`ui_cancel`)

**Test primero:**

```gdscript
func test_pause_menu_toggles_on_ui_cancel() -> void:
	var floor := preload("res://scenes/casino_floor.tscn").instantiate()
	add_child_autofree(floor)
	floor._toggle_pause_menu()
	assert_true(floor.pause_menu.visible)
	floor._toggle_pause_menu()
	assert_false(floor.pause_menu.visible)
```

**Implementación**, en `scripts/net/casino_floor.gd`:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause_menu()

func _toggle_pause_menu() -> void:
	pause_menu.visible = not pause_menu.visible
```

`ui_cancel` ya existe por defecto en cualquier proyecto Godot (mapeado a
ESC) — no hace falta tocar `project.godot` `[input]` para esto. Si al
probar en el editor descubres que no está mapeado por algún motivo en
este proyecto concreto, confírmalo primero (`ProjectSettings.has_setting
("input/ui_cancel")` o revisando `project.godot`) antes de asumir que
hace falta añadirlo a mano.

## Tarea 5 — `PauseMenu`: contenido y `mouse_filter` correcto

**Test primero:**

```gdscript
func test_pause_menu_does_not_block_own_buttons() -> void:
	var pause_menu := preload("res://scenes/ui/casino/pause_menu.tscn").instantiate()
	add_child_autofree(pause_menu)
	assert_ne(pause_menu.resume_button.mouse_filter, Control.MOUSE_FILTER_IGNORE)
```

**Implementación**: overlay `Control` a pantalla completa,
`mouse_filter = MOUSE_FILTER_STOP` en el fondo (para no dejar pasar
clics a la mesa de debajo, mismo patrón que `DefeatOverlay`), pero los
botones hijos (`ResumeButton`/`SettingsButton`/`ExitRoomButton`/
`QuitButton`) mantienen su `mouse_filter` normal (`MOUSE_FILTER_STOP`
por defecto en `Button`, que sí procesa sus propios clics) — el bug
histórico fue un overlay entero con `mouse_filter=STOP` colocado
DESPUÉS de un botón hermano en el árbol, no un problema del propio
overlay con sus hijos. Verifica el orden de nodos en el `.tscn`: el
`PauseMenu` debe estar en un nivel donde sus propios botones sean hijos
directos (reciben el evento antes de que el fondo lo consuma).

`ExitRoomButton` del menú de pausa llama a la misma función que ya
existe (`_on_exit_room_pressed` en `casino_floor.gd`, de Plan 24) — no
dupliques su lógica:

```gdscript
exit_room_button_in_pause.pressed.connect(_on_exit_room_pressed)
```

## Tarea 6 — botón "Salir al escritorio" con confirmación (en `PauseMenu` y en `SettingsMenu`)

**Test primero:**

```gdscript
func test_quit_button_requires_confirmation() -> void:
	var menu := preload("res://scenes/ui/casino/settings_menu.tscn").instantiate()
	add_child_autofree(menu)
	menu.quit_button.pressed.emit()
	assert_true(menu.quit_confirm.visible)
	# get_tree().quit() no se puede testear en GUT sin cerrar el runner —
	# basta con verificar que el diálogo aparece, no que quit() se llame de verdad
```

**Implementación**: ya cubierta en la Tarea 1 (`quit_confirm.popup_centered`
+ `quit_confirm.confirmed.connect`). Reutiliza el mismo patrón/nodo en
`PauseMenu` (puedes factorizar un componente `QuitConfirmDialog` común
si prefieres no duplicar el `ConfirmationDialog` en dos escenas).

## Verificación en vivo (no te la saltes)

Con 2 clientes Steam reales (o al menos revisando el código con mucho
cuidado si no tienes 2 cuentas disponibles en tu sesión): confirma que
abrir `PauseMenu` en un cliente **no** congela la partida para el otro
— ninguna llamada a `get_tree().paused` en todo el código nuevo. Si no
puedes hacer el playtest de 2 clientes tú misma, dilo explícito en tu
reporte final, no lo des por hecho.

## Reporte final a pilar

Rama, commits, `X/X tests` tras reconstruir caché de clases, y
confirmación explícita de que ningún código nuevo usa
`get_tree().paused = true` (grep tu propio diff antes de reportar).

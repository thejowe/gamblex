# Plan: pantalla de inicio (Home) — Agente 32

Diseño acordado con el usuario en sesión de brainstorming (bounded, sin
doc de spec aparte — este plan es la única fuente). TDD: test antes que
implementación en cada tarea. `HomeScreen` tendrá `class_name` nuevo —
reconstruye la caché de clases (`godot --headless --editor --quit --path .`)
antes de correr GUT tras la Tarea 1.

## Contexto (no reinventar, interfaces reales ya confirmadas leyendo el repo)

- `lobby_bg.png` (`res://assets/pixels/inicio/lobby_bg/lobby_bg.png`) es
  arte `FINAL`, ya pensado como "pantalla de bienvenida" — se mueve de
  `LobbyMenu` a `HomeScreen`.
- `CasinoButton` (`res://scenes/ui/casino/casino_button.tscn`) es el botón
  estándar del proyecto — todos los botones nuevos de Home lo usan
  (a diferencia de los `Button` nativos que hoy tiene `LobbyMenu`, deuda
  existente, fuera de alcance).
- `SettingsMenu` (`res://scenes/ui/casino/settings_menu.tscn`) se añade
  como nodo hijo en la escena y se abre con `visible = true` — patrón ya
  usado en `LobbyMenu`/`PauseMenu`, no hace falta `instantiate()`.
- `CreditsMenu` (`res://scenes/ui/casino/credits_menu.tscn`,
  `scripts/ui/casino/credits_menu.gd`) es una escena aparte, navegación
  vía `get_tree().change_scene_to_file(...)`. Su `_on_back_pressed` hoy
  apunta a `res://scenes/lobby_menu.tscn` — pasa a apuntar a
  `res://scenes/home_screen.tscn` (Tarea 4).
- `HelpOverlay` (`class_name HelpOverlay`,
  `res://scenes/ui/casino/help_overlay.tscn`) se añade como nodo hijo en
  la escena (no dinámico), con `set_rules_text(String)` + `open()`/
  `close()`. Patrón real de uso (`scenes/dice_table_net.gd:30`):
  `help_button.pressed.connect(func(): help_overlay.set_rules_text(TEXT); help_overlay.open())`.
- `ConfirmationDialog` + `CasinoTheme.style_confirmation_dialog(dialog)`
  (ya existe en `scripts/ui/casino/casino_theme.gd`) es el patrón real de
  "¿seguro que quieres salir?" usado en `PauseMenu`/`SettingsMenu`:
  ```gdscript
  quit_button.pressed.connect(quit_confirm.popup_centered)
  quit_confirm.confirmed.connect(func(): get_tree().quit())
  CasinoTheme.style_confirmation_dialog(quit_confirm)
  ```
- `LoadingScreen` (`res://scenes/ui/casino/loading_screen.tscn`,
  `class_name LoadingScreen`) con `fade_and_change_scene(path: String)` es
  el patrón real de transición entre pantallas (`scenes/lobby_menu.gd:88-94`):
  ```gdscript
  var loading: LoadingScreen = preload("res://scenes/ui/casino/loading_screen.tscn").instantiate()
  add_child(loading)
  loading.fade_and_change_scene("res://scenes/casino_floor.tscn")
  ```
- `AudioManager.play_music("lobby")` ya se llama en `_ready()` de
  `LobbyMenu` — se queda ahí (la sala Steam sigue siendo la pantalla con
  música de lobby). `HomeScreen` no necesita música nueva a menos que el
  usuario la pida más adelante (fuera de alcance de este plan).

## Tarea 1 — escena `HomeScreen` con fondo y 5 botones (sin wiring)

**Test primero** (`tests/unit/test_home_screen.gd`):

```gdscript
extends GutTest

func _make() -> Control:
	var scene := load("res://scenes/home_screen.tscn")
	var instance: Control = scene.instantiate()
	add_child_autofree(instance)
	return instance

func test_has_five_buttons() -> void:
	var home := _make()
	assert_not_null(home.get_node("StartButton"))
	assert_not_null(home.get_node("SettingsButton"))
	assert_not_null(home.get_node("CreditsButton"))
	assert_not_null(home.get_node("HelpButton"))
	assert_not_null(home.get_node("QuitButton"))

func test_covers_full_screen() -> void:
	var home := _make()
	assert_eq(home.anchor_right, 1.0)
	assert_eq(home.anchor_bottom, 1.0)
```

**Implementación** — `scenes/home_screen.gd`:

```gdscript
class_name HomeScreen
extends Control

@onready var start_button: CasinoButton = $StartButton
@onready var settings_button: CasinoButton = $SettingsButton
@onready var credits_button: CasinoButton = $CreditsButton
@onready var help_button: CasinoButton = $HelpButton
@onready var quit_button: CasinoButton = $QuitButton
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var help_overlay: HelpOverlay = $HelpOverlay
@onready var quit_confirm: ConfirmationDialog = $QuitConfirm

func _ready() -> void:
	pass # wiring en tareas siguientes
```

Escena `scenes/home_screen.tscn`: `Control` raíz full-rect (mismo
`anchors_preset = 15` que `LobbyMenu`) → `TextureRect Background`
(`lobby_bg.png`, `stretch_mode = 6`, `texture_filter = 1`, `mouse_filter = 2`,
idéntico al `Background` que hoy tiene `lobby_menu.tscn`) → 5
`CasinoButton` (instancias de `casino_button.tscn`, columna vertical
centrada, texto: "Iniciar Partida", "Ajustes", "Créditos", "Ayuda",
"Salir") → `SettingsMenu` (instancia, oculto por defecto como ya hace) →
`HelpOverlay` (instancia) → `QuitConfirm` (`ConfirmationDialog` nativo,
`dialog_text = "¿Seguro que quieres salir?"`).

## Tarea 2 — Iniciar Partida navega a la sala Steam

**Test primero:**

```gdscript
func test_start_button_text() -> void:
	var home := _make()
	assert_eq(home.start_button.text, "Iniciar Partida")
```

(La navegación real con `LoadingScreen`+`change_scene_to_file` no es
testeable con GUT sin cargar la escena de verdad — cúbrela con el test de
texto/conexión de señal y anótalo como visual-only en el reporte, mismo
criterio que ya usó el Agente 27.)

**Implementación** en `_ready()`:

```gdscript
start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	var loading: LoadingScreen = preload("res://scenes/ui/casino/loading_screen.tscn").instantiate()
	add_child(loading)
	loading.fade_and_change_scene("res://scenes/lobby_menu.tscn")
```

## Tarea 3 — Ajustes y Ayuda

**Test primero:**

```gdscript
func test_settings_button_opens_settings_menu() -> void:
	var home := _make()
	home.settings_button.pressed.emit()
	assert_true(home.settings_menu.visible)

func test_help_button_opens_help_overlay() -> void:
	var home := _make()
	home.help_button.pressed.emit()
	assert_true(home.help_overlay.visible)
```

**Implementación:**

```gdscript
const HELP_TEXT := """Cómo jugar
Crea una sala e invita a tus amigos de Steam, o únete a la suya.
Elige Modo Libre (todos comparten una meta de fichas colectiva) o
Modo Batalla (equipos 1v1/2v2/4v4 compiten por vaciar el pozo rival).
Cada mesa tiene su propio botón de ayuda (?) con las reglas concretas
de ese juego."""

settings_button.pressed.connect(func(): settings_menu.visible = true)
help_button.pressed.connect(func(): help_overlay.set_rules_text(HELP_TEXT); help_overlay.open())
```

## Tarea 4 — Créditos y actualizar su botón "Volver"

**Test primero:** ninguno nuevo en `HomeScreen` (la navegación por
`change_scene_to_file` no es testeable en aislado); en su lugar, un test
de regresión sobre el propio `CreditsMenu`:

```gdscript
# tests/unit/test_credits_menu.gd — añadir si no existe, o extender si ya existe
func test_back_button_target_is_home_screen() -> void:
	# No se puede assertar el string privado del scene-change sin
	# refactorizar CreditsMenu a una señal; documentar en el reporte que
	# la verificación real es visual (pulsar Volver desde Créditos y
	# comprobar que aterriza en HomeScreen, no en LobbyMenu).
	pass_test("verificación visual pendiente, ver reporte del agente")
```

**Implementación:**

```gdscript
# scenes/home_screen.gd
credits_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/casino/credits_menu.tscn"))
```

```gdscript
# scripts/ui/casino/credits_menu.gd:10 — cambio de una línea
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/home_screen.tscn")
```

## Tarea 5 — Salir con confirmación

**Test primero:**

```gdscript
func test_quit_button_triggers_confirm_dialog() -> void:
	var home := _make()
	assert_false(home.quit_confirm.visible)
	# popup_centered() de un ConfirmationDialog nativo no es fácil de
	# assertar visible=true en headless (depende de la ventana) —
	# cubrir con doble: comprobar la conexión existe, no el popup real.
	assert_true(home.quit_button.pressed.is_connected(home.quit_confirm.popup_centered))
```

**Implementación:**

```gdscript
quit_button.pressed.connect(quit_confirm.popup_centered)
quit_confirm.confirmed.connect(func(): get_tree().quit())
CasinoTheme.style_confirmation_dialog(quit_confirm)
```

## Tarea 6 — `project.godot` arranca en `HomeScreen`

Sin test GUT (config del proyecto, no código). Cambio de una línea:

```
run/main_scene="res://scenes/home_screen.tscn"
```

Verificación: `godot --headless --editor --quit --path .` no debe fallar
al cargar el proyecto con el nuevo `main_scene` (comprueba que resuelve).

## Tarea 7 — `LobbyMenu` pierde fondo/Ajustes/Créditos, gana "Volver"

**Test primero** (`tests/unit/test_lobby_menu.gd` — extender si ya existe,
crear si no):

```gdscript
func test_no_longer_has_settings_or_credits() -> void:
	var scene := load("res://scenes/lobby_menu.tscn")
	var instance: Control = scene.instantiate()
	add_child_autofree(instance)
	assert_null(instance.get_node_or_null("SettingsButton"))
	assert_null(instance.get_node_or_null("SettingsMenu"))
	assert_null(instance.get_node_or_null("CreditsButton"))

func test_has_back_button() -> void:
	var scene := load("res://scenes/lobby_menu.tscn")
	var instance: Control = scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance.get_node("BackButton"))
```

**Implementación:**

- `scenes/lobby_menu.tscn`: quitar nodos `Background` (TextureRect
  `lobby_bg.png`), `SettingsButton`, `SettingsMenu`, `CreditsButton`, y
  sus `ext_resource` ya no usados (`id="2"` CasinoButton solo si
  `CreditsButton` era el único consumidor — revisar antes de borrar el
  `ext_resource`, `InviteButton` no lo usa). Añadir fondo plano: un
  `ColorRect Background` (full-rect) con `color = CasinoTheme.PANEL_NAVY_DARK`
  asignado en `_ready()` (igual patrón que `PauseMenu`/`HelpOverlay`
  hacen con su `Backdrop`, no hardcodeado en el `.tscn`). Añadir
  `CasinoButton BackButton`, texto "Volver".
- `scenes/lobby_menu.gd`: quitar `@onready var credits_button`,
  `@onready var settings_button`, `@onready var settings_menu`, sus
  conexiones y `_on_credits_pressed`. Añadir:

```gdscript
@onready var background: ColorRect = $Background
@onready var back_button: CasinoButton = $BackButton

func _ready() -> void:
	background.color = CasinoTheme.PANEL_NAVY_DARK
	back_button.pressed.connect(_on_back_pressed)
	# ... resto de _ready() igual que hoy, sin las líneas de settings/credits

func _on_back_pressed() -> void:
	if SteamManager.current_lobby_id > 0:
		Steam.leaveLobby(SteamManager.current_lobby_id)
		SteamManager.reset()
	var loading: LoadingScreen = preload("res://scenes/ui/casino/loading_screen.tscn").instantiate()
	add_child(loading)
	loading.fade_and_change_scene("res://scenes/home_screen.tscn")
```

(Sale de la sala Steam si había una creada, igual que ya hace
`_on_cancel_pressed` — no dejar una lobby Steam viva colgando al volver a
Home.)

## Reporte final del agente

Confirma en el reporte a la sesión pilar: rama, commits, `X/X` tests tras
reconstruir caché de clases, y qué quedó marcado como "verificación
visual pendiente" (arranque en `HomeScreen`, fade Iniciar Partida→sala,
Volver→Home, Créditos→Volver→Home, diálogo real de Salir) — nada de esto
es cubrible 100% con GUT headless, decirlo explícito en vez de forzar un
assert frágil.

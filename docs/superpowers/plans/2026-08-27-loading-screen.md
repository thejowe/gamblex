# Plan: pantalla de carga / transición — Agente 27

Lee primero `docs/superpowers/specs/2026-08-27-loading-screen-design.md`
— este plan lo implementa tal cual. TDD: test antes que implementación en
cada tarea. Reconstruye la caché de clases
(`godot --headless --editor --quit --path .`) tras crear `LoadingScreen`
(tiene `class_name`) antes de correr GUT.

## Tarea 1 — escena `LoadingScreen` + overlay a pantalla completa

**Test primero** (`tests/unit/test_loading_screen.gd`):

```gdscript
extends GutTest

func test_covers_full_screen() -> void:
	var scene := load("res://scenes/ui/casino/loading_screen.tscn")
	var instance: Control = scene.instantiate()
	add_child_autofree(instance)
	assert_eq(instance.anchor_right, 1.0)
	assert_eq(instance.anchor_bottom, 1.0)

func test_starts_fully_transparent() -> void:
	var scene := load("res://scenes/ui/casino/loading_screen.tscn")
	var instance: Control = scene.instantiate()
	add_child_autofree(instance)
	assert_almost_eq(instance.modulate.a, 0.0, 0.01)
```

**Implementación** (`scripts/ui/casino/loading_screen.gd`, nodo raíz
`Control` con anchors 0,0 a 1,1, `mouse_filter = STOP` para bloquear
clics mientras está visible):

```gdscript
class_name LoadingScreen
extends Control

@onready var background: ColorRect = $Background
@onready var indicator: Control = $Indicator  # 3 puntos o arco, dibujado por código

func _ready() -> void:
	modulate.a = 0.0
	background.color = CasinoTheme.PANEL_NAVY_DARK
	mouse_filter = Control.MOUSE_FILTER_STOP
```

Escena `.tscn`: `Control` raíz (anchors full-rect) → `ColorRect
Background` (mismo full-rect) → `Indicator` (Control pequeño centrado,
ver Tarea 2) → opcional `Label` "Cargando…" (`CasinoTheme.TEXT_LIGHT`,
fuente por defecto vía `ThemeDB.fallback_font`, mismo patrón que
`roulette_result_badge.gd`).

## Tarea 2 — indicador animado (3 puntos pulsando)

**Test primero:**

```gdscript
func test_indicator_dots_pulse_without_crash() -> void:
	var scene := load("res://scenes/ui/casino/loading_screen.tscn")
	var instance := scene.instantiate()
	add_child_autofree(instance)
	instance._process(0.1)  # un tick manual, no debe crashear
	pass_test("no crashea")
```

**Implementación**, dentro de `loading_screen.gd` o un script propio del
nodo `Indicator` (`class_name LoadingIndicator extends Control`):

```gdscript
var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var dot_count := 3
	var spacing := 20.0
	for i in dot_count:
		var phase := fmod(_t * 2.0 - i * 0.3, 1.0)
		var alpha := 0.3 + 0.7 * absf(sin(phase * PI))
		var x := (i - 1) * spacing
		draw_circle(Vector2(x, 0), 5.0, Color(CasinoTheme.TEXT_LIGHT, alpha))
```

Simple, barato, suficiente para "se está cargando algo" — no es
prioridad estética alta.

## Tarea 3 — `fade_and_change_scene()`

**Test primero:**

```gdscript
func test_fade_and_change_scene_animates_alpha() -> void:
	var scene := load("res://scenes/ui/casino/loading_screen.tscn")
	var instance: LoadingScreen = scene.instantiate()
	add_child_autofree(instance)
	var tween := instance.start_fade_in(0.1)
	assert_not_null(tween)
	# no forzamos el change_scene_to_file real en el test (rompe el
	# árbol de escena de GUT) — testea solo la parte animable: el tween
	# se crea y apunta a modulate:a
```

Separa la responsabilidad en dos métodos para que el fade sea testeable
sin disparar el cambio de escena real dentro de GUT:

**Implementación:**

```gdscript
func start_fade_in(fade_sec: float = 0.4) -> Tween:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_sec)
	return tween

func fade_and_change_scene(path: String, fade_sec: float = 0.4) -> void:
	var tween := start_fade_in(fade_sec)
	await tween.finished
	get_tree().change_scene_to_file(path)
```

`await tween.finished` es sintaxis válida de Godot 4 para esperar a que
un `Tween` termine dentro de una función `async` (cualquier función que
use `await` se vuelve corutina automáticamente, no hace falta declarar
nada especial). Confirma esto contra la documentación de Godot 4.7 si
tienes dudas antes de darlo por hecho.

## Tarea 4 — enganche en `LobbyMenu`

**Test primero** (`tests/unit/test_lobby_menu.gd`, añade si no existe ya
un caso — revisa el archivo antes de crear uno nuevo):

```gdscript
func test_go_to_casino_floor_instances_loading_screen() -> void:
	# según cómo esté estructurado el resto de tests de LobbyMenu en el
	# proyecto (instancian la escena completa vía GUT, revisa el patrón
	# real antes de escribir este test) — confirma que tras llamar
	# _go_to_casino_floor() hay un hijo de tipo LoadingScreen en el árbol
	pass
```

**Implementación**, en `scenes/lobby_menu.gd`:

```gdscript
func _go_to_casino_floor() -> void:
	if _transitioned:
		return
	_transitioned = true
	var loading: LoadingScreen = preload("res://scenes/ui/casino/loading_screen.tscn").instantiate()
	add_child(loading)
	loading.fade_and_change_scene("res://scenes/casino_floor.tscn")
```

Revisa que `LobbyMenu` sea `Control`/`CanvasItem` en la escena para que
`add_child` de un `Control` a pantalla completa se posicione bien encima
del resto — si `LobbyMenu` no cubre pantalla completa por su propio
anchor, ajusta el `LoadingScreen` para que se añada como hijo del nodo
raíz de la escena (`get_tree().root` o el nodo apropiado) en vez de
`self`, de forma que sí tape todo. Verifica esto en vivo/headless antes
de dar la tarea por cerrada.

## Reporte final a pilar

Rama, commits, `X/X tests` tras reconstruir caché, qué parte del fundido
verificaste en headless vs. qué queda pendiente de confirmación visual
en vivo (el hitch síncrono de `change_scene_to_file` es difícil de
percibir sin jugar de verdad).

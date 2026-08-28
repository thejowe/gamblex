# Plan: tutorial / "Cómo jugar" por mesa — Agente 28

Lee primero `docs/superpowers/specs/2026-08-27-tutorial-help-design.md` —
este plan lo implementa tal cual. TDD: test antes que implementación en
cada tarea. Reconstruye la caché de clases
(`godot --headless --editor --quit --path .`) tras crear
`help_overlay.gd` (tiene `class_name`) antes de confiar en un run de GUT,
y revisa `git status` después por si el editor reformateó espacios/tabs
en archivos que no tocaste (gotcha de siempre, descártalo con
`git checkout --` antes de commitear).

## Tarea 1 — componente `HelpOverlay`

**Test primero** (`tests/unit/test_help_overlay.gd`):

```gdscript
extends GutTest

func test_starts_hidden() -> void:
	var overlay := preload("res://scenes/ui/casino/help_overlay.tscn").instantiate()
	add_child_autofree(overlay)
	assert_false(overlay.visible)

func test_set_rules_text_updates_label() -> void:
	var overlay := preload("res://scenes/ui/casino/help_overlay.tscn").instantiate()
	add_child_autofree(overlay)
	overlay.set_rules_text("Texto de prueba")
	assert_true(overlay.get_node("Panel/RulesLabel").text.contains("Texto de prueba"))

func test_open_shows_overlay() -> void:
	var overlay := preload("res://scenes/ui/casino/help_overlay.tscn").instantiate()
	add_child_autofree(overlay)
	overlay.open()
	assert_true(overlay.visible)

func test_close_button_hides_overlay() -> void:
	var overlay := preload("res://scenes/ui/casino/help_overlay.tscn").instantiate()
	add_child_autofree(overlay)
	overlay.open()
	overlay.get_node("Panel/CloseButton").pressed.emit()
	assert_false(overlay.visible)
```

**Implementación** (`scripts/ui/casino/help_overlay.gd`):

```gdscript
class_name HelpOverlay
extends Control

@onready var backdrop: ColorRect = $Backdrop
@onready var rules_label: Label = $Panel/RulesLabel
@onready var close_button: CasinoButton = $Panel/CloseButton

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(close)

func set_rules_text(text: String) -> void:
	rules_label.text = text

func open() -> void:
	visible = true

func close() -> void:
	visible = false
```

**Escena** (`scenes/ui/casino/help_overlay.tscn`): `Control` raíz
(`anchor_right=1, anchor_bottom=1`, cubre toda la mesa) con:
- `Backdrop`: `ColorRect` a pantalla completa, color
  `Color(CasinoTheme.PANEL_NAVY_DARK, 0.85)` (semitransparente, oscurece
  la mesa detrás sin ocultar el propio panel de reglas).
- `Panel`: `PanelContainer` centrado (`anchor_left=0.5, anchor_right=0.5,
  anchor_top=0.5, anchor_bottom=0.5`, tamaño fijo razonable p.ej.
  480×360, `grow_horizontal`/`grow_vertical = 2` para centrarse de
  verdad), `StyleBoxFlat` con `bg_color = CasinoTheme.PANEL_NAVY_MID`,
  `border_color = CasinoTheme.GOLD_ACCENT`, `border_width_*` = 2,
  `corner_radius_*` = 10 — mismo lenguaje visual que el resto.
  - `RulesLabel` dentro: `Label` con `autowrap_mode = TextServer.AUTOWRAP_WORD`,
    `add_theme_color_override("font_color", CasinoTheme.TEXT_LIGHT)`.
  - `CloseButton` dentro (instancia de `scenes/ui/casino/casino_button.tscn`,
    `variant = CasinoButton.Variant.NEUTRAL`, texto "Cerrar").

## Tarea 2 — botón "?" + integración en cada mesa (7 sub-tareas, una por mesa)

Para cada mesa, en este orden (del layout más simple al más complejo, para
coger el patrón antes de las mesas más llenas):

1. Dice (`scenes/dice_table_net.tscn`/`.gd`)
2. Crash (`scenes/crash_table_net.tscn`/`.gd`)
3. Mines (`scenes/mines_table_net.tscn`/`.gd`)
4. Plinko (`scenes/plinko_table_net.tscn`/`.gd`)
5. Ruleta (`scenes/roulette_table_net.tscn`/`.gd`)
6. Póker (`scenes/poker_table_net.tscn`/`.gd`)
7. Blackjack (`scenes/blackjack_table_net.tscn`/`.gd`) — tiene `DeckIcon`
   ya ocupando la esquina superior derecha (`anchor_left=1, anchor_right=1,
   offset_top=20` en el `.tscn` actual), así que el botón "?" de esta
   mesa concreta necesita otra esquina libre — confírmalo leyendo el
   `.tscn` real antes de decidir, no copies la posición de las otras 6.

**Test por mesa** (ejemplo con Dice, replica el patrón en las otras 6 —
nombre de archivo `tests/unit/test_<juego>_table_net.gd`, revisa si ya
existe uno para esa mesa y añade el caso en vez de crear un archivo
duplicado):

```gdscript
func test_help_button_opens_overlay() -> void:
	var scene := preload("res://scenes/dice_table_net.tscn").instantiate()
	add_child_autofree(scene)
	scene.get_node("HelpButton").pressed.emit()
	assert_true(scene.get_node("HelpOverlay").visible)
```

**Implementación por mesa** (`.tscn`): añade nodo `HelpButton` (instancia
de `casino_button.tscn`, texto "?", tamaño 36×36, anclado a la esquina
libre que confirmaste) y nodo `HelpOverlay` (instancia de
`help_overlay.tscn`, `anchor_right=1, anchor_bottom=1`, al final del
árbol de nodos para quedar por encima de todo). En el `.gd` de la mesa,
`_ready()`:

```gdscript
help_button.pressed.connect(func(): help_overlay.set_rules_text(RULES_TEXT); help_overlay.open())
```

`RULES_TEXT` es una constante `const RULES_TEXT := "..."` en cada script
de mesa, con el texto de reglas de ese juego (contenido factual ya
verificado en el spec — redacta la prosa final tú mismo, corta y clara,
sin inventar ningún número).

## Reporte final a pilar

Rama, commits, `X/X tests` tras reconstruir caché, confirma que las 7
mesas tienen su botón "?" funcional sin solaparse con nada existente
(di explícitamente qué esquina usaste en cada una — especialmente
Blackjack, que necesitó una esquina distinta a las otras 6), y que el
texto de reglas de cada juego coincide con la lógica real (cita el
archivo/función que verificaste por cada uno).

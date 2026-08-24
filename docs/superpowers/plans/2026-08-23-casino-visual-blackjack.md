# Fundación Visual de Casino + Reskin de Blackjack — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir un sistema de componentes visuales de casino reutilizable (fieltro, fichas, cartas, botones, HUD — todo dibujado por código, sin assets de imagen) y aplicarlo por completo a la mesa de Blackjack, con animación de reparto de cartas, fichas y victoria.

**Architecture:** 6 componentes `Control`/`Button` presentacionales y desacoplados en `scripts/ui/casino/` + `scenes/ui/casino/`, sin conocimiento de red ni de reglas de juego. `BlackjackTableState.to_dict()` gana dos claves aditivas (`hand`, `dealer_hand`) para poder dibujar cartas reales — ninguna función de apuesta/turno/pago cambia. `scenes/blackjack_table_net.tscn`/`.gd` se reconstruye sobre esos componentes, sigue siendo un observador puro de `TableController.state_changed`, cero RPC nuevo.

**Tech Stack:** Godot 4.7 / GDScript, GUT para tests unitarios, `Control._draw()` + `Tween` para todo el dibujo y animación (sin texturas).

**Spec:** `docs/superpowers/specs/2026-08-23-casino-visual-blackjack-design.md` (léelo completo antes de empezar — este plan lo implementa, no lo repite).

## Global Constraints

- Cero archivos de imagen/textura nuevos — todo el look es `_draw()` procedural + `StyleBoxFlat`.
- No tocar ninguna otra mesa (`roulette_*`, `poker_*`, `dice_*`, `crash_*`, `mines_*`, `plinko_*`, `lobby_*`) ni `casino_floor.tscn`/`.gd`.
- No tocar ninguna función de apuesta/turno/pago en `BlackjackTableState` (`sit`, `place_bet`, `hit`, `stand`, `_resolve_round`, `_resolve_seat_payout`) — solo `to_dict()`.
- No introducir RPCs nuevas ni cambiar la firma de `TableController` (`state_changed`, `chips_won`, `sit()/bet()/hit()/stand()/request_state()`).
- Trabaja en un worktree aislado (`.claude/worktrees/feature+casino-visual-blackjack` o equivalente vía `superpowers:using-git-worktrees`), rama `feature/casino-visual-blackjack` — nunca en el checkout compartido de pilar.
- Cada archivo `.gd` nuevo usa `class_name` para quedar disponible globalmente, igual que el resto del proyecto.
- Godot para correr tests/verificación: `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe` (el binario custom `godotsteam.multiplayerpeer.451...` tiene Error 127 y no debe usarse). Steam debe estar corriendo para cualquier verificación de escena en vivo.
- Tras cualquier merge/checkout previo con clases nuevas, reconstruye la caché de clases (`godot --headless --editor --quit --path .`) antes de confiar en un run de GUT — y revisa `git status` después por si el editor reformateó espacios/tabs en archivos que no tocaste (gotcha conocido, documentado en `todo_agents.md`).

---

## Task 1: CasinoTheme — paleta compartida

**Files:**
- Create: `scripts/ui/casino/casino_theme.gd`
- Test: `tests/unit/test_casino_theme.gd`

**Interfaces:**
- Produces: `class_name CasinoTheme` con constantes `Color` (`FELT_GREEN_LIGHT`, `FELT_GREEN_DARK`, `WOOD_BROWN_LIGHT`, `WOOD_BROWN_DARK`, `GOLD_ACCENT`, `CARD_WHITE`, `CARD_RED`, `CARD_BLACK`, `TEXT_CREAM`) y `static func chip_color(denomination: int) -> Color`. Todas las tareas siguientes dependen de estos nombres exactos.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_casino_theme.gd
extends GutTest

func test_chip_color_known_denomination_returns_expected_color():
	assert_eq(CasinoTheme.chip_color(50), Color("e07b1f"))

func test_chip_color_unknown_denomination_returns_fallback_purple():
	assert_eq(CasinoTheme.chip_color(9999), Color("9b59b6"))

func test_palette_constants_are_colors():
	assert_true(CasinoTheme.FELT_GREEN_LIGHT is Color)
	assert_true(CasinoTheme.WOOD_BROWN_LIGHT is Color)
	assert_true(CasinoTheme.GOLD_ACCENT is Color)
	assert_true(CasinoTheme.CARD_WHITE is Color)
	assert_true(CasinoTheme.TEXT_CREAM is Color)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_theme.gd -gexit`
Expected: FAIL — `Identifier "CasinoTheme" not declared`.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/casino_theme.gd
class_name CasinoTheme
extends RefCounted

const FELT_GREEN_LIGHT := Color("2f8f5b")
const FELT_GREEN_DARK := Color("1c5c3a")
const WOOD_BROWN_LIGHT := Color("8a5a34")
const WOOD_BROWN_DARK := Color("5c3a20")
const GOLD_ACCENT := Color("e8c468")
const CARD_WHITE := Color("f5f5f0")
const CARD_RED := Color("c0392b")
const CARD_BLACK := Color("1a1a1a")
const TEXT_CREAM := Color("f0e6d2")

const CHIP_COLORS := {
	1: Color("e8e8e8"),
	5: Color("c0392b"),
	10: Color("2e6da4"),
	25: Color("2f8f5b"),
	50: Color("e07b1f"),
	100: Color("1a1a1a"),
}

static func chip_color(denomination: int) -> Color:
	if CHIP_COLORS.has(denomination):
		return CHIP_COLORS[denomination]
	return Color("9b59b6")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_theme.gd -gexit`
Expected: PASS, 3/3.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/casino_theme.gd tests/unit/test_casino_theme.gd
git commit -m "feat(ui): add CasinoTheme shared palette"
```

---

## Task 2: CasinoChip — ficha dibujada por código

**Files:**
- Create: `scripts/ui/casino/casino_chip.gd`
- Create: `scenes/ui/casino/casino_chip.tscn`
- Test: `tests/unit/test_casino_chip.gd`

**Interfaces:**
- Consumes: `CasinoTheme.chip_color(denomination: int) -> Color` (Task 1).
- Produces: `class_name CasinoChip extends Control`, propiedad `denomination: int` (export, default 50), constante `RADIUS := 24.0`. La tarea 9 (escena de Blackjack) instancia `preload("res://scenes/ui/casino/casino_chip.tscn")` y asigna `.denomination`.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_casino_chip.gd
extends GutTest

func test_default_size_matches_radius():
	var chip: CasinoChip = CasinoChip.new()
	assert_eq(chip.custom_minimum_size, Vector2(CasinoChip.RADIUS * 2, CasinoChip.RADIUS * 2))
	chip.free()

func test_denomination_defaults_to_50():
	var chip: CasinoChip = CasinoChip.new()
	assert_eq(chip.denomination, 50)
	chip.free()

func test_setting_denomination_does_not_error():
	var chip: CasinoChip = CasinoChip.new()
	add_child_autofree(chip)
	chip.denomination = 100
	assert_eq(chip.denomination, 100)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_chip.gd -gexit`
Expected: FAIL — `Identifier "CasinoChip" not declared`.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/casino_chip.gd
class_name CasinoChip
extends Control

const RADIUS := 24.0
const NOTCH_COUNT := 12

@export var denomination: int = 50:
	set(value):
		denomination = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2, RADIUS * 2)

func _draw() -> void:
	var center := size / 2.0
	var color := CasinoTheme.chip_color(denomination)
	draw_circle(center, RADIUS, color)
	draw_arc(center, RADIUS, 0, TAU, 32, CasinoTheme.TEXT_CREAM, 2.0)
	for i in range(NOTCH_COUNT):
		if i % 2 != 0:
			continue
		var angle := TAU * float(i) / float(NOTCH_COUNT)
		var notch_center := center + Vector2(cos(angle), sin(angle)) * (RADIUS - 4.0)
		draw_circle(notch_center, 3.0, CasinoTheme.TEXT_CREAM)
	draw_circle(center, RADIUS * 0.55, color.darkened(0.15))
	var font := ThemeDB.fallback_font
	var text := str(denomination)
	var font_size := 14
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, center - text_size / 2.0 + Vector2(0, text_size.y * 0.3), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, CasinoTheme.TEXT_CREAM)
```

```gdscript
# scenes/ui/casino/casino_chip.tscn (crea este archivo como texto plano)
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/casino_chip.gd" id="1"]

[node name="CasinoChip" type="Control"]
script = ExtResource("1")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_chip.gd -gexit`
Expected: PASS, 3/3.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/casino_chip.gd scenes/ui/casino/casino_chip.tscn tests/unit/test_casino_chip.gd
git commit -m "feat(ui): add CasinoChip component"
```

---

## Task 3: PlayingCard — carta dibujada por código, con flip animado

**Files:**
- Create: `scripts/ui/casino/playing_card.gd`
- Create: `scenes/ui/casino/playing_card.tscn`
- Test: `tests/unit/test_playing_card.gd`

**Interfaces:**
- Consumes: `CasinoTheme.CARD_WHITE/CARD_RED/CARD_BLACK` (Task 1); `Card.Suit` enum (`HEARTS=0, DIAMONDS=1, CLUBS=2, SPADES=3`) y `Card.rank` (`1..13`) de `scripts/blackjack/card.gd` (ya existente, no se modifica).
- Produces: `class_name PlayingCard extends Control`, propiedades `rank: int`, `suit: int`, `face_up: bool`, método `rank_label() -> String`, método `flip() -> void`, señal `flip_completed`. La tarea 9 instancia `preload("res://scenes/ui/casino/playing_card.tscn")` y asigna `rank`/`suit`/`face_up` directamente (no llama `flip()` para el reparto inicial, solo para revelar la carta tapada del dealer).

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_playing_card.gd
extends GutTest

func test_default_size_matches_card_size():
	var card: PlayingCard = PlayingCard.new()
	assert_eq(card.custom_minimum_size, PlayingCard.CARD_SIZE)
	card.free()

func test_rank_label_face_cards():
	var card: PlayingCard = PlayingCard.new()
	card.rank = 1
	assert_eq(card.rank_label(), "A")
	card.rank = 11
	assert_eq(card.rank_label(), "J")
	card.rank = 12
	assert_eq(card.rank_label(), "Q")
	card.rank = 13
	assert_eq(card.rank_label(), "K")
	card.free()

func test_rank_label_number_cards():
	var card: PlayingCard = PlayingCard.new()
	card.rank = 7
	assert_eq(card.rank_label(), "7")
	card.free()

func test_face_up_default_true_and_settable():
	var card: PlayingCard = PlayingCard.new()
	add_child_autofree(card)
	assert_true(card.face_up)
	card.face_up = false
	assert_false(card.face_up)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_playing_card.gd -gexit`
Expected: FAIL — `Identifier "PlayingCard" not declared`.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/playing_card.gd
class_name PlayingCard
extends Control

signal flip_completed

const CARD_SIZE := Vector2(70, 100)
const SUIT_SYMBOLS := {
	0: "♥",  # Card.Suit.HEARTS
	1: "♦",  # Card.Suit.DIAMONDS
	2: "♣",  # Card.Suit.CLUBS
	3: "♠",  # Card.Suit.SPADES
}
const RANK_LABELS := {
	1: "A", 11: "J", 12: "Q", 13: "K",
}

@export var rank: int = 1:
	set(value):
		rank = value
		queue_redraw()
@export var suit: int = 3:
	set(value):
		suit = value
		queue_redraw()
@export var face_up: bool = true:
	set(value):
		face_up = value
		queue_redraw()

func _init() -> void:
	custom_minimum_size = CARD_SIZE
	pivot_offset = CARD_SIZE / 2.0

func rank_label() -> String:
	return RANK_LABELS.get(rank, str(rank))

func _is_red() -> bool:
	return suit == 0 or suit == 1

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, CARD_SIZE)
	if face_up:
		draw_rect(rect, CasinoTheme.CARD_WHITE)
		draw_rect(rect, CasinoTheme.CARD_BLACK, false, 1.5)
		var color := CasinoTheme.CARD_RED if _is_red() else CasinoTheme.CARD_BLACK
		var font := ThemeDB.fallback_font
		var symbol: String = SUIT_SYMBOLS[suit]
		draw_string(font, Vector2(6, 16), rank_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		draw_string(font, Vector2(6, 32), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		var big_size := font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 28)
		draw_string(font, CARD_SIZE / 2.0 - big_size / 2.0 + Vector2(0, big_size.y * 0.3), symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 28, color)
	else:
		draw_rect(rect, Color("1c3f6e"))
		draw_rect(rect, CasinoTheme.CARD_WHITE, false, 1.5)
		var step := 10
		var x := step
		while x < CARD_SIZE.x:
			draw_line(Vector2(x, 0), Vector2(x, CARD_SIZE.y), Color("2a5490"), 1.0)
			x += step

func flip() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.15)
	tween.tween_callback(func(): face_up = not face_up)
	tween.tween_property(self, "scale:x", 1.0, 0.15)
	tween.finished.connect(func(): flip_completed.emit())
```

```gdscript
# scenes/ui/casino/playing_card.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/playing_card.gd" id="1"]

[node name="PlayingCard" type="Control"]
script = ExtResource("1")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_playing_card.gd -gexit`
Expected: PASS, 4/4.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/playing_card.gd scenes/ui/casino/playing_card.tscn tests/unit/test_playing_card.gd
git commit -m "feat(ui): add PlayingCard component with flip animation"
```

---

## Task 4: CasinoButton — botón estilizado con estados y hover/press animado

**Files:**
- Create: `scripts/ui/casino/casino_button.gd`
- Create: `scenes/ui/casino/casino_button.tscn`
- Test: `tests/unit/test_casino_button.gd`

**Interfaces:**
- Consumes: `CasinoTheme.TEXT_CREAM` (Task 1).
- Produces: `class_name CasinoButton extends Button`, `enum Variant { NEUTRAL, POSITIVE, NEGATIVE }`, `static func color_for_variant(v: int) -> Color`, propiedad `variant: Variant`. La tarea 9 usa `preload("res://scenes/ui/casino/casino_button.tscn")` para Hit (POSITIVE)/Stand (NEGATIVE)/Double/Split (NEUTRAL).

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_casino_button.gd
extends GutTest

func test_color_for_variant_positive_is_green():
	assert_eq(CasinoButton.color_for_variant(CasinoButton.Variant.POSITIVE), Color("2f8f5b"))

func test_color_for_variant_negative_is_red():
	assert_eq(CasinoButton.color_for_variant(CasinoButton.Variant.NEGATIVE), Color("b23b3b"))

func test_default_variant_is_neutral():
	var button: CasinoButton = CasinoButton.new()
	add_child_autofree(button)
	assert_eq(button.variant, CasinoButton.Variant.NEUTRAL)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_button.gd -gexit`
Expected: FAIL — `Identifier "CasinoButton" not declared`.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/casino_button.gd
class_name CasinoButton
extends Button

enum Variant { NEUTRAL, POSITIVE, NEGATIVE }

const VARIANT_COLORS := {
	Variant.NEUTRAL: Color("4a4a4a"),
	Variant.POSITIVE: Color("2f8f5b"),
	Variant.NEGATIVE: Color("b23b3b"),
}

@export var variant: Variant = Variant.NEUTRAL:
	set(value):
		variant = value
		_apply_styles()

static func color_for_variant(v: int) -> Color:
	return VARIANT_COLORS[v]

func _ready() -> void:
	_apply_styles()
	pivot_offset = size / 2.0
	mouse_entered.connect(_on_hover_start)
	mouse_exited.connect(_on_hover_end)
	button_down.connect(_on_press)
	button_up.connect(_on_release)

func _apply_styles() -> void:
	var base_color := color_for_variant(variant)
	add_theme_stylebox_override("normal", _style(base_color))
	add_theme_stylebox_override("hover", _style(base_color.lightened(0.15)))
	add_theme_stylebox_override("pressed", _style(base_color.darkened(0.2)))
	add_theme_stylebox_override("disabled", _style(base_color.darkened(0.4), 0.5))

func _style(color: Color, alpha: float = 1.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(color.r, color.g, color.b, alpha)
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.corner_radius_bottom_left = 6
	box.corner_radius_bottom_right = 6
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.border_color = CasinoTheme.TEXT_CREAM
	return box

func _on_hover_start() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_hover_end() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _on_press() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)

func _on_release() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.05)
```

```gdscript
# scenes/ui/casino/casino_button.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/casino_button.gd" id="1"]

[node name="CasinoButton" type="Button"]
script = ExtResource("1")
text = "Button"
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_button.gd -gexit`
Expected: PASS, 3/3.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/casino_button.gd scenes/ui/casino/casino_button.tscn tests/unit/test_casino_button.gd
git commit -m "feat(ui): add CasinoButton component with hover/press animation"
```

---

## Task 5: CasinoHudBar — barra inferior de balance/apuesta

**Files:**
- Create: `scripts/ui/casino/casino_hud_bar.gd`
- Create: `scenes/ui/casino/casino_hud_bar.tscn`
- Test: `tests/unit/test_casino_hud_bar.gd`

**Interfaces:**
- Consumes: `CasinoTheme.GOLD_ACCENT` (Task 1).
- Produces: `class_name CasinoHudBar extends PanelContainer`, métodos `set_balance(amount: int) -> void`, `set_bet(amount: int) -> void`. La tarea 9 instancia `preload("res://scenes/ui/casino/casino_hud_bar.tscn")` (o la coloca directo en la escena de Blackjack) y llama a estos métodos desde `_render_state`.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_casino_hud_bar.gd
extends GutTest

func test_set_balance_formats_label_text():
	var hud: CasinoHudBar = load("res://scenes/ui/casino/casino_hud_bar.tscn").instantiate()
	add_child_autofree(hud)
	hud.set_balance(1234)
	assert_eq(hud.balance_label.text, "BALANCE  $1234")

func test_set_bet_formats_label_text():
	var hud: CasinoHudBar = load("res://scenes/ui/casino/casino_hud_bar.tscn").instantiate()
	add_child_autofree(hud)
	hud.set_bet(50)
	assert_eq(hud.bet_label.text, "APUESTA  $50")
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_hud_bar.gd -gexit`
Expected: FAIL — escena no existe todavía.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/casino_hud_bar.gd
class_name CasinoHudBar
extends PanelContainer

@onready var balance_label: Label = $Margin/HBox/BalanceLabel
@onready var bet_label: Label = $Margin/HBox/BetLabel

func _ready() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.078, 0.078, 0.059, 0.92)
	box.border_width_top = 2
	box.border_color = CasinoTheme.GOLD_ACCENT
	add_theme_stylebox_override("panel", box)
	balance_label.add_theme_color_override("font_color", CasinoTheme.GOLD_ACCENT)
	bet_label.add_theme_color_override("font_color", CasinoTheme.GOLD_ACCENT)

func set_balance(amount: int) -> void:
	balance_label.text = "BALANCE  $%d" % amount

func set_bet(amount: int) -> void:
	bet_label.text = "APUESTA  $%d" % amount
```

```gdscript
# scenes/ui/casino/casino_hud_bar.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/casino_hud_bar.gd" id="1"]

[node name="CasinoHudBar" type="PanelContainer"]
script = ExtResource("1")

[node name="Margin" type="MarginContainer" parent="."]
layout_mode = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 8
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 8

[node name="HBox" type="HBoxContainer" parent="Margin"]
layout_mode = 2
theme_override_constants/separation = 40

[node name="BalanceLabel" type="Label" parent="Margin/HBox"]
layout_mode = 2
text = "BALANCE  $0"

[node name="BetLabel" type="Label" parent="Margin/HBox"]
layout_mode = 2
text = "APUESTA  $0"
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_casino_hud_bar.gd -gexit`
Expected: PASS, 2/2.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/casino_hud_bar.gd scenes/ui/casino/casino_hud_bar.tscn tests/unit/test_casino_hud_bar.gd
git commit -m "feat(ui): add CasinoHudBar component"
```

---

## Task 6: FeltTablePanel — tapete verde, borde de madera, texto curvo

**Files:**
- Create: `scripts/ui/casino/felt_table_panel.gd`
- Create: `scenes/ui/casino/felt_table_panel.tscn`
- Test: `tests/unit/test_felt_table_panel.gd`

**Interfaces:**
- Consumes: `CasinoTheme.FELT_GREEN_LIGHT/FELT_GREEN_DARK/WOOD_BROWN_LIGHT/TEXT_CREAM` (Task 1).
- Produces: `class_name FeltTablePanel extends Control`, propiedades `rules_text_top: String`, `rules_text_bottom: String` (defaults abajo). La tarea 8 lo coloca como fondo de la escena de Blackjack, `size` ligado a anchors full-rect.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_felt_table_panel.gd
extends GutTest

func test_default_rules_text():
	var panel: FeltTablePanel = load("res://scenes/ui/casino/felt_table_panel.tscn").instantiate()
	add_child_autofree(panel)
	assert_eq(panel.rules_text_top, "BLACKJACK PAYS 3 TO 2")
	assert_eq(panel.rules_text_bottom, "INSURANCE PAYS 2 TO 1")

func test_can_resize_and_redraw_without_error():
	var panel: FeltTablePanel = load("res://scenes/ui/casino/felt_table_panel.tscn").instantiate()
	add_child_autofree(panel)
	panel.size = Vector2(900, 1080)
	panel.queue_redraw()
	await get_tree().process_frame
	assert_true(true)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_felt_table_panel.gd -gexit`
Expected: FAIL — escena no existe todavía.

- [ ] **Step 3: Implementa**

```gdscript
# scripts/ui/casino/felt_table_panel.gd
class_name FeltTablePanel
extends Control

@export var rules_text_top: String = "BLACKJACK PAYS 3 TO 2"
@export var rules_text_bottom: String = "INSURANCE PAYS 2 TO 1"

func _draw() -> void:
	var center := Vector2(size.x / 2.0, size.y * 0.18)
	var radius := Vector2(size.x * 0.46, size.y * 0.42)
	_draw_wood_rail(center, radius)
	_draw_felt(center, radius)
	_draw_curved_text(rules_text_top, center, radius.y * 0.55, PI * 0.5 - 0.6, PI * 0.5 + 0.6, 18)
	_draw_curved_text(rules_text_bottom, center, radius.y * 0.75, PI * 0.5 - 0.45, PI * 0.5 + 0.45, 14)

func _arc_points(center: Vector2, radius: Vector2, expand: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps) * PI
		points.append(center + Vector2(cos(t) * (radius.x + expand), sin(t) * (radius.y + expand)))
	return points

func _draw_wood_rail(center: Vector2, radius: Vector2) -> void:
	var outer := _arc_points(center, radius, 26.0, 64)
	var inner := _arc_points(center, radius, -4.0, 64)
	inner.reverse()
	var points := PackedVector2Array()
	points.append_array(outer)
	points.append_array(inner)
	draw_colored_polygon(points, CasinoTheme.WOOD_BROWN_LIGHT)

func _draw_felt(center: Vector2, radius: Vector2) -> void:
	var points := _arc_points(center, radius, 0.0, 64)
	points.append(Vector2(center.x - radius.x, center.y))
	draw_colored_polygon(points, CasinoTheme.FELT_GREEN_LIGHT)
	draw_polyline(_arc_points(center, radius, 0.0, 64), CasinoTheme.FELT_GREEN_DARK, 3.0, true)

func _draw_curved_text(text: String, center: Vector2, radius: float, start_angle: float, end_angle: float, font_size: int) -> void:
	if text.is_empty():
		return
	var font := ThemeDB.fallback_font
	var char_widths: Array[float] = []
	var total_width := 0.0
	for c in text:
		var w := font.get_string_size(c, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
		char_widths.append(w)
		total_width += w
	var angle_span := end_angle - start_angle
	var angle := start_angle
	for i in range(text.length()):
		var pos := center + Vector2(cos(angle), sin(angle)) * radius
		draw_set_transform(pos, angle + PI / 2.0, Vector2.ONE)
		draw_string(font, Vector2(-char_widths[i] / 2.0, 0), text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, CasinoTheme.TEXT_CREAM)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if total_width > 0.0:
			angle += (char_widths[i] / total_width) * angle_span
```

```gdscript
# scenes/ui/casino/felt_table_panel.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/casino/felt_table_panel.gd" id="1"]

[node name="FeltTablePanel" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_felt_table_panel.gd -gexit`
Expected: PASS, 2/2.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/casino/felt_table_panel.gd scenes/ui/casino/felt_table_panel.tscn tests/unit/test_felt_table_panel.gd
git commit -m "feat(ui): add FeltTablePanel component with curved rules text"
```

---

## Task 7: Extiende `BlackjackTableState.to_dict()` con cartas reales

**Files:**
- Modify: `scripts/blackjack/blackjack_table_state.gd:154-171` (función `to_dict`)
- Test: `tests/unit/test_blackjack_table_state.gd` (añade casos al final del archivo existente)

**Interfaces:**
- Consumes: `Hand.cards: Array[Card]` (ya existente en `scripts/blackjack/hand.gd`), `Card.rank: int`, `Card.suit: int` (ya existentes).
- Produces: `to_dict()` añade, sin quitar ninguna clave existente: por asiento `"hand": Array` de `{"rank": int, "suit": int}`; a nivel de mesa `"dealer_hand": Array` de `{"rank": int, "suit": int}` o `{"hidden": true}` para la segunda carta mientras `round_active == true`. La tarea 9 (vista de Blackjack) lee estas dos claves nuevas.

- [ ] **Step 1: Escribe los tests que fallan**

Añade al final de `tests/unit/test_blackjack_table_state.gd`:

```gdscript
func test_to_dict_exposes_seat_hand_cards():
	var table = BlackjackTableState.new()
	table.sit(0, 111)
	table.sit(1, 222)
	table.place_bet(0, 111, 50)
	table.place_bet(1, 222, 50)
	var state = table.to_dict()
	var hand = state["seats"][0]["hand"]
	assert_eq(hand.size(), 2)
	assert_true(hand[0].has("rank"))
	assert_true(hand[0].has("suit"))

func test_to_dict_hides_second_dealer_card_while_round_active():
	var table = BlackjackTableState.new()
	table.sit(0, 111)
	table.place_bet(0, 111, 50)
	var state = table.to_dict()
	assert_true(state["round_active"])
	var dealer_hand = state["dealer_hand"]
	assert_eq(dealer_hand.size(), 2)
	assert_true(dealer_hand[0].has("rank"))
	assert_true(dealer_hand[1].has("hidden"))
	assert_eq(dealer_hand[1]["hidden"], true)

func test_to_dict_reveals_dealer_hand_after_round_resolves():
	var table = BlackjackTableState.new()
	table.sit(0, 111)
	table.place_bet(0, 111, 50)
	table.stand(0, 111)
	var state = table.to_dict()
	assert_false(state["round_active"])
	var dealer_hand = state["dealer_hand"]
	for card_data in dealer_hand:
		assert_true(card_data.has("rank"))
		assert_false(card_data.has("hidden"))
```

- [ ] **Step 2: Corre los tests, confirma que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_blackjack_table_state.gd -gexit`
Expected: FAIL en los 3 tests nuevos — `Invalid get index 'hand'` / `Invalid get index 'dealer_hand'`.

- [ ] **Step 3: Implementa**

Reemplaza la función `to_dict()` completa en `scripts/blackjack/blackjack_table_state.gd` (líneas 154-171):

```gdscript
func to_dict() -> Dictionary:
	var seats_data := []
	for seat in seats:
		if seat == null:
			seats_data.append(null)
		else:
			seats_data.append({
				"player_id": seat.player_id,
				"balance": seat.ledger.balance,
				"bet": seat.current_bet,
				"hand_value": seat.hand.value() if seat.hand else 0,
				"hand": _cards_to_dicts(seat.hand.cards) if seat.hand else [],
			})
	return {
		"seats": seats_data,
		"dealer_value": dealer_hand.value() if dealer_hand else 0,
		"dealer_hand": _dealer_hand_to_dicts(),
		"active_seat_index": active_seat_index,
		"round_active": round_active,
	}

func _cards_to_dicts(cards: Array) -> Array:
	var result := []
	for card in cards:
		result.append({"rank": card.rank, "suit": card.suit})
	return result

func _dealer_hand_to_dicts() -> Array:
	if dealer_hand == null:
		return []
	var cards := dealer_hand.cards
	var result := []
	for i in range(cards.size()):
		if i == 1 and round_active:
			result.append({"hidden": true})
		else:
			result.append({"rank": cards[i].rank, "suit": cards[i].suit})
	return result
```

- [ ] **Step 4: Corre los tests, confirma que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_blackjack_table_state.gd -gexit`
Expected: PASS, todos los tests del archivo (los preexistentes + los 3 nuevos).

- [ ] **Step 5: Commit**

```bash
git add scripts/blackjack/blackjack_table_state.gd tests/unit/test_blackjack_table_state.gd
git commit -m "feat(blackjack): expose real hand cards in to_dict, hide dealer hole card mid-round"
```

---

## Task 8: Reconstruye la escena `blackjack_table_net.tscn`

**Files:**
- Modify: `scenes/blackjack_table_net.tscn` (reescritura completa del árbol de nodos, mismo `script` y `TableController` hijo)
- Test: `tests/unit/test_blackjack_table_scene_structure.gd`

**Interfaces:**
- Consumes: `FeltTablePanel`, `CasinoHudBar`, `CasinoButton` (Tasks 4-6), `TableController` (ya existente, sin cambios), script `blackjack_table_net.gd` (lo reescribe la Tarea 9 — en esta tarea el script existente se deja intacto salvo por los `@onready` que ya no resuelven porque cambian los nombres de nodo; **para que esta tarea sea verificable de forma aislada, actualiza en este mismo paso solo los `@onready var ... = $NodePath` al principio de `blackjack_table_net.gd` para que apunten a los nuevos nombres de nodo — el resto de la lógica del script se reescribe en la Tarea 9**).
- Produces: árbol de nodos con los paths exactos que consume la Tarea 9: `$FeltTablePanel`, `$DealerCards`, `$DealerValueLabel`, `$DeckIcon`, `$SeatsRoot`, `$SitButton`, `$BetButton`, `$HitButton`, `$StandButton`, `$DoubleButton`, `$SplitButton`, `$CasinoHudBar`, `$TableController`.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_blackjack_table_scene_structure.gd
extends GutTest

func test_scene_has_expected_node_paths():
	var scene := load("res://scenes/blackjack_table_net.tscn")
	var root := scene.instantiate()
	add_child_autofree(root)
	for path in [
		"FeltTablePanel", "DealerCards", "DealerValueLabel", "DeckIcon",
		"SeatsRoot", "SitButton", "BetButton", "HitButton", "StandButton",
		"DoubleButton", "SplitButton", "CasinoHudBar", "TableController",
	]:
		assert_not_null(root.get_node_or_null(path), "falta el nodo %s" % path)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_blackjack_table_scene_structure.gd -gexit`
Expected: FAIL — la escena actual no tiene esos nodos.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/blackjack_table_net.tscn`:

```gdscript
[gd_scene load_steps=8 format=3]

[ext_resource type="Script" path="res://scenes/blackjack_table_net.gd" id="1"]
[ext_resource type="Script" path="res://scripts/net/table_controller.gd" id="2"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/felt_table_panel.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/casino_hud_bar.tscn" id="4"]
[ext_resource type="PackedScene" path="res://scenes/ui/casino/casino_button.tscn" id="5"]

[node name="BlackjackTableNet" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="TableController" type="Node" parent="."]
script = ExtResource("2")

[node name="FeltTablePanel" parent="." instance=ExtResource("3")]
layout_mode = 1

[node name="DeckIcon" type="Control" parent="."]
layout_mode = 0
offset_left = 820.0
offset_top = 20.0
offset_right = 890.0
offset_bottom = 90.0

[node name="DealerCards" type="Control" parent="."]
layout_mode = 0
offset_left = 0.0
offset_top = 0.0
offset_right = 900.0
offset_bottom = 1080.0

[node name="DealerValueLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 420.0
offset_top = 250.0
offset_right = 480.0
offset_bottom = 280.0
text = "0"
horizontal_alignment = 1

[node name="SeatsRoot" type="Control" parent="."]
layout_mode = 0
offset_left = 0.0
offset_top = 0.0
offset_right = 900.0
offset_bottom = 1080.0

[node name="SitButton" parent="." instance=ExtResource("5")]
layout_mode = 0
offset_left = 20.0
offset_top = 900.0
offset_right = 160.0
offset_bottom = 940.0
text = "Sentarse"

[node name="BetButton" parent="." instance=ExtResource("5")]
layout_mode = 0
offset_left = 180.0
offset_top = 900.0
offset_right = 320.0
offset_bottom = 940.0
text = "Apostar 50"

[node name="HitButton" parent="." instance=ExtResource("5")]
layout_mode = 0
offset_left = 400.0
offset_top = 900.0
offset_right = 520.0
offset_bottom = 940.0
text = "HIT"
variant = 1

[node name="StandButton" parent="." instance=ExtResource("5")]
layout_mode = 0
offset_left = 540.0
offset_top = 900.0
offset_right = 660.0
offset_bottom = 940.0
text = "STAND"
variant = 2

[node name="DoubleButton" parent="." instance=ExtResource("5")]
layout_mode = 0
offset_left = 260.0
offset_top = 900.0
offset_right = 380.0
offset_bottom = 940.0
text = "DOUBLE"
disabled = true

[node name="SplitButton" parent="." instance=ExtResource("5")]
layout_mode = 0
offset_left = 680.0
offset_top = 900.0
offset_right = 800.0
offset_bottom = 940.0
text = "SPLIT"
disabled = true

[node name="CasinoHudBar" parent="." instance=ExtResource("4")]
layout_mode = 0
offset_left = 0.0
offset_top = 1000.0
offset_right = 900.0
offset_bottom = 1080.0
```

En `scenes/blackjack_table_net.gd`, actualiza solo el bloque de `@onready var` al principio (deja el resto del archivo tal cual por ahora, la Tarea 9 lo reescribe entero):

```gdscript
@onready var table_controller: TableController = $TableController
@onready var felt_panel: FeltTablePanel = $FeltTablePanel
@onready var hud_bar: CasinoHudBar = $CasinoHudBar
@onready var sit_button: Button = $SitButton
@onready var bet_button: Button = $BetButton
@onready var hit_button: Button = $HitButton
@onready var stand_button: Button = $StandButton
@onready var double_button: Button = $DoubleButton
@onready var split_button: Button = $SplitButton
@onready var dealer_cards: Control = $DealerCards
@onready var dealer_value_label: Label = $DealerValueLabel
@onready var deck_icon: Control = $DeckIcon
@onready var seats_root: Control = $SeatsRoot
```

(Deja `seats_label`/`dealer_label` y sus referencias tal cual por ahora si el script no compila sin ellas — no importa, la Tarea 9 sustituye toda la lógica de este `.gd`.)

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_blackjack_table_scene_structure.gd -gexit`
Expected: PASS, 1/1. Si el script no compila por referencias rotas a `seats_label`/`dealer_label`, elimínalas del script en este mismo paso (no son parte de la interfaz que otras tareas consumen).

- [ ] **Step 5: Commit**

```bash
git add scenes/blackjack_table_net.tscn scenes/blackjack_table_net.gd tests/unit/test_blackjack_table_scene_structure.gd
git commit -m "feat(blackjack): rebuild table scene on shared casino UI components"
```

---

## Task 9: Reescribe `blackjack_table_net.gd` — render de estado + animación

**Files:**
- Modify: `scenes/blackjack_table_net.gd` (reescritura completa)
- Test: `tests/unit/test_blackjack_table_view.gd`

**Interfaces:**
- Consumes: `TableController.state_changed(state: Dictionary)`, `TableController.chips_won(player_id, amount)` (sin cambios); claves nuevas `state["seats"][i]["hand"]`, `state["dealer_hand"]` (Task 7); `PlayingCard`, `CasinoChip` (Tasks 2-3).
- Produces: método público `_render_state(state: Dictionary) -> void` y `seat_anchor(seat_index: int, seat_count: int) -> Vector2`, ambos usados por el test de esta tarea para verificar la lógica de render sin pasar por RPCs reales.

- [ ] **Step 1: Escribe el test que falla**

```gdscript
# tests/unit/test_blackjack_table_view.gd
extends GutTest

func _make_view():
	var scene := load("res://scenes/blackjack_table_net.tscn")
	var view = scene.instantiate()
	add_child_autofree(view)
	return view

func test_seat_anchor_spreads_across_width_for_multiple_seats():
	var view = _make_view()
	view.size = Vector2(900, 1080)
	var a0 = view.seat_anchor(0, 4)
	var a3 = view.seat_anchor(3, 4)
	assert_true(a3.x > a0.x)

func test_render_state_creates_one_card_node_per_seat_card():
	var view = _make_view()
	view.size = Vector2(900, 1080)
	var state := {
		"seats": [
			{"player_id": 111, "balance": 450, "bet": 50, "hand_value": 20, "hand": [
				{"rank": 10, "suit": 2}, {"rank": 13, "suit": 1},
			]},
			null, null, null,
		],
		"dealer_value": 6,
		"dealer_hand": [{"rank": 6, "suit": 0}, {"hidden": true}],
		"active_seat_index": 0,
		"round_active": true,
	}
	view._render_state(state)
	assert_eq(view._seat_card_nodes[0].size(), 2)
	assert_eq(view._dealer_card_nodes.size(), 2)
	assert_false(view._dealer_card_nodes[1].face_up)

func test_render_state_removes_card_nodes_when_hand_shrinks():
	var view = _make_view()
	view.size = Vector2(900, 1080)
	var state_with_cards := {
		"seats": [{"player_id": 111, "balance": 450, "bet": 50, "hand_value": 20, "hand": [
			{"rank": 10, "suit": 2}, {"rank": 13, "suit": 1},
		]}, null, null, null],
		"dealer_value": 0, "dealer_hand": [], "active_seat_index": 0, "round_active": true,
	}
	view._render_state(state_with_cards)
	var state_no_cards := {
		"seats": [{"player_id": 111, "balance": 450, "bet": 0, "hand_value": 0, "hand": []}, null, null, null],
		"dealer_value": 0, "dealer_hand": [], "active_seat_index": -1, "round_active": false,
	}
	view._render_state(state_no_cards)
	assert_eq(view._seat_card_nodes[0].size(), 0)
```

- [ ] **Step 2: Corre el test, confirma que falla**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_blackjack_table_view.gd -gexit`
Expected: FAIL — `_render_state`/`seat_anchor`/`_seat_card_nodes`/`_dealer_card_nodes` no existen todavía en el script actual.

- [ ] **Step 3: Implementa**

Reemplaza el contenido completo de `scenes/blackjack_table_net.gd`:

```gdscript
extends Control

const PlayingCardScene := preload("res://scenes/ui/casino/playing_card.tscn")
const CasinoChipScene := preload("res://scenes/ui/casino/casino_chip.tscn")
const CARD_SPACING := 24.0

@onready var table_controller: TableController = $TableController
@onready var felt_panel: FeltTablePanel = $FeltTablePanel
@onready var hud_bar: CasinoHudBar = $CasinoHudBar
@onready var sit_button: Button = $SitButton
@onready var bet_button: Button = $BetButton
@onready var hit_button: Button = $HitButton
@onready var stand_button: Button = $StandButton
@onready var double_button: Button = $DoubleButton
@onready var split_button: Button = $SplitButton
@onready var dealer_cards: Control = $DealerCards
@onready var dealer_value_label: Label = $DealerValueLabel
@onready var deck_icon: Control = $DeckIcon
@onready var seats_root: Control = $SeatsRoot

var my_seat_index: int = -1
var _last_state: Dictionary = {"seats": [null, null, null, null], "dealer_hand": []}
var _seat_card_nodes: Array = [[], [], [], []]
var _dealer_card_nodes: Array = []
var _seat_chip_nodes: Array = [null, null, null, null]

func _display_name(peer_id: int) -> String:
	var steam_id: int = NetworkManager.peer_steam_ids.get(peer_id, 0)
	if steam_id == 0:
		return "jugador %d" % peer_id
	var persona_name := Steam.getFriendPersonaName(steam_id)
	return persona_name if not persona_name.is_empty() else "jugador %d" % peer_id

func _ready() -> void:
	table_controller.state_changed.connect(_on_state_changed)
	table_controller.chips_won.connect(_on_chips_won)
	sit_button.pressed.connect(_on_sit_pressed)
	bet_button.pressed.connect(_on_bet_pressed)
	hit_button.pressed.connect(_on_hit_pressed)
	stand_button.pressed.connect(_on_stand_pressed)
	double_button.disabled = true
	split_button.disabled = true
	if not multiplayer.is_server():
		var peer := multiplayer.multiplayer_peer
		if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			sit_button.disabled = true
			multiplayer.connected_to_server.connect(func():
				sit_button.disabled = false
				table_controller.request_state()
			)
		else:
			table_controller.request_state()

func _on_sit_pressed() -> void:
	var seats: Array = _last_state.get("seats", [null, null, null, null])
	var seat_index := 0
	for i in range(seats.size()):
		if seats[i] == null:
			seat_index = i
			break
	table_controller.sit(seat_index)
	my_seat_index = seat_index

func _on_bet_pressed() -> void:
	table_controller.bet(my_seat_index, 50)

func _on_hit_pressed() -> void:
	table_controller.hit(my_seat_index)

func _on_stand_pressed() -> void:
	table_controller.stand(my_seat_index)

func seat_anchor(seat_index: int, seat_count: int) -> Vector2:
	if seat_count <= 1:
		return Vector2(size.x / 2.0, size.y * 0.62)
	var usable_width := size.x * 0.7
	var start_x := size.x * 0.15
	var step := usable_width / float(seat_count - 1)
	return Vector2(start_x + step * seat_index, size.y * 0.62)

func _on_state_changed(state: Dictionary) -> void:
	_render_state(state)

func _render_state(state: Dictionary) -> void:
	var previous := _last_state
	var seats: Array = state["seats"]
	var previous_seats: Array = previous.get("seats", [null, null, null, null])
	_render_dealer(state.get("dealer_hand", []), state["dealer_value"])
	for i in range(seats.size()):
		var previous_seat = previous_seats[i] if i < previous_seats.size() else null
		_render_seat(i, seats[i], previous_seat, seats.size())
	_last_state = state
	if my_seat_index >= 0 and my_seat_index < seats.size() and seats[my_seat_index] != null:
		bet_button.disabled = seats[my_seat_index]["bet"] > 0
		hud_bar.set_balance(seats[my_seat_index]["balance"])
		hud_bar.set_bet(seats[my_seat_index]["bet"])

func _render_dealer(hand_data: Array, dealer_value: int) -> void:
	dealer_value_label.text = str(dealer_value)
	_sync_hand_visual(dealer_cards, _dealer_card_nodes, hand_data, Vector2(size.x / 2.0, size.y * 0.28))

func _render_seat(seat_index: int, seat, previous_seat, seat_count: int) -> void:
	var anchor := seat_anchor(seat_index, seat_count)
	var hand_data: Array = seat["hand"] if seat != null else []
	_sync_hand_visual(seats_root, _seat_card_nodes[seat_index], hand_data, anchor)
	_sync_chip(seat_index, seat, anchor)

func _sync_hand_visual(container: Control, nodes: Array, hand_data: Array, anchor: Vector2) -> void:
	while nodes.size() > hand_data.size():
		var node = nodes.pop_back()
		node.queue_free()
	for i in range(hand_data.size()):
		var card_data = hand_data[i]
		var is_new := i >= nodes.size()
		var card: PlayingCard
		if is_new:
			card = PlayingCardScene.instantiate()
			container.add_child(card)
			card.position = deck_icon.position
			nodes.append(card)
		else:
			card = nodes[i]
		if card_data.has("hidden"):
			card.face_up = false
		else:
			card.rank = card_data["rank"]
			card.suit = card_data["suit"]
			card.face_up = true
		var target := anchor + Vector2(i * CARD_SPACING - hand_data.size() * CARD_SPACING * 0.5, 0)
		if is_new:
			var tween := create_tween()
			tween.tween_property(card, "position", target, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			card.position = target

func _sync_chip(seat_index: int, seat, anchor: Vector2) -> void:
	var chip_anchor := anchor + Vector2(0, 60)
	var existing = _seat_chip_nodes[seat_index]
	var bet: int = seat["bet"] if seat != null else 0
	if bet <= 0:
		if existing != null:
			existing.queue_free()
			_seat_chip_nodes[seat_index] = null
		return
	if existing == null:
		var chip: CasinoChip = CasinoChipScene.instantiate()
		seats_root.add_child(chip)
		chip.position = hud_bar.position
		_seat_chip_nodes[seat_index] = chip
		existing = chip
		var tween := create_tween()
		tween.tween_property(chip, "position", chip_anchor, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	existing.denomination = bet

func _on_chips_won(player_id: int, amount: int) -> void:
	var seats: Array = _last_state.get("seats", [])
	for i in range(seats.size()):
		var seat = seats[i]
		if seat != null and seat["player_id"] == player_id:
			_celebrate_seat(i, seats.size())
			return

func _celebrate_seat(seat_index: int, seat_count: int) -> void:
	var anchor := seat_anchor(seat_index, seat_count)
	var particles := CPUParticles2D.new()
	particles.position = anchor
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 24
	particles.lifetime = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, 200)
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 160.0
	particles.color = CasinoTheme.GOLD_ACCENT
	add_child(particles)
	get_tree().create_timer(1.2).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)
	for card in _seat_card_nodes[seat_index]:
		var tween := create_tween()
		tween.tween_property(card, "modulate", CasinoTheme.GOLD_ACCENT, 0.15)
		tween.tween_property(card, "modulate", Color.WHITE, 0.35)
```

- [ ] **Step 4: Corre el test, confirma que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=test_blackjack_table_view.gd -gexit`
Expected: PASS, 3/3.

- [ ] **Step 5: Commit**

```bash
git add scenes/blackjack_table_net.gd tests/unit/test_blackjack_table_view.gd
git commit -m "feat(blackjack): render real cards/chips with deal, bet and win animations"
```

---

## Task 10: Suite completa + verificación visual manual

**Files:** ninguno nuevo — solo verificación.

- [ ] **Step 1: Reconstruye la caché de clases**

Run: `godot --headless --editor --quit --path .` (usando el binario `/c/Users/Usuari/tools/godot/Godot_v4.7.1-stable_win64_console.exe`)
Después, revisa `git status` — si el editor reformateó algún `.gd` que no tocaste en este plan (espacios↔tabs), descártalo con `git checkout -- <archivo>` antes de seguir (gotcha conocido, no es parte de este trabajo).

- [ ] **Step 2: Corre la suite completa de GUT**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit`
Expected: todos los tests en verde, incluidos los ~10 archivos nuevos/modificados de este plan. Si el conteo total es sospechosamente bajo (menos que antes de este plan), sospecha del mismo gotcha de caché de clases silenciando tests — repite el Step 1.

- [ ] **Step 3: Verificación visual manual**

Con Steam abierto y logueado, lanza el proyecto (`Godot_v4.7.1-stable_win64_console.exe --path .`), entra a la mesa de Blackjack, siéntate, apuesta, pide carta, plántate. Confirma:
- El tapete verde con borde de madera y texto curvo se ve (no rectángulos grises por defecto).
- Las cartas repartidas muestran rank/palo reales y llegan animadas desde la esquina del mazo.
- La segunda carta del dealer se ve tapada mientras la ronda está activa y se revela al resolver.
- La ficha de apuesta viaja animada desde el HUD hasta el punto de apuesta.
- Al ganar, se ve el flash dorado + confeti sobre la mano ganadora.
- Los botones Hit/Stand reaccionan a hover/press.

No cierres esta fase sin que el usuario confirme el punto anterior en vivo — mismo patrón usado para cerrar el fix de resolución de pantalla (`todo_agents.md`, sección del fix de resolución).

- [ ] **Step 4: Commit final (si algo quedó sin commitear)**

```bash
git status
git add -A
git commit -m "chore: verify casino visual foundation + Blackjack reskin end to end" --allow-empty
```

# Plan: pantallas de victoria y derrota temporales — Agente 26

Lee primero `docs/superpowers/specs/2026-08-27-victory-defeat-screens-design.md`
— este plan lo implementa tal cual. TDD real: test antes que
implementación en cada tarea. Reconstruye la caché de clases
(`godot --headless --editor --quit --path .`) antes de confiar en un run
de GUT tras crear cualquier script nuevo con `class_name`.

**Antes de la Tarea 1**: confirma que `AudioManager.play_sfx` existe en
`main` (`git log --oneline | grep -i audio` o `grep -rn "func play_sfx"
autoloads/`). Si no está, para aquí y avisa a la sesión pilar — no
inventes un stub.

## Tarea 1 — mejorar `DefeatOverlay` con estilo real + soporte de dos modos

**Estado actual** (`scenes/casino_floor.tscn`, dentro de `Hud`):

```
[node name="DefeatOverlay" type="ColorRect" parent="Hud"]
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.05, 0.02, 0.02, 0.85)
mouse_filter = 2
visible = false

[node name="DefeatLabel" type="Label" parent="Hud/DefeatOverlay"]
...
text = "PERDISTE — el pozo compartido se agotó"
```

**Test primero** (`tests/unit/test_casino_floor_result_overlays.gd`,
archivo nuevo — sigue el patrón de instanciar `casino_floor.tscn` que ya
usan otros tests de este archivo, p.ej. `test_casino_floor_ledger_wiring.gd`,
revísalo para copiar el setup exacto: cómo se crea la escena headless sin
Steam real):

```gdscript
extends GutTest

func test_defeat_overlay_shows_free_mode_message() -> void:
	var floor := _make_casino_floor()  # helper que instancia sin conectar a Steam de verdad
	floor._receive_goal_state({"balance": 0, "target": 1000, "unlocked": false, "bankrupt": true})
	var overlay: Control = floor.get_node("Hud/DefeatOverlay")
	assert_true(overlay.visible)
	assert_true(overlay.get_node("DefeatLabel").text.contains("pozo"))

func test_defeat_overlay_shows_battle_message_for_losing_team() -> void:
	var floor := _make_casino_floor()
	# fuerza el equipo local a 0 (ajusta según cómo el test helper simule multiplayer.get_unique_id())
	floor._on_match_state_changed({"pool_balances": [0, 800], "finished": true, "winning_team": 1, "reason": "bankrupt"})
	var overlay: Control = floor.get_node("Hud/DefeatOverlay")
	assert_true(overlay.visible)
```

(Revisa cómo los tests existentes de `casino_floor.gd` simulan
`multiplayer.get_unique_id()`/`battle_controller.team_for()` en modo
headless sin red real — sigue exactamente ese patrón, no inventes uno
nuevo.)

**Implementación**: reemplaza el `ColorRect` liso por un `Control` con
`_draw()` propio (o mantenlo como contenedor y añade un `Panel` hijo con
`StyleBoxFlat`, lo que sea más simple de testear). Estilo:

```gdscript
func _style_result_panel(accent: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = CasinoTheme.PANEL_NAVY_DARK
	box.border_color = accent
	box.border_width_left = 3
	box.border_width_top = 3
	box.border_width_right = 3
	box.border_width_bottom = 3
	box.corner_radius_top_left = 12
	box.corner_radius_top_right = 12
	box.corner_radius_bottom_left = 12
	box.corner_radius_bottom_right = 12
	return box
```

`DefeatOverlay` sigue siendo el nodo raíz a pantalla completa
(`mouse_filter = 2`, sin tocar ese valor), pero dentro añade un `Panel`
centrado (no a pantalla completa) con el `StyleBoxFlat` de arriba y
`CasinoTheme.ACCENT_RED` como acento, más un `Label` de título grande y
uno de submensaje más pequeño.

Actualiza `_receive_goal_state` (Modo Libre, ya existente) y añade la
rama de Modo Batalla dentro de `_on_match_state_changed`:

```gdscript
func _show_result_overlay(overlay: Control, title: String, message: String) -> void:
	if overlay.visible:
		return  # ya mostrado, no repetir SFX
	overlay.visible = true
	overlay.get_node("TitleLabel").text = title
	overlay.get_node("MessageLabel").text = message
	AudioManager.play_sfx("lose" if overlay == defeat_overlay else "win")

func _reason_label(reason: String) -> String:
	match reason:
		"goal_reached": return "el equipo rival llegó antes a la meta"
		"bankrupt": return "tu equipo se quedó sin fichas"
		_: return reason
```

Guarda el `visible` anterior antes de reasignarlo si necesitas
distinguir "ya estaba visible" de "se acaba de mostrar" — no dispares
`play_sfx` en cada llamada de `_receive_goal_state`/
`_on_match_state_changed` mientras el overlay sigue con `bankrupt`/
`finished` en `true` (llega más de una vez por RPCs de refresco).

## Tarea 2 — `VictoryOverlay` nuevo

**Test primero:**

```gdscript
func test_victory_overlay_shows_only_for_winning_team() -> void:
	var floor := _make_casino_floor()
	# simula que el jugador local pertenece al equipo 0
	floor._on_match_state_changed({"pool_balances": [1000, 200], "finished": true, "winning_team": 0, "reason": "goal_reached"})
	assert_true(floor.get_node("Hud/VictoryOverlay").visible)
	assert_false(floor.get_node("Hud/DefeatOverlay").visible)

func test_victory_overlay_hidden_for_losing_team() -> void:
	var floor := _make_casino_floor()
	# simula equipo local 1, ganó el equipo 0
	floor._on_match_state_changed({"pool_balances": [1000, 200], "finished": true, "winning_team": 0, "reason": "goal_reached"})
	assert_false(floor.get_node("Hud/VictoryOverlay").visible)
	assert_true(floor.get_node("Hud/DefeatOverlay").visible)
```

**Implementación**: nuevo nodo `VictoryOverlay` en `scenes/casino_floor.tscn`,
hermano de `DefeatOverlay` dentro de `Hud`, mismo patrón estructural
(`mouse_filter = 2`, panel centrado con `StyleBoxFlat`), acento
`CasinoTheme.ACCENT_GREEN`/`CasinoTheme.GOLD_ACCENT` en vez de rojo.

En `_on_match_state_changed`, decide overlay según equipo local:

```gdscript
func _on_match_state_changed(state: Dictionary) -> void:
	var msg := "Pozo A: %d | Pozo B: %d" % [state["pool_balances"][0], state["pool_balances"][1]]
	if state["finished"]:
		msg += " — FIN (equipo %d, %s)" % [state["winning_team"], state["reason"]]
		var my_team := battle_controller.team_for(multiplayer.get_unique_id())
		if my_team == state["winning_team"]:
			_show_result_overlay(victory_overlay, "¡GANASTE!", "Tu equipo ganó — %s" % _reason_label(state["reason"]))
		elif my_team != -1:
			_show_result_overlay(defeat_overlay, "PERDISTE", "Tu equipo perdió — %s" % _reason_label(state["reason"]))
	_state_line = msg
	_refresh_battle_label()
	...
```

Añade `@onready var victory_overlay: Control = $Hud/VictoryOverlay`
junto al resto de `@onready` existentes.

## Tarea 3 — celebración de victoria (pulso/confeti simple)

**Test primero:** verifica que mostrar el overlay no lanza error al
arrancar el efecto (un test de humo basta, no hace falta verificar
frames de animación exactos):

```gdscript
func test_victory_celebration_does_not_error() -> void:
	var floor := _make_casino_floor()
	floor._on_match_state_changed({"pool_balances": [1000, 0], "finished": true, "winning_team": 0, "reason": "goal_reached"})
	pass_test("no crashea al disparar la celebración")
```

**Implementación** (elige una, no ambas): pulso de brillo dorado —

```gdscript
func _play_victory_pulse(panel: Control) -> void:
	var tween := create_tween().set_loops(3)
	tween.tween_property(panel, "modulate", CasinoTheme.GOLD_ACCENT, 0.3)
	tween.tween_property(panel, "modulate", Color.WHITE, 0.3)
```

— o confeti simple (8-12 `ColorRect` de 6x12px, posición X aleatoria en
el ancho del overlay, animados cayendo + fade con `Tween`, generados de
nuevo cada vez que se muestra la pantalla, `queue_free()` al terminar).
Cualquiera de las dos cumple el spec — prioriza la más simple de testear
sin flaky timing.

## Reporte final a pilar

Rama, commits, `X/X tests` tras reconstruir caché de clases, capturas o
confirmación (si pudiste probar en vivo) de ambos overlays, y si el
efecto de celebración elegido fue pulso o confeti.

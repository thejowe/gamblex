# Plan: reskin visual de Póker — Agente 31

Lee primero `docs/superpowers/specs/2026-08-27-poker-visual-design.md`.
Referencia visual ya copiada en
`docs/superpowers/specs/references/poker-reference.webp` — ábrela antes
de empezar. TDD: test antes que implementación en cada tarea. Reconstruye
la caché de clases (`godot --headless --editor --quit --path .`) antes
de cualquier run de GUT que dependa de scripts nuevos con `class_name`.

## Aviso importante sobre `FeltTablePanel` — léelo antes de la Tarea 1

`FeltTablePanel._draw()` (`scripts/ui/casino/felt_table_panel.gd`) dibuja
un **semi-óvalo** (`_arc_points` recorre `t` de `0` a `PI`, es decir solo
la mitad superior de una elipse) — encaja con Blackjack porque ahí el
crupier está arriba y los jugadores en una fila abajo, nunca rodeando la
mesa entera. **Póker necesita un óvalo completo** (6 asientos alrededor,
como la referencia). No dupliques el componente ni inventes uno nuevo
desde cero — añade un parámetro:

```gdscript
@export var full_oval: bool = false  # false = comportamiento actual (Blackjack), true = elipse completa
```

y en `_arc_points`, cuando `full_oval` sea `true`, recorre `t` de `0` a
`TAU` en vez de `0` a `PI` (verifica tú el rango exacto necesario para
que el polígono cierre bien — probablemente necesitas duplicar la
llamada a `_draw_wood_rail`/`_draw_felt` sin cambiar su firma, solo lo
que `_arc_points` genera puede depender de `full_oval`). Confirma con un
test de Blackjack existente (`test_felt_table_panel.gd` si existe, o
revisa a mano) que el comportamiento por defecto (`full_oval = false`)
no cambia nada de lo que Blackjack ya tiene — **cero regresión en
Blackjack**, es la única mesa que ya usa este componente en producción.

## Tarea 1 — `FeltTablePanel` con óvalo completo opcional

**Test primero** (añade a un test existente de `FeltTablePanel` si lo
hay, o crea `tests/unit/test_felt_table_panel.gd`):

```gdscript
extends GutTest

func test_default_behavior_unchanged() -> void:
	var panel := FeltTablePanel.new()
	panel.size = Vector2(900, 1080)
	add_child_autofree(panel)
	assert_false(panel.full_oval)  # default sigue siendo el de Blackjack

func test_full_oval_flag_settable() -> void:
	var panel := FeltTablePanel.new()
	panel.full_oval = true
	add_child_autofree(panel)
	assert_true(panel.full_oval)
```

No hay mucho más que testear automatizado de un `_draw()` — el resto se
confirma visualmente. Implementa el flag, corre los tests de Blackjack
completos (`test_blackjack_table_net.gd` o el que exista) para confirmar
cero regresión.

## Tarea 2 — `seat_anchor_oval(seat_index, seat_count)`

**Test primero** (`tests/unit/test_poker_table_net.gd`, nuevo):

```gdscript
extends GutTest

func test_seat_anchor_oval_distributes_around_ellipse() -> void:
	var scene := load("res://scenes/poker_table_net.tscn")
	var instance := scene.instantiate()
	instance.size = Vector2(900, 1080)
	add_child_autofree(instance)
	var anchors: Array[Vector2] = []
	for i in 6:
		anchors.append(instance.seat_anchor_oval(i, 6))
	# Los 6 puntos deben ser distintos entre sí (sin dos asientos superpuestos)
	for i in 6:
		for j in range(i + 1, 6):
			assert_gt(anchors[i].distance_to(anchors[j]), 30.0)
	# Todos dentro del área visible
	for a in anchors:
		assert_between(a.x, 0.0, 900.0)
		assert_between(a.y, 0.0, 1080.0)
```

**Implementación**, nueva función en `scenes/poker_table_net.gd`:

```gdscript
func seat_anchor_oval(seat_index: int, seat_count: int) -> Vector2:
	var center := Vector2(size.x / 2.0, size.y * 0.42)
	var radius := Vector2(size.x * 0.42, size.y * 0.32)
	# Empieza en la parte inferior-central (hueco para tus propias cartas,
	# igual que la referencia) y reparte el resto en sentido horario.
	var start_angle := PI / 2.0 + (PI / float(seat_count))
	var angle := start_angle + TAU * float(seat_index) / float(seat_count)
	return center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
```

Ajusta las constantes (`0.42`, `0.32`, el offset del ángulo inicial)
a ojo hasta que los 6 puntos queden repartidos de forma razonable sin
solaparse con la fila de botones de abajo — el test solo comprueba que
no se solapen entre sí y queden dentro del área, no una posición exacta.

## Tarea 3 — reconstruir la escena: fieltro + asientos + cartas + fichas

Reescribe `scenes/poker_table_net.tscn` y `scenes/poker_table_net.gd`
sustituyendo los `Label`/`Button` planos por:

- `FeltTablePanel` (`full_oval = true`) como fondo, tamaño completo.
- Un nodo `Control` por asiento (`SeatsRoot/Seat0`...`Seat5`) posicionado
  en `seat_anchor_oval(i, 6)`, cada uno con:
  - Avatar circular procedural (nuevo componente pequeño, o `_draw()`
    directo en el mismo `Control` del asiento — tu elección de diseño,
    documenta cuál elegiste) con la inicial de `_display_name(player_id)`
    sobre un color determinista por `player_id` (ej. `Color.from_hsv(
    (player_id % 8) / 8.0, 0.55, 0.75)`).
  - Nombre + fichas (`balance`) en texto pequeño debajo del avatar.
  - Dos `PlayingCard` (instancias de `res://scenes/ui/casino/playing_card.tscn`)
    para `hole_cards` — `face_up = true` si `hole_cards` no viene vacío
    (te toca a ti o es showdown), si no, dos cartas con `face_up = false`
    (dorso) mientras `hand_active` sea cierto y el asiento esté ocupado
    y no retirado.
  - Un `CasinoChip` (o 2-3 apilados con pequeño offset si `current_bet`
    es alto — umbral a tu criterio, no hace falta exactitud) cerca del
    asiento si `current_bet > 0`.
  - Atenuar visualmente (p.ej. `modulate = Color(1,1,1,0.4)`) el asiento
    si `folded == true`.
- Ficha de dealer "D" (círculo dorado pequeño, `CasinoTheme.GOLD_ACCENT`)
  posicionada junto al asiento en `dealer_button_index`.
- Cartas comunitarias: fila de hasta 5 `PlayingCard` centradas en medio
  del óvalo, `face_up = true` siempre (nunca se ocultan).
- Label de bote centrado arriba de las cartas comunitarias, estilo
  `CasinoTheme.GOLD_ACCENT`, tamaño de fuente grande — reemplaza al
  `PotLabel` actual, mismo dato (`state["pot"]`).
- Fila de botones de acción abajo (`CasinoButton`): Sentarse (si no
  estás sentado), Repartir (si eres el único con permiso — igual que
  antes, deshabilitado según `occupied_seats < 2` o `hand_active`),
  Retirarse/Pasar/Igualar/Subir (deshabilitados según `is_my_turn`,
  misma lógica que ya existe en `_on_state_changed`, no la reinventes).
- Mantén `HelpButton`/`HelpOverlay` (Plan 28) — solo reposiciónalos si
  el nuevo layout los tapa.

**Test de estructura** (`tests/unit/test_poker_table_scene_structure.gd`,
nuevo o actualizado): confirma que los nodos clave existen
(`FeltTablePanel`, `SeatsRoot` con 6 hijos, `HelpButton`, `HelpOverlay`,
botones de acción) sin verificar posiciones exactas en píxeles (mismo
criterio que otros tests de estructura del proyecto desde Plan 23).

## Tarea 4 — enganchar `AudioManager`

- `AudioManager.play_sfx("card")` cuando cambian las cartas comunitarias
  o tus propias `hole_cards` respecto al estado anterior (compara
  `_last_state` contra el nuevo, mismo patrón que
  `_maybe_flash_result` de Dice/Mines).
- `AudioManager.play_sfx("chip")` cuando `_on_call_pressed`/
  `_on_raise_pressed` se disparan (ya existen esas funciones, añade la
  línea).
- `AudioManager.play_sfx("win")` si `last_winner_seats` incluye
  `my_seat_index` y es la primera vez que se ve ese resultado (guarda
  un flag `_last_winner_seats_seen` o compara contra `_last_state`, no
  sonar en cada refresco RPC repetido — mismo cuidado que Plan 26 con
  `_show_result_overlay`).
- `AudioManager.play_sfx("lose")` si la mano termina (`hand_active` pasa
  de `true` a `false`), estabas sentado y sin retirarte, y no estás en
  `last_winner_seats`.

## Tarea 5 — banner de mano ganada

**Test primero:**

```gdscript
func test_show_winner_banner_no_crash() -> void:
	var scene := load("res://scenes/poker_table_net.tscn")
	var instance := scene.instantiate()
	add_child_autofree(instance)
	instance._show_winner_banner(2, "jugador de prueba")
	pass_test("no crashea")
```

**Implementación**: banner corto (`Label` o `PanelContainer` pequeño)
posicionado en `seat_anchor_oval(seat_index, 6)` del asiento ganador,
aparece con un `Tween` (fade in 0.2s, se queda 2s, fade out 0.3s, luego
`queue_free()` o `visible = false`), texto "¡Gana [nombre]!". Dispara
desde `_on_state_changed` cuando `last_winner_seats` cambia de vacío a
no-vacío (mismo cuidado anti-duplicado que el resto de esta tarea).

## Tarea 6 — mejora opcional: slider de cantidad al subir

Solo si el tiempo alcanza tras las Tareas 1-5, TDD igual que el resto.
`HSlider` con rango `[current_bet + min_raise, balance_del_asiento]`,
label mostrando el valor actual, botón "Confirmar subida" que llama
`table_controller.raise_bet(my_seat_index, valor_del_slider)`. Si el
rango es inválido (`balance <= current_bet + min_raise`, jugador
all-in), oculta el slider y deja el botón "Subir" actual con el
comportamiento de incremento fijo que ya tiene. No cambies ninguna
firma de `PokerTableController`/`PokerTableState` — la interfaz
`raise_bet(seat_index, raise_to)` ya existe tal cual.

## Reporte final a pilar

Rama, commits, `X/X tests` tras reconstruir caché, confirmación
explícita de que Blackjack sigue con `0` regresiones (corre su test
suite completa, no solo la de Póker), qué partes de la Tarea 6
(opcional) llegaste a hacer, y qué verificación visual pudiste hacer
(headless/capturas) dado que no hay forma de probar una mano de 6
jugadores reales en este entorno.

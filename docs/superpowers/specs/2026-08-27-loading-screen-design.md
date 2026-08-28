# Spec: pantalla de carga / transición — Ampliación v1.7, Agente 27

## Contexto

`assets/pixels/ASSETS.md` línea 85 lo dice explícito: "hoy no existe
ninguna pantalla de carga en el código, ni siquiera el splash de Godot
está personalizado". El único punto de transición de escena de todo el
proyecto es `scenes/lobby_menu.gd::_go_to_casino_floor()` (línea 78):

```gdscript
func _go_to_casino_floor() -> void:
	if _transitioned:
		return
	_transitioned = true
	get_tree().change_scene_to_file("res://scenes/casino_floor.tscn")
```

Corte seco, sin ningún feedback visual. `LobbyMenu` ya tiene feedback
textual de conexión Steam (`error_label`, `members_label`, deshabilitar
`create_button` mientras Steam no está listo) — este agente no toca ese
flujo, solo el instante del cambio de escena en sí.

Carpeta de arte reservada `assets/pixels/carga/loading_bg/` — vacía a
propósito, sin imagen todavía. Mismo criterio "sin pipeline de arte" que
Plan 14 (visual) y Agente 25 (audio): la pantalla de carga es 100%
procedural (`ColorRect` + `Tween` + `_process`), reemplazable después sin
tocar el resto del código cuando llegue el fondo real.

## Caveat técnico real de Godot (por qué el diseño es así)

`get_tree().change_scene_to_file()` es **síncrono**: instancia la nueva
escena en el mismo frame, bloqueando el hilo principal un instante
(hitch). No hay margen real para animar un spinner "mientras carga" salvo
que se use carga asíncrona (`ResourceLoader.load_threaded_request`), que
está fuera de alcance aquí (complejidad no justificada para una escena
tan ligera como `casino_floor.tscn`). Diseño elegido: fundido a
`PANEL_NAVY_DARK` **antes** del cambio de escena (esto sí se anima,
ocurre en `LobbyMenu` con tiempo de sobra), el hitch ocurre con la
pantalla ya completamente opaca (invisible para el jugador, se lee como
intencional, no como un tirón), y la nueva escena aparece ya cargada del
otro lado. No hay fade-in explícito de vuelta (eso viviría en
`casino_floor.gd`, fuera de alcance de este agente).

## Qué construye

- `scenes/ui/casino/loading_screen.tscn`/`.gd` — overlay reutilizable:
  `ColorRect` a pantalla completa (`PANEL_NAVY_DARK`), un indicador
  simple animado por código (3 puntos pulsando opacidad en secuencia, o
  un arco girando con `_process` — a elección del agente ejecutor,
  barato de implementar) centrado, opcional texto "Cargando…" con
  `CasinoTheme.TEXT_LIGHT`.
- Método público, p.ej. `LoadingScreen.fade_and_change_scene(path:
  String, fade_sec: float = 0.4) -> void` — hace el tween de opacidad
  0→1, espera a que termine (`await`), llama
  `get_tree().change_scene_to_file(path)`.
- `lobby_menu.gd::_go_to_casino_floor()` instancia el `LoadingScreen`
  (como hijo de sí misma, `add_child` + `move_to_front` o similar para
  que quede encima de todo) y llama a ese método en vez de
  `change_scene_to_file` directo.

## Fuera de alcance

- Fade-in de llegada a `CasinoFloor` (tocaría `casino_floor.gd`/`.tscn`,
  fuera de alcance de este agente).
- Carga asíncrona/progreso real (no hay nada pesado que cargar de forma
  incremental hoy).
- Pantalla de carga durante la espera de Steam (ya cubierta por texto
  existente) — opcional, a discreción del agente, no es el foco.
- Imagen de fondo real (`loading_bg/`, vacía, fase futura).
- Audio — no depende de `AudioManager` (Agente 25), no lo bloquea ni lo
  necesita.

## Archivos que toca (y solo esos)

`scenes/lobby_menu.gd`, `scenes/lobby_menu.tscn` (mínimo, solo para
instanciar el overlay), `scenes/ui/casino/loading_screen.tscn`/`.gd`
(nuevos). No toca `casino_floor.gd`/`.tscn`, no toca `AudioManager`, no
toca ninguna mesa.

## Verificación

- GUT: `LoadingScreen` existe, su `ColorRect` cubre pantalla completa,
  `fade_and_change_scene()` no crashea al llamarse en un `SceneTree` de
  test (puede que el `change_scene_to_file` real no sea practicable
  dentro de GUT — si no, testea solo el tween/estado hasta el punto
  anterior a `change_scene_to_file` y deja explícito en el reporte qué
  parte quedó sin cobertura automatizada).
- Verificación en vivo: confirmar que el corte Lobby→CasinoFloor ya no
  es un salto seco sino un fundido a navy y vuelta — pendiente de que el
  usuario lo confirme jugando, como todo lo demás de esta ampliación.

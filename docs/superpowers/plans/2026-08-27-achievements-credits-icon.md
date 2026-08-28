# Plan: logros de Steam + créditos + icono/splash — Agente 30

Lee primero `docs/superpowers/specs/2026-08-27-achievements-credits-icon-design.md`
— este plan lo implementa tal cual, no repitas el porqué, solo el cómo.
Tres tareas independientes entre sí, puedes hacerlas en cualquier orden.

## Tarea A — icono y splash (la más rápida, empieza por aquí)

Sin test GUT sensato (es config de motor + un asset estático) — verifica
visualmente lanzando el juego con el binario estándar.

`assets/icon.svg` (128×128, ficha de casino simple, colores exactos de
`CasinoTheme`):

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <circle cx="64" cy="64" r="60" fill="#131b26" stroke="#e8c468" stroke-width="6"/>
  <circle cx="64" cy="64" r="46" fill="none" stroke="#e8c468" stroke-width="2" stroke-dasharray="6 5"/>
  <circle cx="64" cy="64" r="34" fill="#1c2733" stroke="#4caf6e" stroke-width="3"/>
  <text x="64" y="78" font-family="Georgia, 'Times New Roman', serif" font-size="38"
        font-weight="bold" fill="#f0e6d2" text-anchor="middle">C</text>
</svg>
```

(El borde punteado dorado sobre el círculo exterior imita el canto
ranurado de una ficha real — ajusta `stroke-dasharray` a tu gusto, no es
crítico.)

`project.godot`, dentro de `[application]` (añade las claves, no borres
`config/name`/`run/main_scene`/`config/features` que ya están):

```
config/icon="res://assets/icon.svg"
boot_splash/bg_color=Color(0.0745, 0.1059, 0.149, 1)
boot_splash/image="res://assets/icon.svg"
```

Verifica que Godot importa el `.svg` sin error
(`.godot/imported/icon.svg-*.ctex` debe generarse) corriendo
`godot --headless --editor --quit --path .` una vez tras crear el
archivo.

## Tarea B — pantalla de créditos

**Test primero** (`tests/unit/test_credits_menu.gd`):

```gdscript
extends GutTest

const CreditsMenuScene := preload("res://scenes/ui/casino/credits_menu.tscn")

func test_instantiates_without_error() -> void:
	var instance := CreditsMenuScene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance)

func test_back_button_exists() -> void:
	var instance := CreditsMenuScene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance.get_node("BackButton"))
```

**Implementación**: `scenes/ui/casino/credits_menu.tscn` — `Control`
raíz a pantalla completa (mismo patrón de anchors reales que el resto
del proyecto desde la Ampliación v1.6, no offsets absolutos), fondo
`ColorRect` color `CasinoTheme.PANEL_NAVY_DARK`, `VBoxContainer` centrado
con:

- `Label` título "Casino Pixel" (fuente grande, `CasinoTheme.GOLD_ACCENT`).
- `Label` "Desarrollado por thejowe".
- `Label` multilínea de agradecimientos — texto exacto de la licencia de
  cada dependencia sacado de `addons/godotsteam/license.md` y
  `addons/gut/LICENSE.md` (léelos primero, no asumas MIT si dicen otra
  cosa).
- `CasinoButton` (`BackButton`, variante `NEUTRAL`) "‹ Volver".

`credits_menu.gd`:

```gdscript
extends Control

@onready var back_button: CasinoButton = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby_menu.tscn")
```

**Enganche en `LobbyMenu`**: añade `CasinoButton` "Créditos" a
`scenes/lobby_menu.tscn`, conectado en `lobby_menu.gd` a
`get_tree().change_scene_to_file("res://scenes/ui/casino/credits_menu.tscn")`.
Colócalo donde quepa sin solapar los botones existentes
(`CreateButton`/`MatchTypeOption`/`InviteButton`/`CancelButton`/
`MembersLabel`/`ErrorLabel` — revisa sus `offset_*` reales en el archivo
antes de decidir la posición, no adivines coordenadas).

## Tarea C — logros de Steam

No hay test GUT real posible (necesita Steam corriendo) — documenta esa
limitación en tu reporte en vez de fingir cobertura. Sí puedes testear
que la función wrapper no crashea si `SteamManager.is_ready` es `false`
(caso headless/sin Steam, que es el 100% de esta sesión de desarrollo):

```gdscript
func test_unlock_achievement_noop_when_steam_not_ready() -> void:
	var original_ready: bool = SteamManager.is_ready
	SteamManager.is_ready = false
	SteamManager.unlock_achievement("TEST_ACHIEVEMENT")  # no debe crashear
	SteamManager.is_ready = original_ready
	pass_test("no crashea sin Steam listo")
```

**Implementación**, añadido a `autoloads/steam_manager.gd`:

```gdscript
func unlock_achievement(achievement_api_name: String) -> void:
	if not is_ready:
		return
	var ok: bool = Steam.setAchievement(achievement_api_name)
	if ok:
		Steam.storeStats()
	print("SteamManager: logro '%s' -> setAchievement=%s" % [achievement_api_name, ok])
```

Confirma el nombre real de `Steam.setAchievement`/`Steam.storeStats`
contra la build real del addon si algo no cuadra al probar — el spec ya
trae los nombres verificados por la sesión pilar, pero GodotSteam cambia
firmas entre versiones menores, así que si algo no compila, revisa la
documentación de la versión exacta instalada (`addons/godotsteam/plugin.cfg`
dice `4.21`) antes de asumir que el spec tiene razón.

**Puntos de disparo** (IDs placeholder de la tabla del spec):

- `scripts/net/casino_floor.gd::_set_pool_unlocked_if_reached_goal()` →
  al pasar de no-desbloqueado a desbloqueado,
  `SteamManager.unlock_achievement("FREE_MODE_GOAL_REACHED")`.
- `scripts/net/casino_floor.gd::_on_match_state_changed()` → si
  `state["finished"]` y `state["winning_team"] ==
  battle_controller.team_for(multiplayer.get_unique_id())`,
  `SteamManager.unlock_achievement("BATTLE_MODE_WIN")`. Si al llegar
  aquí `plan26` (pantallas de victoria/derrota) ya está mergeado a
  `main` y ya tiene su propia detección de "gané" en este mismo sitio,
  añade la llamada al logro junto a la suya — no dupliques el `if`.
- `bet_sidebar_panel.gd`, dentro del handler de `bet_pressed(amount)` (o
  donde el sidebar ya procese la apuesta) → si `amount >= 100`,
  `SteamManager.unlock_achievement("HIGH_ROLLER")`.
- Mines: busca dónde `mines_table_state.gd` cuenta casillas reveladas
  con éxito en la ronda actual; si el conteo llega a 5 sin mina,
  `SteamManager.unlock_achievement("MINES_SURVIVOR")`.
- "Primera ronda ganada": el más difícil de anclar sin tracking nuevo —
  si no encuentras un punto limpio y único donde todas las mesas ya
  notifiquen "gané fichas" al cliente local, es aceptable dejarlo fuera
  y decirlo explícito en el reporte en vez de inventar un sistema de
  tracking nuevo solo para esto.

## Reporte final a pilar

Rama, commits, `X/X tests` tras reconstruir caché de clases, confirmar
que `assets/icon.svg` se ve en la ventana al lanzar el juego real (no
solo headless) si tuviste oportunidad, qué logros quedaron enganchados
de verdad y a cuáles tuviste que renunciar y por qué, y el texto de
licencias que usaste en créditos (por si la sesión pilar quiere
revisarlo antes de dar el agente por cerrado).

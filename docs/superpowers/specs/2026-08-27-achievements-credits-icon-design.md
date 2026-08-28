# Spec: logros de Steam + créditos + icono/splash — Ampliación v1.7, Agente 30

## Contexto

Auditoría de la sesión pilar (2026-08-27): cero logros (ni locales ni de
Steam, aunque el juego ya corre sobre Steamworks vía GodotSteam v4.21),
cero pantalla de créditos, `project.godot` sin `config/icon` (usa el
robot de Godot por defecto en ventana/taskbar) y sin splash
personalizado. Tres piezas de pulido final, pequeñas e independientes
entre sí, agrupadas en un solo agente porque ninguna por separado
justifica su propia rama.

Parte de la Ampliación v1.7 (audio, menús de sistema, pantallas que
faltan). **Sin dependencia dura de ningún otro agente de la ampliación**
— no llama a `AudioManager` (plan25) ni a nada de plan26/29. Sí comparte
archivos con ellos (`scripts/net/casino_floor.gd`, `scenes/lobby_menu.tscn`)
sin coordinación de código real — conflicto textual esperado al mergear,
lo resuelve la sesión pilar, no bloquea el arranque de este agente.

## 1. Logros de Steam

API confirmada contra documentación/changelog real de GodotSteam antes de
escribir este spec (no inventada):

```gdscript
Steam.setAchievement(achievement_api_name: String) -> bool   # marca desbloqueado localmente
Steam.getAchievement(achievement_api_name: String) -> Dictionary  # {"ret": bool, "achieved": bool} — confirma el shape exacto del Dictionary contra la build real del addon en tu sesión (GodotSteam a veces cambia claves entre versiones), no asumas ciegamente estos dos nombres de clave
Steam.storeStats() -> bool  # persiste a los servidores de Steam — llamar tras cada setAchievement
```

`requestCurrentStats()` **no hace falta** en GodotSteam 4.14+ (este
proyecto usa 4.21, ver `addons/godotsteam/plugin.cfg`) — stats y logros
se sincronizan solos al arrancar el cliente Steam.

**Los IDs de logro son placeholder.** No hay app de Steamworks Partner
real detrás de este proyecto (es desarrollo, no publicado) — los
`achievement_api_name` que uses (`"WIN_FIRST_HAND"`, `"REACH_GOAL"`,
etc.) no existen en ningún backend de Steam todavía. `setAchievement`
sobre un ID no registrado en el backend no debe crashear el juego (según
la documentación de Steamworks, la llamada simplemente no tiene efecto
persistente hasta que el ID se dé de alta en el Partner Portal) — el
código debe ser defensivo de todas formas: envuelve cada llamada,
registra el intento con `print()`, nunca asumas que `setAchievement`
devolvió `true`.

**Logros diseñados (4-6), todos enganchados a eventos que YA existen —
no crear tracking nuevo:**

| ID (placeholder) | Evento | Dónde |
|---|---|---|
| `WIN_FIRST_ROUND` | primera ronda ganada en cualquier mesa (bandera local `_has_won_once` en el cliente, primera vez que ve `chips_won > 0` en cualquier `*_table_controller`) | punto donde cada mesa ya notifica ganancia al jugador |
| `FREE_MODE_GOAL_REACHED` | meta colectiva de Modo Libre alcanzada | `scripts/net/casino_floor.gd::_set_pool_unlocked_if_reached_goal()` |
| `BATTLE_MODE_WIN` | victoria en Modo Batalla (tu equipo) | `scripts/net/casino_floor.gd::_on_match_state_changed()`, mismo punto exacto que usará plan26 para su pantalla de victoria — **no dupliques la detección de "gané", solo añade la llamada al logro junto a la lógica que exista o esté por llegar; si plan26 ya está en `main` cuando trabajes, reutiliza su condición, no la reescribas** |
| `MINES_SURVIVOR` | revelar 5+ casillas seguras en una ronda de Mines sin explotar | `scripts/mines/mines_table_state.gd` o donde ya se trackee el conteo de revelados |
| `HIGH_ROLLER` | apostar 100+ fichas de una vez en cualquier mesa | `bet_sidebar_panel.gd`, señal `bet_pressed(amount)` |

No es una lista cerrada — si al implementar ves que alguno no cuadra con
el código real, sustitúyelo por otro igual de barato en vez de forzarlo.

## 2. Pantalla de créditos

Nueva escena `scenes/ui/casino/credits_menu.tscn`/`.gd`, mismo lenguaje
visual que el resto (`CasinoTheme`: fondo `PANEL_NAVY_DARK`, acento
`GOLD_ACCENT`, texto `TEXT_CREAM`). Contenido:

- Título: "Casino Pixel" (nombre real del proyecto en `project.godot`).
- Desarrollador: `thejowe` (usuario git configurado en este repo).
- Agradecimientos: Godot Engine (MIT), GodotSteam
  (`addons/godotsteam/license.md`), GUT
  (`addons/gut/LICENSE.md`) — lee ambos archivos de licencia antes de
  escribir el texto de atribución, para citar el nombre de licencia
  correcto de cada uno en vez de asumir.
- Botón "‹ Volver" al `LobbyMenu`.

Accesible desde `LobbyMenu` con un botón nuevo "Créditos", junto a donde
plan29 (si ya existe cuando trabajes) o tú mismo coloquéis el resto de
botones de navegación. **Conflicto textual esperado con plan29 en
`lobby_menu.tscn`** (ambos añaden un botón a la misma escena) — la
sesión pilar lo resuelve al mergear, no es tu responsabilidad evitarlo.

## 3. Icono y splash

Sin pipeline de arte real (mismo criterio que toda esta ampliación) — un
icono vectorial simple, autoría a mano en SVG (geometría básica, no
"arte"), en los colores exactos de `CasinoTheme`. Godot importa `.svg`
igual que cualquier otra imagen (usa el renderizador vectorial
integrado). Guárdalo en `assets/icon.svg`.

`project.godot`, sección `[application]`, claves confirmadas contra
documentación oficial de Godot 4 antes de escribir este spec:

```
config/icon="res://assets/icon.svg"
boot_splash/bg_color=Color(0.0745, 0.1059, 0.1490, 1)   # PANEL_NAVY_DARK en 0-1, no 0-255
boot_splash/image="res://assets/icon.svg"                # opcional: mismo icono como splash, mejor que el logo de Godot por defecto
```

`boot_splash/bg_color` y `boot_splash/image` están confirmados como
claves reales de `[application]`. **No hay confirmación fiable de una
clave `boot_splash/show_image` en esta sesión** (la documentación
consultada no la lista con certeza) — no la uses a ciegas; si quieres
suprimir del todo el logo de Godot sobre tu fondo, la vía segura es
poner `boot_splash/image` a tu propio `icon.svg` (lo sustituye) en vez
de intentar ocultarlo con una clave sin confirmar. Si quieres confirmar
`show_image` de verdad, ábrelo en el editor de Godot
(`Project > Project Settings > Application > Boot Splash`) y mira si
existe el checkbox — no lo escribas en `project.godot` a mano sin haberlo
visto ahí primero.

## Fuera de alcance

- Dar de alta los logros en el Steamworks Partner Portal real (fuera del
  repo, tarea humana futura).
- Iconos por plataforma (`.ico` de Windows con múltiples resoluciones) —
  el SVG único basta para esta fase, Godot lo reescala en el export.
- Rediseño de `LobbyMenu` — solo añades un botón, no reordenas el resto.

## Verificación

- Tests GUT: donde sea testeable sin Steam corriendo (p.ej. que
  `credits_menu.tscn` instancia sin error, que el botón "Créditos"
  existe en `lobby_menu.tscn` y su señal está conectada). **Los logros de
  Steam no son testeables de verdad en headless sin Steam corriendo** —
  sé explícito sobre esa limitación en el reporte final, igual que el
  resto del proyecto ya lo es con todo lo que depende de Steamworks en
  vivo.
- Verificación visual: `credits_menu.tscn` instanciada headless sin error
  de carga; icono aplicado visible en la ventana/taskbar al lanzar el
  juego real (no solo headless) si tienes oportunidad.

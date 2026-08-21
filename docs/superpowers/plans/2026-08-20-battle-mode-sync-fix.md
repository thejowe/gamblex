# Fix: `chosen_match_type` nunca se sincroniza del host al invitado

## Contexto / diagnóstico (hecho por la sesión pilar, 2026-08-20)

Playtest real con 2 cuentas Steam (1v1) reveló dos síntomas:

1. **Host (A):** crash en el Output al conectar B:
   ```
   E   _request_goal_state: Invalid call. Nonexistent function 'to_dict' in base 'Nil'.
     casino_floor.gd:120 @ _request_goal_state()
   ```
2. **Invitado (B):** no podía sentarse en ninguna mesa, ni encontraba el
   botón "Volver al lobby".

**Causa raíz confirmada leyendo el código** (no es solo teoría — la traza
de error de arriba encaja exacto con este flujo):

- `SteamManager.chosen_match_type` (`autoloads/steam_manager.gd:10`) solo se
  escribe en un sitio de todo el repo: `LobbyMenu._on_create_pressed()`
  (`scenes/lobby_menu.gd:27`), que **solo corre en el cliente del host**
  (quien pulsa "Crear"). Nunca se comunica al invitado — ni por RPC ni por
  dato de lobby Steam.
- El invitado se queda con el valor por defecto `-1` para siempre →
  `scripts/net/casino_floor.gd:43` (`_is_battle_mode =
  SteamManager.chosen_match_type != -1`) calcula **modo libre** en el
  invitado aunque el host eligió 1v1.
- El invitado, creyendo que está en modo libre, llama
  `request_goal_state()` (`casino_floor.gd:79`, rama `else`) en vez de
  `battle_controller.join()` + `battle_controller.request_state()`
  (`casino_floor.gd:75-77`, rama de batalla) — **nunca se une al pozo de
  equipo**, lo cual es la sospecha principal de por qué B no podía
  sentarse/apostar en modo batalla.
- El host, correctamente en modo batalla, nunca inicializa `goal` (solo se
  crea en la rama de modo libre, `casino_floor.gd:55`) — quedó `null`. Al
  recibir el RPC `_request_goal_state` de B, el host explota en
  `goal.to_dict()` (`casino_floor.gd:120`) porque `goal` es `Nil`. Esto
  reproduce el error exacto visto en el log de A.

No se investigó a fondo por qué A tampoco podía pulsar las tarjetas del
lobby — puede ser un síntoma más de esta misma causa (el crash del host
interrumpiendo algo), o un problema aparte. **Repetir el playtest tras este
fix antes de seguir investigando eso.**

## Fix

### Task 1 — Sincronizar `chosen_match_type` vía dato de lobby Steam

API real verificada con WebSearch (GodotSteam GDExtension, clase
Matchmaking): `Steam.setLobbyData(steam_lobby_id: int, key: String, value:
String) -> bool` (solo el dueño del lobby puede escribir) y
`Steam.getLobbyData(steam_lobby_id: int, key: String) -> String` (string
vacío si la key no existe).

En `autoloads/steam_manager.gd`:

- En `_on_lobby_created(connect_result, lobby_id)`, justo después de
  `current_lobby_id = lobby_id` y antes de `lobby_ready.emit(...)`: llamar
  `Steam.setLobbyData(lobby_id, "match_type", str(chosen_match_type))`.
  `chosen_match_type` ya está puesto correctamente en este punto porque
  `LobbyMenu._on_create_pressed()` lo asigna de forma síncrona *antes* de
  llamar a `SteamManager.create_lobby(...)`, y `_on_lobby_created` es el
  callback async que llega después.
- En `_on_lobby_joined(lobby_id, _permissions, _locked, response)`, en la
  rama del invitado real (después del `if lobby_id == current_lobby_id:
  return` que ya filtra al propio creador), antes de `lobby_ready.emit(...)`:
  leer el dato y parsearlo a un método pequeño y testeable, por ejemplo:
  ```gdscript
  static func parse_match_type(raw: String) -> int:
      return int(raw) if not raw.is_empty() else -1
  ```
  y usarlo: `chosen_match_type = parse_match_type(Steam.getLobbyData(lobby_id, "match_type"))`.
  Extraer esta función estática aparte (aunque sea trivial) es a propósito:
  es la única parte de este fix que se puede testear con GUT sin Steam real.

### Task 2 — Test unitario de la función de parseo

`tests/unit/test_steam_manager.gd` (o donde ya vivan tests de autoloads si
existen) — casos: `""` → `-1`; `"-1"` → `-1`; `"0"` (1v1) → `0`; `"2"`
(4v4) → `2`. No se puede testear `setLobbyData`/`getLobbyData` en sí sin
Steam real corriendo — no lo intentes, deja esa parte para el playtest
manual.

### Task 3 — (opcional, cosmético) Silenciar warning de división entera

`scripts/plinko/plinko_table_state.gd:28`:
```gdscript
result = result * (n - i) / (i + 1)
```
Genera warning `INTEGER_DIVISION` en el log — matemáticamente el resultado
intermedio siempre es exacto (es el truco estándar de calcular nCk
iterativo en enteros), así que no es un bug real, solo ruido. Añade
`@warning_ignore("integer_division")` en la línea anterior si quieres
limpiar el log; no toques el algoritmo.

### Task 4 — Verificación

1. `godot --headless --editor --quit --path .` (reconstruye caché de
   clases) y luego GUT (`-gdir=res://tests/unit`) — confirmar que sigue
   211+/211+ (211 + los nuevos de `parse_match_type`).
2. **Repetir el playtest real de 2 clientes Steam en 1v1** (el mismo que
   detectó este bug) y confirmar:
   - No aparece el error `_request_goal_state`/`Nonexistent function
     'to_dict'` en el host.
   - B se une correctamente al pozo de equipo (usa
     `battle_controller`/`request_state`, no `request_goal_state`).
   - B puede sentarse y apostar en una mesa.
   - Repetir el intento de A de pulsar las tarjetas del lobby — si sigue
     fallando, es un bug aparte, repórtalo a pilar con el log de Output
     completo de A en ese momento.

## Archivos a tocar

- `autoloads/steam_manager.gd` (fix principal)
- `tests/unit/test_steam_manager.gd` (nuevo, o el que corresponda)
- `scripts/plinko/plinko_table_state.gd` (opcional, 1 línea)

No toques `casino_floor.gd`, `battle_controller.gd`, ni ningún
`*_table_controller.gd` — su lógica ya es correcta una vez
`chosen_match_type` llega bien al invitado.

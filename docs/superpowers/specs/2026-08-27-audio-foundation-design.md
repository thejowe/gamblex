# Spec: fundación de audio (música + SFX) — Ampliación v1.7, Agente 25

## Contexto

Auditoría de la sesión pilar (2026-08-27) confirmó: cero `AudioStreamPlayer`
en todo el repo, cero buses de audio más allá del `Master` por defecto,
ninguna carpeta de assets de audio reservada (a diferencia de pixel art,
que sí tiene 108 carpetas en `assets/pixels/`). El proyecto no tiene ni
música ni efectos de sonido de ningún tipo.

Es el primer agente de la Ampliación v1.7 (pulido de producto: audio,
menús de sistema, pantallas que faltan). Es fundacional — el resto de
agentes de esta ampliación (`plan26`-`plan30`) llaman a la interfaz
pública que este agente construye, así que **debe mergearse a `main`
antes de que los demás arranquen** (mismo criterio que "Dice primero" en
la Ampliación v1.1).

## Decisión: sin pipeline de audio real, todo procedural

Mismo criterio que Plan 14 aplicó a lo visual ("sin pipeline de arte,
todo con `_draw()`/`StyleBoxFlat`/`Tween`"): no hay archivos `.ogg`/`.wav`
de música o SFX reales todavía, ni artista de sonido disponible. En vez de
bloquear el pulido de audio hasta que lleguen assets reales, este agente
genera el audio **proceduralmente en tiempo de ejecución** con
`AudioStreamGenerator`/`AudioStreamGeneratorPlayback` (API oficial de
Godot, confirmada contra la documentación antes de escribir este spec —
`mix_rate`/`buffer_length` en el generador, `push_frame(Vector2)`/
`get_frames_available()` en el playback, obtenido vía
`AudioStreamPlayer.get_stream_playback()`).

- **SFX**: tonos cortos generados con osciladores simples (seno/cuadrada)
  y envolvente ADSR básica (ataque/decay rápidos, sin sostenido largo) —
  clic de botón, ficha, carta, dado, giro de ruleta, victoria, derrota.
  Suficiente para que el juego "suene vivo" sin sonar a placeholder mudo.
- **Música**: un loop ambiental simple (pad/arpegio generado, no una
  composición real) para el lobby y otro, ligeramente distinto, para
  dentro de una mesa. Volumen bajo por defecto — es relleno, no debe
  cansar.
- **Reemplazable sin tocar el resto del código**: cuando llegue audio
  real (`.ogg` grabado/comprado), solo hay que sustituir la generación
  procedural dentro de `AudioManager` por `load()` de los streams reales
  — el resto del proyecto solo conoce `AudioManager.play_sfx(name)`/
  `play_music(name)`, nunca los streams ni cómo se generan.

## Interfaz pública (contrato para plan26-plan30)

Autoload `AudioManager` (`res://autoloads/audio_manager.gd`), registrado
en `project.godot` después de `NetworkManager`.

```gdscript
# SFX — dispara un sonido corto, no bloqueante, polifónico (varios a la vez)
AudioManager.play_sfx(sfx_name: String) -> void
# nombres válidos: "click", "chip", "card", "dice", "spin", "win", "lose"
# nombre desconocido: warning en consola, no crashea

# Música — loop con crossfade, no vuelve a arrancar si ya suena la misma pista
AudioManager.play_music(track_name: String, fade_in_sec: float = 1.0) -> void
# nombres válidos: "lobby", "table"
AudioManager.stop_music(fade_out_sec: float = 1.0) -> void

# Volumen — bus_name en {"Master", "Music", "SFX"}, db en escala AudioServer (negativo = más flojo)
AudioManager.set_bus_volume_db(bus_name: String, db: float) -> void
AudioManager.get_bus_volume_db(bus_name: String) -> float
AudioManager.set_bus_mute(bus_name: String, muted: bool) -> void
AudioManager.is_bus_muted(bus_name: String) -> bool
```

Persistencia: `AudioManager` guarda/carga sus propios volúmenes en
`user://settings.cfg`, sección `[audio]` (claves `master_db`/`music_db`/
`sfx_db`/`master_muted`/`music_muted`/`sfx_muted`), al cambiar cualquier
volumen y al `_ready()`. **Contrato de convivencia con plan29** (menú de
ajustes/pausa): ese agente añadirá su propia sección `[display]` al mismo
`user://settings.cfg` para el toggle pantalla completa — mismo archivo,
secciones distintas, sin conflicto real (es un archivo en tiempo de
ejecución del usuario, no un archivo del repo, así que tampoco hay
conflicto de git posible).

## Dónde se conectan los eventos (SFX)

- **Clic de botón**: `scripts/ui/casino/casino_button.gd::_on_press()` —
  único punto de hook para "click", porque prácticamente todos los
  botones del proyecto ya son `CasinoButton`. Una línea.
- **Ficha apostada**: `scripts/ui/casino/bet_sidebar_panel.gd`, señal
  `bet_pressed` — "chip".
- **Carta repartida**: `scripts/ui/casino/playing_card.gd` o el punto de
  Blackjack/Póker donde se anima el reparto — "card".
- **Dado/giro**: `DiceThresholdSlider`/`RouletteWheelDisplay.spin_to()` —
  "dice"/"spin".
- **Victoria/derrota**: donde el propio Agente 26 (pantallas de
  victoria/derrota) dispare su overlay — "win"/"lose". **Este agente no
  toca `casino_floor.gd`** para no pisar a plan26; solo deja la interfaz
  lista para que plan26 la llame.
- **Música**: `LobbyMenu._ready()` → `play_music("lobby")`; al entrar a
  una mesa dentro de `CasinoFloor` → `play_music("table")`; al volver al
  lobby de `CasinoFloor` (rejilla de 7 tarjetas, no salir de la sala) →
  de vuelta a `play_music("lobby")` si se considera oportuno (a criterio
  del agente, no es crítico).

## Fuera de alcance

- Menú de ajustes (control de volumen visible al jugador) — Agente 29.
- SFX/música específicos de victoria/derrota (el overlay en sí) — Agente 26.
- Audio real grabado/comprado — fase futura sin fecha.
- Mezcla profesional / mastering — un placeholder decente basta.

## Verificación

- Tests GUT: `AudioManager` expone las 6 funciones del contrato, bus
  layout tiene 3 buses (`Master`/`Music`/`SFX`), persistencia
  guarda/recarga volúmenes de un `ConfigFile` de prueba (no
  `user://settings.cfg` real, usar ruta temporal inyectable — mismo
  patrón que otros autoloads testeables del proyecto: exponer la ruta de
  config como constante o parámetro para poder apuntar a un archivo de
  test).
- Verificación en vivo (headless, sin audio real posible sin dispositivo):
  confirmar por log/print que `play_sfx`/`play_music` no lanzan error con
  cada nombre válido y que un nombre inválido solo genera warning.

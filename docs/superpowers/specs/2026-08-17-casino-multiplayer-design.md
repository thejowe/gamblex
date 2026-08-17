# Casino Multijugador Pixel Art — Diseño

Fecha: 2026-08-17
Estado: Aprobado, pendiente de plan de implementación

## Resumen

Juego de escritorio, estética pixel art, ambientado en un casino. Los jugadores comparten un mismo espacio (casino) donde ven las mesas de los demás en tiempo real, y pueden competir en batallas de equipos (1v1, 2v2, 4v4) o jugar libremente hacia una meta colectiva de grupo.

## Decisiones clave

- **Plataforma**: App de escritorio (no web, no móvil).
- **Motor**: Godot 4.
- **Distribución**: Steam. Coste: 100 USD de Steam Direct fee (pago único, recuperable tras 1000 USD en ventas).
- **Multijugador/networking**: Steamworks vía addon GodotSteam (gratis, open source). Steam Networking/Relay resuelve NAT sin servidor propio ni puertos abiertos. Emparejamiento vía Steam Lobbies (invitar desde overlay/lista de amigos de Steam), no código de sala manual.
- **Persistencia**: Ninguna entre partidas en v1. Todo (fichas, progreso) se reinicia cada vez que se crea una sala.
- **Juegos v1**: Blackjack, Ruleta, Póker. Se añaden más juegos después de tener estos tres terminados.

## Modos de juego

### Modo libre
Jugadores en el mismo casino sin competir entre sí. Existe una **meta colectiva de grupo**: un objetivo compartido (ej. acumular X fichas entre todos los presentes) que al cumplirse desbloquea algo (nueva mesa, cosmético, etc.).

### Modo batalla (1v1 / 2v2 / 4v4)
Equipos compiten dentro del mismo casino compartido, jugando lo que quieran (blackjack, ruleta, póker indistintamente).

- **Saldo por equipo**: en partidas con más de un jugador por bando, el saldo de fichas es un **pozo común compartido** entre los miembros del equipo, no individual.
- **Condición de victoria**:
  1. Si un equipo alcanza la meta de fichas fijada, gana inmediatamente.
  2. Si se agota el tiempo sin que nadie llegue a la meta, gana el equipo con más fichas.
  3. Si un equipo llega a bancarrota (saldo a 0), pierde automáticamente, sin esperar al resto de condiciones.

### Visibilidad compartida
Da igual el modo: todos los jugadores conectados al casino ven las mesas ajenas en vivo — quién apuesta, cuánto, y si gana o pierde — aunque estén jugando en otra mesa distinta.

## Arquitectura técnica

Godot 4 + GodotSteam. Modelo host-cliente (listen server): el jugador que crea el lobby de Steam es la autoridad de la partida; los clientes solo envían acciones, el host valida y decide el resultado, y propaga el estado a todos.

### Componentes

- **LobbyManager** — crea/une lobbies de Steam, gestiona tipo de partida (libre/1v1/2v2/4v4) y composición de equipos.
- **CasinoFloor** — escena principal compartida (planta del casino en pixel art) con las mesas de blackjack, ruleta y póker como nodos fijos. Todos los jugadores conectados comparten esta misma instancia.
- **TableController** (uno por mesa, autoridad en el host) — estado de una mesa: jugadores sentados, apuestas activas, resultado. Sincroniza a todos los clientes vía RPC/MultiplayerSynchronizer para que cualquiera pueda observar cualquier mesa en vivo.
- **ChipLedger** — saldo de fichas. Individual + contador de meta colectiva en modo libre; pozo único por equipo en modo batalla.
- **MatchRules** — árbitro del modo batalla: vigila meta, temporizador y bancarrota; decide la condición de victoria.
- **GameLogic (Blackjack / Ruleta / Póker)** — reglas de cada juego, módulos aislados, ejecutados solo en el host.

### Flujo de datos

Cliente envía acción → host valida (turno correcto, fondos suficientes) → host actualiza `TableController` y `ChipLedger` → host emite el nuevo estado por RPC a todos los presentes en `CasinoFloor` (no solo a los sentados en esa mesa) → cada cliente renderiza el update.

### Manejo de errores

- Jugador se desconecta de una mesa: su apuesta activa se resuelve (o se retira, según el juego) y su silla queda libre.
- Host se cae: la partida termina, se muestra pantalla de "partida interrumpida". No hay migración de host en v1 (posible mejora futura).
- Acción inválida de cliente (ej. apostar más de lo que tiene el equipo): el host la rechaza y no propaga cambio.

### Testing

- Lógica de cada juego (BJ/ruleta/póker) como módulos GDScript testeables de forma aislada, sin red, para verificar reglas y cálculo de pagos.
- Prueba manual multijugador con varias instancias del juego en local antes de probar con Steam real.
- Prueba de `MatchRules` con casos límite (empate en tiempo, bancarrota simultánea de ambos equipos).

## Fuera de alcance (v1)

- Persistencia de progreso entre partidas.
- Migración de host tras desconexión.
- Juegos más allá de blackjack, ruleta y póker.
- Servidor dedicado / relay propio (sustituido por Steam Networking).

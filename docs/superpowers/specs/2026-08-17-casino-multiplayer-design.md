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

## Ampliación v1.1: juegos de casino "originales" (Dice, Crash, Mines, Plinko)

Decidido 2026-08-19. A diferencia de Blackjack/Ruleta/Póker (mesa compartida,
turnos, varios jugadores interactuando entre sí), estos cuatro son **ronda
independiente por jugador contra la casa**: cada jugador apuesta y resuelve
su propia ronda cuando quiere, sin esperar turno ni compartir resultado con
nadie. Se mantiene la visibilidad compartida del spec original — todos los
presentes en `CasinoFloor` ven en vivo las rondas de los demás — pero nadie
más participa en la ronda de otro jugador.

**Margen de casa: 1%** en los cuatro juegos (estándar de casino online),
aplicado en la fórmula de pago de cada uno, no como un impuesto aparte.

### Componente nuevo: patrón de ronda independiente

No hay `TableController` con asientos. Cada juego define su propio
controlador (uno por mesa, autoridad en el host, mismo patrón RPC que
`TableController`/`RouletteTableController`), pero el estado que sincroniza
es **por jugador**, no un asiento compartido: cada cliente apuesta, el host
resuelve con RNG propio (`randi()`/`randf()` del host, sin necesidad de ser
"provably fair" — no hay dinero real, spec ya dice que las fichas se
reinician cada partida) y hace broadcast del resultado de *ese* jugador a
todos los presentes (para que lo vean en vivo), igual que
`TableController.chips_won` ya hace en Blackjack.

Construido primero por el Agente 8 (Dice, el más simple) como Plan base;
Crash/Mines/Plinko reutilizan la interfaz que defina, no inventan la suya.

### Dice

Jugador elige un número umbral (1-99) y dirección ("mayor que" / "menor
que"), más el monto apostado. El host tira un número aleatorio 0-99.99 y
decide victoria si cae del lado elegido.

- `win_chance = 100 - umbral` (si "mayor que") o `= umbral` (si "menor que").
- `multiplicador = 99 / win_chance` (el 99 en vez de 100 ya incorpora el 1%
  de margen).
- Pago si gana: `apuesta * multiplicador`. Si pierde, pierde la apuesta.

### Mines

Grid configurable (default 5×5 = 25 casillas) con N minas ocultas (default
3, configurable 1-24). Jugador aporta apuesta y empieza a revelar casillas
una a una. Cada casilla segura revelada sube el multiplicador acumulado;
puede retirarse ("cash out") en cualquier momento y cobrar
`apuesta * multiplicador_actual`. Si revela una mina, pierde la apuesta y
la ronda termina.

- Multiplicador tras revelar `k` casillas seguras, con `T` casillas totales
  y `M` minas: `mult(k) = 0.99 * C(T, k) / C(T - M, k)` (combinatorio,
  probabilidad justa de sobrevivir k revelados, con el 1% de margen
  aplicado como factor).
- El host decide las posiciones de las minas al empezar la ronda (RNG del
  host, no se revela al cliente hasta game over o cash-out).

### Crash

Un multiplicador empieza en 1.00x y sube con el tiempo (curva exponencial).
Jugador apuesta antes de que arranque la ronda; puede pulsar "retirar" en
cualquier momento mientras sube para cobrar `apuesta * multiplicador_actual`.
Si no se retira antes de que la ronda "explote", pierde la apuesta.

- Punto de explosión decidido por el host al arrancar la ronda (no
  incremental/adivinable):
  `r = randf()` (uniforme 0-1, evitar r=0);
  `crash_point = max(1.00, floor(100 * 0.99 / (1 - r)) / 100)`.
- Curva de subida: `multiplicador_actual(t) = 1.00 + growth_rate * t^2` (t en
  segundos desde el inicio de la ronda); `growth_rate` es una constante de
  diseño (no fijada aún — el Agente 8/9 la ajusta para que una ronda típica
  dure entre 3 y 15 segundos antes de explotar en el rango medio de
  multiplicadores).
- Cliente ve el multiplicador subir en tiempo real (broadcast periódico del
  host o extrapolación local desde el timestamp de inicio); el host es la
  única autoridad sobre cuándo "explota".

### Plinko

Bola cae desde arriba por un tablero de clavijas con `rows` filas
(default 12, configurable). En cada fila rebota a izquierda o derecha con
50/50 de probabilidad. Cae en uno de `rows + 1` slots al fondo, cada uno
con un multiplicador fijo — los slots centrales pagan menos de 1x, los de
los extremos pagan mucho más (curva simétrica tipo binomial invertida).

- El host tira `rows` bits aleatorios (izquierda/derecha) y determina el
  slot final = número de rebotes a la derecha (0..rows).
- Tabla de multiplicadores por slot: distribución binomial invertida
  normalizada a 0.99 de retorno esperado total — el Agente responsable la
  calcula (no hay tabla fija todavía; debe verificar con su test que el
  retorno esperado da ~99%).
- No hace falta simular física real de la bola — solo el resultado final
  (slot) importa para el pago; la animación de caída es puramente visual y
  puede ser aproximada.

## Fuera de alcance (v1 / v1.1)

- Persistencia de progreso entre partidas.
- Migración de host tras desconexión.
- Juegos más allá de blackjack, ruleta, póker, dice, crash, mines y plinko.
- Servidor dedicado / relay propio (sustituido por Steam Networking).
- "Provably fair" verificable por el cliente (seeds firmados, hash previo)
  — no hace falta sin dinero real; el RNG del host basta.

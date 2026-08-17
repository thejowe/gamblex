# Blackjack en Solitario Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sentar la base del proyecto Godot (estructura, testing) y construir la lógica de Blackjack jugable en solitario contra la banca, sin networking todavía.

**Architecture:** Proyecto Godot 4 con GDScript puro para la lógica de juego (clases `RefCounted`, sin dependencia de nodos de escena), testeado con el framework GUT en modo headless. Una escena mínima (`BlackjackTable`) conecta la lógica a botones de UI para poder jugar manualmente. Este plan es la base sobre la que Plan 2 (Steam) y Plan 3 (CasinoFloor multijugador) añadirán red sin tocar la lógica de juego aquí construida.

**Tech Stack:** Godot 4.x, GDScript, addon GUT (Godot Unit Test) para testing headless.

**Spec:** `docs/superpowers/specs/2026-08-17-casino-multiplayer-design.md`

## Global Constraints

- Motor: Godot 4.x (spec: "Motor: Godot 4").
- Este plan NO incluye networking ni Steam — se añade en Plan 2 y Plan 3. La lógica debe quedar aislada de nodos de escena para poder reutilizarse tal cual cuando se sincronice por red.
- Sin persistencia entre partidas (spec: "Ninguna entre partidas en v1") — el estado vive solo en memoria mientras corre la partida.
- El juego objetivo de este plan es únicamente Blackjack (spec v1 incluye también Ruleta y Póker, cubiertos en planes posteriores).

---

## Task 1: Proyecto Godot + framework de testing GUT

**Files:**
- Create: `project.godot`
- Create: `addons/gut/` (addon descargado, no se escribe a mano)
- Create: `tests/unit/test_smoke.gd`

**Interfaces:**
- Produce: comando de test headless reutilizable por el resto de tareas: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`

- [ ] **Step 1: Crear estructura de carpetas**

```bash
mkdir -p scripts/blackjack tests/unit scenes
```

- [ ] **Step 2: Crear `project.godot`**

```ini
config_version=5

[application]

config/name="Casino Pixel"
config/features=PackedStringArray("4.3", "GL Compatibility")

[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

- [ ] **Step 3: Descargar e instalar el addon GUT**

```bash
GUT_URL=$(curl -s https://api.github.com/repos/bitwes/Gut/releases/latest | grep browser_download_url | grep '.zip' | cut -d '"' -f 4)
curl -L "$GUT_URL" -o /tmp/gut.zip
unzip -q /tmp/gut.zip -d /tmp/gut_extracted
mkdir -p addons
cp -r /tmp/gut_extracted/*/addons/gut addons/gut
```

Verifica que exista `addons/gut/plugin.cfg` y `addons/gut/gut_cmdln.gd` tras la extracción; si la ruta interna del zip difiere, ajusta el `cp` para apuntar a la carpeta `addons/gut` real dentro de lo extraído.

- [ ] **Step 4: Escribir un test trivial (smoke test)**

```gdscript
extends GutTest

func test_true_is_true():
    assert_true(true)
```

Guardar en `tests/unit/test_smoke.gd`.

- [ ] **Step 5: Ejecutar el test y verificar que pasa**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: salida mostrando `1 passed`, `0 failed` (bloque `Totals`).

Si el comando falla porque `godot` no está en el PATH, ejecuta la misma orden con la ruta completa al ejecutable de Godot 4.x instalado.

- [ ] **Step 6: Commit**

```bash
git init
git add project.godot addons tests/unit/test_smoke.gd
git commit -m "chore: scaffold Godot project with GUT test framework"
```

---

## Task 2: ChipLedger

**Files:**
- Create: `scripts/chip_ledger.gd`
- Test: `tests/unit/test_chip_ledger.gd`

**Interfaces:**
- Produce: `ChipLedger.new(starting_balance: int)`, propiedad `balance: int`, métodos `place_bet(amount: int) -> bool`, `payout(amount: int) -> void`, `can_afford(amount: int) -> bool`, `is_bankrupt() -> bool`. Usado por `BlackjackGame` en Task 5/6, y más adelante (Plan 4) por `MatchRules` para el pozo de equipo.

- [ ] **Step 1: Escribir los tests**

```gdscript
extends GutTest

func test_starts_with_given_balance():
    var ledger = ChipLedger.new(500)
    assert_eq(ledger.balance, 500)

func test_place_bet_deducts_balance_when_affordable():
    var ledger = ChipLedger.new(500)
    var ok = ledger.place_bet(100)
    assert_true(ok)
    assert_eq(ledger.balance, 400)

func test_place_bet_fails_when_insufficient_funds():
    var ledger = ChipLedger.new(50)
    var ok = ledger.place_bet(100)
    assert_false(ok)
    assert_eq(ledger.balance, 50)

func test_payout_adds_to_balance():
    var ledger = ChipLedger.new(100)
    ledger.payout(50)
    assert_eq(ledger.balance, 150)

func test_is_bankrupt_when_balance_zero():
    var ledger = ChipLedger.new(0)
    assert_true(ledger.is_bankrupt())

func test_is_not_bankrupt_with_positive_balance():
    var ledger = ChipLedger.new(1)
    assert_false(ledger.is_bankrupt())
```

Guardar en `tests/unit/test_chip_ledger.gd`.

- [ ] **Step 2: Ejecutar y verificar que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `Identifier "ChipLedger" not declared` (la clase no existe todavía).

- [ ] **Step 3: Implementar ChipLedger**

```gdscript
class_name ChipLedger
extends RefCounted

var balance: int

func _init(starting_balance: int) -> void:
    balance = starting_balance

func can_afford(amount: int) -> bool:
    return amount > 0 and amount <= balance

func place_bet(amount: int) -> bool:
    if not can_afford(amount):
        return false
    balance -= amount
    return true

func payout(amount: int) -> void:
    balance += amount

func is_bankrupt() -> bool:
    return balance <= 0
```

Guardar en `scripts/chip_ledger.gd`.

- [ ] **Step 4: Ejecutar y verificar que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests de `test_chip_ledger.gd` en verde, `0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/chip_ledger.gd tests/unit/test_chip_ledger.gd
git commit -m "feat: add ChipLedger for bet/payout balance tracking"
```

---

## Task 3: Card y Hand

**Files:**
- Create: `scripts/blackjack/card.gd`
- Create: `scripts/blackjack/hand.gd`
- Test: `tests/unit/test_hand.gd`

**Interfaces:**
- Produce: `Card.new(rank: int, suit: int)` con enum `Card.Suit {HEARTS, DIAMONDS, CLUBS, SPADES}`, propiedades `rank: int`, `suit: int`, métodos `is_ace() -> bool`, `blackjack_value() -> int`.
- Produce: `Hand.new()`, propiedad `cards: Array[Card]`, métodos `add_card(card: Card) -> void`, `value() -> int` (as blando, ases cuentan 11 u 1), `is_bust() -> bool`, `is_blackjack() -> bool`.
- Consume: `Card` (definido en este mismo task, usado por `Hand`).
- Usado por: `Deck` (Task 4) y `BlackjackGame` (Task 5/6).

- [ ] **Step 1: Escribir los tests**

```gdscript
extends GutTest

func test_value_counts_number_cards():
    var hand = Hand.new()
    hand.add_card(Card.new(5, Card.Suit.HEARTS))
    hand.add_card(Card.new(7, Card.Suit.SPADES))
    assert_eq(hand.value(), 12)

func test_face_cards_count_as_ten():
    var hand = Hand.new()
    hand.add_card(Card.new(11, Card.Suit.HEARTS)) # Jack
    hand.add_card(Card.new(13, Card.Suit.SPADES)) # King
    assert_eq(hand.value(), 20)

func test_ace_counts_as_11_when_it_fits():
    var hand = Hand.new()
    hand.add_card(Card.new(1, Card.Suit.HEARTS))
    hand.add_card(Card.new(9, Card.Suit.SPADES))
    assert_eq(hand.value(), 20)

func test_ace_counts_as_1_when_11_would_bust():
    var hand = Hand.new()
    hand.add_card(Card.new(1, Card.Suit.HEARTS))
    hand.add_card(Card.new(9, Card.Suit.SPADES))
    hand.add_card(Card.new(5, Card.Suit.CLUBS))
    assert_eq(hand.value(), 15)

func test_is_bust_above_21():
    var hand = Hand.new()
    hand.add_card(Card.new(10, Card.Suit.HEARTS))
    hand.add_card(Card.new(10, Card.Suit.SPADES))
    hand.add_card(Card.new(5, Card.Suit.CLUBS))
    assert_true(hand.is_bust())

func test_is_blackjack_with_ace_and_ten_card():
    var hand = Hand.new()
    hand.add_card(Card.new(1, Card.Suit.HEARTS))
    hand.add_card(Card.new(13, Card.Suit.SPADES))
    assert_true(hand.is_blackjack())

func test_is_not_blackjack_with_three_cards_totaling_21():
    var hand = Hand.new()
    hand.add_card(Card.new(7, Card.Suit.HEARTS))
    hand.add_card(Card.new(7, Card.Suit.SPADES))
    hand.add_card(Card.new(7, Card.Suit.CLUBS))
    assert_false(hand.is_blackjack())
```

Guardar en `tests/unit/test_hand.gd`.

- [ ] **Step 2: Ejecutar y verificar que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `Identifier "Hand" not declared` / `Identifier "Card" not declared`.

- [ ] **Step 3: Implementar Card**

```gdscript
class_name Card
extends RefCounted

enum Suit { HEARTS, DIAMONDS, CLUBS, SPADES }

var rank: int # 1=As ... 11=J, 12=Q, 13=K
var suit: int

func _init(p_rank: int, p_suit: int) -> void:
    rank = p_rank
    suit = p_suit

func is_ace() -> bool:
    return rank == 1

func blackjack_value() -> int:
    if rank == 1:
        return 11
    elif rank >= 10:
        return 10
    else:
        return rank
```

Guardar en `scripts/blackjack/card.gd`.

- [ ] **Step 4: Implementar Hand**

```gdscript
class_name Hand
extends RefCounted

var cards: Array[Card] = []

func add_card(card: Card) -> void:
    cards.append(card)

func value() -> int:
    var total := 0
    var aces := 0
    for card in cards:
        total += card.blackjack_value()
        if card.is_ace():
            aces += 1
    while total > 21 and aces > 0:
        total -= 10
        aces -= 1
    return total

func is_bust() -> bool:
    return value() > 21

func is_blackjack() -> bool:
    return cards.size() == 2 and value() == 21
```

Guardar en `scripts/blackjack/hand.gd`.

- [ ] **Step 5: Ejecutar y verificar que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests de `test_hand.gd` en verde, `0 failed`.

- [ ] **Step 6: Commit**

```bash
git add scripts/blackjack/card.gd scripts/blackjack/hand.gd tests/unit/test_hand.gd
git commit -m "feat: add Card and Hand with soft-ace scoring"
```

---

## Task 4: Deck

**Files:**
- Create: `scripts/blackjack/deck.gd`
- Test: `tests/unit/test_deck.gd`

**Interfaces:**
- Consume: `Card.new(rank: int, suit: int)` (Task 3).
- Produce: `Deck.new()`, propiedad pública `cards: Array[Card]`, métodos `shuffle_deck(rng: RandomNumberGenerator) -> void`, `draw_card() -> Card`, `cards_remaining() -> int`. `BlackjackGame` (Task 5/6) construye mazos de test asignando directamente `deck.cards` en el orden de reparto deseado.
- Nota de orden: `draw_card()` extrae del final del array (`pop_back`), por eso los tests que fijan `cards` a mano para simular reparto lo hacen con `.duplicate()` + `.reverse()` sobre la secuencia de reparto deseada.

- [ ] **Step 1: Escribir los tests**

```gdscript
extends GutTest

func test_new_deck_has_52_cards():
    var deck = Deck.new()
    assert_eq(deck.cards_remaining(), 52)

func test_draw_card_reduces_remaining():
    var deck = Deck.new()
    deck.draw_card()
    assert_eq(deck.cards_remaining(), 51)

func test_draw_card_returns_a_card():
    var deck = Deck.new()
    var card = deck.draw_card()
    assert_true(card is Card)

func test_shuffle_keeps_same_card_count():
    var deck = Deck.new()
    var rng = RandomNumberGenerator.new()
    rng.seed = 42
    deck.shuffle_deck(rng)
    assert_eq(deck.cards_remaining(), 52)
```

Guardar en `tests/unit/test_deck.gd`.

- [ ] **Step 2: Ejecutar y verificar que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `Identifier "Deck" not declared`.

- [ ] **Step 3: Implementar Deck**

```gdscript
class_name Deck
extends RefCounted

var cards: Array[Card] = []

func _init() -> void:
    _build()

func _build() -> void:
    cards.clear()
    for suit in range(4):
        for rank in range(1, 14):
            cards.append(Card.new(rank, suit))

func shuffle_deck(rng: RandomNumberGenerator) -> void:
    for i in range(cards.size() - 1, 0, -1):
        var j = rng.randi_range(0, i)
        var tmp = cards[i]
        cards[i] = cards[j]
        cards[j] = tmp

func draw_card() -> Card:
    return cards.pop_back()

func cards_remaining() -> int:
    return cards.size()
```

Guardar en `scripts/blackjack/deck.gd`.

- [ ] **Step 4: Ejecutar y verificar que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests de `test_deck.gd` en verde, `0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/blackjack/deck.gd tests/unit/test_deck.gd
git commit -m "feat: add Deck with build/shuffle/draw"
```

---

## Task 5: BlackjackGame — reparto inicial y apuesta

**Files:**
- Create: `scripts/blackjack/blackjack_game.gd`
- Test: `tests/unit/test_blackjack_game.gd`

**Interfaces:**
- Consume: `ChipLedger` (Task 2), `Deck`/`Card` (Task 3/4), `Hand` (Task 3).
- Produce: `BlackjackGame.new(ledger: ChipLedger, deck: Deck)`, enum `BlackjackGame.State {BETTING, PLAYER_TURN, DEALER_TURN, ROUND_OVER}`, propiedades `player_hand: Hand`, `dealer_hand: Hand`, `state: int`, método `start_round(bet: int) -> bool`. Usado por Task 6 (`hit`/`stand`) y por la escena de Task 7.

- [ ] **Step 1: Escribir los tests**

```gdscript
extends GutTest

func _stub_deck(draw_order: Array) -> Deck:
    var deck = Deck.new()
    deck.cards = draw_order.duplicate()
    deck.cards.reverse()
    return deck

func test_start_round_deducts_bet_and_deals_two_cards_each():
    var ledger = ChipLedger.new(500)
    var deck = _stub_deck([
        Card.new(9, Card.Suit.HEARTS),   # player card 1
        Card.new(6, Card.Suit.SPADES),   # dealer card 1
        Card.new(8, Card.Suit.CLUBS),    # player card 2
        Card.new(7, Card.Suit.DIAMONDS), # dealer card 2
    ])
    var game = BlackjackGame.new(ledger, deck)
    var ok = game.start_round(100)
    assert_true(ok)
    assert_eq(ledger.balance, 400)
    assert_eq(game.player_hand.value(), 17)
    assert_eq(game.dealer_hand.value(), 13)
    assert_eq(game.state, BlackjackGame.State.PLAYER_TURN)

func test_start_round_fails_when_bet_exceeds_balance():
    var ledger = ChipLedger.new(50)
    var deck = _stub_deck([
        Card.new(9, Card.Suit.HEARTS),
        Card.new(6, Card.Suit.SPADES),
        Card.new(8, Card.Suit.CLUBS),
        Card.new(7, Card.Suit.DIAMONDS),
    ])
    var game = BlackjackGame.new(ledger, deck)
    var ok = game.start_round(100)
    assert_false(ok)
    assert_eq(ledger.balance, 50)
    assert_eq(game.state, BlackjackGame.State.BETTING)

func test_natural_blackjack_resolves_immediately():
    var ledger = ChipLedger.new(500)
    var deck = _stub_deck([
        Card.new(1, Card.Suit.HEARTS),   # player card 1 (As)
        Card.new(6, Card.Suit.SPADES),   # dealer card 1
        Card.new(13, Card.Suit.CLUBS),   # player card 2 (K) -> blackjack natural
        Card.new(7, Card.Suit.DIAMONDS), # dealer card 2 -> dealer 13
    ])
    var game = BlackjackGame.new(ledger, deck)
    game.start_round(100)
    assert_eq(game.state, BlackjackGame.State.ROUND_OVER)
    assert_eq(ledger.balance, 600) # 500 - 100 apuesta + 200 pago (blackjack vs no-blackjack)
```

Guardar en `tests/unit/test_blackjack_game.gd`.

- [ ] **Step 2: Ejecutar y verificar que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `Identifier "BlackjackGame" not declared`.

- [ ] **Step 3: Implementar BlackjackGame (parte 1: reparto y apuesta)**

```gdscript
class_name BlackjackGame
extends RefCounted

enum State { BETTING, PLAYER_TURN, DEALER_TURN, ROUND_OVER }

var ledger: ChipLedger
var deck: Deck
var player_hand: Hand
var dealer_hand: Hand
var current_bet: int
var state: int = State.BETTING

func _init(p_ledger: ChipLedger, p_deck: Deck) -> void:
    ledger = p_ledger
    deck = p_deck

func start_round(bet: int) -> bool:
    if state != State.BETTING:
        return false
    if not ledger.place_bet(bet):
        return false
    current_bet = bet
    player_hand = Hand.new()
    dealer_hand = Hand.new()
    player_hand.add_card(deck.draw_card())
    dealer_hand.add_card(deck.draw_card())
    player_hand.add_card(deck.draw_card())
    dealer_hand.add_card(deck.draw_card())
    state = State.PLAYER_TURN
    if player_hand.is_blackjack():
        state = State.ROUND_OVER
        _resolve_payout()
    return true

func _finish_dealer_turn() -> void:
    state = State.DEALER_TURN
    if not player_hand.is_bust():
        while dealer_hand.value() < 17:
            dealer_hand.add_card(deck.draw_card())
    state = State.ROUND_OVER
    _resolve_payout()

func _resolve_payout() -> void:
    if player_hand.is_bust():
        return
    if dealer_hand.is_bust():
        ledger.payout(current_bet * 2)
        return
    if player_hand.value() > dealer_hand.value():
        ledger.payout(current_bet * 2)
    elif player_hand.value() == dealer_hand.value():
        ledger.payout(current_bet)
```

Guardar en `scripts/blackjack/blackjack_game.gd`.

- [ ] **Step 4: Ejecutar y verificar que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests de `test_blackjack_game.gd` en verde, `0 failed`.

- [ ] **Step 5: Commit**

```bash
git add scripts/blackjack/blackjack_game.gd tests/unit/test_blackjack_game.gd
git commit -m "feat: add BlackjackGame deal/bet/natural-blackjack resolution"
```

---

## Task 6: BlackjackGame — hit, stand, IA de banca y pagos

**Files:**
- Modify: `scripts/blackjack/blackjack_game.gd`
- Modify: `tests/unit/test_blackjack_game.gd`

**Interfaces:**
- Produce (añadido a `BlackjackGame`): `hit() -> void`, `stand() -> void`.
- Consume: todo lo de Task 5 (mismo archivo).

- [ ] **Step 1: Añadir los tests de hit/stand/resolución**

Añadir al final de `tests/unit/test_blackjack_game.gd`:

```gdscript
func test_hit_adds_card_and_busts_player():
    var ledger = ChipLedger.new(500)
    var deck = _stub_deck([
        Card.new(9, Card.Suit.HEARTS),   # player card 1
        Card.new(6, Card.Suit.SPADES),   # dealer card 1
        Card.new(8, Card.Suit.CLUBS),    # player card 2 -> player 17
        Card.new(7, Card.Suit.DIAMONDS), # dealer card 2 -> dealer 13
        Card.new(10, Card.Suit.HEARTS),  # player hit -> 27 bust
    ])
    var game = BlackjackGame.new(ledger, deck)
    game.start_round(100)
    game.hit()
    assert_true(game.player_hand.is_bust())
    assert_eq(game.state, BlackjackGame.State.ROUND_OVER)
    assert_eq(ledger.balance, 400) # apuesta perdida, sin pago

func test_stand_lets_dealer_hit_to_17_and_player_wins():
    var ledger = ChipLedger.new(500)
    var deck = _stub_deck([
        Card.new(10, Card.Suit.HEARTS),  # player card 1
        Card.new(2, Card.Suit.SPADES),   # dealer card 1
        Card.new(9, Card.Suit.CLUBS),    # player card 2 -> player 19
        Card.new(4, Card.Suit.DIAMONDS), # dealer card 2 -> dealer 6
        Card.new(5, Card.Suit.HEARTS),   # dealer hit -> 11
        Card.new(6, Card.Suit.SPADES),   # dealer hit -> 17, se detiene
    ])
    var game = BlackjackGame.new(ledger, deck)
    game.start_round(100)
    game.stand()
    assert_eq(game.dealer_hand.value(), 17)
    assert_eq(game.state, BlackjackGame.State.ROUND_OVER)
    assert_eq(ledger.balance, 600) # 500 - 100 + 200 (jugador gana 19 vs 17)

func test_dealer_bust_pays_player():
    var ledger = ChipLedger.new(500)
    var deck = _stub_deck([
        Card.new(10, Card.Suit.HEARTS),  # player card 1
        Card.new(10, Card.Suit.SPADES),  # dealer card 1
        Card.new(6, Card.Suit.CLUBS),    # player card 2 -> player 16
        Card.new(2, Card.Suit.DIAMONDS), # dealer card 2 -> dealer 12
        Card.new(10, Card.Suit.HEARTS),  # dealer hit -> 22 bust
    ])
    var game = BlackjackGame.new(ledger, deck)
    game.start_round(100)
    game.stand()
    assert_true(game.dealer_hand.is_bust())
    assert_eq(ledger.balance, 600) # 500 - 100 + 200

func test_push_returns_bet_without_profit():
    var ledger = ChipLedger.new(500)
    var deck = _stub_deck([
        Card.new(10, Card.Suit.HEARTS),  # player card 1
        Card.new(10, Card.Suit.SPADES),  # dealer card 1
        Card.new(8, Card.Suit.CLUBS),    # player card 2 -> player 18
        Card.new(8, Card.Suit.DIAMONDS), # dealer card 2 -> dealer 18
    ])
    var game = BlackjackGame.new(ledger, deck)
    game.start_round(100)
    game.stand()
    assert_eq(ledger.balance, 500) # empate: se devuelve la apuesta, sin ganancia
```

- [ ] **Step 2: Ejecutar y verificar que fallan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: FAIL — `Invalid call. Nonexistent function 'hit'/'stand' in base 'RefCounted'`.

- [ ] **Step 3: Implementar hit/stand**

Añadir dentro de `scripts/blackjack/blackjack_game.gd` (junto a `_finish_dealer_turn`):

```gdscript
func hit() -> void:
    if state != State.PLAYER_TURN:
        return
    player_hand.add_card(deck.draw_card())
    if player_hand.is_bust():
        state = State.ROUND_OVER

func stand() -> void:
    if state != State.PLAYER_TURN:
        return
    _finish_dealer_turn()
```

- [ ] **Step 4: Ejecutar y verificar que pasan**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`
Expected: todos los tests en verde, `0 failed`, incluidos los de Task 5.

- [ ] **Step 5: Commit**

```bash
git add scripts/blackjack/blackjack_game.gd tests/unit/test_blackjack_game.gd
git commit -m "feat: add hit/stand, dealer AI and full payout resolution to BlackjackGame"
```

---

## Task 7: Escena jugable BlackjackTable (verificación manual)

**Files:**
- Create: `scenes/blackjack_table.tscn`
- Create: `scenes/blackjack_table.gd`

**Interfaces:**
- Consume: `ChipLedger.new(int)` (Task 2), `Deck.new()` (Task 4), `BlackjackGame.new(ledger, deck)` con `start_round(bet)`, `hit()`, `stand()`, `state`, `player_hand`, `dealer_hand` (Task 5/6).

- [ ] **Step 1: Crear el script de la escena**

```gdscript
extends Control

var ledger := ChipLedger.new(500)
var game: BlackjackGame

@onready var balance_label: Label = $BalanceLabel
@onready var player_label: Label = $PlayerLabel
@onready var dealer_label: Label = $DealerLabel
@onready var bet_button: Button = $BetButton
@onready var hit_button: Button = $HitButton
@onready var stand_button: Button = $StandButton

func _ready() -> void:
    _new_round()
    bet_button.pressed.connect(_new_round)
    hit_button.pressed.connect(_on_hit)
    stand_button.pressed.connect(_on_stand)

func _new_round() -> void:
    var deck = Deck.new()
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    deck.shuffle_deck(rng)
    game = BlackjackGame.new(ledger, deck)
    game.start_round(50)
    _refresh_labels()

func _on_hit() -> void:
    game.hit()
    _refresh_labels()

func _on_stand() -> void:
    game.stand()
    _refresh_labels()

func _refresh_labels() -> void:
    balance_label.text = "Fichas: %d" % ledger.balance
    player_label.text = "Jugador: %d" % game.player_hand.value()
    dealer_label.text = "Banca: %d" % game.dealer_hand.value()
```

Guardar en `scenes/blackjack_table.gd`.

- [ ] **Step 2: Crear la escena mínima en el editor de Godot**

Abrir el proyecto en el editor de Godot 4, crear una escena nueva `Control` como raíz, guardarla como `scenes/blackjack_table.tscn`, añadir como hijos: `Label` llamado `BalanceLabel`, `Label` llamado `PlayerLabel`, `Label` llamado `DealerLabel`, `Button` llamado `BetButton` (texto "Apostar 50"), `Button` llamado `HitButton` (texto "Pedir"), `Button` llamado `StandButton` (texto "Plantarse"). Adjuntar el script `scenes/blackjack_table.gd` a la raíz `Control`.

- [ ] **Step 3: Verificación manual**

Ejecutar la escena (`F6` en el editor, o `godot --path . scenes/blackjack_table.tscn`) y jugar varias manos: comprobar que "Apostar 50" reparte cartas y descuenta 50 fichas, "Pedir" añade carta y planta si te pasas de 21, "Plantarse" hace jugar a la banca y liquida el resultado, y que el saldo de fichas sube o baja según corresponda.

- [ ] **Step 4: Commit**

```bash
git add scenes/blackjack_table.tscn scenes/blackjack_table.gd
git commit -m "feat: add playable BlackjackTable scene for manual verification"
```

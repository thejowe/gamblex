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
    # TEMP verificación manual Task 2 (Plan 2) — borrar antes de commitear.
    SteamManager.lobby_ready.connect(func(id, is_owner): print("Lobby listo: %d (owner=%s)" % [id, is_owner]))
    SteamManager.lobby_join_failed.connect(func(reason): print("Fallo de lobby: %s" % reason))

func _unhandled_key_input(event: InputEvent) -> void:
    if not event.is_pressed() or event.echo:
        return
    if event is InputEventKey and event.keycode == KEY_C:
        print("Creando lobby...")
        SteamManager.create_lobby(4)
    elif event is InputEventKey and event.keycode == KEY_J:
        var id_str := DisplayServer.clipboard_get().strip_edges()
        print("Uniendo a lobby %s (desde portapapeles)..." % id_str)
        SteamManager.join_lobby(int(id_str))

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

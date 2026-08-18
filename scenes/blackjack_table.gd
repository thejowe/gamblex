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

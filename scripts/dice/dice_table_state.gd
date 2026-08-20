class_name DiceTableState
extends RefCounted

signal chips_won(player_id: int, amount: int)

const STARTING_BALANCE := 500

enum Direction { OVER, UNDER }

class Player:
    var player_id: int = 0
    var ledger: ChipLedger
    var last_round: Dictionary = {}

var players: Dictionary = {}
var roller: DiceRoller

func _init(p_roller: DiceRoller = null) -> void:
    roller = p_roller if p_roller else DiceRoller.new()

static func win_chance(threshold: int, direction: int) -> float:
    if direction == Direction.OVER:
        return 100.0 - threshold
    return float(threshold)

static func multiplier(threshold: int, direction: int) -> float:
    return 99.0 / win_chance(threshold, direction)

func _player_for(player_id: int) -> Player:
    if not players.has(player_id):
        var player := Player.new()
        player.player_id = player_id
        player.ledger = ChipLedger.new(STARTING_BALANCE)
        players[player_id] = player
    return players[player_id]

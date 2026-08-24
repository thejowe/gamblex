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

func _player_for(player_id: int, external_ledger: ChipLedger = null) -> Player:
    if not players.has(player_id):
        var player := Player.new()
        player.player_id = player_id
        player.ledger = external_ledger if external_ledger != null else ChipLedger.new(STARTING_BALANCE)
        players[player_id] = player
    return players[player_id]

func roll(player_id: int, threshold: int, direction: int, amount: int, external_ledger: ChipLedger = null) -> bool:
    if threshold < 1 or threshold > 99:
        return false
    if direction != Direction.OVER and direction != Direction.UNDER:
        return false
    var player := _player_for(player_id, external_ledger)
    if not player.ledger.place_bet(amount):
        return false
    var result := roller.roll()
    var win := (direction == Direction.OVER and result > threshold) \
        or (direction == Direction.UNDER and result < threshold)
    var payout := 0
    if win:
        payout = int(amount * multiplier(threshold, direction))
        player.ledger.payout(payout)
        chips_won.emit(player_id, payout - amount)
    player.last_round = {
        "threshold": threshold,
        "direction": direction,
        "amount": amount,
        "result": result,
        "win": win,
        "payout": payout,
    }
    return true

func to_dict() -> Dictionary:
    var players_data := {}
    for player_id in players:
        var player = players[player_id]
        players_data[player_id] = {
            "player_id": player.player_id,
            "balance": player.ledger.balance,
            "last_round": player.last_round,
        }
    return {"players": players_data}

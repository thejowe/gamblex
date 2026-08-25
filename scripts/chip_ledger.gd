class_name ChipLedger
extends RefCounted

var balance: int
var pending_amount: int = 0

func _init(starting_balance: int) -> void:
    balance = starting_balance

func can_afford(amount: int) -> bool:
    return amount > 0 and amount <= balance

func place_bet(amount: int) -> bool:
    if not can_afford(amount):
        return false
    balance -= amount
    pending_amount += amount
    return true

func payout(amount: int) -> void:
    balance += amount

func resolve_bet(amount: int) -> void:
    pending_amount = max(0, pending_amount - amount)

func is_bankrupt() -> bool:
    return balance <= 0 and pending_amount <= 0

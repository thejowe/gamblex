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

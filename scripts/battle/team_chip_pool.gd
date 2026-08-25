class_name TeamChipPool
extends RefCounted

var team_id: int
var ledger: ChipLedger

func _init(p_team_id: int, starting_balance: int) -> void:
	team_id = p_team_id
	ledger = ChipLedger.new(starting_balance)

func balance() -> int:
	return ledger.balance

func can_afford(amount: int) -> bool:
	return ledger.can_afford(amount)

func place_bet(amount: int) -> bool:
	return ledger.place_bet(amount)

func payout(amount: int) -> void:
	ledger.payout(amount)

func resolve_bet(amount: int) -> void:
	ledger.resolve_bet(amount)

func is_bankrupt() -> bool:
	return ledger.is_bankrupt()

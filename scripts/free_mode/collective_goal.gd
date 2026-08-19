class_name CollectiveGoal
extends RefCounted

var target: int
var total: int = 0
var unlocked: bool = false

func _init(p_target: int) -> void:
    target = p_target

func add_chips(amount: int) -> bool:
    if amount <= 0:
        return false
    total += amount
    if not unlocked and total >= target:
        unlocked = true
        return true
    return false

func to_dict() -> Dictionary:
    return {
        "total": total,
        "target": target,
        "unlocked": unlocked,
    }

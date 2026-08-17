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

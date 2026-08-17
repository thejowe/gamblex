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

extends GutTest

func test_starts_with_given_balance():
    var ledger = ChipLedger.new(500)
    assert_eq(ledger.balance, 500)

func test_place_bet_deducts_balance_when_affordable():
    var ledger = ChipLedger.new(500)
    var ok = ledger.place_bet(100)
    assert_true(ok)
    assert_eq(ledger.balance, 400)

func test_place_bet_fails_when_insufficient_funds():
    var ledger = ChipLedger.new(50)
    var ok = ledger.place_bet(100)
    assert_false(ok)
    assert_eq(ledger.balance, 50)

func test_payout_adds_to_balance():
    var ledger = ChipLedger.new(100)
    ledger.payout(50)
    assert_eq(ledger.balance, 150)

func test_is_bankrupt_when_balance_zero():
    var ledger = ChipLedger.new(0)
    assert_true(ledger.is_bankrupt())

func test_is_not_bankrupt_with_positive_balance():
    var ledger = ChipLedger.new(1)
    assert_false(ledger.is_bankrupt())

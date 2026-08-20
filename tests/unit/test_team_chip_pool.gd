extends GutTest

func test_starting_balance_matches_constructor_argument():
	var pool := TeamChipPool.new(0, 500)
	assert_eq(pool.balance(), 500)
	assert_eq(pool.team_id, 0)

func test_bet_from_one_member_reduces_shared_balance_for_whole_team():
	var pool := TeamChipPool.new(0, 500)
	assert_true(pool.place_bet(200)) # miembro A apuesta
	assert_eq(pool.balance(), 300)
	assert_true(pool.place_bet(300)) # miembro B apuesta contra el mismo pozo
	assert_eq(pool.balance(), 0)

func test_bet_fails_when_pool_cannot_afford_it():
	var pool := TeamChipPool.new(0, 100)
	assert_false(pool.place_bet(200))
	assert_eq(pool.balance(), 100)

func test_payout_credits_shared_pool_regardless_of_which_member_won():
	var pool := TeamChipPool.new(1, 500)
	pool.place_bet(200)
	pool.payout(400) # el miembro que jugó gana, pero el pago va al pozo del equipo
	assert_eq(pool.balance(), 700)

func test_is_bankrupt_reflects_shared_balance():
	var pool := TeamChipPool.new(0, 100)
	pool.place_bet(100)
	assert_true(pool.is_bankrupt())

extends GutTest

func test_default_size_matches_card_size():
	var card: PlayingCard = PlayingCard.new()
	assert_eq(card.custom_minimum_size, PlayingCard.CARD_SIZE)
	card.free()

func test_rank_label_face_cards():
	var card: PlayingCard = PlayingCard.new()
	card.rank = 1
	assert_eq(card.rank_label(), "A")
	card.rank = 11
	assert_eq(card.rank_label(), "J")
	card.rank = 12
	assert_eq(card.rank_label(), "Q")
	card.rank = 13
	assert_eq(card.rank_label(), "K")
	card.free()

func test_rank_label_number_cards():
	var card: PlayingCard = PlayingCard.new()
	card.rank = 7
	assert_eq(card.rank_label(), "7")
	card.free()

func test_face_up_default_true_and_settable():
	var card: PlayingCard = PlayingCard.new()
	add_child_autofree(card)
	assert_true(card.face_up)
	card.face_up = false
	assert_false(card.face_up)

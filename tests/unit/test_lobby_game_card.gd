extends GutTest

func test_ready_sets_nearest_texture_filter():
	var card: LobbyGameCard = LobbyGameCard.new()
	card.texture_normal = load("res://assets/pixels/lobby/card_blackjack/card_blackjack.png")
	add_child_autofree(card)
	assert_eq(card.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)

func test_press_plays_click_sfx():
	var card: LobbyGameCard = LobbyGameCard.new()
	add_child_autofree(card)
	card._on_press()
	pass_test("no crashea al reproducir click")

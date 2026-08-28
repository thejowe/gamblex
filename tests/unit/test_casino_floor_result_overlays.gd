extends GutTest

func _make_casino_floor() -> Node:
	var root = load("res://scenes/casino_floor.tscn").instantiate()
	add_child_autofree(root)
	return root

# ---- Modo Libre: DefeatOverlay ----

func test_defeat_overlay_shows_free_mode_message() -> void:
	var floor := _make_casino_floor()
	floor._receive_goal_state({"balance": 0, "target": 1000, "unlocked": false, "bankrupt": true})
	var overlay: Control = floor.get_node("Hud/DefeatOverlay")
	assert_true(overlay.visible)
	assert_true(overlay.get_node("MessageLabel").text.contains("pozo"))

func test_defeat_overlay_hidden_while_pool_not_bankrupt() -> void:
	var floor := _make_casino_floor()
	floor._receive_goal_state({"balance": 500, "target": 1000, "unlocked": false, "bankrupt": false})
	var overlay: Control = floor.get_node("Hud/DefeatOverlay")
	assert_false(overlay.visible)

# ---- Modo Batalla: DefeatOverlay / VictoryOverlay ----

func test_defeat_overlay_shows_battle_message_for_losing_team() -> void:
	var floor := _make_casino_floor()
	floor.battle_controller.assignment = TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	# jugador local se une primero -> equipo 0 (el que pierde en este estado)
	floor.battle_controller.assignment.join(multiplayer.get_unique_id())
	floor.battle_controller.assignment.join(222)
	floor._on_match_state_changed({"pool_balances": [0, 800], "finished": true, "winning_team": 1, "reason": "bankrupt"})
	var overlay: Control = floor.get_node("Hud/DefeatOverlay")
	assert_true(overlay.visible)
	assert_true(overlay.get_node("MessageLabel").text.contains("fichas"))
	assert_false(floor.get_node("Hud/VictoryOverlay").visible)

func test_victory_overlay_shows_only_for_winning_team() -> void:
	var floor := _make_casino_floor()
	floor.battle_controller.assignment = TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	# jugador local se une primero -> equipo 0 (el que gana en este estado)
	floor.battle_controller.assignment.join(multiplayer.get_unique_id())
	floor.battle_controller.assignment.join(222)
	floor._on_match_state_changed({"pool_balances": [1000, 200], "finished": true, "winning_team": 0, "reason": "goal_reached"})
	assert_true(floor.get_node("Hud/VictoryOverlay").visible)
	assert_false(floor.get_node("Hud/DefeatOverlay").visible)

func test_victory_overlay_hidden_for_losing_team() -> void:
	var floor := _make_casino_floor()
	floor.battle_controller.assignment = TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	# equipo 1 es el jugador local (se une segundo), equipo 0 gana
	floor.battle_controller.assignment.join(999)
	floor.battle_controller.assignment.join(multiplayer.get_unique_id())
	floor._on_match_state_changed({"pool_balances": [1000, 200], "finished": true, "winning_team": 0, "reason": "goal_reached"})
	assert_false(floor.get_node("Hud/VictoryOverlay").visible)
	assert_true(floor.get_node("Hud/DefeatOverlay").visible)

# ---- dedupe de SFX (no repetir sonido en refrescos mientras el overlay ya está visible) ----

func test_defeat_sfx_not_repeated_on_second_state_refresh() -> void:
	var floor := _make_casino_floor()
	var before: int = AudioManager._sfx_pool_next
	floor._receive_goal_state({"balance": 0, "target": 1000, "unlocked": false, "bankrupt": true})
	var after_first: int = AudioManager._sfx_pool_next
	assert_eq(after_first, (before + 1) % AudioManager._sfx_pool.size(), "primer refresco sí debe sonar el SFX")
	floor._receive_goal_state({"balance": 0, "target": 1000, "unlocked": false, "bankrupt": true})
	var after_second: int = AudioManager._sfx_pool_next
	assert_eq(after_second, after_first, "segundo refresco con el overlay ya visible no debe repetir el SFX")

func test_victory_sfx_not_repeated_on_second_state_refresh() -> void:
	var floor := _make_casino_floor()
	floor.battle_controller.assignment = TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	floor.battle_controller.assignment.join(multiplayer.get_unique_id())
	floor.battle_controller.assignment.join(222)
	var state := {"pool_balances": [1000, 200], "finished": true, "winning_team": 0, "reason": "goal_reached"}
	var before: int = AudioManager._sfx_pool_next
	floor._on_match_state_changed(state)
	var after_first: int = AudioManager._sfx_pool_next
	assert_eq(after_first, (before + 1) % AudioManager._sfx_pool.size(), "primer refresco sí debe sonar el SFX")
	floor._on_match_state_changed(state)
	var after_second: int = AudioManager._sfx_pool_next
	assert_eq(after_second, after_first, "segundo refresco con el overlay ya visible no debe repetir el SFX")

# ---- celebración de victoria (Tarea 3) ----

func test_victory_celebration_does_not_error() -> void:
	var floor := _make_casino_floor()
	floor.battle_controller.assignment = TeamAssignment.new(TeamAssignment.MatchType.ONE_V_ONE)
	floor.battle_controller.assignment.join(multiplayer.get_unique_id())
	floor.battle_controller.assignment.join(222)
	floor._on_match_state_changed({"pool_balances": [1000, 0], "finished": true, "winning_team": 0, "reason": "goal_reached"})
	pass_test("no crashea al disparar la celebración")

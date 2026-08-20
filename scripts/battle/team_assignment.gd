class_name TeamAssignment
extends RefCounted

enum MatchType { ONE_V_ONE, TWO_V_TWO, FOUR_V_FOUR }

const TEAM_SIZE_BY_MATCH_TYPE := {
	MatchType.ONE_V_ONE: 1,
	MatchType.TWO_V_TWO: 2,
	MatchType.FOUR_V_FOUR: 4,
}

var match_type: int
var teams: Array = [[], []]

func _init(p_match_type: int) -> void:
	match_type = p_match_type

static func team_size_for(p_match_type: int) -> int:
	return TEAM_SIZE_BY_MATCH_TYPE[p_match_type]

func team_size() -> int:
	return TeamAssignment.team_size_for(match_type)

func max_players() -> int:
	return team_size() * 2

func join(player_id: int) -> int:
	if team_for(player_id) != -1:
		return -1
	var size := team_size()
	if teams[0].size() <= teams[1].size() and teams[0].size() < size:
		teams[0].append(player_id)
		return 0
	if teams[1].size() < size:
		teams[1].append(player_id)
		return 1
	return -1

func team_for(player_id: int) -> int:
	for i in range(2):
		if teams[i].has(player_id):
			return i
	return -1

func is_full() -> bool:
	return teams[0].size() == team_size() and teams[1].size() == team_size()

class_name CasinoTheme
extends RefCounted

const FELT_GREEN_LIGHT := Color("2f8f5b")
const FELT_GREEN_DARK := Color("1c5c3a")
const WOOD_BROWN_LIGHT := Color("8a5a34")
const WOOD_BROWN_DARK := Color("5c3a20")
const GOLD_ACCENT := Color("e8c468")
const CARD_WHITE := Color("f5f5f0")
const CARD_RED := Color("c0392b")
const CARD_BLACK := Color("1a1a1a")
const TEXT_CREAM := Color("f0e6d2")

const CHIP_COLORS := {
	1: Color("e8e8e8"),
	5: Color("c0392b"),
	10: Color("2e6da4"),
	25: Color("2f8f5b"),
	50: Color("e07b1f"),
	100: Color("1a1a1a"),
}

static func chip_color(denomination: int) -> Color:
	if CHIP_COLORS.has(denomination):
		return CHIP_COLORS[denomination]
	return Color("9b59b6")

const PANEL_NAVY_DARK := Color("131b26")
const PANEL_NAVY_MID := Color("1c2733")
const PANEL_NAVY_LIGHT := Color("28374a")
const ACCENT_GREEN := Color("4caf6e")
const ACCENT_RED := Color("d9534f")
const TEXT_LIGHT := Color("e8edf2")
const TEXT_MUTED := Color("7c8a9a")

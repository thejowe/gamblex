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

# Godot pinta LineEdit/OptionButton por defecto en blanco con texto negro —
# sin esto cualquier control nativo sin estilizar rompe el tema navy/dorado
# en medio de una mesa. Reutilizado por BetSidebarPanel y MinesTableNet.
static func style_line_edit(edit: LineEdit) -> void:
	var normal_box := StyleBoxFlat.new()
	normal_box.bg_color = PANEL_NAVY_DARK
	normal_box.border_color = PANEL_NAVY_LIGHT
	normal_box.set_border_width_all(1)
	normal_box.set_corner_radius_all(4)
	normal_box.content_margin_left = 8
	normal_box.content_margin_right = 8
	normal_box.content_margin_top = 4
	normal_box.content_margin_bottom = 4
	var focus_box := normal_box.duplicate()
	focus_box.border_color = GOLD_ACCENT
	edit.add_theme_stylebox_override("normal", normal_box)
	edit.add_theme_stylebox_override("focus", focus_box)
	edit.add_theme_color_override("font_color", TEXT_LIGHT)
	edit.add_theme_color_override("font_selected_color", PANEL_NAVY_DARK)
	edit.add_theme_color_override("selection_color", GOLD_ACCENT)
	edit.add_theme_color_override("caret_color", GOLD_ACCENT)

static func style_slider(slider: HSlider) -> void:
	var groove := StyleBoxFlat.new()
	groove.bg_color = PANEL_NAVY_DARK
	groove.set_corner_radius_all(3)
	groove.content_margin_top = 3
	groove.content_margin_bottom = 3
	var filled := StyleBoxFlat.new()
	filled.bg_color = GOLD_ACCENT
	filled.set_corner_radius_all(3)
	filled.content_margin_top = 3
	filled.content_margin_bottom = 3
	slider.add_theme_stylebox_override("slider", groove)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)

# Todos los modales del proyecto (HelpOverlay, SettingsMenu, PauseMenu)
# aparecían con visible=true instantáneo, sin ningún tipo de transición —
# el mismo corte seco que ya se corrigió en los overlays de victoria/derrota.
# No anima la propia visibilidad (los tests dependen de que sea un booleano
# síncrono), solo un pop de escala cosmético sobre el panel ya visible.
static func play_modal_pop_in(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(0.85, 0.85)
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func style_option_button(button: OptionButton) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_NAVY_DARK
	box.border_color = PANEL_NAVY_LIGHT
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", box)
	button.add_theme_stylebox_override("pressed", box)
	button.add_theme_color_override("font_color", TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", GOLD_ACCENT)

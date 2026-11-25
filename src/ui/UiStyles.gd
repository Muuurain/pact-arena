class_name UiStyles
extends RefCounted
## Shared style factory for dark-neon roguelite panels, tier borders, and mobile touch targets.

const COL_BG := Color(0.05, 0.04, 0.09, 1.0)
const COL_PANEL := Color(0.10, 0.08, 0.16, 0.94)
const COL_CARD := Color(0.13, 0.10, 0.21, 0.96)
const COL_BORDER := Color(0.32, 0.22, 0.45, 0.9)
const COL_CRIMSON := Color(0.96, 0.25, 0.37, 1.0)
const COL_AZURE := Color(0.22, 0.74, 0.97, 1.0)
const COL_VOID := Color(0.75, 0.52, 0.99, 1.0)
const COL_GOLD := Color(0.98, 0.80, 0.08, 1.0)
const COL_EMERALD := Color(0.20, 0.83, 0.60, 1.0)
const COL_TEXT_DIM := Color(0.72, 0.68, 0.80, 1.0)


static func tier_color(tier: int) -> Color:
	match tier:
		2: return COL_AZURE
		3: return COL_VOID
		4: return COL_CRIMSON
		_: return Color(0.78, 0.82, 0.88, 1.0)


static func tier_name(tier: int) -> String:
	match tier:
		2: return "稀有"
		3: return "史诗"
		4: return "觉醒红"
		_: return "普通"


static func faction_color(faction: String) -> Color:
	match faction:
		"crimson": return COL_CRIMSON
		"azure": return COL_AZURE
		"void": return COL_VOID
		_: return Color.WHITE


static func faction_name(faction: String) -> String:
	match faction:
		"crimson": return "猩红"
		"azure": return "苍蓝"
		"void": return "虚空"
		_: return "通用"


static func make_panel_style(bg: Color = COL_CARD, border: Color = COL_BORDER, radius: int = 14, border_w: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func style_button(btn: Button, accent: Color = COL_CRIMSON, filled: bool = true, min_h: float = 52.0) -> void:
	btn.custom_minimum_size.y = min_h
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.52))

	var normal := make_panel_style(
		Color(accent.r * 0.48, accent.g * 0.48, accent.b * 0.48, 0.95) if filled else Color(0.12, 0.09, 0.19, 0.95),
		accent,
		12,
		2
	)
	var hover := make_panel_style(
		Color(accent.r * 0.65, accent.g * 0.65, accent.b * 0.65, 1.0) if filled else Color(0.18, 0.14, 0.28, 1.0),
		accent.lightened(0.25),
		12,
		2
	)
	var pressed := make_panel_style(
		Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 1.0),
		Color.WHITE,
		12,
		2
	)
	var disabled := make_panel_style(Color(0.12, 0.11, 0.16, 0.7), Color(0.26, 0.24, 0.32, 0.6), 12, 1)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)


static func apply_safe_area_padding(ctrl: Control, base_top: float = 12.0, base_bottom: float = 12.0) -> void:
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	var top_pad := base_top
	var bot_pad := base_bottom
	if win.y > 0 and safe.size.y > 0:
		var scale_y := 1280.0 / float(win.y)
		top_pad = maxf(base_top, float(safe.position.y) * scale_y + 6.0)
		var bottom_cut := float(win.y - (safe.position.y + safe.size.y))
		bot_pad = maxf(base_bottom, bottom_cut * scale_y + 8.0)
	ctrl.offset_top = top_pad
	ctrl.offset_bottom = -bot_pad

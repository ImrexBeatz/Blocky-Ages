## UI helpers: the game's theme, pixel-art icons and common widgets.
extends RefCounted

const GOLD := Color("#f2c14e")
const PARCH := Color("#f3e6c4")
const DIM := Color("#a89a86")
const BG := Color(0.07, 0.06, 0.09, 0.94)

static var _theme: Theme
static var _icons := {}

const ICONS := {
	"sword": ["..........##", ".........#w#", "........#w#.", ".......#w#..", "......#w#...", ".....#w#....", "..#.#w#.....", "...#w#......", "...##.......", "..#..#......", ".#..........", "#..........."],
	"axe": ["......####..", ".....#wwww#.", "....#wwwww#.", "....#ww#ww#.", "....##.#ww#.", "...#h#..##..", "..#h#.......", ".#h#........", "#h#.........", "h#..........", "............", "............"],
	"hammer": ["...######...", "...#wwww#...", "...#wwww#...", "...######...", ".....hh.....", ".....hh.....", ".....hh.....", ".....hh.....", ".....hh.....", ".....hh.....", ".....hh.....", "............"],
	"dagger": ["............", "........##..", ".......#w#..", "......#w#...", ".....#w#....", "....#w#.....", "..#.##......", "...#........", "..#.#.......", "............", "............", "............"],
	"spear": ["..........#w", ".........#ww", "........h#..", ".......h....", "......h.....", ".....h......", "....h.......", "...h........", "..h.........", ".h..........", "h...........", "............"],
	"bow": ["..####......", ".#h..s......", "#h...s......", "#h...s......", "#h...s......", "#h...s......", "#h...s......", "#h...s......", "#h...s......", ".#h..s......", "..####......", "............"],
	"crossbow": ["............", ".##########.", "#....hh....#", ".....hh.....", ".....hh.....", ".....hh.....", ".....hh.....", ".....hh.....", "....hhhh....", "............", "............", "............"],
	"armor": ["..##....##..", ".#ww####ww#.", "#wwwwwwwwww#", "#wwwwwwwwww#", ".##wwwwww##.", "..#wwwwww#..", "..#wwwwww#..", "..#wwwwww#..", "..#wwwwww#..", "..########..", "............", "............"],
	"orb": ["....####....", "..##wwww##..", ".#wwwssww#..", ".#wwsswww#..", "#wwwwwwwww#.", "#wwwwwwwww#.", "#wwwwwwwww#.", ".#wwwwwww#..", ".#wwwwwww#..", "..##wwww##..", "....####....", "............"],
	"ring": ["....####....", "...#ssss#...", "..##....##..", ".#h......h#.", ".#h......h#.", ".#h......h#.", ".#h......h#.", "..#h....h#..", "...#hhhh#...", "....####....", "............", "............"],
	"amulet": ["#..........#", ".#........#.", "..#......#..", "...#....#...", "....#..#....", ".....##.....", "....####....", "...#wwww#...", "...#wssw#...", "...#wwww#...", "....####....", "............"],
	"charm": ["....##......", "...#ww#.....", "..#wwww#....", "..#wsww#....", "...#ww#.....", "....##......", "....#.......", "....#.......", "...###......", "............", "............", "............"],
	"potion": ["....##......", "....##......", "...#ss#.....", "..#wwww#....", ".#wwwwww#...", ".#wwswww#...", ".#wwwwww#...", ".#wwwwww#...", "..######....", "............", "............", "............"],
	"gem": ["............", "...######...", "..#wwssww#..", ".#wwwwwwww#.", "#wwwwwwwwww#", ".#wwwwwwww#.", "..#wwwwww#..", "...#wwww#...", "....#ww#....", ".....##.....", "............", "............"],
	"gauntlets": ["............", "..#.#.#.#...", ".#w#w#w#w#..", ".#wwwwwwww#.", ".#wwwwwwww#.", ".#wwwwwwww#.", "..#wwwwww#..", "..#ssssss#..", "..#wwwwww#..", "..########..", "............", "............"],
	"scythe": ["..#######...", ".#wwwwwww#..", "#ww#....#h..", "#w#.....h...", "##.....h....", "......h.....", ".....h......", "....h.......", "...h........", "..h.........", ".h..........", "............"],
	"lock": ["....####....", "...#....#...", "..#......#..", "..#......#..", ".##########.", ".#wwwwwwww#.", ".#wwwssww#..", ".#wwwssww#..", ".#wwwwwwww#.", ".##########.", "............", "............"],
}


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 18
	var panel := StyleBoxFlat.new()
	panel.bg_color = BG
	panel.border_color = Color("#6b5636")
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(3)
	panel.set_content_margin_all(14)
	panel.shadow_color = Color(0, 0, 0, 0.5)
	panel.shadow_size = 8
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("panel", "PanelContainer", panel)
	var bn := StyleBoxFlat.new()
	bn.bg_color = Color("#3a3149")
	bn.border_color = Color("#1a1522")
	bn.set_border_width_all(2)
	bn.border_width_bottom = 4
	bn.set_corner_radius_all(2)
	bn.set_content_margin_all(8)
	var bh := bn.duplicate() as StyleBoxFlat
	bh.bg_color = Color("#5a4b72")
	bh.border_color = GOLD
	var bp := bn.duplicate() as StyleBoxFlat
	bp.bg_color = Color("#2a2236")
	bp.border_width_bottom = 2
	var bd := bn.duplicate() as StyleBoxFlat
	bd.bg_color = Color("#262230")
	t.set_stylebox("normal", "Button", bn)
	t.set_stylebox("hover", "Button", bh)
	t.set_stylebox("pressed", "Button", bp)
	t.set_stylebox("disabled", "Button", bd)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", PARCH)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("#6a6070"))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0))
	t.set_constant("outline_size", "Button", 4)
	t.set_color("font_color", "Label", PARCH)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0))
	t.set_constant("outline_size", "Label", 4)
	t.set_color("default_color", "RichTextLabel", PARCH)
	t.set_font_size("normal_font_size", "RichTextLabel", 17)
	t.set_font_size("bold_font_size", "RichTextLabel", 17)
	var le := StyleBoxFlat.new()
	le.bg_color = Color("#1a1522")
	le.border_color = Color("#6b5636")
	le.set_border_width_all(2)
	le.set_content_margin_all(8)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#2a2236")
	t.set_stylebox("scroll", "VScrollBar", sb)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color("#6b5636")
	grab.set_corner_radius_all(3)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	var tab := StyleBoxFlat.new()
	tab.bg_color = Color("#2a2236")
	tab.set_content_margin_all(8)
	var tab_sel := tab.duplicate() as StyleBoxFlat
	tab_sel.bg_color = Color("#5a4b72")
	tab_sel.border_color = GOLD
	tab_sel.border_width_bottom = 3
	t.set_stylebox("tab_unselected", "TabBar", tab)
	t.set_stylebox("tab_hovered", "TabBar", tab)
	t.set_stylebox("tab_selected", "TabBar", tab_sel)
	t.set_color("font_selected_color", "TabBar", Color.WHITE)
	t.set_color("font_unselected_color", "TabBar", DIM)
	var pg_bg := StyleBoxFlat.new()
	pg_bg.bg_color = Color(0, 0, 0, 0.6)
	pg_bg.set_corner_radius_all(2)
	var pg_fill := StyleBoxFlat.new()
	pg_fill.bg_color = Color("#d43a3a")
	pg_fill.set_corner_radius_all(2)
	t.set_stylebox("background", "ProgressBar", pg_bg)
	t.set_stylebox("fill", "ProgressBar", pg_fill)
	_theme = t
	return t


static func icon(kind: String, c: Color) -> ImageTexture:
	var key := "%s_%s" % [kind, c.to_html()]
	if _icons.has(key):
		return _icons[key]
	var pat: Array = ICONS.get(kind, ICONS["gem"])
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 12:
		var row: String = pat[y]
		for x in mini(12, row.length()):
			var ch := row[x]
			var col := Color(0, 0, 0, 0)
			match ch:
				"#": col = c.darkened(0.55)
				"w": col = c
				"s": col = c.lightened(0.55)
				"h": col = Color("#7a5634")
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_icons[key] = tex
	return tex


static func item_icon_kind(inst) -> String:
	var d: Dictionary = Data.items.get(inst["id"], {})
	match d.get("kind", ""):
		"melee":
			match d["sub"]:
				"sword", "katana": return "sword"
				"axe": return "axe"
				"hammer": return "hammer"
				"dagger": return "dagger"
				"spear", "glaive": return "spear"
				"scythe": return "scythe"
				"gauntlets": return "gauntlets"
			return "sword"
		"ranged": return d["sub"]
		"armor": return "armor"
		"artifact": return "orb"
		"accessory": return d["slot"]
	return "gem"


static func label(text: String, size := 18, color := PARCH, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


static func rich(text: String, min_h := 0.0) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = text
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size.y = min_h
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


static func button(text: String, cb: Callable, min_w := 0.0, size := 18) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 40)
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(func():
		Sfx.play("ui", 1.0, -6.0)
		cb.call())
	return b


static func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func color_box(c: Color, size: Vector2, border := Color(0, 0, 0, 0)) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	if border.a > 0:
		sb.border_color = border
		sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = size
	return p


static func clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


static func cost_text(cost: Dictionary) -> String:
	var parts: Array = []
	for k in cost:
		var have := State.res(k)
		var col := "#8aff8a" if have >= cost[k] else "#ff7a7a"
		parts.append("[color=%s]%d %s[/color]" % [col, cost[k], Data.resources[k]["name"]])
	return ", ".join(parts)


## BBCode description of an item instance, with stats compared against what is equipped.
static func item_text(inst) -> String:
	var d: Dictionary = Data.items[inst["id"]]
	var rc: Color = Data.rarity_color(inst["rarity"])
	var s := "[font_size=22][color=#%s]%s[/color][/font_size]\n" % [rc.to_html(false), State.item_name(inst)]
	s += "[color=#a89a86]%s %s  -  Power %d[/color]\n" % [Data.RARITIES[inst["rarity"]]["name"], d["kind"].capitalize(), inst["power"]]
	match d["kind"]:
		"melee":
			s += "Damage: [color=#ffd84a]%d[/color]   Speed: %.2fs   Reach: %.1f\n" % [State.weapon_damage(inst), d["speed"], d["range"]]
			if d.has("effect"):
				s += "[color=#ff9a5a]Inflicts %s[/color]\n" % d["effect"].capitalize()
			if d.has("crit"):
				s += "+%d%% Critical chance\n" % int(d["crit"] * 100)
			if d.has("lifesteal"):
				s += "+%d%% Lifesteal\n" % int(d["lifesteal"] * 100)
		"ranged":
			s += "Damage: [color=#ffd84a]%d[/color] x%d   Fire rate: %.2fs\n" % [State.weapon_damage(inst), d["multishot"], d["speed"]]
			if d["pierce"] > 0:
				s += "Pierces %d enemies\n" % d["pierce"]
			if d.has("effect"):
				s += "[color=#9ce0ff]Inflicts %s[/color]\n" % d["effect"].capitalize()
		"armor":
			s += "Health: [color=#ff7a7a]+%d[/color]   Damage reduction: %d%%\n" % [d["hp"] * State.power_mult(inst) * 0.6, int(d["def"] * 100)]
			for k in d["bonus"]:
				s += "%s\n" % _mod_text(k, d["bonus"][k])
		"artifact":
			s += "Power: [color=#c48aff]%d[/color]   Cooldown: %.1fs\n" % [State.artifact_power(inst), State.artifact_cooldown(inst)]
		"accessory":
			for k in d["mods"]:
				var mult: float = (0.8 + 0.25 * inst["rarity"]) * (1.0 + 0.06 * inst["upg"])
				s += "%s\n" % _mod_text(k, d["mods"][k] * mult)
	for e in inst["ench"]:
		var ed: Dictionary = Data.enchants[e["id"]]
		s += "[color=#b48aff]* %s %s[/color] - %s\n" % [ed["name"], ["", "I", "II", "III"][e["lvl"]], ed["desc"]]
	s += "[i][color=#a89a86]%s[/color][/i]" % d["desc"]
	return s


static func _mod_text(k: String, v: float) -> String:
	var names := {"hp": "+%d Max health", "melee_pct": "+%d%% Melee damage", "ranged_pct": "+%d%% Ranged damage", "artifact_pct": "+%d%% Artifact damage",
		"speed_pct": "+%d%% Move speed", "crit": "+%d%% Critical chance", "lifesteal": "+%d%% Lifesteal", "cdr": "+%d%% Artifact recharge",
		"luck": "+%d%% Luck", "armor": "+%d%% Damage reduction", "xp": "+%d%% Experience", "regen": "+%.1f Health regen", "potion": "+%d%% Potion healing",
		"magnet": "+%d Loot magnet range", "emerald": "+%d%% Emeralds", "thorns": "%d%% Thorns", "burn_pct": "+%d%% Burn damage", "roll_cd": "-%d%% Roll cooldown",
		"hp_pct": "+%d%% Max health", "aura_burn": "Burning aura %d"}
	var f: String = names.get(k, k + " %d")
	if k in ["hp", "magnet", "aura_burn"]:
		return "[color=#9aff9a]" + f % v + "[/color]"
	if k == "regen":
		return "[color=#9aff9a]" + f % v + "[/color]"
	var col := "#9aff9a" if v >= 0 else "#ff7a7a"
	return "[color=%s]%s[/color]" % [col, f % absf(v * 100.0)]

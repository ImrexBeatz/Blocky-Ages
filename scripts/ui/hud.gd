## In-game heads-up display.
extends Control

const K = preload("res://scripts/ui/ui_kit.gd")

var hp_bar: ProgressBar
var hp_text: Label
var xp_bar: ProgressBar
var lvl_label: Label
var potion_label: Label
var potion_cd: ColorRect
var art_slots: Array = []
var roll_bar: ProgressBar
var region_label: Label
var realm_label: Label
var emerald_label: Label
var clock_label: Label
var map_rect: TextureRect
var map_img: Image
var map_tex: ImageTexture
var map_overlay: Control
var map_t := 0.0
var quest_title: Label
var quest_prog: Label
var boss_panel: PanelContainer
var boss_name: Label
var boss_bar: ProgressBar
var boss: Node
var notes: VBoxContainer
var banner: Label
var banner_sub: Label
var banner_t := 0.0
var prompt_label: Label
var powerup_box: HBoxContainer
var vignette: ColorRect
var points_label: Label
const MAP_PX := 90
const MAP_SCALE := 1.5


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = K.theme()
	_build()
	Game.notify.connect(_on_notify)
	Game.banner.connect(_on_banner)
	Game.boss_engaged.connect(func(b): boss = b; boss_panel.visible = true)
	Game.boss_cleared.connect(func(): boss = null; boss_panel.visible = false)
	Game.interact_prompt.connect(_on_prompt)
	Game.powerup_changed.connect(_refresh_powerups)
	State.leveled_up.connect(_on_level)
	Quests.quest_completed.connect(_on_quest_done)
	Quests.quests_changed.connect(_refresh_quest)
	State.inventory_changed.connect(_refresh_slots)
	_refresh_quest()
	_refresh_slots()


func _panel(pos_preset: int) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.07, 0.72)
	sb.border_color = Color("#6b5636")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_meta("preset", pos_preset)
	add_child(p)
	return p


func _place(c: Control, margin := 16) -> void:
	var preset: int = c.get_meta("preset", Control.PRESET_TOP_LEFT)
	c.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, margin)
	match preset:
		Control.PRESET_TOP_RIGHT:
			c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		Control.PRESET_CENTER_BOTTOM:
			c.grow_horizontal = Control.GROW_DIRECTION_BOTH
			c.grow_vertical = Control.GROW_DIRECTION_BEGIN
		Control.PRESET_CENTER_TOP:
			c.grow_horizontal = Control.GROW_DIRECTION_BOTH


func _build() -> void:
	vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vs := Shader.new()
	vs.code = """
shader_type canvas_item;
uniform float amount = 0.0;
void fragment() {
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.35, 0.75, length(d));
	COLOR = vec4(0.6, 0.0, 0.0, v * amount);
}
"""
	var vm := ShaderMaterial.new()
	vm.shader = vs
	vignette.material = vm
	add_child(vignette)
	# Top-left: realm info
	var tl := _panel(Control.PRESET_TOP_LEFT)
	var tlv := K.vbox(2)
	tl.add_child(tlv)
	realm_label = K.label("", 20, K.GOLD)
	region_label = K.label("", 16, K.PARCH)
	var row := K.hbox(14)
	emerald_label = K.label("", 18, Color("#2fd37a"))
	clock_label = K.label("", 16, K.DIM)
	row.add_child(emerald_label)
	row.add_child(clock_label)
	points_label = K.label("", 15, Color("#ffd84a"))
	tlv.add_child(realm_label)
	tlv.add_child(region_label)
	tlv.add_child(row)
	tlv.add_child(points_label)
	_place(tl)
	# Top-right: minimap + quest
	var tr := _panel(Control.PRESET_TOP_RIGHT)
	var trv := K.vbox(6)
	tr.add_child(trv)
	map_rect = TextureRect.new()
	map_rect.custom_minimum_size = Vector2(200, 200)
	map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_img = Image.create(MAP_PX, MAP_PX, false, Image.FORMAT_RGB8)
	map_tex = ImageTexture.create_from_image(map_img)
	map_rect.texture = map_tex
	trv.add_child(map_rect)
	map_overlay = Control.new()
	map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_rect.add_child(map_overlay)
	map_overlay.draw.connect(_draw_map_overlay)
	quest_title = K.label("", 17, K.GOLD)
	quest_title.custom_minimum_size.x = 200
	quest_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_prog = K.label("", 15, K.PARCH)
	quest_prog.custom_minimum_size.x = 200
	quest_prog.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trv.add_child(quest_title)
	trv.add_child(quest_prog)
	_place(tr)
	# Bottom hotbar
	var bot := _panel(Control.PRESET_CENTER_BOTTOM)
	var bv := K.vbox(6)
	bot.add_child(bv)
	var hb := K.hbox(10)
	bv.add_child(hb)
	var pot := _slot("potion", Color("#ff3a5a"), "Q")
	potion_label = pot[1]
	potion_cd = pot[2]
	hb.add_child(pot[0])
	var hpv := K.vbox(2)
	hpv.alignment = BoxContainer.ALIGNMENT_CENTER
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(340, 30)
	hp_bar.show_percentage = false
	hpv.add_child(hp_bar)
	hp_text = K.label("", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	hp_bar.add_child(hp_text)
	hp_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	roll_bar = ProgressBar.new()
	roll_bar.custom_minimum_size = Vector2(340, 6)
	roll_bar.show_percentage = false
	var rf := StyleBoxFlat.new()
	rf.bg_color = Color("#9ce0ff")
	roll_bar.add_theme_stylebox_override("fill", rf)
	hpv.add_child(roll_bar)
	hb.add_child(hpv)
	for i in 3:
		var s := _slot("orb", Color.GRAY, str(i + 1))
		art_slots.append(s)
		hb.add_child(s[0])
	var xr := K.hbox(8)
	lvl_label = K.label("Lv 1", 18, K.GOLD)
	lvl_label.custom_minimum_size.x = 64
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(560, 12)
	xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_bar.show_percentage = false
	var xf := StyleBoxFlat.new()
	xf.bg_color = Color("#6ad65a")
	xp_bar.add_theme_stylebox_override("fill", xf)
	xr.add_child(lvl_label)
	xr.add_child(xp_bar)
	bv.add_child(xr)
	_place(bot)
	# Interaction prompt
	prompt_label = K.label("", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(prompt_label)
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_WIDTH, 170)
	prompt_label.offset_left = -500
	prompt_label.offset_right = 500
	# Boss bar
	boss_panel = _panel(Control.PRESET_CENTER_TOP)
	var bpv := K.vbox(4)
	boss_panel.add_child(bpv)
	boss_name = K.label("", 22, Color("#ffb0a0"), HORIZONTAL_ALIGNMENT_CENTER)
	bpv.add_child(boss_name)
	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size = Vector2(620, 22)
	boss_bar.show_percentage = false
	var bf := StyleBoxFlat.new()
	bf.bg_color = Color("#a32a4a")
	boss_bar.add_theme_stylebox_override("fill", bf)
	bpv.add_child(boss_bar)
	_place(boss_panel)
	boss_panel.visible = false
	powerup_box = K.hbox(8)
	powerup_box.alignment = BoxContainer.ALIGNMENT_CENTER
	powerup_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(powerup_box)
	powerup_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_WIDTH, 112)
	powerup_box.offset_left = -500
	powerup_box.offset_right = 500
	# Notifications
	notes = K.vbox(4)
	notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notes)
	notes.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE, 18)
	notes.offset_top = -40
	notes.offset_right = 700
	# Banner
	banner = K.label("", 46, K.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	banner.add_theme_constant_override("outline_size", 10)
	banner.modulate.a = 0.0
	add_child(banner)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_WIDTH, 150)
	banner.offset_left = -700
	banner.offset_right = 700
	banner_sub = K.label("", 22, K.PARCH, HORIZONTAL_ALIGNMENT_CENTER)
	banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_sub.modulate.a = 0.0
	add_child(banner_sub)
	banner_sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_WIDTH, 212)
	banner_sub.offset_left = -480
	banner_sub.offset_right = 480
	var help := K.label("[I] Inventory  [J] Quests  [P] Skills  [M] Map  [C] Codex  [Esc] Menu", 14, K.DIM)
	add_child(help)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 12)


func _slot(icon_kind: String, c: Color, key: String) -> Array:
	var p := K.color_box(Color(0.1, 0.08, 0.14, 0.9), Vector2(58, 58), Color("#6b5636"))
	var ic := TextureRect.new()
	ic.texture = K.icon(icon_kind, c)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic.offset_left = 7
	ic.offset_top = 7
	ic.offset_right = -7
	ic.offset_bottom = -7
	p.add_child(ic)
	var cd := ColorRect.new()
	cd.color = Color(0, 0, 0, 0.65)
	cd.position = Vector2(0, 58)
	cd.size = Vector2(58, 0)
	cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(cd)
	var kl := K.label(key, 14, K.GOLD)
	kl.position = Vector2(3, -2)
	p.add_child(kl)
	var cnt := K.label("", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	cnt.position = Vector2(4, 34)
	cnt.size = Vector2(50, 22)
	p.add_child(cnt)
	return [p, cnt, cd, ic]


func _refresh_slots() -> void:
	for i in 3:
		var inst = State.equipment.get("art%d" % (i + 1))
		var s: Array = art_slots[i]
		var ic: TextureRect = s[3]
		if not State.slot_unlocked("art%d" % (i + 1)):
			ic.texture = K.icon("lock", Color("#6a6070"))
		elif inst == null:
			ic.texture = null
		else:
			ic.texture = K.icon("orb", Data.items[inst["id"]]["color"])


func _refresh_quest() -> void:
	if quest_title == null:
		return
	var id := Quests.tracked
	if id == "" or Quests.def(id).is_empty():
		quest_title.text = "No quest tracked"
		quest_prog.text = "Talk to villagers with [!] marks"
		return
	var q := Quests.def(id)
	quest_title.text = ("[Main] " if q["main"] else "") + q["title"]
	if q["type"] == "level":
		quest_prog.text = "Reach level %d (%d)" % [q["count"], State.level]
	else:
		quest_prog.text = "%s\n%d / %d" % [_short_obj(q), Quests.progress_of(id), q["count"]]


func _short_obj(q: Dictionary) -> String:
	match q["type"]:
		"kill":
			return "Defeat " + ("monsters" if q["target"] == "any" else Data.enemies[q["target"]]["name"] + "s")
		"boss": return "Defeat " + Data.bosses[q["target"]]["name"]
		"gather": return "Collect " + Data.resources[q["target"]]["name"]
		"talk": return "Speak with the " + Data.role(q["target"])["name"]
		"travel": return "Travel to " + Data.dim(q["target"])["short"]
		"cave": return "Clear caves"
		"lore": return "Read Lore Stones"
		"chest": return "Open chests"
		"shrine": return "Use shrines"
		"village": return "Discover villages"
	return ""


func _on_notify(text: String, color: Color) -> void:
	var l := K.label(text, 17, color)
	l.modulate.a = 0.0
	notes.add_child(l)
	if notes.get_child_count() > 7:
		notes.get_child(0).queue_free()
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.2)
	tw.tween_interval(4.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)


func _on_banner(title: String, sub: String) -> void:
	banner.text = title
	banner_sub.text = sub
	banner_t = 3.5


func _on_prompt(text: String) -> void:
	prompt_label.text = "" if text == "" else "[E]  " + text


func _on_level(lv: int) -> void:
	Sfx.play("levelup")
	_on_banner("LEVEL UP!", "Level %d  -  +1 Attribute Point, +1 Enchantment Point%s" % [lv, ", +1 Perk Point" if lv % 5 == 0 else ""])
	for slot in State.SLOT_UNLOCK:
		if State.SLOT_UNLOCK[slot] == lv:
			_on_notify("New equipment slot unlocked: %s" % slot.capitalize(), K.GOLD)
	_refresh_slots()


func _on_quest_done(q: Dictionary) -> void:
	Sfx.play("quest")
	_on_banner("Quest Complete", q["title"])
	_on_notify("+%d XP, +%d Emeralds" % [q["xp"], q["emerald"]], Color("#8aff8a"))
	if q.get("item", 0) > 0 and Game.world and Game.player:
		var inst := State.roll_item(maxi(State.level, Game.enemy_level_at(Game.player.global_position)), 0.5, int(q["item"]) - 1 if q["item"] > 1 else 0)
		if State.add_item(inst):
			_on_notify("Reward: %s %s" % [Data.RARITIES[inst["rarity"]]["name"], State.item_name(inst)], Data.rarity_color(inst["rarity"]))
	if q.get("unlock", "") != "":
		_on_notify("The Realm Gate to %s has awakened!" % Data.dim(q["unlock"])["name"], Color("#c48aff"))


func _refresh_powerups() -> void:
	K.clear(powerup_box)
	if Game.player == null:
		return
	for id in Game.player.powerups:
		var p: Dictionary = Data.powerups[id]
		var l := K.label("%s %ds" % [p["name"], int(Game.player.powerups[id])], 16, p["color"])
		l.set_meta("pid", id)
		powerup_box.add_child(l)


func _process(delta: float) -> void:
	var p = Game.player
	if p == null or Game.world == null:
		return
	hp_bar.max_value = p.max_hp
	hp_bar.value = p.hp
	hp_text.text = "%d / %d" % [ceil(p.hp), ceil(p.max_hp)]
	vignette.material.set_shader_parameter("amount", clampf((0.35 - p.hp / p.max_hp) * 3.0, 0.0, 0.9) * (0.75 + sin(Time.get_ticks_msec() / 200.0) * 0.25))
	roll_bar.max_value = 1.0
	roll_bar.value = 1.0 - clampf(p.roll_cd / 1.1, 0.0, 1.0)
	xp_bar.max_value = State.xp_needed()
	xp_bar.value = State.xp
	lvl_label.text = "Lv %d" % State.level
	potion_label.text = str(State.potions)
	potion_cd.size.y = 58.0 * clampf(p.potion_cd / 20.0, 0.0, 1.0)
	potion_cd.position.y = 58.0 - potion_cd.size.y
	for i in 3:
		var s: Array = art_slots[i]
		var cd: ColorRect = s[2]
		var frac: float = clampf(p.art_cd[i] / maxf(p.art_cd_max[i], 0.01), 0.0, 1.0)
		cd.size.y = 58.0 * frac
		cd.position.y = 58.0 - cd.size.y
		var cl: Label = s[1]
		cl.text = "%d" % ceil(p.art_cd[i]) if p.art_cd[i] > 0.0 else ""
	var d := Data.dim(State.current_dim)
	realm_label.text = d["name"] if not Game.world.in_cave else d["short"] + " - Underground"
	region_label.text = Game.world.region_name()
	emerald_label.text = "Emeralds %s" % State.res("emerald")
	if Game.world.in_cave or not d["day_cycle"]:
		clock_label.text = ""
	else:
		clock_label.text = "Night" if Game.world.is_night() else "Day"
	var pts: Array = []
	if State.attr_points > 0:
		pts.append("%d attribute pts" % State.attr_points)
	if State.perk_points > 0:
		pts.append("%d perk pts" % State.perk_points)
	if State.enchant_points > 0:
		pts.append("%d enchant pts" % State.enchant_points)
	points_label.text = ("Unspent: " + ", ".join(pts)) if not pts.is_empty() else ""
	if boss and is_instance_valid(boss) and not boss.dead:
		boss_name.text = "%s, %s  [Lv %d]" % [boss.def["name"], boss.def["title"], boss.level]
		boss_bar.max_value = boss.max_hp
		boss_bar.value = boss.hp
	elif boss_panel.visible:
		boss_panel.visible = false
	if banner_t > 0.0:
		banner_t -= delta
		var a := clampf(minf(banner_t, 3.5 - banner_t) * 3.0, 0.0, 1.0)
		banner.modulate.a = a
		banner_sub.modulate.a = a
	map_t -= delta
	if map_t <= 0.0:
		map_t = 0.35
		_update_map()
		for c in powerup_box.get_children():
			var pid: String = c.get_meta("pid", "")
			if Game.player.powerups.has(pid):
				c.text = "%s %ds" % [Data.powerups[pid]["name"], int(Game.player.powerups[pid])]
		if Engine.get_process_frames() % 3 == 0:
			_refresh_quest()
	map_overlay.queue_redraw()
	queue_redraw()


func _update_map() -> void:
	var c: Vector3 = Game.player.global_position
	var half := MAP_PX / 2
	for j in MAP_PX:
		for i in MAP_PX:
			map_img.set_pixel(i, j, Game.world.map_color_loaded(c.x + (i - half) * MAP_SCALE, c.z + (j - half) * MAP_SCALE))
	map_tex.update(map_img)


func _world_to_map(w: Vector3) -> Vector2:
	var c: Vector3 = Game.player.global_position
	var s := map_rect.size.x / (MAP_PX * MAP_SCALE)
	return map_rect.size * 0.5 + Vector2(w.x - c.x, w.z - c.z) * s


func _draw_map_overlay() -> void:
	if Game.player == null or Game.world == null:
		return
	var sz := map_rect.size
	for e in Game.world.enemies:
		if is_instance_valid(e):
			var mp := _world_to_map(e.global_position)
			if Rect2(Vector2.ZERO, sz).has_point(mp):
				map_overlay.draw_rect(Rect2(mp - Vector2(2, 2), Vector2(4, 4)) if not e.is_boss else Rect2(mp - Vector2(5, 5), Vector2(10, 10)), Color("#ff3a3a") if not e.is_boss else Color("#ff00ff"))
	for v in Game.world.villagers:
		if is_instance_valid(v):
			var mp := _world_to_map(v.global_position)
			if Rect2(Vector2.ZERO, sz).has_point(mp):
				map_overlay.draw_rect(Rect2(mp - Vector2(2, 2), Vector2(4, 4)), Color("#7aff7a"))
	var t = Game.world.quest_target()
	if t != null:
		var mp := _world_to_map(t)
		var cen := sz * 0.5
		if not Rect2(Vector2(6, 6), sz - Vector2(12, 12)).has_point(mp):
			mp = cen + (mp - cen).normalized() * (sz.x * 0.5 - 8)
		map_overlay.draw_circle(mp, 6, Color("#ffd84a"))
		map_overlay.draw_circle(mp, 3, Color("#7a4a00"))
	var fwd: Vector3 = Game.player.facing
	var ang := atan2(fwd.z, fwd.x)
	var c := sz * 0.5
	var pts := PackedVector2Array([c + Vector2(cos(ang), sin(ang)) * 8, c + Vector2(cos(ang + 2.5), sin(ang + 2.5)) * 6, c + Vector2(cos(ang - 2.5), sin(ang - 2.5)) * 6])
	map_overlay.draw_colored_polygon(pts, Color.WHITE)
	map_overlay.draw_rect(Rect2(Vector2.ZERO, sz), Color("#6b5636"), false, 2.0)


func _draw() -> void:
	if Game.player == null or Game.world == null or Game.camera == null:
		return
	var t = Game.world.quest_target()
	if t == null:
		return
	var pp: Vector3 = Game.player.global_position
	var dist := Vector2(t.x - pp.x, t.z - pp.z).length()
	if dist < 5.0:
		return
	var sp := Game.camera.unproject_position(pp + Vector3(0, 1, 0))
	var tp := Game.camera.unproject_position(Vector3(t.x, pp.y + 1.0, t.z))
	var dir := (tp - sp).normalized()
	var base := sp + dir * 80.0
	var perp := Vector2(-dir.y, dir.x)
	var pulse := 1.0 + sin(Time.get_ticks_msec() / 180.0) * 0.12
	var pts := PackedVector2Array([base + dir * 22 * pulse, base + perp * 11 - dir * 4, base - perp * 11 - dir * 4])
	draw_colored_polygon(pts, Color(1.0, 0.84, 0.3, 0.92))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(0.3, 0.18, 0.0), 2.0)
	var font := get_theme_default_font()
	draw_string_outline(font, base - dir * 22 + Vector2(-20, 6), "%dm" % int(dist), HORIZONTAL_ALIGNMENT_CENTER, 40, 14, 4, Color.BLACK)
	draw_string(font, base - dir * 22 + Vector2(-20, 6), "%dm" % int(dist), HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color("#ffe9b0"))

## Inventory & equipment: equip, compare and salvage gear; view resources and character stats.
extends "res://scripts/ui/screen.gd"

var equip_box: GridContainer
var stats_text: RichTextLabel
var grid: GridContainer
var details: RichTextLabel
var actions: HBoxContainer
var res_list: VBoxContainer
var selected_uid := -1
var tab := 0
var tab_bar: TabBar
var grid_scroll: ScrollContainer
var res_scroll: ScrollContainer
var filter := "all"


func _ready() -> void:
	build("Inventory", Vector2(1380, 780))
	var cols := K.hbox(16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	# Equipment column
	var left := K.vbox(8)
	left.custom_minimum_size.x = 360
	cols.add_child(left)
	left.add_child(K.label("Equipment", 22, K.GOLD))
	equip_box = GridContainer.new()
	equip_box.columns = 2
	equip_box.add_theme_constant_override("h_separation", 6)
	equip_box.add_theme_constant_override("v_separation", 6)
	left.add_child(equip_box)
	var ss: Array = scroll()
	left.add_child(ss[0])
	stats_text = K.rich("")
	stats_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ss[1].add_child(stats_text)
	# Inventory column
	var mid := K.vbox(8)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(mid)
	tab_bar = TabBar.new()
	for t in ["All Gear", "Weapons", "Armor", "Artifacts", "Accessories", "Resources"]:
		tab_bar.add_tab(t)
	tab_bar.tab_changed.connect(func(i): tab = i; refresh())
	mid.add_child(tab_bar)
	grid_scroll = ScrollContainer.new()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mid.add_child(grid_scroll)
	grid = GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid_scroll.add_child(grid)
	res_scroll = ScrollContainer.new()
	res_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	res_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	res_scroll.visible = false
	mid.add_child(res_scroll)
	res_list = K.vbox(4)
	res_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_scroll.add_child(res_list)
	# Details column
	var right := K.vbox(8)
	right.custom_minimum_size.x = 380
	cols.add_child(right)
	right.add_child(K.label("Details", 22, K.GOLD))
	var ds: Array = scroll()
	right.add_child(ds[0])
	details = K.rich("Select an item.")
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ds[1].add_child(details)
	actions = K.hbox(6)
	right.add_child(actions)
	refresh()


func refresh() -> void:
	_refresh_equipment()
	_refresh_stats()
	grid_scroll.visible = tab != 5
	res_scroll.visible = tab == 5
	if tab == 5:
		_refresh_resources()
	else:
		_refresh_grid()
	_refresh_details()
	title_label.text = "Inventory  (%d / %d)" % [State.inventory.size(), State.INVENTORY_CAP]


func _item_button(inst, size := Vector2(66, 66)) -> Button:
	var b := Button.new()
	b.custom_minimum_size = size
	var rc: Color = Data.rarity_color(inst["rarity"])
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(rc.r * 0.18, rc.g * 0.18, rc.b * 0.18, 0.95)
	sb.border_color = rc
	sb.set_border_width_all(3 if inst["uid"] == selected_uid else 2)
	if inst["uid"] == selected_uid:
		sb.border_color = Color.WHITE
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(rc.r * 0.32, rc.g * 0.32, rc.b * 0.32, 0.95)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.icon = K.icon(K.item_icon_kind(inst), Data.items[inst["id"]].get("color", Color.WHITE))
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", int(size.x) - 18)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.tooltip_text = State.item_name(inst)
	if State.is_equipped(inst["uid"]):
		var e := K.label("E", 14, K.GOLD)
		e.position = Vector2(4, 0)
		b.add_child(e)
	elif inst.get("new", false):
		var n := K.label("NEW", 11, Color("#8aff8a"))
		n.position = Vector2(4, 0)
		b.add_child(n)
	if inst["upg"] > 0:
		var u := K.label("+%d" % inst["upg"], 13, Color.WHITE)
		u.position = Vector2(size.x - 26, size.y - 22)
		b.add_child(u)
	var uid: int = inst["uid"]
	b.pressed.connect(func():
		selected_uid = uid
		var it = State.find_item(uid)
		if it:
			it["new"] = false
		Sfx.play("ui", 1.2, -8.0)
		refresh())
	return b


func _refresh_equipment() -> void:
	K.clear(equip_box)
	var names := {"melee": "Melee", "ranged": "Ranged", "armor": "Armor", "art1": "Artifact 1", "art2": "Artifact 2", "art3": "Artifact 3",
		"ring1": "Ring", "ring2": "Ring 2", "amulet": "Amulet", "charm": "Charm"}
	for s in State.SLOTS:
		var row := K.hbox(6)
		row.custom_minimum_size = Vector2(176, 66)
		var inst = State.equipment[s]
		if not State.slot_unlocked(s):
			var lb := K.color_box(Color(0.1, 0.1, 0.12), Vector2(66, 66), Color("#3a3640"))
			var ic := TextureRect.new()
			ic.texture = K.icon("lock", Color("#6a6070"))
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ic.offset_left = 14; ic.offset_top = 14; ic.offset_right = -14; ic.offset_bottom = -14
			lb.add_child(ic)
			row.add_child(lb)
			row.add_child(K.label("%s\nUnlocks at Lv %d" % [names[s], State.SLOT_UNLOCK[s]], 13, K.DIM))
		elif inst == null:
			row.add_child(K.color_box(Color(0.1, 0.08, 0.14), Vector2(66, 66), Color("#4a4056")))
			row.add_child(K.label("%s\n(empty)" % names[s], 13, K.DIM))
		else:
			row.add_child(_item_button(inst))
			var l := K.label("%s\n%s" % [names[s], State.item_name(inst)], 13, Data.rarity_color(inst["rarity"]))
			l.custom_minimum_size.x = 100
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(l)
		equip_box.add_child(row)


func _refresh_stats() -> void:
	var s := State.stats
	var melee = State.equipment["melee"]
	var ranged = State.equipment["ranged"]
	var t := "[color=#f2c14e]%s[/color]  Level %d %s\n" % [State.profile.get("name", "Wayfinder"), State.level, State.profile.get("origin", "").capitalize()]
	t += "Health: [color=#ff7a7a]%d[/color]\n" % s["max_hp"]
	if melee:
		t += "Melee: [color=#ffd84a]%d[/color]\n" % (State.weapon_damage(melee) * (1.0 + s["melee_pct"]))
	if ranged:
		t += "Ranged: [color=#ffd84a]%d[/color]\n" % (State.weapon_damage(ranged) * (1.0 + s["ranged_pct"]))
	t += "Damage reduction: %d%%\nCritical: %d%%   Lifesteal: %d%%\nArtifact damage: +%d%%   Recharge: +%d%%\nMove speed: +%d%%   Luck: +%d%%\nRegen: %.1f/s   Potions: %d\n" % [
		s["armor"] * 100, s["crit"] * 100, s["lifesteal"] * 100, s["artifact_pct"] * 100, s["cdr"] * 100, s["speed_pct"] * 100, s["luck"] * 100, s["regen"], State.potions]
	t += "[color=#a89a86]Enchantment points: %d[/color]" % State.enchant_points
	stats_text.text = t


func _passes_filter(inst) -> bool:
	var k: String = Data.items[inst["id"]]["kind"]
	match tab:
		1: return k == "melee" or k == "ranged"
		2: return k == "armor"
		3: return k == "artifact"
		4: return k == "accessory"
	return true


func _refresh_grid() -> void:
	K.clear(grid)
	var order := {"melee": 0, "ranged": 1, "armor": 2, "artifact": 3, "accessory": 4}
	var list: Array = State.inventory.filter(_passes_filter)
	list.sort_custom(func(a, b):
		var ka: int = order[Data.items[a["id"]]["kind"]]
		var kb: int = order[Data.items[b["id"]]["kind"]]
		if ka != kb:
			return ka < kb
		if a["rarity"] != b["rarity"]:
			return a["rarity"] > b["rarity"]
		return a["power"] > b["power"])
	for inst in list:
		grid.add_child(_item_button(inst))


func _refresh_resources() -> void:
	K.clear(res_list)
	var keys: Array = State.resources.keys()
	keys.sort()
	for k in keys:
		if State.res(k) <= 0 or not Data.resources.has(k):
			continue
		var r: Dictionary = Data.resources[k]
		var row := K.hbox(10)
		var ic := TextureRect.new()
		ic.texture = K.icon("gem", r["color"])
		ic.custom_minimum_size = Vector2(28, 28)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(ic)
		var nl := K.label("%s  x%d" % [r["name"], State.res(k)], 18, r["color"].lightened(0.2))
		nl.custom_minimum_size.x = 260
		row.add_child(nl)
		var dl := K.label(r["desc"], 14, K.DIM)
		dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(dl)
		res_list.add_child(row)


func _refresh_details() -> void:
	K.clear(actions)
	var inst = State.find_item(selected_uid)
	if inst == null:
		details.text = "Select an item to see its details.\n\n[color=#a89a86]Tip: Gear drops at the power level of the area it was found in. Travel farther from the village for stronger enemies and better loot.[/color]"
		return
	var t := K.item_text(inst)
	var d: Dictionary = Data.items[inst["id"]]
	var slots := State.slots_for(inst)
	if not slots.is_empty() and not State.is_equipped(inst["uid"]):
		var cur = State.equipment[slots[0]]
		if cur != null:
			t += "\n\n[color=#a89a86]Currently equipped:[/color]\n" + K.item_text(cur)
	details.text = t
	var uid: int = inst["uid"]
	if State.is_equipped(uid):
		if not d["kind"] in ["melee", "ranged", "armor"]:
			for s in slots:
				if State.equipment[s] != null and State.equipment[s]["uid"] == uid:
					actions.add_child(K.button("Unequip", func(): State.unequip(s); refresh()))
	else:
		if d["kind"] in ["artifact", "accessory"] and slots.size() > 1:
			for s in slots:
				if State.slot_unlocked(s):
					actions.add_child(K.button("Equip %s" % s.capitalize(), func(): State.equip(uid, s); Sfx.play("pickup", 0.8); refresh()))
		else:
			actions.add_child(K.button("Equip", func(): State.equip(uid); Sfx.play("pickup", 0.8); refresh()))
		actions.add_child(K.button("Salvage", func():
			var r := State.salvage(uid)
			if not r.is_empty():
				Game.toast("Salvaged: +%d Arcane Dust, +%d Emeralds%s" % [r["arcane_dust"], r["emerald"], (", +%d Enchant pts" % r["ep"]) if r["ep"] > 0 else ""], Color("#c48aff"))
				selected_uid = -1
				refresh()))

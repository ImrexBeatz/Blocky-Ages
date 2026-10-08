## Villager conversation and services: quests, trading, upgrades, enchanting, artifacts, potions and lore.
extends "res://scripts/ui/screen.gd"

var villager: Node
var line_label: RichTextLabel
var tabs: HBoxContainer
var content: VBoxContainer
var service := ""
var ench_uid := -1
var ench_offer: Array = []


func setup(v: Node) -> void:
	villager = v


func _ready() -> void:
	var r := Data.role(villager.role)
	build("%s the %s  -  %s" % [villager.vname, r["name"], villager.village], Vector2(1180, 760))
	line_label = K.rich("")
	line_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(line_label)
	tabs = K.hbox(8)
	body.add_child(tabs)
	var s: Array = scroll()
	body.add_child(s[0])
	content = s[1]
	var services: Array = r["services"].duplicate()
	if not "quests" in services:
		services.push_front("quests")
	for sv in services:
		var label: String = {"quests": "Quests", "trade": "Trade", "upgrade": "Blacksmith", "enchant": "Enchant", "artifact": "Empower Artifacts", "potions": "Brew", "lore": "Tales"}[sv]
		var sid: String = sv
		tabs.add_child(K.button(label, func(): service = sid; refresh(), 150))
	tabs.add_child(K.button("Farewell", close, 120))
	service = services[1] if services.size() > 1 and villager.role != "elder" else services[0]
	if not Quests.offers_for(villager.role, State.current_dim, 1).is_empty():
		service = "quests"
	_set_line()
	refresh()


func _set_line() -> void:
	var main := Quests.current_main()
	var txt := Story.role_line(villager.role, villager.seed_v + int(State.playtime / 60.0))
	if main != "":
		var q := Quests.def(main)
		if q["type"] == "talk" and q["target"] == villager.role and q["dim"] == State.current_dim:
			txt = "Ah, the Wayfinder! I've been expecting you."
	line_label.text = "[i][color=#f3e6c4]\"%s\"[/color][/i]" % txt


func refresh() -> void:
	K.clear(content)
	match service:
		"quests": _quests()
		"trade": _trade()
		"upgrade": _upgrade()
		"enchant": _enchant()
		"artifact": _artifacts()
		"potions": _potions()
		"lore": _lore()


func _row(text: String, btn_text: String, cb: Callable, enabled := true, width := 160.0) -> HBoxContainer:
	var row := K.hbox(10)
	var r := K.rich(text)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(r)
	if btn_text != "":
		var b := K.button(btn_text, cb, width)
		b.disabled = not enabled
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
	content.add_child(row)
	return row


func _area_level() -> int:
	return maxi(1, Game.enemy_level_at(Game.player.global_position))


# ---------------------------------------------------------------- quests

func _quests() -> void:
	var offers := Quests.offers_for(villager.role, State.current_dim, 3)
	content.add_child(K.label("Active side quests: %d / %d" % [Quests.side_active_count(), Quests.MAX_SIDE], 16, K.DIM))
	if offers.is_empty():
		content.add_child(K.label("\"I don't have anything for you right now. Check back as you grow stronger, or try the bounty board.\"", 17, K.PARCH))
	for id in offers:
		var q := Quests.def(id)
		var qid: String = id
		_row("[color=#f2c14e][b]%s[/b][/color]  [color=#a89a86](Lv %d+)[/color]\n%s\n[color=#8aff8a]%d XP[/color], [color=#2fd37a]%d Emeralds[/color]%s" % [q["title"], q["min_level"], q["desc"], q["xp"], q["emerald"], ", gear reward" if q["item"] > 0 else ""],
			"Accept", func():
				if Quests.accept(qid):
					Sfx.play("quest", 1.3, -4.0)
					Game.toast("Quest accepted: " + q["title"], K.GOLD)
				else:
					Game.toast("You can only carry %d side quests at once." % Quests.MAX_SIDE, Color("#ff8a8a"))
				refresh(), Quests.side_active_count() < Quests.MAX_SIDE)


# ---------------------------------------------------------------- trade

func _trade() -> void:
	var lvl := _area_level()
	content.add_child(K.label("Emeralds: %d" % State.res("emerald"), 20, Color("#2fd37a")))
	var pc := 25 + State.level * 2
	_row("[b]Health Potion[/b] - restores half your health.  [color=#2fd37a]%d emeralds[/color]  (you have %d)" % [pc, State.potions], "Buy", func():
		if State.spend({"emerald": pc}):
			State.potions += 1
			Sfx.play("coin")
		refresh(), State.res("emerald") >= pc)
	for kind in ["melee", "ranged", "armor", "artifact", "accessory"]:
		var cost := int((45 + lvl * 12) * (1.4 if kind in ["artifact", "accessory"] else 1.0))
		var k: String = kind
		_row("[b]Mystery %s[/b] - random gear at power %d.  [color=#2fd37a]%d emeralds[/color]" % [kind.capitalize(), lvl, cost], "Buy", func():
			if State.inventory.size() >= State.INVENTORY_CAP:
				Game.toast("Inventory full!", Color("#ff8a8a"))
				return
			if State.spend({"emerald": cost}):
				var inst := State.roll_item(lvl, 0.15, 0, k)
				State.add_item(inst)
				Sfx.play("chest")
				Game.toast("Bought: %s %s" % [Data.RARITIES[inst["rarity"]]["name"], State.item_name(inst)], Data.rarity_color(inst["rarity"]))
			refresh(), State.res("emerald") >= cost)
	content.add_child(HSeparator.new())
	content.add_child(K.label("Sell resources", 20, K.GOLD))
	var total := 0
	for id in State.resources:
		if id in ["emerald", "prism_shard", "arcane_dust"] or State.res(id) <= 0:
			continue
		var r: Dictionary = Data.resources[id]
		var val: int = r["value"] * State.res(id)
		total += val
		var rid: String = id
		_row("%s x%d  ->  [color=#2fd37a]%d emeralds[/color]" % [r["name"], State.res(id), val], "Sell", func():
			State.add_resource("emerald", r["value"] * State.res(rid))
			State.resources[rid] = 0
			Sfx.play("coin")
			refresh(), true, 100)
	if total == 0:
		content.add_child(K.label("Nothing to sell.", 16, K.DIM))


# ---------------------------------------------------------------- blacksmith

func _gear_list(kinds: Array) -> Array:
	var out: Array = []
	for s in State.SLOTS:
		var e = State.equipment[s]
		if e != null and Data.items[e["id"]]["kind"] in kinds and not e in out:
			out.append(e)
	for it in State.inventory:
		if Data.items[it["id"]]["kind"] in kinds and not it in out:
			out.append(it)
	return out


func _upgrade() -> void:
	var lvl := _area_level()
	content.add_child(K.label("Upgrade raises an item's level (max +%d). Reforge raises its power to this area's level (%d). Equipped items listed first." % [Data.MAX_UPGRADE, lvl], 16, K.DIM))
	for inst in _gear_list(["melee", "ranged", "armor", "accessory"]):
		var rc: Color = Data.rarity_color(inst["rarity"])
		var cost := State.upgrade_cost(inst)
		var maxed: bool = inst["upg"] >= Data.MAX_UPGRADE
		var it = inst
		var row := _row("[color=#%s][b]%s[/b][/color] [color=#a89a86](Power %d)%s[/color]\n%s" % [rc.to_html(false), State.item_name(inst), inst["power"], "  [E]" if State.is_equipped(inst["uid"]) else "", "Upgrade: " + K.cost_text(cost) if not maxed else "[color=#ffd84a]Fully upgraded[/color]"],
			"Upgrade", func():
				if State.spend(State.upgrade_cost(it)):
					it["upg"] += 1
					State.compute_stats()
					State.inventory_changed.emit()
					Sfx.play("hit", 1.4)
					Sfx.play("levelup", 1.8, -10.0)
					Quests.notify("upgrade", "", 1)
				refresh(), not maxed and State.can_afford(cost), 120)
		if inst["power"] < lvl:
			var rcost := State.reforge_cost(inst)
			var b := K.button("Reforge", func():
				if State.spend(State.reforge_cost(it)):
					it["power"] = lvl
					State.compute_stats()
					State.inventory_changed.emit()
					Sfx.play("magic", 0.8)
				refresh(), 110)
			b.tooltip_text = "Raise power to %d: %s" % [lvl, ", ".join(rcost.keys())]
			b.disabled = not State.can_afford(rcost)
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(b)


# ---------------------------------------------------------------- enchanter

func _enchant() -> void:
	content.add_child(K.label("Enchantment points: %d  (earn 1 per level; salvaging refunds them)" % State.enchant_points, 18, Color("#c48aff")))
	var it = State.find_item(ench_uid)
	if it == null:
		for inst in _gear_list(["melee", "ranged", "armor"]):
			var rc: Color = Data.rarity_color(inst["rarity"])
			var names: Array = []
			for e in inst["ench"]:
				names.append("%s %d" % [Data.enchants[e["id"]]["name"], e["lvl"]])
			var uid: int = inst["uid"]
			_row("[color=#%s][b]%s[/b][/color]%s\n[color=#b48aff]%s[/color]  [color=#a89a86](%d / %d slots)[/color]" % [rc.to_html(false), State.item_name(inst), "  [E]" if State.is_equipped(uid) else "", ", ".join(names) if not names.is_empty() else "No enchantments", inst["ench"].size(), State.enchant_slots(inst)],
				"Select", func():
					ench_uid = uid
					ench_offer = []
					refresh(), true, 110)
		return
	content.add_child(K.button("<  Back to item list", func(): ench_uid = -1; refresh(), 220))
	content.add_child(K.rich(K.item_text(it)))
	for e in it["ench"]:
		var ed: Dictionary = Data.enchants[e["id"]]
		var lv: int = e["lvl"]
		var cost := lv + 1
		var ench = e
		_row("[color=#b48aff][b]%s %d[/b][/color] - %s" % [ed["name"], lv, ed["desc"]], "Level up (%d pts)" % cost if lv < 3 else "Max", func():
			if State.enchant_points >= cost:
				State.enchant_points -= cost
				it["ep"] += cost
				ench["lvl"] += 1
				State.compute_stats()
				State.inventory_changed.emit()
				Sfx.play("magic", 1.5)
			refresh(), lv < 3 and State.enchant_points >= cost, 170)
	if it["ench"].size() < State.enchant_slots(it):
		if ench_offer.is_empty():
			var pool := State.enchant_pool(it)
			pool.shuffle()
			for id in pool:
				if ench_offer.size() >= 3:
					break
				var has := false
				for e in it["ench"]:
					if e["id"] == id:
						has = true
				if not has:
					ench_offer.append(id)
		content.add_child(K.label("Choose a new enchantment (1 point):", 18, K.GOLD))
		for id in ench_offer:
			var ed: Dictionary = Data.enchants[id]
			var eid: String = id
			_row("[color=#b48aff][b]%s[/b][/color] - %s" % [ed["name"], ed["desc"]], "Enchant", func():
				if State.enchant_points >= 1:
					State.enchant_points -= 1
					it["ep"] += 1
					it["ench"].append({"id": eid, "lvl": 1})
					ench_offer = []
					State.compute_stats()
					State.inventory_changed.emit()
					Sfx.play("magic", 1.2)
					Sfx.play("levelup", 2.0, -10.0)
				refresh(), State.enchant_points >= 1, 130)


# ---------------------------------------------------------------- mystic

func _artifacts() -> void:
	var lvl := _area_level()
	content.add_child(K.label("Arcane Dust: %d   Emeralds: %d   (salvage gear for dust)" % [State.res("arcane_dust"), State.res("emerald")], 18, Color("#c48aff")))
	for inst in _gear_list(["artifact"]):
		var d: Dictionary = Data.items[inst["id"]]
		var rc: Color = Data.rarity_color(inst["rarity"])
		var cost := State.artifact_upgrade_cost(inst)
		var maxed: bool = inst["upg"] >= Data.MAX_UPGRADE
		var it = inst
		var row := _row("[color=#%s][b]%s[/b][/color]  [color=#a89a86]Power %d, %.1fs cooldown[/color]\n%s\n%s" % [rc.to_html(false), State.item_name(inst), State.artifact_power(inst), State.artifact_cooldown(inst), d["desc"], ("Empower: " + K.cost_text(cost)) if not maxed else "[color=#ffd84a]Fully empowered[/color]"],
			"Empower", func():
				if State.spend(State.artifact_upgrade_cost(it)):
					it["upg"] += 1
					State.inventory_changed.emit()
					Sfx.play("magic", 1.5)
				refresh(), not maxed and State.can_afford(cost), 120)
		if inst["power"] < lvl:
			var rcost := State.reforge_cost(inst)
			var b := K.button("Attune", func():
				if State.spend(State.reforge_cost(it)):
					it["power"] = lvl
					State.inventory_changed.emit()
					Sfx.play("magic", 0.8)
				refresh(), 110)
			b.disabled = not State.can_afford(rcost)
			b.tooltip_text = "Raise power to %d" % lvl
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(b)


# ---------------------------------------------------------------- alchemist

func _potions() -> void:
	var pc := 22 + State.level * 2
	var d := Data.dim(State.current_dim)
	var herb: String = d["resources"][4]
	content.add_child(K.label("Potions carried: %d" % State.potions, 20, Color("#ff7a9a")))
	_row("[b]Health Potion[/b]  [color=#2fd37a]%d emeralds[/color]" % pc, "Buy", func():
		if State.spend({"emerald": pc}):
			State.potions += 1
			Sfx.play("pickup")
		refresh(), State.res("emerald") >= pc)
	_row("[b]Brew from herbs[/b] - 3 %s into a potion. (%d owned)" % [Data.resources[herb]["name"], State.res(herb)], "Brew", func():
		if State.spend({herb: 3}):
			State.potions += 1
			Sfx.play("magic")
		refresh(), State.res(herb) >= 3)
	var ec := 60 + State.level * 5
	_row("[b]Wayfinder's Elixir[/b] - drink now for a random magic power-up.  [color=#2fd37a]%d emeralds[/color]" % ec, "Drink", func():
		if State.spend({"emerald": ec}):
			var keys := Data.powerups.keys()
			Game.player.add_powerup(keys[randi() % keys.size()])
		close(), State.res("emerald") >= ec)
	_row("[b]Ichor Tonic[/b] - 5 Rotten Ichor + 2 Slime Gel into 2 potions.", "Brew", func():
		if State.spend({"ichor": 5, "slime_gel": 2}):
			State.potions += 2
			Sfx.play("magic")
		refresh(), State.can_afford({"ichor": 5, "slime_gel": 2}))


# ---------------------------------------------------------------- lore

func _lore() -> void:
	var main := Quests.current_main()
	var t := ""
	if main != "":
		var q := Quests.def(main)
		t += "[color=#f2c14e][b]Your path: %s[/b][/color]\n%s\n\n" % [q["title"], q["desc"]]
	var d := Data.dim(State.current_dim)
	t += "[color=#f2c14e][b]%s[/b][/color]\n%s\n\n" % [d["name"], d["desc"]]
	match villager.role:
		"cartographer":
			var g = Game.world.surface_gen
			var p: Vector3 = Game.player.global_position
			for type in ["cave", "lore", "shrine"]:
				var poi: Dictionary = g.find_nearest_poi(type, p, 400.0)
				if not poi.is_empty():
					var dir := Vector2(poi["x"] - p.x, poi["z"] - p.z)
					t += "Nearest %s: about %d blocks to the %s.\n" % [{"cave": "cave", "lore": "unread Lore Stone", "shrine": "unclaimed shrine"}[type], int(dir.length()), _compass(dir)]
		"bard":
			var found: Array = []
			for l in Story.lore:
				if State.lore_found.has(l["id"]):
					found.append(l)
			if not found.is_empty():
				var l: Dictionary = found[randi() % found.size()]
				t += "[i]\"Let me sing you of %s...\"[/i]\n%s" % [l["title"], l["text"]]
			else:
				t += "[i]\"%s\"[/i]" % Story.PROLOGUE[randi() % Story.PROLOGUE.size()]
		_:
			t += "[i]\"%s\"[/i]" % Story.PROLOGUE[mini(Quests.completed.size() / 5, Story.PROLOGUE.size() - 1)]
	var r := K.rich(t)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(r)


func _compass(d: Vector2) -> String:
	var a := fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0)
	var names := ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]
	return names[int(round(a / 45.0)) % 8]

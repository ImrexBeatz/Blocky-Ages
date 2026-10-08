## Persistent player state: profile, progression, inventory, loot rolls and save/load.
extends Node

signal stats_changed
signal inventory_changed
signal resources_changed
signal xp_changed
signal leveled_up(level: int)

const SAVE_PATH := "user://blockydungeons_save.json"
const SLOTS := ["melee", "ranged", "armor", "art1", "art2", "art3", "ring1", "ring2", "amulet", "charm"]
const SLOT_UNLOCK := {"melee": 1, "ranged": 1, "armor": 1, "art1": 1, "art2": 3, "art3": 8, "ring1": 1, "amulet": 4, "ring2": 6, "charm": 10}
const INVENTORY_CAP := 90
const ATTRS := ["might", "vitality", "arcana", "agility", "fortune"]

var profile := {}
var level := 1
var xp := 0
var attr_points := 0
var enchant_points := 0
var perk_points := 0
var attrs := {"might": 0, "vitality": 0, "arcana": 0, "agility": 0, "fortune": 0}
var perks := {}
var inventory: Array = []
var equipment := {}
var resources := {}
var potions := 3
var next_uid := 1
var stats := {}

var world_seed := 0
var current_dim := "verdant"
var positions := {}
var unlocked_dims: Array = ["verdant"]
var opened := {}
var bosses_defeated := {}
var lore_found := {}
var bestiary := {}
var playtime := 0.0
var ascension := 0
var story_done := false
var total_kills := 0
var caves_cleared := 0
var visited_villages := {}


func _ready() -> void:
	reset()


func reset() -> void:
	profile = default_profile()
	level = 1
	xp = 0
	attr_points = 0
	enchant_points = 0
	perk_points = 0
	attrs = {"might": 0, "vitality": 0, "arcana": 0, "agility": 0, "fortune": 0}
	perks = {}
	inventory = []
	equipment = {}
	for s in SLOTS:
		equipment[s] = null
	resources = {"emerald": 25}
	potions = 3
	next_uid = 1
	world_seed = randi() % 1000000
	current_dim = "verdant"
	positions = {}
	unlocked_dims = ["verdant"]
	opened = {}
	bosses_defeated = {}
	lore_found = {}
	bestiary = {}
	playtime = 0.0
	ascension = 0
	story_done = false
	total_kills = 0
	caves_cleared = 0
	visited_villages = {}
	compute_stats()


func default_profile() -> Dictionary:
	return {
		"name": "Wayfinder", "origin": "warrior",
		"skin": "#e0ac7e", "hair": "#4a2e1a", "hair_style": 0, "eyes": "#3a6ad6",
		"shirt": "#3a7ad6", "pants": "#3a3a5a", "boots": "#4a2e1a", "cape": true, "cape_color": "#a33a2a", "hat": 0,
	}


func new_game(p: Dictionary) -> void:
	reset()
	profile = p
	var origin := _origin(p.get("origin", "warrior"))
	for k in origin["attr"]:
		attrs[k] += origin["attr"][k]
	var slot_for := {"melee": "melee", "ranged": "ranged", "armor": "armor", "artifact": "art1"}
	for id in origin["kit"]:
		var inst := make_item(id, 1, 0)
		add_item(inst)
		equip(inst["uid"], slot_for[Data.items[id]["kind"]])
	add_item(make_item("wooden_sword", 1, 0))
	add_item(make_item("ring_vigor", 1, 0))
	compute_stats()


func _origin(id: String) -> Dictionary:
	for o in Data.origins:
		if o["id"] == id:
			return o
	return Data.origins[0]


# ---------------------------------------------------------------- items

func make_item(id: String, power: int, rarity: int) -> Dictionary:
	var inst := {"uid": next_uid, "id": id, "power": maxi(1, power), "rarity": rarity, "upg": 0, "ench": [], "ep": 0, "new": true}
	next_uid += 1
	return inst


func def_of(inst) -> Dictionary:
	if inst == null:
		return {}
	return Data.items.get(inst["id"], {})


func item_name(inst) -> String:
	var d := def_of(inst)
	var n: String = d.get("name", "?")
	if inst["upg"] > 0:
		n += " +%d" % inst["upg"]
	return n


func power_mult(inst) -> float:
	var r: float = Data.RARITIES[inst["rarity"]]["mult"]
	return (1.0 + 0.08 * (inst["power"] - 1)) * r * (1.0 + 0.12 * inst["upg"])


func ench_level(inst, ench_id: String) -> int:
	if inst == null:
		return 0
	for e in inst["ench"]:
		if e["id"] == ench_id:
			return e["lvl"]
	return 0


func equipped_ench(slot: String, ench_id: String) -> int:
	return ench_level(equipment.get(slot), ench_id)


func weapon_damage(inst) -> float:
	var d := def_of(inst)
	return d.get("dmg", 5.0) * power_mult(inst)


func artifact_power(inst) -> float:
	var d := def_of(inst)
	var p: float = d.get("power", 10.0)
	if d.get("ability", "") in ["iron_hide", "haste", "time_slow", "lifebloom"]:
		return p * (1.0 + 0.04 * inst["upg"] + 0.05 * inst["rarity"])
	return p * (1.0 + 0.08 * (inst["power"] - 1)) * Data.RARITIES[inst["rarity"]]["mult"] * (1.0 + 0.2 * inst["upg"])


func artifact_cooldown(inst) -> float:
	var d := def_of(inst)
	return d.get("cd", 10.0) * (1.0 - stats.get("cdr", 0.0)) * (1.0 - 0.04 * inst["upg"])


func item_value(inst) -> int:
	return int((10 + inst["power"] * 3) * (1 + inst["rarity"] * 1.5) * (1 + inst["upg"] * 0.3))


func add_item(inst: Dictionary) -> bool:
	if inventory.size() >= INVENTORY_CAP:
		return false
	inventory.append(inst)
	inventory_changed.emit()
	return true


func find_item(uid: int) -> Variant:
	for it in inventory:
		if it["uid"] == uid:
			return it
	return null


func is_equipped(uid: int) -> bool:
	for s in SLOTS:
		var e = equipment[s]
		if e != null and e["uid"] == uid:
			return true
	return false


func slot_unlocked(slot: String) -> bool:
	return level >= SLOT_UNLOCK[slot]


func slots_for(inst) -> Array:
	var d := def_of(inst)
	match d.get("kind", ""):
		"melee": return ["melee"]
		"ranged": return ["ranged"]
		"armor": return ["armor"]
		"artifact": return ["art1", "art2", "art3"]
		"accessory":
			match d["slot"]:
				"ring": return ["ring1", "ring2"]
				"amulet": return ["amulet"]
				"charm": return ["charm"]
	return []


func equip(uid: int, slot := "") -> bool:
	var inst = find_item(uid)
	if inst == null:
		return false
	var options := slots_for(inst)
	if options.is_empty():
		return false
	if slot == "":
		slot = options[0]
		for s in options:
			if slot_unlocked(s) and equipment[s] == null:
				slot = s
				break
	if not slot_unlocked(slot) or not slot in options:
		return false
	# One copy of the same artifact at a time.
	for s in options:
		if s != slot and equipment[s] != null and equipment[s]["uid"] == uid:
			equipment[s] = null
	equipment[slot] = inst
	inst["new"] = false
	compute_stats()
	inventory_changed.emit()
	return true


func unequip(slot: String) -> void:
	if slot in ["melee", "ranged", "armor"]:
		return
	equipment[slot] = null
	compute_stats()
	inventory_changed.emit()


func salvage(uid: int) -> Dictionary:
	var inst = find_item(uid)
	if inst == null or is_equipped(uid):
		return {}
	inventory.erase(inst)
	var dust: int = 1 + inst["rarity"] * 2 + int(inst["power"] / 8.0)
	var ems: int = int(item_value(inst) * 0.35)
	add_resource("arcane_dust", dust)
	add_resource("emerald", ems)
	enchant_points += inst["ep"]
	inventory_changed.emit()
	return {"arcane_dust": dust, "emerald": ems, "ep": inst["ep"]}


func upgrade_cost(inst) -> Dictionary:
	var dim_ix := clampi(int((inst["power"] - 1) / 10), 0, 4)
	var dimdef: Dictionary = Data.dimensions[dim_ix]
	var ore: String = dimdef["resources"][2]
	var cost := {"emerald": int((20 + inst["power"] * 4) * (1 + inst["upg"] * 0.6) * (1 + inst["rarity"] * 0.25)), ore: 2 + inst["upg"]}
	if inst["upg"] >= 7:
		cost["prism_shard"] = inst["upg"] - 6
	return cost


func artifact_upgrade_cost(inst) -> Dictionary:
	return {"arcane_dust": 4 + inst["upg"] * 4, "emerald": int(30 + inst["power"] * 3 * (1 + inst["upg"] * 0.5))}


func reforge_cost(inst) -> Dictionary:
	return {"emerald": int(60 + inst["power"] * 10), "arcane_dust": 6 + inst["power"] / 4}


func enchant_slots(inst) -> int:
	return Data.RARITIES[inst["rarity"]]["slots"]


func enchant_pool(inst) -> Array:
	var kind: String = def_of(inst).get("kind", "")
	var out: Array = []
	for id in Data.enchants:
		if Data.enchants[id]["kind"] == kind:
			out.append(id)
	return out


# ---------------------------------------------------------------- resources

func res(id: String) -> int:
	return resources.get(id, 0)


func add_resource(id: String, n: int) -> void:
	resources[id] = res(id) + n
	resources_changed.emit()
	if n > 0:
		Quests.notify("gather", id, n)


func can_afford(cost: Dictionary) -> bool:
	for k in cost:
		if res(k) < cost[k]:
			return false
	return true


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for k in cost:
		resources[k] = res(k) - cost[k]
	resources_changed.emit()
	return true


# ---------------------------------------------------------------- progression

func xp_needed(lv: int = -1) -> int:
	if lv < 0:
		lv = level
	return int(80.0 * pow(lv, 1.45))


func add_xp(amount: int) -> void:
	if level >= Data.MAX_LEVEL:
		return
	xp += int(amount * (1.0 + stats.get("xp", 0.0)))
	while xp >= xp_needed() and level < Data.MAX_LEVEL:
		xp -= xp_needed()
		level += 1
		attr_points += 1
		enchant_points += 1
		if level % 5 == 0:
			perk_points += 1
		compute_stats()
		leveled_up.emit(level)
		Quests.notify("level", "", level)
	xp_changed.emit()


func spend_attr(a: String) -> bool:
	if attr_points <= 0:
		return false
	attr_points -= 1
	attrs[a] += 1
	compute_stats()
	return true


func buy_perk(id: String) -> bool:
	if perk_points <= 0 or perks.has(id):
		return false
	for p in Data.perks:
		if p["id"] == id and level >= p["req"]:
			perks[id] = true
			perk_points -= 1
			compute_stats()
			return true
	return false


func has_perk(id: String) -> bool:
	return perks.has(id)


func compute_stats() -> void:
	var s := {
		"max_hp": 100.0 + 8.0 * (level - 1), "melee_pct": 0.0, "ranged_pct": 0.0, "artifact_pct": 0.0, "cdr": 0.0,
		"crit": 0.05, "lifesteal": 0.0, "speed_pct": 0.0, "armor": 0.0, "regen": 0.5, "luck": 0.0, "xp": 0.0,
		"potion": 0.0, "magnet": 2.5, "emerald": 0.0, "thorns": 0.0, "burn_pct": 0.0, "roll_cd": 0.0, "hp_pct": 0.0,
		"aura_burn": 0.0,
	}
	s["melee_pct"] += attrs["might"] * 0.04
	s["ranged_pct"] += attrs["might"] * 0.03 + attrs["agility"] * 0.02
	s["max_hp"] += attrs["vitality"] * 12.0
	s["regen"] += attrs["vitality"] * 0.1
	s["artifact_pct"] += attrs["arcana"] * 0.05
	s["cdr"] += attrs["arcana"] * 0.012
	s["speed_pct"] += attrs["agility"] * 0.012
	s["crit"] += attrs["agility"] * 0.008
	s["luck"] += attrs["fortune"] * 0.03
	s["emerald"] += attrs["fortune"] * 0.03

	var armor = equipment.get("armor")
	if armor != null:
		var ad := def_of(armor)
		s["max_hp"] += ad["hp"] * power_mult(armor) * 0.6
		s["armor"] += ad["def"]
		for k in ad["bonus"]:
			s[k] = s.get(k, 0.0) + ad["bonus"][k]
		s["armor"] += ench_level(armor, "protection") * 0.04
		s["hp_pct"] += ench_level(armor, "health_boost") * 0.1
		s["cdr"] += ench_level(armor, "cooldown") * 0.08
		s["speed_pct"] += ench_level(armor, "swiftness") * 0.05
		s["thorns"] += ench_level(armor, "thorns") * 0.2
		s["aura_burn"] += ench_level(armor, "burning")
	for slot in ["ring1", "ring2", "amulet", "charm"]:
		var a = equipment.get(slot)
		if a == null:
			continue
		var scale: float = (0.8 + 0.25 * a["rarity"]) * (1.0 + 0.06 * a["upg"]) * (1.0 + 0.02 * (a["power"] - 1))
		var mods: Dictionary = def_of(a)["mods"]
		for k in mods:
			var v: float = mods[k]
			if k == "hp":
				s["max_hp"] += v * scale
			elif k == "magnet":
				s["magnet"] += v
			else:
				s[k] = s.get(k, 0.0) + v * (0.8 + 0.25 * a["rarity"]) * (1.0 + 0.06 * a["upg"])
	var melee = equipment.get("melee")
	if melee != null:
		s["crit"] += def_of(melee).get("crit", 0.0) + ench_level(melee, "critical") * 0.06
		s["lifesteal"] += def_of(melee).get("lifesteal", 0.0) + ench_level(melee, "leeching") * 0.02
		s["melee_pct"] += ench_level(melee, "sharpness") * 0.12
	var ranged = equipment.get("ranged")
	if ranged != null:
		s["ranged_pct"] += ench_level(ranged, "power") * 0.15
	if has_perk("thick_skin"):
		s["armor"] += 0.1
	if has_perk("mana_font"):
		s["cdr"] += 0.15
	if has_perk("vampiric"):
		s["lifesteal"] += 0.02
	if has_perk("pyromancer"):
		s["burn_pct"] += 0.5
	if has_perk("wayfinder"):
		s["hp_pct"] += 0.1
		s["melee_pct"] += 0.1
		s["ranged_pct"] += 0.1
		s["artifact_pct"] += 0.1
	s["max_hp"] *= 1.0 + s["hp_pct"]
	s["armor"] = clampf(s["armor"], -0.3, 0.75)
	s["cdr"] = clampf(s["cdr"], 0.0, 0.6)
	s["crit"] = clampf(s["crit"], 0.0, 0.8)
	s["speed_pct"] = clampf(s["speed_pct"], -0.3, 0.8)
	stats = s
	stats_changed.emit()


# ---------------------------------------------------------------- loot

func roll_rarity(bonus := 0.0, min_rarity := 0) -> int:
	var luck: float = stats.get("luck", 0.0) + bonus + ascension * 0.1
	var w := [60.0, 28.0 * (1 + luck), 9.0 * (1 + luck * 1.5), 2.7 * (1 + luck * 2.0), 0.3 * (1 + luck * 3.0)]
	if ascension == 0 and level < 25:
		w[4] *= 0.3
	var total := 0.0
	for i in range(min_rarity, w.size()):
		total += w[i]
	var r := randf() * total
	for i in range(min_rarity, w.size()):
		r -= w[i]
		if r <= 0:
			return i
	return min_rarity


## Picks a random gear id appropriate for the realm tier, with a little cross-tier spillover.
func roll_item(power: int, rarity_bonus := 0.0, min_rarity := 0, kind := "") -> Dictionary:
	if kind == "":
		var r := randf()
		kind = "melee" if r < 0.27 else ("ranged" if r < 0.44 else ("armor" if r < 0.64 else ("artifact" if r < 0.84 else "accessory")))
	var pool := Data.item_pool(kind)
	var tier := clampf((power - 1) / 45.0, 0.0, 1.0)
	var ix := clampi(int(round((tier + randf_range(-0.25, 0.25)) * (pool.size() - 1))), 0, pool.size() - 1)
	if kind in ["artifact", "accessory"]:
		ix = randi() % pool.size()
	var id: String = pool[ix]
	var rar := roll_rarity(rarity_bonus, min_rarity)
	if id.begins_with("prism") and rar < 3:
		rar = 3
	var inst := make_item(id, power, rar)
	if rar >= 3 and randf() < 0.6:
		var ep := enchant_pool(inst)
		if not ep.is_empty():
			inst["ench"].append({"id": ep[randi() % ep.size()], "lvl": 1 + (1 if rar == 4 else 0)})
	return inst


# ---------------------------------------------------------------- save/load

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var eq := {}
	for s in SLOTS:
		eq[s] = equipment[s]["uid"] if equipment[s] != null else -1
	var data := {
		"version": 1, "profile": profile, "level": level, "xp": xp, "attr_points": attr_points, "enchant_points": enchant_points,
		"perk_points": perk_points, "attrs": attrs, "perks": perks, "inventory": inventory, "equipment": eq, "resources": resources,
		"potions": potions, "next_uid": next_uid, "world_seed": world_seed, "current_dim": current_dim, "positions": positions,
		"unlocked_dims": unlocked_dims, "opened": opened, "bosses_defeated": bosses_defeated, "lore_found": lore_found,
		"bestiary": bestiary, "playtime": playtime, "ascension": ascension, "story_done": story_done, "total_kills": total_kills,
		"caves_cleared": caves_cleared, "visited_villages": visited_villages, "quests": Quests.serialize(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	reset()
	profile = data.get("profile", default_profile())
	level = int(data.get("level", 1))
	xp = int(data.get("xp", 0))
	attr_points = int(data.get("attr_points", 0))
	enchant_points = int(data.get("enchant_points", 0))
	perk_points = int(data.get("perk_points", 0))
	for k in ATTRS:
		attrs[k] = int(data.get("attrs", {}).get(k, 0))
	perks = data.get("perks", {})
	inventory = []
	for it in data.get("inventory", []):
		if not Data.items.has(it.get("id", "")):
			continue
		it["uid"] = int(it["uid"])
		it["power"] = int(it["power"])
		it["rarity"] = int(it["rarity"])
		it["upg"] = int(it["upg"])
		it["ep"] = int(it.get("ep", 0))
		for e in it["ench"]:
			e["lvl"] = int(e["lvl"])
		inventory.append(it)
	var eq: Dictionary = data.get("equipment", {})
	for s in SLOTS:
		equipment[s] = find_item(int(eq.get(s, -1)))
	resources = {}
	var rs: Dictionary = data.get("resources", {})
	for k in rs:
		resources[k] = int(rs[k])
	potions = int(data.get("potions", 3))
	next_uid = int(data.get("next_uid", 1000))
	world_seed = int(data.get("world_seed", 1))
	current_dim = data.get("current_dim", "verdant")
	positions = data.get("positions", {})
	unlocked_dims = data.get("unlocked_dims", ["verdant"])
	opened = data.get("opened", {})
	bosses_defeated = data.get("bosses_defeated", {})
	lore_found = data.get("lore_found", {})
	bestiary = data.get("bestiary", {})
	playtime = float(data.get("playtime", 0.0))
	ascension = int(data.get("ascension", 0))
	story_done = bool(data.get("story_done", false))
	total_kills = int(data.get("total_kills", 0))
	caves_cleared = int(data.get("caves_cleared", 0))
	visited_villages = data.get("visited_villages", {})
	Quests.deserialize(data.get("quests", {}))
	compute_stats()
	inventory_changed.emit()
	return true


func color(key: String) -> Color:
	return Color(profile.get(key, "#ffffff"))

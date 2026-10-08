## Static game content: realms, biomes, creatures, bosses, items, magic and resources.
extends Node

const RARITIES := [
	{"name": "Common", "color": Color("#c9c9c9"), "mult": 1.0, "slots": 1},
	{"name": "Rare", "color": Color("#4fa8ff"), "mult": 1.25, "slots": 2},
	{"name": "Epic", "color": Color("#b45cff"), "mult": 1.55, "slots": 2},
	{"name": "Legendary", "color": Color("#ffb52e"), "mult": 1.9, "slots": 3},
	{"name": "Mythic", "color": Color("#ff4f6d"), "mult": 2.4, "slots": 3},
]

const MAX_LEVEL := 100
const MAX_UPGRADE := 10

var dimensions: Array = []
var dim_index := {}
var enemies := {}
var bosses := {}
var items := {}
var resources := {}
var enchants := {}
var perks: Array = []
var powerups := {}
var villager_roles: Array = []
var origins: Array = []


func _ready() -> void:
	_build_dimensions()
	_build_resources()
	_build_enemies()
	_build_bosses()
	_build_weapons()
	_build_ranged()
	_build_armor()
	_build_artifacts()
	_build_accessories()
	_build_enchants()
	_build_perks()
	_build_powerups()
	_build_roles()
	_build_origins()


func dim(id: String) -> Dictionary:
	return dimensions[dim_index.get(id, 0)]


func rarity_color(r: int) -> Color:
	return RARITIES[clampi(r, 0, RARITIES.size() - 1)]["color"]


# ---------------------------------------------------------------- realms

func _biome(name: String, top: String, side: String, deep: String, tree: String, amp: float, trees: float, extra := {}) -> Dictionary:
	var b := {"name": name, "top": Color(top), "side": Color(side), "deep": Color(deep), "tree": tree, "amp": amp, "trees": trees}
	b.merge(extra, true)
	b["wetness"] = 1.0 if b.get("wet", false) else 0.0
	return b


func _build_dimensions() -> void:
	dimensions = [
		{
			"id": "verdant", "name": "The Verdant Reach", "short": "Verdant Reach",
			"desc": "Rolling meadows, whispering birchwoods and ancient highlands. The first realm to feel Malgrath's corruption.",
			"base_level": 1, "liquid": "water", "liquid_color": Color(0.18, 0.42, 0.78, 0.72), "sea": 2,
			"sky_top": Color("#3d7fd6"), "sky_horizon": Color("#b9dcff"), "ground_horizon": Color("#6f8f6a"),
			"fog": Color("#bcd8f0"), "fog_density": 0.006, "sun": Color("#fff2d6"), "sun_energy": 1.25, "ambient": Color("#9ab7d8"),
			"particles": "fireflies", "day_cycle": true, "music": [0, 4, 7, 11, 12, 7, 4, 2],
			"house": {"wall": Color("#c8a46e"), "frame": Color("#6b4a2b"), "roof": Color("#8f3b2b"), "floor": Color("#8a6a45")},
			"village_names": ["Oak", "Willow", "Brook", "Thorn", "Elm", "Briar", "Moss", "Amber", "Fern", "Hollow"],
			"village_suffix": ["hollow", "ford", "vale", "stead", "wick", "brook", "haven", "field"],
			"biomes": [
				_biome("Sunlit Meadows", "#5ea43a", "#7a5634", "#7d7d7d", "oak", 5.0, 0.025, {"flowers": 0.06}),
				_biome("Whispering Birchwood", "#6fae45", "#7a5634", "#7d7d7d", "birch", 7.0, 0.07, {"flowers": 0.03}),
				_biome("Amber Dunes", "#dcc787", "#c9b071", "#b39a5e", "cactus", 4.0, 0.012),
				_biome("Mirewood Swamp", "#4a6b33", "#4f3d26", "#5e5e52", "swamp", 2.0, 0.04, {"wet": true}),
				_biome("Stonecrown Highlands", "#6a8f4a", "#8a8a8a", "#6e6e6e", "pine", 20.0, 0.03),
			],
			"enemies": ["shambler", "bone_archer", "creepling", "web_lurker", "vindicator", "hex_evoker", "bog_witch", "rampager_boar"],
			"bosses": ["gorehorn", "velkar", "mire_matriarch", "stone_colossus"],
			"resources": ["timber", "stone", "iron_ore", "gold_ore", "silverleaf"],
		},
		{
			"id": "ember", "name": "The Ashen Underrealm", "short": "Ashen Underrealm",
			"desc": "A smoldering realm of ash, basalt and soulfire, where the Shard of Flame burns at the heart of a dead empire.",
			"base_level": 10, "liquid": "lava", "liquid_color": Color(1.0, 0.42, 0.08, 1.0), "sea": 1,
			"sky_top": Color("#2a0a08"), "sky_horizon": Color("#a3361a"), "ground_horizon": Color("#3a1410"),
			"fog": Color("#6e2416"), "fog_density": 0.014, "sun": Color("#ff9a5a"), "sun_energy": 0.9, "ambient": Color("#a3503a"),
			"particles": "embers", "day_cycle": false, "music": [0, 1, 5, 7, 8, 7, 5, 3],
			"house": {"wall": Color("#4a3a3a"), "frame": Color("#2a1d1d"), "roof": Color("#7a2a1a"), "floor": Color("#3b2b2b")},
			"village_names": ["Cinder", "Ash", "Ember", "Soot", "Brand", "Scorch", "Pyre", "Char"],
			"village_suffix": ["hold", "keep", "forge", "hearth", "refuge", "crag"],
			"biomes": [
				_biome("Ash Wastes", "#5b5250", "#463d3b", "#2e2a2a", "deadwood", 6.0, 0.012),
				_biome("Crimson Forest", "#8a1f2a", "#5a2a26", "#3a2222", "crimson", 6.0, 0.06),
				_biome("Basalt Spires", "#3c3c42", "#2d2d33", "#222226", "spire", 18.0, 0.02),
				_biome("Soulfire Valley", "#4b3b30", "#3a2c24", "#2a201a", "soul", 4.0, 0.03, {"glow": Color("#46d6ff")}),
			],
			"enemies": ["ember_imp", "magma_cube", "blaze_wisp", "tuskguard", "charred_revenant", "soul_wraith", "cinderhog", "ash_golem"],
			"bosses": ["grimtusk", "pyrrhia", "infernax", "soulforged_sentinel"],
			"resources": ["ashwood", "basalt", "cinder_ore", "soul_gem", "quartz"],
		},
		{
			"id": "frost", "name": "The Frostfall Wastes", "short": "Frostfall Wastes",
			"desc": "An endless winter born when the Shard of Stillness froze the sky itself. Wolves howl beneath the aurora.",
			"base_level": 20, "liquid": "ice", "liquid_color": Color(0.7, 0.88, 1.0, 1.0), "sea": 3,
			"sky_top": Color("#1f3a6b"), "sky_horizon": Color("#cfe6ff"), "ground_horizon": Color("#a8c4dc"),
			"fog": Color("#c9dcef"), "fog_density": 0.012, "sun": Color("#dff0ff"), "sun_energy": 0.8, "ambient": Color("#8aa6c8"),
			"particles": "snow", "day_cycle": true, "music": [0, 3, 7, 10, 14, 10, 7, 3],
			"house": {"wall": Color("#9a8a78"), "frame": Color("#4d3b2c"), "roof": Color("#e8f0f8"), "floor": Color("#6e5a46")},
			"village_names": ["Frost", "Rime", "Winter", "Hail", "Glacier", "North", "Snow", "Ice"],
			"village_suffix": ["hearth", "watch", "holm", "fell", "mark", "spire"],
			"biomes": [
				_biome("Snowfield Tundra", "#dfe8f1", "#8a7a6a", "#7a7f88", "none", 4.0, 0.004),
				_biome("Frostpine Taiga", "#d2dde8", "#6b5a48", "#70757e", "snowpine", 8.0, 0.07),
				_biome("Crystal Ice Spikes", "#cfe7ff", "#9cc8f0", "#86aed6", "icespike", 6.0, 0.03),
				_biome("Glacier Rift", "#b8d4ea", "#8fb1cf", "#6d8aa6", "none", 16.0, 0.0),
			],
			"enemies": ["stray_ranger", "frost_wolf", "ice_golem", "yeti", "frost_wraith", "snow_imp", "iceclaw_spider", "frozen_revenant"],
			"bosses": ["rimefang", "glaciara", "avalanche_titan", "frostheart_wyrm"],
			"resources": ["frostpine_log", "packed_ice", "frost_crystal", "mithril_ore", "snowbloom"],
		},
		{
			"id": "spore", "name": "The Sporelight Hollows", "short": "Sporelight Hollows",
			"desc": "A glowing fungal wilderness where the Shard of Life grew wild, and everything that breathes now blooms.",
			"base_level": 30, "liquid": "toxic", "liquid_color": Color(0.45, 0.95, 0.35, 0.85), "sea": 2,
			"sky_top": Color("#1a0f2e"), "sky_horizon": Color("#6b3d8f"), "ground_horizon": Color("#2a1a3a"),
			"fog": Color("#4b2d63"), "fog_density": 0.013, "sun": Color("#c9a6ff"), "sun_energy": 0.8, "ambient": Color("#8a6ab8"),
			"particles": "spores", "day_cycle": false, "music": [0, 2, 3, 7, 9, 7, 3, 2],
			"house": {"wall": Color("#d8c9b0"), "frame": Color("#6a4a7a"), "roof": Color("#c23b5a"), "floor": Color("#5a4a5a")},
			"village_names": ["Spore", "Cap", "Gill", "Bloom", "Myco", "Glow", "Moss", "Puff"],
			"village_suffix": ["dell", "ring", "grove", "burrow", "hollow", "cradle"],
			"biomes": [
				_biome("Mycelium Flats", "#7a6a8a", "#5a4a5a", "#4a4050", "shroom_small", 4.0, 0.04, {"glow": Color("#9cff6a")}),
				_biome("Giant Shroom Forest", "#6a5a7a", "#4a3a4a", "#3e3644", "shroom_giant", 7.0, 0.05),
				_biome("Glowcap Grotto", "#3a5a6a", "#2e4450", "#26343e", "glowcap", 10.0, 0.05, {"glow": Color("#5ff3ff")}),
				_biome("Bloomrot Marsh", "#4a6a3a", "#3a4a2a", "#30382a", "rotvine", 2.0, 0.04, {"wet": true}),
			],
			"enemies": ["sporeling", "fungal_shambler", "mooshroom_brute", "glowmoth", "spore_caster", "rotvine_lurker", "myconid_archer", "puffcap_bomber"],
			"bosses": ["rot_mother", "queen_lumina", "myco_colossus", "overgrowth_heart"],
			"resources": ["shroom_cap", "glowspore", "myco_fiber", "bioluminite", "rot_amber"],
		},
		{
			"id": "void", "name": "The Hollow Void", "short": "Hollow Void",
			"desc": "Shattered islands adrift in starless dark. Malgrath's throne lies at the edge of everything.",
			"base_level": 40, "liquid": "void", "liquid_color": Color(0.05, 0.0, 0.1, 1.0), "sea": -1,
			"sky_top": Color("#05020c"), "sky_horizon": Color("#2a1145"), "ground_horizon": Color("#0a0414"),
			"fog": Color("#1a0b2e"), "fog_density": 0.011, "sun": Color("#b38cff"), "sun_energy": 0.75, "ambient": Color("#5b3f8f"),
			"particles": "void", "day_cycle": false, "music": [0, 1, 6, 7, 11, 6, 1, 13],
			"house": {"wall": Color("#d9d3a4"), "frame": Color("#3a2a4a"), "roof": Color("#5a2a7a"), "floor": Color("#2a2034")},
			"village_names": ["Star", "Echo", "Null", "Rift", "Gloam", "Dusk", "Veil", "Aether"],
			"village_suffix": ["reach", "spire", "anchor", "light", "sanctum", "rest"],
			"biomes": [
				_biome("Shattered Isles", "#d9d3a4", "#b3ad80", "#8a8562", "chorus", 6.0, 0.03, {"void_gaps": 0.45}),
				_biome("Chorus Gardens", "#cfc89a", "#a59f78", "#7f7a5c", "chorus", 5.0, 0.08, {"void_gaps": 0.25}),
				_biome("Obsidian Wastes", "#2a1f3a", "#1e162a", "#140f1d", "obsidian", 10.0, 0.02, {"void_gaps": 0.2}),
				_biome("Starfall Crater", "#3a3360", "#2a2448", "#1c1832", "crystal", 8.0, 0.03, {"glow": Color("#ffe58a"), "void_gaps": 0.3}),
			],
			"enemies": ["enderling", "void_shulker", "voidstalker", "null_sentry", "star_wisp", "rift_spawn", "gloom_crawler", "phantom"],
			"bosses": ["warden_echoes", "nihila", "phantom_monarch", "malgrath"],
			"resources": ["void_shard", "chorus_fruit", "obsidian", "star_fragment", "echo_crystal"],
		},
	]
	for i in dimensions.size():
		dim_index[dimensions[i]["id"]] = i


# ---------------------------------------------------------------- resources

func _res(id: String, name: String, color: String, value: int, dimid: String, desc: String) -> void:
	resources[id] = {"id": id, "name": name, "color": Color(color), "value": value, "dim": dimid, "desc": desc}


func _build_resources() -> void:
	_res("emerald", "Emeralds", "#2fd37a", 1, "", "The currency of every realm. Villagers love them.")
	_res("arcane_dust", "Arcane Dust", "#c48aff", 3, "", "Shimmering residue of salvaged magic. Used to empower artifacts.")
	_res("prism_shard", "Prism Fragment", "#ffffff", 50, "", "A sliver of the Prism of Ages. Used for legendary upgrades.")
	_res("bone", "Bone", "#e8e2cf", 2, "", "Dropped by the restless dead.")
	_res("ichor", "Rotten Ichor", "#6b7a3a", 1, "", "Foul, but alchemists pay for it.")
	_res("silk", "Spider Silk", "#f0f0f0", 2, "", "Strong as wire, light as breath.")
	_res("blastpowder", "Blastpowder", "#5a5a5a", 3, "", "Volatile grey dust from Creeplings.")
	_res("slime_gel", "Slime Gel", "#7ad65a", 2, "", "Sticky and oddly warm.")
	_res("rift_pearl", "Rift Pearl", "#2a8a7a", 8, "", "A pearl that remembers where it has been.")
	_res("timber", "Oak Timber", "#9c7a4a", 1, "verdant", "Sturdy wood from the Verdant forests.")
	_res("stone", "Cobblestone", "#8a8a8a", 1, "verdant", "Common stone, good for walls and wards.")
	_res("iron_ore", "Iron Ore", "#d8b49a", 4, "verdant", "Smelted by blacksmiths into upgrades.")
	_res("gold_ore", "Gold Ore", "#ffd84a", 7, "verdant", "Gleaming ore prized by enchanters.")
	_res("silverleaf", "Silverleaf Herb", "#bfe8c0", 3, "verdant", "A healing herb. Brewed into potions.")
	_res("ashwood", "Ashwood", "#5a4a44", 3, "ember", "Wood that never stops smoldering.")
	_res("basalt", "Basalt", "#3a3a40", 3, "ember", "Dense volcanic stone.")
	_res("cinder_ore", "Cinder Ore", "#ff7a2a", 9, "ember", "Ore veined with living fire.")
	_res("soul_gem", "Soul Gem", "#46d6ff", 14, "ember", "A trapped spark of a lost soul.")
	_res("quartz", "Ember Quartz", "#f2e6dc", 6, "ember", "Crystal that hums near heat.")
	_res("frostpine_log", "Frostpine Log", "#6b5a48", 5, "frost", "Wood that stays cold even in fire.")
	_res("packed_ice", "Packed Ice", "#9cc8f0", 5, "frost", "Ice so old it is blue.")
	_res("frost_crystal", "Frost Crystal", "#bff0ff", 14, "frost", "A shard of frozen time.")
	_res("mithril_ore", "Mithril Ore", "#cfe0ff", 20, "frost", "Light, unbreakable, rare.")
	_res("snowbloom", "Snowbloom", "#ffffff", 9, "frost", "A flower that blooms only in blizzards.")
	_res("shroom_cap", "Shroom Cap", "#c23b5a", 7, "spore", "Edible. Probably.")
	_res("glowspore", "Glowspore", "#9cff6a", 12, "spore", "Spores that store light.")
	_res("myco_fiber", "Myco Fiber", "#d8c9b0", 8, "spore", "Fungal thread stronger than silk.")
	_res("bioluminite", "Bioluminite", "#5ff3ff", 22, "spore", "Living crystal, faintly breathing.")
	_res("rot_amber", "Rot Amber", "#d68a2a", 16, "spore", "Hardened sap with something inside.")
	_res("void_shard", "Void Shard", "#5a2a8a", 18, "void", "A piece of nothing, made solid.")
	_res("chorus_fruit", "Chorus Fruit", "#b38cff", 12, "void", "Tastes like falling.")
	_res("obsidian", "Obsidian", "#1e162a", 14, "void", "Volcanic glass from a realm with no volcanoes.")
	_res("star_fragment", "Star Fragment", "#ffe58a", 30, "void", "Still warm from the sky.")
	_res("echo_crystal", "Echo Crystal", "#2ae0c0", 26, "void", "Whisper into it and it whispers back.")


# ---------------------------------------------------------------- enemies

func _enemy(id: String, name: String, dimid: String, model: String, ai: String, hp: float, dmg: float, spd: float, xp: int,
		c1: String, c2: String, c3: String, scale: float, drops: Array, desc: String, extra := {}) -> void:
	var e := {
		"id": id, "name": name, "dim": dimid, "model": model, "ai": ai, "hp": hp, "dmg": dmg, "speed": spd, "xp": xp,
		"c1": Color(c1), "c2": Color(c2), "c3": Color(c3), "scale": scale, "drops": drops, "desc": desc,
		"range": 1.6, "atk_cd": 1.4,
	}
	match ai:
		"ranged": e["range"] = 11.0; e["atk_cd"] = 2.0
		"caster": e["range"] = 10.0; e["atk_cd"] = 2.8
		"summoner": e["range"] = 9.0; e["atk_cd"] = 6.0
		"exploder": e["range"] = 2.2; e["atk_cd"] = 1.0
		"charger": e["range"] = 9.0; e["atk_cd"] = 3.5
		"teleporter": e["range"] = 1.8; e["atk_cd"] = 1.2
		"turret": e["range"] = 13.0; e["atk_cd"] = 2.4
	e.merge(extra, true)
	enemies[id] = e


func _build_enemies() -> void:
	# Verdant Reach
	_enemy("shambler", "Shambler", "verdant", "humanoid", "melee", 40, 7, 2.6, 12, "#3f7a4a", "#5aa35f", "#1a1a1a", 1.0, [["ichor", 0.6, 1, 2]], "Restless dead raised by Malgrath's whisper. Slow, but they never stop.")
	_enemy("bone_archer", "Bone Archer", "verdant", "humanoid", "ranged", 32, 6, 3.0, 15, "#d8d4c4", "#e8e4d4", "#222222", 1.0, [["bone", 0.7, 1, 3]], "Skeletal marksmen who remember only the bow.", {"proj_color": Color("#e8e2cf")})
	_enemy("creepling", "Creepling", "verdant", "creeper", "exploder", 28, 22, 3.4, 18, "#4cae4c", "#2f7a2f", "#111111", 1.0, [["blastpowder", 0.8, 1, 2]], "Silent green menaces that hiss once before they burst.")
	_enemy("web_lurker", "Web Lurker", "verdant", "spider", "melee", 34, 6, 4.4, 14, "#3a3030", "#4a3c3c", "#ff2a2a", 1.0, [["silk", 0.7, 1, 2]], "Fast, eight-eyed hunters of the birchwood canopy.")
	_enemy("vindicator", "Vindicator", "verdant", "humanoid", "melee", 60, 11, 3.2, 22, "#4a4a5a", "#9a9a8a", "#2a2a3a", 1.05, [["emerald", 0.6, 1, 4]], "Axe-wielding illager raiders who serve the Hexers.", {"weapon": "axe"})
	_enemy("hex_evoker", "Hex Evoker", "verdant", "humanoid", "summoner", 50, 8, 2.8, 30, "#2a2a4a", "#9a9a8a", "#c9a227", 1.0, [["emerald", 0.8, 2, 5], ["arcane_dust", 0.3, 1, 1]], "Robed illager mages who conjure Vexlings from thin air.", {"summon": "vexling"})
	_enemy("bog_witch", "Bog Witch", "verdant", "humanoid", "caster", 46, 9, 2.6, 26, "#4a2a5a", "#7aa36a", "#7a3aa3", 1.0, [["silverleaf", 0.6, 1, 2], ["ichor", 0.5, 1, 2]], "Hurls bubbling flasks of poison from the swamp.", {"proj_color": Color("#9a4ad6"), "effect": "poison", "hat": true})
	_enemy("rampager_boar", "Rampager Boar", "verdant", "quad", "charger", 70, 13, 3.0, 24, "#8a5a3a", "#6a4a2a", "#f0e0c0", 1.2, [["timber", 0.4, 1, 3]], "A tusked beast that charges anything that moves.")
	_enemy("vexling", "Vexling", "verdant", "flyer", "melee", 14, 5, 5.0, 4, "#a8b8c8", "#c8d8e8", "#ff4a4a", 0.6, [], "Tiny winged spirits summoned by Evokers.")
	# Ashen Underrealm
	_enemy("ember_imp", "Ember Imp", "ember", "humanoid", "melee", 40, 9, 4.2, 20, "#a33a1a", "#d65a2a", "#ffd84a", 0.75, [["cinder_ore", 0.3, 1, 1]], "Cackling fire-sprites that swarm in packs.")
	_enemy("magma_cube", "Magma Cube", "ember", "slime", "melee", 70, 12, 2.8, 26, "#5a1a0a", "#ff6a1a", "#ffd84a", 1.2, [["slime_gel", 0.6, 1, 2], ["cinder_ore", 0.3, 1, 1]], "Bouncing cubes of molten rock.", {"glow": 1.2})
	_enemy("blaze_wisp", "Blaze Wisp", "ember", "flyer", "ranged", 44, 10, 3.2, 28, "#ffb52e", "#ff7a1a", "#2a1a0a", 1.0, [["quartz", 0.5, 1, 2]], "Spinning wisps that rain fireballs.", {"proj_color": Color("#ff7a1a"), "effect": "burn", "glow": 2.0})
	_enemy("tuskguard", "Tuskguard Brute", "ember", "humanoid", "melee", 110, 16, 3.0, 34, "#c98a7a", "#b07060", "#c9a227", 1.25, [["emerald", 0.8, 2, 6], ["gold_ore", 0.3, 1, 2]], "Golden-armored hog-men, sworn to the Warlord.", {"weapon": "axe"})
	_enemy("charred_revenant", "Charred Revenant", "ember", "humanoid", "melee", 90, 15, 3.4, 30, "#2a2a2a", "#3a3a3a", "#ff4a1a", 1.15, [["bone", 0.7, 2, 3], ["basalt", 0.4, 1, 2]], "Blackened skeletons with blades of cooling slag.", {"weapon": "sword", "effect": "burn"})
	_enemy("soul_wraith", "Soul Wraith", "ember", "wraith", "teleporter", 60, 13, 3.6, 32, "#2a6a8a", "#46d6ff", "#ffffff", 1.0, [["soul_gem", 0.35, 1, 1]], "Lost souls that blink through the ash to strike.", {"glow": 1.5})
	_enemy("cinderhog", "Cinderhog", "ember", "quad", "charger", 120, 18, 3.2, 36, "#8a3a2a", "#5a2a1a", "#ff8a2a", 1.35, [["ashwood", 0.5, 1, 3]], "Smoldering beasts with flaming tusks.")
	_enemy("ash_golem", "Ash Golem", "ember", "golem", "melee", 180, 22, 2.2, 45, "#4a4440", "#5a524c", "#ff6a1a", 1.4, [["basalt", 0.8, 2, 4]], "Ancient guardians of the dead empire, still on patrol.")
	# Frostfall Wastes
	_enemy("stray_ranger", "Stray Ranger", "frost", "humanoid", "ranged", 70, 14, 3.2, 34, "#8aa0a8", "#b8ccd4", "#1a2a3a", 1.0, [["bone", 0.6, 1, 3], ["frost_crystal", 0.15, 1, 1]], "Frozen archers whose arrows slow the blood.", {"proj_color": Color("#bff0ff"), "effect": "freeze"})
	_enemy("frost_wolf", "Frost Wolf", "frost", "quad", "melee", 80, 14, 5.0, 32, "#e0e8f0", "#c0ccd8", "#4ad6ff", 0.95, [["snowbloom", 0.2, 1, 1]], "Packs of white wolves that circle before they bite.")
	_enemy("ice_golem", "Ice Golem", "frost", "golem", "melee", 220, 26, 2.2, 55, "#9cc8f0", "#bfe0ff", "#2a6aa3", 1.4, [["packed_ice", 0.8, 2, 4]], "Living glaciers. Their punches freeze the ground.", {"effect": "freeze"})
	_enemy("yeti", "Yeti", "frost", "golem", "charger", 200, 24, 3.2, 52, "#f0f0f0", "#d8d8d8", "#5a8aa8", 1.35, [["frostpine_log", 0.5, 2, 3]], "Shaggy giants that hurl themselves down slopes.")
	_enemy("frost_wraith", "Frost Wraith", "frost", "wraith", "caster", 90, 16, 3.0, 44, "#6a9ad6", "#bff0ff", "#ffffff", 1.0, [["frost_crystal", 0.35, 1, 1]], "Howling spirits of the first winter.", {"proj_color": Color("#9ce0ff"), "effect": "freeze", "glow": 1.0})
	_enemy("snow_imp", "Snow Imp", "frost", "humanoid", "exploder", 60, 34, 4.2, 30, "#e8f4ff", "#9cc8f0", "#2a4a8a", 0.75, [["packed_ice", 0.5, 1, 2]], "Giggling imps packed with frozen powder.")
	_enemy("iceclaw_spider", "Iceclaw Spider", "frost", "spider", "melee", 85, 15, 4.6, 36, "#9cc8f0", "#d0ecff", "#2a6aff", 1.1, [["silk", 0.7, 1, 3]], "Crystal-backed spiders hiding in ice caves.")
	_enemy("frozen_revenant", "Frozen Revenant", "frost", "humanoid", "melee", 130, 20, 3.0, 46, "#5a7a9a", "#8ab0d0", "#bff0ff", 1.15, [["mithril_ore", 0.2, 1, 1], ["bone", 0.5, 1, 2]], "Soldiers of a kingdom buried in the ice.", {"weapon": "sword", "effect": "freeze"})
	# Sporelight Hollows
	_enemy("sporeling", "Sporeling", "spore", "slime", "melee", 100, 18, 3.4, 40, "#9cff6a", "#6ac24a", "#2a3a1a", 1.0, [["slime_gel", 0.6, 1, 3], ["glowspore", 0.3, 1, 1]], "Bouncing gelatinous spore-sacks.", {"glow": 0.8})
	_enemy("fungal_shambler", "Fungal Shambler", "spore", "humanoid", "melee", 150, 22, 2.8, 46, "#7a6a8a", "#c23b5a", "#f0e0c0", 1.05, [["shroom_cap", 0.6, 1, 2]], "Bodies overtaken by the bloom. Mushrooms sprout from their heads.", {"hat": true})
	_enemy("mooshroom_brute", "Mooshroom Brute", "spore", "quad", "charger", 230, 30, 3.0, 60, "#c23b5a", "#f0e0d0", "#2a2a2a", 1.4, [["shroom_cap", 0.8, 2, 4]], "Fungal cattle the size of a cart.")
	_enemy("glowmoth", "Glowmoth", "spore", "flyer", "ranged", 90, 18, 3.8, 48, "#5ff3ff", "#2a8aa8", "#ffffff", 1.1, [["bioluminite", 0.15, 1, 1], ["glowspore", 0.4, 1, 2]], "Moths of living light that shoot searing dust.", {"proj_color": Color("#5ff3ff"), "glow": 1.5})
	_enemy("spore_caster", "Spore Caster", "spore", "humanoid", "caster", 120, 20, 2.8, 54, "#4a3a5a", "#9cff6a", "#c23b5a", 1.0, [["myco_fiber", 0.5, 1, 2], ["arcane_dust", 0.3, 1, 1]], "Myconid druids who lob clouds of choking spores.", {"proj_color": Color("#9cff6a"), "effect": "poison", "hat": true})
	_enemy("rotvine_lurker", "Rotvine Lurker", "spore", "spider", "melee", 140, 22, 4.6, 50, "#4a6a3a", "#6a8a3a", "#d68a2a", 1.15, [["rot_amber", 0.15, 1, 1], ["silk", 0.4, 1, 2]], "Vine-wrapped crawlers that leave rot behind.", {"effect": "poison"})
	_enemy("myconid_archer", "Myconid Archer", "spore", "humanoid", "ranged", 110, 20, 3.2, 50, "#d8c9b0", "#c23b5a", "#2a2a2a", 0.95, [["myco_fiber", 0.5, 1, 2]], "Mushroom-folk marksmen with spore-tipped bolts.", {"proj_color": Color("#c23b5a"), "hat": true})
	_enemy("puffcap_bomber", "Puffcap Bomber", "spore", "creeper", "exploder", 90, 48, 3.8, 44, "#c23b5a", "#f0e0d0", "#2a2a2a", 1.0, [["glowspore", 0.5, 1, 2]], "Waddling puffballs that burst into toxic clouds.", {"effect": "poison"})
	# Hollow Void
	_enemy("enderling", "Enderling", "void", "humanoid", "teleporter", 160, 28, 4.0, 60, "#141018", "#1a141f", "#d07aff", 1.35, [["rift_pearl", 0.4, 1, 1]], "Tall, thin wanderers. Don't stare at them.", {"thin": true})
	_enemy("void_shulker", "Void Shulker", "void", "golem", "turret", 180, 24, 0.0, 62, "#8a5aa8", "#b38cff", "#ffffff", 1.0, [["void_shard", 0.4, 1, 2]], "Shell-turrets that fire homing orbs.", {"proj_color": Color("#e0c0ff"), "homing": true})
	_enemy("voidstalker", "Voidstalker", "void", "quad", "melee", 190, 32, 5.2, 64, "#1a1028", "#2a1a3a", "#d07aff", 1.1, [["obsidian", 0.4, 1, 2]], "Panther-shaped shadows that hunt in silence.")
	_enemy("null_sentry", "Null Sentry", "void", "golem", "melee", 320, 40, 2.4, 80, "#2a1f3a", "#3a2f4a", "#ff4aff", 1.5, [["obsidian", 0.8, 2, 4], ["void_shard", 0.3, 1, 1]], "Obsidian constructs guarding Malgrath's paths.")
	_enemy("star_wisp", "Star Wisp", "void", "flyer", "caster", 150, 30, 3.6, 70, "#ffe58a", "#fff4c0", "#ffffff", 1.0, [["star_fragment", 0.15, 1, 1]], "Fallen starlight given hateful purpose.", {"proj_color": Color("#ffe58a"), "glow": 2.0})
	_enemy("rift_spawn", "Rift Spawn", "void", "wraith", "summoner", 170, 26, 2.8, 76, "#3a1a5a", "#7a3aa3", "#2ae0c0", 1.1, [["echo_crystal", 0.2, 1, 1]], "Tears in reality that pour out lesser horrors.", {"summon": "void_mite", "glow": 1.0})
	_enemy("gloom_crawler", "Gloom Crawler", "void", "spider", "melee", 180, 30, 4.8, 66, "#1e162a", "#2a1f3a", "#2ae0c0", 1.2, [["silk", 0.5, 2, 3], ["chorus_fruit", 0.3, 1, 2]], "Spiders that weave webs between islands.")
	_enemy("phantom", "Phantom", "void", "flyer", "charger", 160, 32, 4.0, 70, "#3a4a8a", "#5a6ab8", "#7aff7a", 1.3, [["rift_pearl", 0.2, 1, 1]], "Gliding nightmares that dive from above.")
	_enemy("spirit_wolf", "Spirit Wolf", "", "quad", "melee", 60, 10, 6.0, 0, "#cfe8ff", "#9cc8f0", "#4ad6ff", 0.9, [], "A loyal wolf of light.", {"glow": 0.6})
	_enemy("iron_golem", "Iron Golem", "", "golem", "melee", 200, 22, 3.6, 0, "#b0b8c0", "#9aa0a8", "#ff6a4a", 1.2, [], "A sturdy guardian of iron.")
	_enemy("void_mite", "Void Mite", "void", "spider", "melee", 40, 14, 5.0, 8, "#5a2a8a", "#7a3aa3", "#2ae0c0", 0.5, [], "Skittering motes of hunger.")


# ---------------------------------------------------------------- bosses

func _boss(id: String, name: String, title: String, dimid: String, idx: int, model: String, hp: float, dmg: float, spd: float,
		c1: String, c2: String, c3: String, scale: float, attacks: Array, minions: String, intro: String, lore: String) -> void:
	bosses[id] = {
		"id": id, "name": name, "title": title, "dim": dimid, "index": idx, "model": model, "hp": hp, "dmg": dmg, "speed": spd,
		"c1": Color(c1), "c2": Color(c2), "c3": Color(c3), "scale": scale, "attacks": attacks, "minions": minions,
		"intro": intro, "lore": lore, "xp": int(hp * 0.6), "ai": "boss", "range": 3.0, "atk_cd": 1.6,
	}


func _build_bosses() -> void:
	_boss("gorehorn", "Gorehorn", "the Rampager", "verdant", 0, "quad", 900, 16, 3.4, "#7a4a2a", "#5a3a1a", "#ff3a2a", 3.0,
		["charge", "slam", "charge", "summon"], "rampager_boar",
		"The earth trembles. Something enormous snorts in the brush...",
		"Once the gentle king of the Verdant boars, Gorehorn swallowed a splinter of the Shard of Growth and grew without end.")
	_boss("velkar", "Velkar", "the Arch-Hexer", "verdant", 1, "humanoid", 1100, 18, 2.8, "#2a1a4a", "#9a9a8a", "#c9a227", 2.2,
		["summon", "nova", "teleport", "volley", "meteor"], "vexling",
		"\"The Hollow Crown promised us everything. You will not take it away!\"",
		"Velkar led the Illager clans into Malgrath's service in exchange for the secret of undying magic. He received only half of it.")
	_boss("mire_matriarch", "The Mire Matriarch", "Mother of the Swamp", "verdant", 2, "slime", 1300, 20, 2.4, "#3a5a2a", "#7aa36a", "#9a4ad6", 3.4,
		["poison_pool", "slam", "summon", "volley"], "bog_witch",
		"The swamp water bubbles and rises into a towering, giggling shape.",
		"The first bog witch drank the swamp itself to gain the Shard's power. Now she is the swamp.")
	_boss("stone_colossus", "The Stone Colossus", "Keeper of the Shard of Growth", "verdant", 3, "golem", 1800, 26, 2.2, "#7d7d7d", "#5a7a4a", "#5fff7a", 4.0,
		["slam", "meteor", "nova", "charge", "slam"], "shambler",
		"The mountain stands up. Moss falls from its shoulders like rain.",
		"Carved by the first Wayfinders to guard the Verdant Gate, the Colossus was turned when the Shard of Growth lodged in its heart.")
	_boss("grimtusk", "Grimtusk", "the Ash Warlord", "ember", 0, "humanoid", 2600, 30, 3.0, "#c98a7a", "#c9a227", "#ff3a2a", 2.6,
		["charge", "slam", "summon", "volley"], "tuskguard",
		"\"Another little Wayfinder! My tuskguard will feast tonight!\"",
		"Grimtusk conquered the ruins of the Ember Empire and crowned himself in its melted gold.")
	_boss("pyrrhia", "Pyrrhia", "the Flamewing", "ember", 1, "flyer", 2900, 32, 3.6, "#ff7a1a", "#ffb52e", "#fff4c0", 3.2,
		["volley", "meteor", "nova", "charge"], "blaze_wisp",
		"A shriek splits the smoke. Wings of living fire blot out the sky.",
		"The last phoenix of the Underrealm, bound in endless rebirth by the Shard of Flame. Each death makes her angrier.")
	_boss("infernax", "Infernax", "the Molten King", "ember", 2, "golem", 3300, 36, 2.4, "#3a1a0a", "#ff5a1a", "#ffd84a", 4.2,
		["meteor", "slam", "poison_pool", "nova", "summon"], "magma_cube",
		"The lava lake heaves. A crowned titan of magma rises from its throne.",
		"The Ember Emperor who sought immortality in the volcano's heart. He found it.")
	_boss("soulforged_sentinel", "The Soulforged Sentinel", "Keeper of the Shard of Flame", "ember", 3, "golem", 3900, 40, 2.6, "#2a3a4a", "#46d6ff", "#ffffff", 4.2,
		["nova", "teleport", "volley", "slam", "meteor"], "soul_wraith",
		"A thousand trapped souls scream in harmony as the Sentinel awakens.",
		"Forged from the souls of the Ember Empire to guard its treasures, the Sentinel now guards the Shard of Flame for Malgrath.")
	_boss("rimefang", "Rimefang", "Alpha of the Endless Winter", "frost", 0, "quad", 4800, 44, 4.4, "#f0f4f8", "#bfe0ff", "#2a8aff", 2.8,
		["charge", "summon", "charge", "nova"], "frost_wolf",
		"A howl answers your footsteps. Then another. Then hundreds.",
		"The great wolf who once guided lost travelers home. The Shard's cold made her forget the way.")
	_boss("glaciara", "Glaciara", "the Ice Witch Queen", "frost", 1, "humanoid", 5200, 46, 3.0, "#6a9ad6", "#e8f4ff", "#bff0ff", 2.4,
		["volley", "nova", "teleport", "meteor", "summon"], "frost_wraith",
		"\"Stay, little Wayfinder. Stay forever. Be still. Be still.\"",
		"A queen who froze her kingdom so that no one she loved would ever age. She calls it mercy.")
	_boss("avalanche_titan", "The Avalanche Titan", "Wrath of the Peaks", "frost", 2, "golem", 5800, 52, 2.4, "#d8e4f0", "#9cc8f0", "#2a4a8a", 4.4,
		["slam", "meteor", "charge", "slam", "summon"], "ice_golem",
		"The mountainside cracks and comes down. Then it stands up.",
		"Every avalanche that ever fell on Frostfall gathered into one furious body.")
	_boss("frostheart_wyrm", "The Frostheart Wyrm", "Keeper of the Shard of Stillness", "frost", 3, "wyrm", 6600, 58, 3.4, "#4a8ab8", "#bff0ff", "#ffffff", 3.6,
		["volley", "nova", "charge", "meteor", "slam"], "stray_ranger",
		"Ice explodes upward. A crystalline dragon coils into the sky.",
		"The ancient wyrm swallowed the Shard of Stillness and froze time around its lair.")
	_boss("rot_mother", "The Rot Mother", "Queen of Decay", "spore", 0, "slime", 7600, 62, 2.6, "#4a6a3a", "#d68a2a", "#9cff6a", 3.8,
		["poison_pool", "summon", "slam", "volley"], "sporeling",
		"Everything in the glade begins to wilt at once. The Rot Mother has woken.",
		"Mother of all decay, she ensures nothing in the Hollows dies without feeding something else.")
	_boss("queen_lumina", "Queen Lumina", "of the Glowmoths", "spore", 1, "flyer", 8200, 66, 3.8, "#5ff3ff", "#ffffff", "#ff7aff", 3.4,
		["volley", "nova", "teleport", "meteor", "summon"], "glowmoth",
		"The darkness shimmers. A moth the size of a house unfurls wings of light.",
		"Lumina was a lantern-keeper who loved the light too much. The Shard of Life gave her wings.")
	_boss("myco_colossus", "The Myco Colossus", "Walking Forest", "spore", 2, "golem", 9000, 72, 2.4, "#6a5a7a", "#c23b5a", "#9cff6a", 4.6,
		["slam", "poison_pool", "meteor", "summon", "charge"], "fungal_shambler",
		"The giant mushrooms aren't trees. They're the shoulders of something.",
		"An entire forest bound into one body by the mycelium that connects every root.")
	_boss("overgrowth_heart", "The Overgrowth Heart", "Keeper of the Shard of Life", "spore", 3, "heart", 10200, 78, 0.0, "#c23b5a", "#9cff6a", "#ffffff", 4.0,
		["nova", "summon", "poison_pool", "volley", "meteor"], "rotvine_lurker",
		"A massive heartbeat shakes the Hollows. The Overgrowth Heart opens its eye.",
		"The Shard of Life took root here and grew a heart of its own. It beats for Malgrath now.")
	_boss("warden_echoes", "The Warden of Echoes", "Blind Guardian", "void", 0, "golem", 12000, 84, 3.0, "#0a2a2a", "#1a4a4a", "#2ae0c0", 3.6,
		["slam", "charge", "nova", "slam", "summon"], "gloom_crawler",
		"Silence. Then a heartbeat that isn't yours. Don't make a sound.",
		"The Warden cannot see. It hunts by the echoes of footsteps, and it has heard you coming for a long time.")
	_boss("nihila", "Nihila", "the Starless", "void", 1, "wraith", 13000, 90, 3.2, "#05020c", "#5a2a8a", "#ffe58a", 3.0,
		["teleport", "volley", "meteor", "nova", "summon"], "star_wisp",
		"\"I ate the stars, one by one. You are only a little light.\"",
		"Nihila devoured the night sky of the Void to grow strong enough to serve as Malgrath's herald.")
	_boss("phantom_monarch", "The Phantom Monarch", "Lord of Nightmares", "void", 2, "flyer", 14500, 96, 4.2, "#2a3a7a", "#5a6ab8", "#7aff7a", 3.8,
		["charge", "volley", "summon", "meteor", "charge"], "phantom",
		"The sky fills with circling shapes. The largest one screams and dives.",
		"Born from every sleepless night in the five realms, it rules all dreams that never ended.")
	_boss("malgrath", "Malgrath", "the Hollow Crown", "void", 3, "humanoid", 18000, 110, 3.4, "#1a0a2a", "#c9a227", "#d07aff", 3.0,
		["teleport", "meteor", "nova", "summon", "volley", "slam", "charge"], "enderling",
		"\"Wayfinder. I was the first of you. I held the Prism and I saw everything. Kneel, and I will show you too.\"",
		"Malric, first Wayfinder, tried to wield the whole Prism of Ages and was hollowed out by it. Only the crown remained.")


# ---------------------------------------------------------------- items

func _item(id: String, kind: String, name: String, data: Dictionary) -> void:
	var it := {"id": id, "kind": kind, "name": name}
	it.merge(data, true)
	items[id] = it


func _melee(id: String, name: String, sub: String, dmg: float, spd: float, rng: float, arc: float, color: String, accent: String, desc: String, extra := {}) -> void:
	var d := {"sub": sub, "dmg": dmg, "speed": spd, "range": rng, "arc": arc, "color": Color(color), "accent": Color(accent), "desc": desc, "min_level": 1}
	d.merge(extra, true)
	_item(id, "melee", name, d)


func _build_weapons() -> void:
	_melee("wooden_sword", "Wooden Sword", "sword", 9, 0.45, 2.4, 100, "#9c7a4a", "#6b4a2b", "Every legend starts somewhere.")
	_melee("iron_sword", "Iron Sword", "sword", 13, 0.45, 2.5, 100, "#d8d8d8", "#6b4a2b", "A dependable blade.")
	_melee("broadsword", "Broadsword", "sword", 22, 0.75, 2.9, 130, "#c0c8d0", "#c9a227", "Heavy, wide sweeps that hit everything nearby.")
	_melee("hawkbrand", "Hawkbrand", "sword", 15, 0.4, 2.6, 100, "#e8e8f0", "#4fa8ff", "Strikes with uncanny precision.", {"crit": 0.15})
	_melee("diamond_sword", "Diamond Sword", "sword", 20, 0.45, 2.6, 110, "#5ff3e0", "#2a6a6a", "The classic. Sharp, bright and fearless.")
	_melee("battle_axe", "Battle Axe", "axe", 24, 0.8, 2.6, 140, "#9a9a9a", "#6b4a2b", "Slow, punishing chops.")
	_melee("firebrand", "Firebrand", "axe", 22, 0.7, 2.6, 130, "#ff7a2a", "#3a1a0a", "Sets foes ablaze.", {"effect": "burn"})
	_melee("highland_axe", "Highland Axe", "axe", 28, 0.85, 2.8, 150, "#8a8a8a", "#2a5a2a", "Cleaves through crowds.")
	_melee("great_hammer", "Great Hammer", "hammer", 32, 1.0, 2.4, 160, "#7a7a7a", "#4a3a2a", "Each blow sends enemies flying.", {"knockback": 2.0})
	_melee("stormlander", "Stormlander", "hammer", 34, 1.0, 2.5, 160, "#4a6aa8", "#ffe58a", "Calls lightning on the third strike.", {"effect": "shock", "knockback": 1.6})
	_melee("dagger", "Twin Daggers", "dagger", 7, 0.22, 1.9, 80, "#c0c0c0", "#2a2a2a", "Lightning-fast stabs.")
	_melee("fang_of_frost", "Fang of Frost", "dagger", 9, 0.24, 2.0, 80, "#bff0ff", "#4a8ab8", "Freezes enemies with every cut.", {"effect": "freeze"})
	_melee("moon_dagger", "Moon Daggers", "dagger", 10, 0.22, 2.0, 80, "#e0d8ff", "#7a3aa3", "Artifacts recharge faster with each hit.", {"cdr_on_hit": 0.08})
	_melee("spear", "Spear", "spear", 15, 0.55, 3.6, 50, "#9c7a4a", "#c0c0c0", "Long reach, narrow thrusts.")
	_melee("whispering_spear", "Whispering Spear", "spear", 20, 0.55, 3.8, 50, "#5a8a6a", "#bfe8c0", "Pierces through multiple enemies.", {"crit": 0.1})
	_melee("glaive", "Glaive", "glaive", 22, 0.7, 3.4, 120, "#8a6a4a", "#d0d0d0", "Sweeping polearm strikes.")
	_melee("venom_glaive", "Venom Glaive", "glaive", 24, 0.7, 3.4, 120, "#4a6a3a", "#9cff6a", "Coated in toxic sap.", {"effect": "poison"})
	_melee("scythe", "Jailor's Scythe", "scythe", 26, 0.65, 3.0, 200, "#3a3a4a", "#c0c0c0", "Reaps in a full circle.")
	_melee("soul_scythe", "Soul Scythe", "scythe", 30, 0.65, 3.0, 200, "#2a6a8a", "#46d6ff", "Steals life with every reap.", {"lifesteal": 0.05})
	_melee("gauntlets", "Fighter's Gauntlets", "gauntlets", 8, 0.2, 1.8, 70, "#8a6a4a", "#c0c0c0", "A flurry of punches.")
	_melee("magma_gauntlets", "Magma Gauntlets", "gauntlets", 11, 0.22, 1.8, 70, "#ff5a1a", "#3a1a0a", "Burning knuckles.", {"effect": "burn"})
	_melee("katana", "Katana", "sword", 17, 0.35, 2.7, 100, "#f0f0f0", "#2a2a2a", "Swift and elegant.", {"crit": 0.1})
	_melee("dark_katana", "Dark Katana", "sword", 21, 0.35, 2.8, 100, "#2a1a3a", "#d07aff", "Deals bonus damage to the undead.", {"crit": 0.15})
	_melee("void_blade", "Voidcleaver", "sword", 30, 0.5, 3.0, 130, "#1a0a2a", "#d07aff", "A blade cut from the edge of the world.", {"lifesteal": 0.04, "crit": 0.1})
	_melee("prism_sword", "Prismblade", "sword", 36, 0.45, 3.0, 140, "#ffffff", "#ffb52e", "Forged from Prism fragments. Hums with every realm's power.", {"crit": 0.2, "lifesteal": 0.05})


func _ranged(id: String, name: String, sub: String, dmg: float, spd: float, pspeed: float, multishot: int, pierce: int, color: String, desc: String, extra := {}) -> void:
	var d := {"sub": sub, "dmg": dmg, "speed": spd, "proj_speed": pspeed, "multishot": multishot, "pierce": pierce, "color": Color(color), "desc": desc}
	d.merge(extra, true)
	_item(id, "ranged", name, d)


func _build_ranged() -> void:
	_ranged("bow", "Bow", "bow", 10, 0.7, 26, 1, 0, "#9c7a4a", "A simple bow.")
	_ranged("longbow", "Longbow", "bow", 16, 1.0, 34, 1, 1, "#7a5a3a", "Long range, piercing shots.")
	_ranged("power_bow", "Power Bow", "bow", 22, 1.1, 30, 1, 0, "#c0c0c0", "Heavy hitting arrows.", {"knockback": 1.5})
	_ranged("twin_bow", "Twin Bow", "bow", 9, 0.7, 26, 2, 0, "#c9a227", "Fires two arrows at once.")
	_ranged("hunting_bow", "Hunting Bow", "bow", 12, 0.6, 28, 1, 0, "#6a8a4a", "Favored by the woodland rangers.", {"crit": 0.1})
	_ranged("crossbow", "Crossbow", "crossbow", 20, 1.1, 36, 1, 2, "#6b4a2b", "Pierces through foes.")
	_ranged("scatter_crossbow", "Scatter Crossbow", "crossbow", 12, 1.1, 30, 5, 0, "#8a6a4a", "Fires a fan of bolts.")
	_ranged("firebolt_thrower", "Firebolt Thrower", "crossbow", 18, 1.0, 32, 1, 0, "#ff7a2a", "Bolts explode on impact.", {"explode": 2.5})
	_ranged("frost_bow", "Winter's Touch", "bow", 14, 0.75, 28, 1, 0, "#bff0ff", "Arrows freeze their targets.", {"effect": "freeze"})
	_ranged("rot_bow", "Rotbloom Bow", "bow", 15, 0.75, 28, 3, 0, "#9cff6a", "Toxic triple-shot.", {"effect": "poison"})
	_ranged("star_bow", "Starcaller", "bow", 20, 0.65, 38, 3, 1, "#ffe58a", "Shoots shards of falling starlight.", {"glow": 2.0})
	_ranged("void_crossbow", "Echo Repeater", "crossbow", 16, 0.35, 36, 1, 1, "#2ae0c0", "Rapid-fire void bolts.")
	_ranged("harp_crossbow", "Harp Crossbow", "crossbow", 14, 1.2, 32, 7, 0, "#c9a227", "A wide spread of seven bolts.")
	_ranged("prism_bow", "Prism Bow", "bow", 30, 0.7, 40, 3, 2, "#ffffff", "Arrows of pure Prism light.", {"crit": 0.15, "glow": 2.0})


func _armor(id: String, name: String, hp: float, defense: float, color: String, accent: String, desc: String, bonus := {}) -> void:
	_item(id, "armor", name, {"hp": hp, "def": defense, "color": Color(color), "accent": Color(accent), "desc": desc, "bonus": bonus})


func _build_armor() -> void:
	_armor("tunic", "Adventurer's Tunic", 10, 0.04, "#6a8a5a", "#6b4a2b", "Comfortable traveling clothes.")
	_armor("leather", "Hunter's Leather", 20, 0.08, "#8a5a3a", "#5a3a1a", "Boosts ranged damage.", {"ranged_pct": 0.15})
	_armor("scale_mail", "Scale Mail", 30, 0.12, "#8a9aa8", "#c9a227", "Boosts melee damage.", {"melee_pct": 0.1})
	_armor("champion", "Champion's Armor", 40, 0.15, "#c9a227", "#8f3b2b", "Armor of a proven hero.", {"hp_pct": 0.1})
	_armor("mystic_robe", "Mystic Robe", 18, 0.06, "#4a3a8a", "#c48aff", "Artifacts recharge faster.", {"cdr": 0.15})
	_armor("evocation_robe", "Evocation Robe", 22, 0.07, "#2a2a6a", "#c9a227", "Artifact damage increased.", {"artifact_pct": 0.25})
	_armor("plate", "Knight's Plate", 55, 0.2, "#b0b8c0", "#4a5a6a", "Heavy protection. Slows rolls.", {"speed_pct": -0.05})
	_armor("ember_plate", "Ember Plate", 60, 0.18, "#5a2a1a", "#ff7a2a", "Burns nearby enemies.", {"melee_pct": 0.1, "aura_burn": 1})
	_armor("soul_robe", "Soul Robe", 40, 0.1, "#2a4a5a", "#46d6ff", "Kills charge your artifacts.", {"cdr": 0.2, "lifesteal": 0.02})
	_armor("frost_mail", "Frostbound Mail", 70, 0.2, "#9cc8f0", "#e8f4ff", "Chills attackers.", {"hp_pct": 0.1})
	_armor("wolf_pelt", "Wolf Pelt Armor", 55, 0.14, "#e0e8f0", "#7a8a9a", "Swift as the pack.", {"speed_pct": 0.12, "melee_pct": 0.08})
	_armor("myco_armor", "Mycelium Mail", 80, 0.18, "#7a6a8a", "#9cff6a", "Regenerates health slowly.", {"regen": 2.0})
	_armor("glow_robe", "Lumen Robe", 60, 0.12, "#2a8aa8", "#5ff3ff", "Artifacts empowered.", {"artifact_pct": 0.3, "cdr": 0.1})
	_armor("shadow_cloak", "Shadow Cloak", 70, 0.16, "#1a1028", "#d07aff", "Dodge rolls recharge faster.", {"crit": 0.08, "speed_pct": 0.1})
	_armor("obsidian_plate", "Obsidian Plate", 110, 0.26, "#1e162a", "#5a2a8a", "Nearly indestructible.", {"hp_pct": 0.1})
	_armor("star_robe", "Starweave Robe", 85, 0.15, "#3a3360", "#ffe58a", "Woven from fallen starlight.", {"artifact_pct": 0.4, "cdr": 0.15})
	_armor("champion_void", "Voidwalker Armor", 120, 0.24, "#2a1f3a", "#2ae0c0", "Armor of those who walked the edge.", {"melee_pct": 0.15, "ranged_pct": 0.15})
	_armor("prism_armor", "Prismguard", 140, 0.28, "#f0f0ff", "#ffb52e", "Armor forged from all five Shards.", {"hp_pct": 0.15, "melee_pct": 0.15, "artifact_pct": 0.2, "cdr": 0.1})


func _artifact(id: String, name: String, ability: String, cd: float, power: float, color: String, desc: String) -> void:
	_item(id, "artifact", name, {"ability": ability, "cd": cd, "power": power, "color": Color(color), "desc": desc})


func _build_artifacts() -> void:
	_artifact("fire_orb", "Orb of Flame", "fireball", 5.0, 30, "#ff7a2a", "Hurl an exploding fireball that sets enemies ablaze.")
	_artifact("frost_crown", "Frost Crown", "frost_nova", 10.0, 20, "#9ce0ff", "Unleash a nova that freezes all nearby enemies.")
	_artifact("storm_rod", "Rod of Storms", "chain_lightning", 7.0, 26, "#ffe58a", "Lightning leaps between up to five enemies.")
	_artifact("healing_totem", "Totem of Regrowth", "heal_totem", 18.0, 8, "#7aff7a", "Plant a totem that heals you over time.")
	_artifact("blink_pearl", "Blink Pearl", "blink", 6.0, 0, "#2a8a7a", "Teleport instantly toward your aim.")
	_artifact("meteor_staff", "Meteor Staff", "meteor", 14.0, 70, "#ff4a1a", "Call down a meteor on your target.")
	_artifact("soul_lantern", "Soul Lantern", "soul_drain", 9.0, 18, "#46d6ff", "Drain the souls of enemies in front of you, healing yourself.")
	_artifact("wolf_horn", "Horn of the Pack", "summon_wolf", 25.0, 14, "#e0e8f0", "Summon two spirit wolves to fight by your side.")
	_artifact("iron_hide", "Iron Hide Amulet", "iron_hide", 16.0, 0.5, "#b0b8c0", "Become nearly invulnerable for a short time.")
	_artifact("boots_haste", "Boots of Swiftness", "haste", 10.0, 0.6, "#ffffff", "Burst of speed and attack speed.")
	_artifact("arrow_storm", "Quiver of Storms", "arrow_rain", 12.0, 14, "#c9a227", "Rain arrows over a wide area.")
	_artifact("quake_hammer", "Seismic Hammer", "earthquake", 12.0, 34, "#8a6a4a", "Slam the ground, stunning and damaging nearby foes.")
	_artifact("poison_flask", "Corrupted Flask", "poison_cloud", 9.0, 10, "#9cff6a", "Throw a flask that leaves a lingering toxic cloud.")
	_artifact("spirit_blades", "Spirit Blades", "spirit_blades", 15.0, 12, "#c48aff", "Summon blades that orbit you and cut through enemies.")
	_artifact("void_vortex", "Void Vortex", "vortex", 14.0, 16, "#7a3aa3", "Open a vortex that pulls enemies in and crushes them.")
	_artifact("hourglass", "Hourglass of Ages", "time_slow", 20.0, 0.25, "#ffd84a", "Slow time for all nearby enemies.")
	_artifact("void_eye", "Eye of the Void", "void_beam", 10.0, 40, "#d07aff", "Fire a piercing beam of pure nothingness.")
	_artifact("golem_kit", "Golem Kit", "summon_golem", 35.0, 30, "#b0b8c0", "Summon an iron golem guardian.")
	_artifact("flame_dash", "Phoenix Feather", "flame_dash", 7.0, 24, "#ffb52e", "Dash forward in a burst of flame.")
	_artifact("starfall", "Starfall Sigil", "starfall", 18.0, 30, "#ffe58a", "Call a shower of stars all around you.")
	_artifact("lifebloom", "Lifebloom Seed", "lifebloom", 22.0, 0.35, "#ff7aaa", "Instantly heal and gain regeneration.")
	_artifact("thunder_call", "Thunder Bell", "thunder", 8.0, 55, "#bfe0ff", "Strike a single target with a colossal bolt.")


func _acc(id: String, name: String, slot: String, mods: Dictionary, color: String, desc: String) -> void:
	_item(id, "accessory", name, {"slot": slot, "mods": mods, "color": Color(color), "desc": desc})


func _build_accessories() -> void:
	_acc("ring_vigor", "Ring of Vigor", "ring", {"hp": 25}, "#ff6a6a", "+Max health.")
	_acc("ring_might", "Ring of Might", "ring", {"melee_pct": 0.12}, "#ffb52e", "+Melee damage.")
	_acc("ring_hawk", "Hawkeye Ring", "ring", {"ranged_pct": 0.15}, "#6ad66a", "+Ranged damage.")
	_acc("ring_arcana", "Arcanist's Ring", "ring", {"artifact_pct": 0.15}, "#c48aff", "+Artifact damage.")
	_acc("ring_haste", "Ring of Haste", "ring", {"speed_pct": 0.08}, "#ffffff", "+Movement speed.")
	_acc("ring_crit", "Ring of Precision", "ring", {"crit": 0.08}, "#ff4f6d", "+Critical chance.")
	_acc("ring_leech", "Vampire's Ring", "ring", {"lifesteal": 0.03}, "#8a1a2a", "Heal on hit.")
	_acc("ring_time", "Chrono Ring", "ring", {"cdr": 0.1}, "#ffd84a", "Artifacts recharge faster.")
	_acc("ring_fortune", "Ring of Fortune", "ring", {"luck": 0.15}, "#2fd37a", "Better loot.")
	_acc("ring_titan", "Titan's Band", "ring", {"hp": 60, "melee_pct": 0.1}, "#c9a227", "Strength of giants.")
	_acc("amulet_life", "Amulet of Life", "amulet", {"hp": 40, "regen": 1.0}, "#ff7aaa", "Health and regeneration.")
	_acc("amulet_storm", "Storm Amulet", "amulet", {"artifact_pct": 0.2, "cdr": 0.05}, "#ffe58a", "Crackles with power.")
	_acc("amulet_guard", "Guardian's Locket", "amulet", {"armor": 0.08}, "#b0b8c0", "Reduces damage taken.")
	_acc("amulet_wisdom", "Scholar's Pendant", "amulet", {"xp": 0.2}, "#4fa8ff", "+Experience gained.")
	_acc("amulet_fury", "Berserker's Fang", "amulet", {"melee_pct": 0.2, "armor": -0.05}, "#8f3b2b", "More damage, less defense.")
	_acc("amulet_void", "Heart of the Void", "amulet", {"crit": 0.1, "lifesteal": 0.03, "artifact_pct": 0.15}, "#5a2a8a", "Whispers of power.")
	_acc("amulet_prism", "Prism Pendant", "amulet", {"hp": 80, "melee_pct": 0.15, "ranged_pct": 0.15, "artifact_pct": 0.15}, "#ffffff", "A piece of the Prism, set in gold.")
	_acc("charm_clover", "Lucky Clover", "charm", {"luck": 0.25}, "#2fd37a", "Find rarer treasures.")
	_acc("charm_feather", "Feather Charm", "charm", {"speed_pct": 0.12, "roll_cd": 0.3}, "#ffffff", "Roll more often.")
	_acc("charm_potion", "Alchemist's Charm", "charm", {"potion": 0.5}, "#ff6a6a", "Potions heal more.")
	_acc("charm_magnet", "Lodestone Charm", "charm", {"magnet": 6.0}, "#8a8a8a", "Pulls loot from afar.")
	_acc("charm_emerald", "Merchant's Charm", "charm", {"emerald": 0.4}, "#2fd37a", "More emeralds from enemies.")
	_acc("charm_thorns", "Bramble Charm", "charm", {"thorns": 0.35}, "#4a6a3a", "Reflect damage to attackers.")
	_acc("charm_soul", "Soul Charm", "charm", {"cdr": 0.12, "xp": 0.1}, "#46d6ff", "Kills sing to your artifacts.")
	_acc("charm_ember", "Ember Charm", "charm", {"burn_pct": 0.5, "melee_pct": 0.05}, "#ff7a2a", "Fire burns hotter.")
	_acc("charm_frost", "Frost Charm", "charm", {"armor": 0.06, "hp": 30}, "#9ce0ff", "Cold, steady resolve.")


func _ench(id: String, name: String, kind: String, desc: String) -> void:
	enchants[id] = {"id": id, "name": name, "kind": kind, "desc": desc}


func _build_enchants() -> void:
	_ench("sharpness", "Sharpness", "melee", "+12% melee damage per level.")
	_ench("fire_aspect", "Fire Aspect", "melee", "Hits set enemies on fire.")
	_ench("freezing", "Freezing", "melee", "Hits slow enemies.")
	_ench("leeching", "Leeching", "melee", "Heal 2% of damage per level.")
	_ench("critical", "Critical Hit", "melee", "+6% critical chance per level.")
	_ench("chains", "Chains", "melee", "Chance to chain lightning to nearby enemies.")
	_ench("swirling", "Swirling", "melee", "Combo finisher hits all around you.")
	_ench("power", "Power", "ranged", "+15% ranged damage per level.")
	_ench("multishot", "Multishot", "ranged", "+1 arrow per level.")
	_ench("piercing", "Piercing", "ranged", "Arrows pierce +1 enemy per level.")
	_ench("infinity", "Infinity", "ranged", "Faster firing.")
	_ench("explosive", "Explosive", "ranged", "Arrows explode on hit.")
	_ench("protection", "Protection", "armor", "+4% damage reduction per level.")
	_ench("health_boost", "Health Boost", "armor", "+10% max health per level.")
	_ench("cooldown", "Cooldown", "armor", "+8% artifact recharge per level.")
	_ench("swiftness", "Swiftness", "armor", "+5% movement speed per level.")
	_ench("thorns", "Thorns", "armor", "Reflect 20% damage per level.")
	_ench("burning", "Burning", "armor", "Burn nearby enemies.")


func _build_perks() -> void:
	perks = [
		{"id": "second_wind", "name": "Second Wind", "desc": "Once per minute, survive a lethal hit with 30% health.", "req": 5},
		{"id": "vampiric", "name": "Vampiric Strikes", "desc": "Melee hits heal 2% of damage dealt.", "req": 5},
		{"id": "swift_roll", "name": "Swift Roll", "desc": "Dodge roll cooldown reduced by 40%.", "req": 5},
		{"id": "deadeye", "name": "Deadeye", "desc": "Ranged critical hits deal triple damage.", "req": 10},
		{"id": "combo_master", "name": "Combo Master", "desc": "Combo finisher deals +60% damage.", "req": 10},
		{"id": "treasure_hunter", "name": "Treasure Hunter", "desc": "Chests contain an extra item.", "req": 10},
		{"id": "pyromancer", "name": "Pyromancer", "desc": "Burn and fire damage +50%.", "req": 15},
		{"id": "thick_skin", "name": "Thick Skin", "desc": "Take 10% less damage.", "req": 15},
		{"id": "mana_font", "name": "Mana Font", "desc": "Artifacts recharge 15% faster.", "req": 15},
		{"id": "arcane_echo", "name": "Arcane Echo", "desc": "20% chance to cast artifacts twice.", "req": 20},
		{"id": "executioner", "name": "Executioner", "desc": "+50% damage to enemies below 30% health.", "req": 20},
		{"id": "pack_leader", "name": "Pack Leader", "desc": "Summoned allies deal double damage and live longer.", "req": 20},
		{"id": "scavenger", "name": "Scavenger", "desc": "Enemies drop 50% more resources.", "req": 25},
		{"id": "potion_master", "name": "Potion Master", "desc": "Potion cooldown halved.", "req": 25},
		{"id": "berserker", "name": "Berserker", "desc": "Deal up to +40% damage as your health drops.", "req": 30},
		{"id": "wayfinder", "name": "True Wayfinder", "desc": "All stats +10%.", "req": 40},
	]


func _build_powerups() -> void:
	powerups = {
		"rage": {"name": "Rage of the Ancients", "desc": "Double damage", "color": Color("#ff3a2a"), "dur": 15.0},
		"swift": {"name": "Wind Walker", "desc": "+50% speed", "color": Color("#ffffff"), "dur": 20.0},
		"regen": {"name": "Spring of Life", "desc": "Rapid regeneration", "color": Color("#7aff7a"), "dur": 15.0},
		"arcane": {"name": "Arcane Surge", "desc": "Artifacts recharge 4x faster", "color": Color("#c48aff"), "dur": 12.0},
		"golden": {"name": "Golden Touch", "desc": "Triple emeralds", "color": Color("#ffd84a"), "dur": 30.0},
		"giant": {"name": "Giant's Might", "desc": "Grow huge, +50% damage and health", "color": Color("#ffb52e"), "dur": 15.0},
		"ghost": {"name": "Spectral Form", "desc": "Enemies cannot hit you", "color": Color("#9ce0ff"), "dur": 8.0},
	}


func _build_roles() -> void:
	villager_roles = [
		{"id": "elder", "name": "Elder", "robe": Color("#5a3a7a"), "services": ["quests", "lore"]},
		{"id": "blacksmith", "name": "Blacksmith", "robe": Color("#4a3a2a"), "services": ["upgrade", "quests"]},
		{"id": "merchant", "name": "Merchant", "robe": Color("#2a7a4a"), "services": ["trade", "quests"]},
		{"id": "enchanter", "name": "Enchanter", "robe": Color("#3a2a8a"), "services": ["enchant", "quests"]},
		{"id": "mystic", "name": "Mystic", "robe": Color("#7a2a6a"), "services": ["artifact", "quests"]},
		{"id": "farmer", "name": "Farmer", "robe": Color("#8a6a3a"), "services": ["quests"]},
		{"id": "guard", "name": "Guard", "robe": Color("#5a6a7a"), "services": ["quests"]},
		{"id": "cartographer", "name": "Cartographer", "robe": Color("#3a5a8a"), "services": ["quests", "lore"]},
		{"id": "alchemist", "name": "Alchemist", "robe": Color("#2a6a6a"), "services": ["potions", "quests"]},
		{"id": "bard", "name": "Bard", "robe": Color("#8a2a3a"), "services": ["lore", "quests"]},
	]


func role(id: String) -> Dictionary:
	for r in villager_roles:
		if r["id"] == id:
			return r
	return villager_roles[0]


func _build_origins() -> void:
	origins = [
		{"id": "warrior", "name": "Warrior", "desc": "A frontline fighter. Starts with a broadsword, scale mail and the Seismic Hammer.\n+Vitality, +Might",
			"kit": ["broadsword", "bow", "scale_mail", "quake_hammer"], "attr": {"might": 2, "vitality": 2}},
		{"id": "ranger", "name": "Ranger", "desc": "A swift archer. Starts with daggers, a longbow, hunter's leather and the Quiver of Storms.\n+Agility, +Fortune",
			"kit": ["dagger", "longbow", "leather", "arrow_storm"], "attr": {"agility": 3, "fortune": 1}},
		{"id": "mystic", "name": "Mystic", "desc": "A wielder of magic. Starts with a spear, a bow, the mystic robe and the Orb of Flame.\n+Arcana",
			"kit": ["spear", "bow", "mystic_robe", "fire_orb"], "attr": {"arcana": 4}},
	]


## Items of a kind whose tier suits the given realm index (used for loot rolls).
func item_pool(kind: String) -> Array:
	var out: Array = []
	for id in items:
		if items[id]["kind"] == kind:
			out.append(id)
	return out

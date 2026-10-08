## Quest system: the main story chain, generated side quests and endless bounties.
extends Node

signal quests_changed
signal quest_completed(q: Dictionary)
signal story_event(speaker: String, lines: Array)

const MAX_SIDE := 6

var defs := {}
var main_order: Array = []
var side_ids: Array = []
var active := {}
var completed := {}
var bounties := {}
var tracked := ""
var bounty_counter := 0


func _ready() -> void:
	_build_main()
	_build_side()


func total_quests() -> int:
	return main_order.size() + side_ids.size()


# ---------------------------------------------------------------- definitions

func _q(id: String, title: String, dimid: String, type: String, target: String, count: int, desc: String, extra := {}) -> Dictionary:
	var q := {"id": id, "title": title, "dim": dimid, "type": type, "target": target, "count": count, "desc": desc,
		"giver": "story", "main": false, "xp": 0, "emerald": 0, "item": -1, "speaker": "", "story": []}
	q.merge(extra, true)
	defs[id] = q
	return q


func _m(title: String, dimid: String, type: String, target: String, count: int, desc: String, speaker: String, story: Array, extra := {}) -> void:
	var id := "m%02d" % (main_order.size() + 1)
	var tier: int = Data.dim(dimid)["base_level"]
	var e := {"main": true, "speaker": speaker, "story": story, "xp": int(120 * (1 + tier * 0.25) * (1 + main_order.size() * 0.12)),
		"emerald": 40 + main_order.size() * 15, "item": 1 if type == "boss" else 0}
	e.merge(extra, true)
	_q(id, title, dimid, type, target, count, desc, e)
	main_order.append(id)


func _build_main() -> void:
	# Chapter I - The Verdant Reach
	_m("Awakening", "verdant", "talk", "elder", 1, "A strange mark glows on your hand. Speak with the Elder by the Old Oak at the heart of the village.", "The Mark",
		["You wake beneath an enormous oak. Your hand burns with a soft golden light, a mark shaped like a five-pointed prism.", "Villagers whisper as they pass. Someone should be able to explain this. The Elder, perhaps."])
	_m("Monsters at the Gate", "verdant", "kill", "any", 8, "Defeat 8 creatures prowling around the village.", "Elder",
		["\"By the Old Oak... a Wayfinder's mark! I never thought I'd see one again in my lifetime.\"", "\"Listen to me. Since the Prism shattered, monsters have crept closer every night. Show me that mark is more than a pretty light. Drive them back!\""])
	_m("Mending the Walls", "verdant", "gather", "timber", 8, "Gather 8 Oak Timber from fallen trees and supply caches to repair the village walls.", "Guard",
		["\"Not bad, Wayfinder! But they'll be back. The walls are rotten through.\"", "\"Bring me timber. You'll find it in supply crates and wood piles, and the beasts out there carry it sometimes too.\""])
	_m("Steel and Spark", "verdant", "talk", "blacksmith", 1, "Visit the village Blacksmith to learn how to strengthen your gear.", "Guard",
		["\"Good, that'll hold. Now go see the smith. You can't fight Malgrath's army with a butter knife.\""])
	_m("Into the Dark", "verdant", "cave", "", 1, "Find a cave entrance in the wilds and clear it of monsters. Follow your compass arrow.", "Blacksmith",
		["\"Iron! We need iron, and the best ore is underground. Problem is, so are the monsters.\"", "\"Find one of those dark cave mouths and clear it out. Come back richer.\""])
	_m("The Rampager", "verdant", "boss", "gorehorn", 1, "A monstrous boar is tearing up the farmland. Track Gorehorn to his lair and put him down.", "Farmer",
		["\"Wayfinder! Please! Something huge flattened my whole field last night. Hoofprints as big as a cart!\"", "\"The old hunters called it Gorehorn. It used to be just a big boar... now it's a monster. Its lair is marked on your compass.\""])
	_m("Echoes of the Past", "verdant", "lore", "verdant", 2, "Find 2 ancient Lore Stones in the Verdant Reach to learn what happened to the Wayfinders.", "Elder",
		["\"You carry a splinter of the Shard of Growth now. Can you feel it pulling?\"", "\"The old Wayfinders left messages in Lore Stones, glowing blue pillars in the wilds. Read them. You need to understand what you're fighting.\""])
	_m("The Hexer's Court", "verdant", "boss", "velkar", 1, "The Illager Arch-Hexer Velkar is massing an army. Strike at his court before it marches.", "Guard",
		["\"Scouts report Illagers gathering in the hills. Hundreds of them. And at the center, Velkar, the Arch-Hexer.\"", "\"He was the first to kneel to Malgrath. If he falls, the Illager clans will scatter.\""])
	_m("Silverleaf for the Sick", "verdant", "gather", "silverleaf", 5, "The Hexer's curse has sickened the village. Gather 5 Silverleaf herbs.", "Alchemist",
		["\"Velkar's dying curse fell on the village like a fog. Half the children are coughing.\"", "\"Silverleaf! I need Silverleaf. It grows wild, and the swamp witches hoard it.\""])
	_m("Mire of Sorrow", "verdant", "boss", "mire_matriarch", 1, "The swamp itself has risen. Defeat the Mire Matriarch.", "Bard",
		["\"Have you heard the tale of the Mirewood lovers? The lake that drank them? Well, it's not a tale anymore.\"", "\"The swamp has a mother now. And she's hungry.\""])
	_m("Heart of Stone", "verdant", "boss", "stone_colossus", 1, "The Stone Colossus holds the Shard of Growth. Defeat it and claim the first Shard.", "Elder",
		["\"This is it, Wayfinder. The Shard of Growth is lodged in the heart of the Stone Colossus, the ancient guardian of our Gate.\"", "\"Free the Shard and the Gate to the Underrealm will open. And Malgrath will know your name.\""],
		{"unlock": "ember", "item": 3})
	# Chapter II - The Ashen Underrealm
	_m("Through the Burning Gate", "ember", "travel", "ember", 1, "Use the Realm Gate in the village to travel to the Ashen Underrealm.", "Shard of Growth",
		["The Shard of Growth pulses in your hand. Somewhere far below, the Realm Gate shudders and roars to life.", "Through it, you see fire."])
	_m("The Ashborn", "ember", "talk", "elder", 1, "Find the Ashborn refugees' Elder and learn about the Underrealm.", "Shard of Growth",
		["Heat slams into you like a wall. Ash falls like snow. But there, among the basalt, a village still stands."])
	_m("Cinders and Ash", "ember", "kill", "any", 20, "Defeat 20 creatures of the Underrealm to secure the Ashborn's supply routes.", "Elder",
		["\"A Wayfinder? Here? Ha! The ash gods have a sense of humor.\"", "\"If you're really here to help, clear the roads. Our traders haven't come home in weeks.\""])
	_m("Warlord of Gold", "ember", "boss", "grimtusk", 1, "Grimtusk the Ash Warlord rules the Underrealm by force. Break his rule.", "Guard",
		["\"Grimtusk and his Tuskguard take half of everything we mine. Those who don't pay... aren't seen again.\"", "\"Melted the whole imperial treasury into his armor, he did. Let's see how he likes being melted himself.\""])
	_m("Souls in the Fire", "ember", "gather", "soul_gem", 3, "Collect 3 Soul Gems to calm the soulfire that burns the Ashborn's homes.", "Mystic",
		["\"The soulfire grows restless. It whispers names. Mine, last night.\"", "\"Soul Gems can hold the lost ones. Gather them, and we can give the souls some rest.\""])
	_m("Wings of Flame", "ember", "boss", "pyrrhia", 1, "Pyrrhia the Flamewing burns everything that flies. Bring her down.", "Bard",
		["\"The last phoenix! I'd write her a song, if she hadn't burned my lute.\"", "\"They say every time she dies she comes back angrier. Let's hope she's out of lives.\""])
	_m("Deep Delve", "ember", "cave", "", 2, "Clear 2 caves in the Underrealm to reach the old imperial vaults.", "Cartographer",
		["\"The Empire built its vaults deep. My maps say the way to the Molten King's throne runs underground.\""])
	_m("The Molten King", "ember", "boss", "infernax", 1, "Emperor Infernax still sits on his throne of magma. Dethrone him.", "Elder",
		["\"Our emperor walked into the volcano to become eternal. Now he rises from the lava lake and takes our children for his court.\"", "\"End his reign, Wayfinder. He has ruled long enough.\""])
	_m("The Soulforge", "ember", "boss", "soulforged_sentinel", 1, "The Soulforged Sentinel guards the Shard of Flame. Free the trapped souls and claim the Shard.", "Mystic",
		["\"Ten thousand souls in one body. They scream for release. The Shard of Flame burns in its chest.\"", "\"Free them. Free us all.\""],
		{"unlock": "frost", "item": 3})
	# Chapter III - The Frostfall Wastes
	_m("Into the Endless Winter", "frost", "travel", "frost", 1, "Use the Realm Gate to travel to the Frostfall Wastes.", "Shard of Flame",
		["Two Shards now pulse in harmony. The Gate cracks open onto a world of white silence."])
	_m("Hearth and Home", "frost", "talk", "elder", 1, "Find the Elder of the frozen village.", "Shard of Flame",
		["Snow muffles your footsteps. Smoke rises from chimneys ahead. Someone is keeping the fires burning."])
	_m("The Pack Hunts", "frost", "kill", "frost_wolf", 6, "Frost Wolves are hunting the villagers. Thin the pack by 6.", "Guard",
		["\"Wolves. They come in the blizzards now. They didn't used to. Rimefang used to keep them away.\""])
	_m("Rimefang", "frost", "boss", "rimefang", 1, "Rimefang, the great wolf, has forgotten her way. End her suffering.", "Elder",
		["\"Rimefang guided our grandparents home through every storm. Now she leads the pack against us.\"", "\"It's the Shard's cold in her. Please. Give her peace.\""])
	_m("Frozen Memories", "frost", "lore", "frost", 2, "Find 2 Lore Stones in Frostfall to learn of Queen Glaciara.", "Bard",
		["\"The Glass Palace... I've only heard songs. Find the stones. They remember what we've forgotten.\""])
	_m("The Ice Witch Queen", "frost", "boss", "glaciara", 1, "Queen Glaciara froze her own court out of love. Thaw her heart, or shatter it.", "Elder",
		["\"She calls it mercy. Never growing old, never losing anyone. But a life that never changes isn't a life.\""])
	_m("Mithril for the Forge", "frost", "gather", "mithril_ore", 3, "Gather 3 Mithril Ore so the Blacksmith can forge weapons fit for a Titan.", "Blacksmith",
		["\"The Titan's hide is like a glacier. Bring me Mithril and I'll make you something that cuts it.\""])
	_m("Wrath of the Peaks", "frost", "boss", "avalanche_titan", 1, "The Avalanche Titan buries villages whole. Stop it.", "Guard",
		["\"The mountain moved again last night. Took the whole north watch with it.\""])
	_m("The Frostheart Wyrm", "frost", "boss", "frostheart_wyrm", 1, "The Frostheart Wyrm swallowed the Shard of Stillness. Slay it and the winter may break.", "Elder",
		["\"Beneath the glacier sleeps a dragon of ice. In its heart lies the Shard of Stillness.\"", "\"Take it back, Wayfinder, and maybe our children will see spring.\""],
		{"unlock": "spore", "item": 3})
	# Chapter IV - The Sporelight Hollows
	_m("Into the Glow", "spore", "travel", "spore", 1, "Use the Realm Gate to travel to the Sporelight Hollows.", "Shard of Stillness",
		["Three Shards. The mark on your hand blazes. The Gate opens onto a forest of light."])
	_m("The Free Myconids", "spore", "talk", "mystic", 1, "Find a village Mystic who can explain the Bloom.", "Shard of Stillness",
		["Everything here glows. Everything here grows. The air tastes sweet and wrong."])
	_m("Pruning the Bloom", "spore", "kill", "any", 25, "Defeat 25 overgrown creatures before the Bloom swallows the village.", "Mystic",
		["\"The Shard of Life made everything grow. Everything. Forever. Even things that should have died.\"", "\"Prune the overgrowth. It's the only way to slow it.\""])
	_m("Queen of Decay", "spore", "boss", "rot_mother", 1, "The Rot Mother devours everything that falls. Stop her before she devours the village.", "Elder",
		["\"Something has to eat the dead. But she's started eating the living too.\""])
	_m("Living Light", "spore", "gather", "bioluminite", 3, "Gather 3 Bioluminite crystals to blind the Glowmoths.", "Alchemist",
		["\"Glowmoths drink light. Feed them too much and they burst! Bring me Bioluminite and I'll brew something nasty.\""])
	_m("The Moth Queen", "spore", "boss", "queen_lumina", 1, "Queen Lumina drank a sunrise. Make her give it back.", "Bard",
		["\"Lumina was a lantern-keeper once. They say she still sings lullabies to her moths.\""])
	_m("Aeris's Lantern", "spore", "lore", "spore", 2, "Find 2 Lore Stones in the Hollows to follow the trail of the last Wayfinder, Aeris.", "Mystic",
		["\"There was a Wayfinder before you. Aeris. She followed Malgrath into the dark. Her lantern still burns somewhere in the Hollows.\""])
	_m("The Walking Forest", "spore", "boss", "myco_colossus", 1, "The Myco Colossus is marching on the village. Fell the forest.", "Guard",
		["\"The trees are walking! The TREES are WALKING!\""])
	_m("The Overgrowth Heart", "spore", "boss", "overgrowth_heart", 1, "Destroy the Overgrowth Heart and reclaim the Shard of Life.", "Mystic",
		["\"Feel that? The heartbeat in the ground? That's the Overgrowth Heart. The Shard of Life took root and grew a heart.\"", "\"Stop it beating.\""],
		{"unlock": "void", "item": 3})
	# Chapter V - The Hollow Void
	_m("The Edge of Everything", "void", "travel", "void", 1, "Use the Realm Gate to travel to the Hollow Void.", "Shard of Life",
		["Four Shards circle your hand like moons. The Gate opens onto nothing at all.", "A voice speaks inside your head: \"Come, then, little Wayfinder. Come home.\""])
	_m("The Last Light", "void", "talk", "elder", 1, "Find the last village of the Void.", "Malgrath",
		["Islands float in the dark. On one of them, impossibly, lanterns are burning."])
	_m("Island Hopping", "void", "kill", "any", 30, "Defeat 30 creatures of the Void to clear a path to the Throne.", "Elder",
		["\"We are the Starkeepers. We were Wayfinders' servants once, before the dark. We kept a light burning for you.\"", "\"Clear the bridges. The Throne waits at the edge.\""])
	_m("The Blind Guardian", "void", "boss", "warden_echoes", 1, "The Warden of Echoes guards the path to the Throne. Move quietly. Strike hard.", "Guard",
		["\"It can't see you. But it can hear your heart. Make it beat slower, if you can.\""])
	_m("Malric's Journal", "void", "lore", "void", 3, "Find 3 Lore Stones in the Void to uncover the truth about Malgrath.", "Bard",
		["\"Echo crystals keep recording a voice. A sad one. I think... I think it's him. Before.\""])
	_m("The Starless", "void", "boss", "nihila", 1, "Nihila devoured the Void's stars. Make her return them.", "Elder",
		["\"Once there were stars here. Nihila ate them. Every one.\""])
	_m("Lord of Nightmares", "void", "boss", "phantom_monarch", 1, "The Phantom Monarch rules every sleepless night. Wake the realms from the nightmare.", "Guard",
		["\"The phantoms circle closer every hour. Their monarch is the last thing between you and the Throne.\""])
	_m("The Hollow Crown", "void", "boss", "malgrath", 1, "Face Malgrath, the Hollow Crown, and reunite the Prism of Ages.", "Malgrath",
		["\"You came. Of course you came. I came too, once.\"", "\"Give me the Shards, Wayfinder. Or take them from me. Either way, one of us holds the Prism tonight.\""],
		{"finale": true, "item": 4})
	_m("The Endless Road", "void", "level", "", 50, "The realms stretch on forever. Reach level 50 to unlock Ascension, where enemies grow stronger and Mythic loot awaits.", "Elder",
		["\"The Prism is whole, but its light does not reach the edge of the world. Not yet.\"", "\"Keep walking, Wayfinder. There's always farther to go.\""])


func _build_side() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	var used := {}
	var kill_titles := ["{E} Trouble", "Cull the {E}s", "Bane of the {E}s", "{N}'s Revenge", "Thinning the {E} Herd", "The {E} Menace", "{E} Hunt", "Too Many {E}s", "Clear the Road of {E}s", "Night of the {E}s", "{N} Wants Peace", "No Rest for {E}s"]
	var gather_titles := ["{N}'s {R} Order", "A Need for {R}", "{R} Run", "Stockpiling {R}", "{R} for the Winter", "The {R} Shortage", "Fetch Some {R}", "{N}'s Secret Recipe", "Supplies: {R}", "A Pocketful of {R}"]
	var cave_titles := ["Into the Deep", "The Dark Below", "Spelunker's Dare", "What Lurks Beneath", "{N}'s Lost Pick", "The Hollow Earth", "Echoes Underground", "The Unlit Way"]
	var lore_titles := ["Whispers of the Old World", "Stones That Remember", "{N}'s History Lesson", "The Wayfinder Trail", "Forgotten Words", "Lost Chronicles"]
	var chest_titles := ["Treasure Seeker", "{N}'s Missing Crate", "Loot and Plunder", "Hidden Riches", "The Treasure Map", "Finders Keepers"]
	var shrine_titles := ["Pilgrimage of Power", "The Shrine Path", "{N}'s Blessing", "Touch of the Ancients", "Sacred Lights"]
	var village_titles := ["Neighborly Visits", "The Wandering Letter", "{N}'s Grand Tour", "Spreading the Word", "Mapping the Settlements"]
	var boss_titles := ["Rematch: {B}", "{B} Returns", "The Hunt for {B}", "Trophy of {B}"]
	var kill_any_titles := ["Patrol Duty", "Sweep the Wilds", "Hold the Line", "{N}'s Watch", "Monster Slayer", "Purge the Corruption"]
	var dim_ix := 0
	for d in Data.dimensions:
		var dimid: String = d["id"]
		var base: int = d["base_level"]
		var res_list: Array = d["resources"].duplicate()
		for e in d["enemies"]:
			for drop in Data.enemies[e]["drops"]:
				if not drop[0] in res_list and drop[0] != "emerald":
					res_list.append(drop[0])
		for i in 45:
			var name: String = Story.VILLAGER_FIRST[rng.randi() % Story.VILLAGER_FIRST.size()]
			var roll := rng.randf()
			var type := "kill"
			if roll < 0.34: type = "kill"
			elif roll < 0.58: type = "gather"
			elif roll < 0.66: type = "cave"
			elif roll < 0.72: type = "lore"
			elif roll < 0.79: type = "chest"
			elif roll < 0.85: type = "shrine"
			elif roll < 0.89: type = "village"
			elif roll < 0.94: type = "boss"
			else: type = "kill_any"
			var q := {}
			var title := ""
			var giver := "guard"
			match type:
				"kill":
					var e: String = d["enemies"][rng.randi() % d["enemies"].size()]
					var n := rng.randi_range(5, 14)
					var ename: String = Data.enemies[e]["name"]
					title = kill_titles[rng.randi() % kill_titles.size()].replace("{E}", ename).replace("{N}", name)
					giver = ["guard", "farmer", "bard", "elder"][rng.randi() % 4]
					q = {"type": "kill", "target": e, "count": n, "desc": "%s asks you to defeat %d %ss roaming the %s." % [name, n, ename, d["short"]]}
				"gather":
					var r: String = res_list[rng.randi() % res_list.size()]
					var n := rng.randi_range(3, 10)
					var rname: String = Data.resources[r]["name"]
					title = gather_titles[rng.randi() % gather_titles.size()].replace("{R}", rname).replace("{N}", name)
					giver = ["blacksmith", "alchemist", "merchant", "farmer"][rng.randi() % 4]
					q = {"type": "gather", "target": r, "count": n, "desc": "%s needs %d %s. Collect them from ore veins, crates, chests or monsters." % [name, n, rname]}
				"cave":
					var n := rng.randi_range(1, 2)
					title = cave_titles[rng.randi() % cave_titles.size()].replace("{N}", name)
					giver = "cartographer"
					q = {"type": "cave", "target": "", "count": n, "desc": "%s wants %d cave%s charted and cleared of monsters." % [name, n, "s" if n > 1 else ""]}
				"lore":
					title = lore_titles[rng.randi() % lore_titles.size()].replace("{N}", name)
					giver = ["elder", "bard", "cartographer"][rng.randi() % 3]
					q = {"type": "lore", "target": dimid, "count": 1, "desc": "%s wants you to read an ancient Lore Stone in the %s." % [name, d["short"]], "repeat_ok": true}
				"chest":
					var n := rng.randi_range(2, 5)
					title = chest_titles[rng.randi() % chest_titles.size()].replace("{N}", name)
					giver = "merchant"
					q = {"type": "chest", "target": "", "count": n, "desc": "%s heard rumors of treasure. Open %d chests in the wilds or in caves." % [name, n]}
				"shrine":
					var n := rng.randi_range(1, 3)
					title = shrine_titles[rng.randi() % shrine_titles.size()].replace("{N}", name)
					giver = ["mystic", "enchanter"][rng.randi() % 2]
					q = {"type": "shrine", "target": "", "count": n, "desc": "%s asks you to draw power from %d ancient shrine%s." % [name, n, "s" if n > 1 else ""]}
				"village":
					var n := rng.randi_range(2, 3)
					title = village_titles[rng.randi() % village_titles.size()].replace("{N}", name)
					giver = ["bard", "cartographer", "merchant"][rng.randi() % 3]
					q = {"type": "village", "target": "", "count": n, "desc": "%s wants word spread. Visit %d other villages in the %s." % [name, n, d["short"]]}
				"boss":
					var b: String = d["bosses"][rng.randi() % 3]
					var bname: String = Data.bosses[b]["name"]
					title = boss_titles[rng.randi() % boss_titles.size()].replace("{B}", bname)
					giver = ["guard", "elder"][rng.randi() % 2]
					q = {"type": "boss", "target": b, "count": 1, "desc": "%s says %s has returned to its lair. Defeat it again." % [name, bname], "item": 2}
				_:
					var n := rng.randi_range(12, 30)
					title = kill_any_titles[rng.randi() % kill_any_titles.size()].replace("{N}", name)
					giver = "guard"
					q = {"type": "kill", "target": "any", "count": n, "desc": "%s needs the area secured. Defeat %d monsters in the %s." % [name, n, d["short"]]}
			if used.has(title):
				used[title] += 1
				title = "%s %s" % [title, ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"][mini(used[title], 10)]]
			else:
				used[title] = 1
			var id := "s_%s_%02d" % [dimid, i]
			var lvl := base + int(i / 4.5)
			q["xp"] = int((60 + q.get("count", 1) * 12) * (1.0 + lvl * 0.18))
			q["emerald"] = 15 + lvl * 4 + q.get("count", 1) * 2
			if not q.has("item"):
				q["item"] = 1 if rng.randf() < 0.45 else 0
			q["giver"] = giver
			q["giver_name"] = name
			q["min_level"] = lvl
			_q(id, title, dimid, q["type"], q["target"], q["count"], q["desc"], q)
			side_ids.append(id)
		dim_ix += 1


# ---------------------------------------------------------------- runtime

func reset() -> void:
	active = {}
	completed = {}
	bounties = {}
	tracked = ""
	bounty_counter = 0


func start_story() -> void:
	reset()
	_start(main_order[0])


func def(id: String) -> Dictionary:
	if defs.has(id):
		return defs[id]
	return bounties.get(id, {})


func current_main() -> String:
	for id in main_order:
		if active.has(id):
			return id
	return ""


func _start(id: String) -> void:
	var q := def(id)
	if q.is_empty():
		return
	active[id] = 0
	if q["type"] == "level":
		active[id] = State.level
	if q["main"] or tracked == "":
		tracked = id
	quests_changed.emit()
	if q["main"] and not q["story"].is_empty():
		story_event.emit(q["speaker"], q["story"])
	# Some objectives may already be satisfied (e.g. already standing in the realm).
	if q["type"] == "travel" and State.current_dim == q["target"]:
		_progress(id, 1)
	elif q["type"] == "level":
		_progress(id, 0)


func side_active_count() -> int:
	var n := 0
	for id in active:
		if not def(id).get("main", false):
			n += 1
	return n


## Side quests a villager of `role_id` can offer in the current realm.
func offers_for(role_id: String, dimid: String, limit := 3) -> Array:
	var out: Array = []
	for id in side_ids:
		var q: Dictionary = defs[id]
		if q["dim"] != dimid or q["giver"] != role_id or completed.has(id) or active.has(id):
			continue
		if q["min_level"] > State.level + 4:
			continue
		out.append(id)
		if out.size() >= limit:
			break
	return out


func accept(id: String) -> bool:
	if active.has(id) or completed.has(id):
		return false
	if side_active_count() >= MAX_SIDE:
		return false
	_start(id)
	return true


func abandon(id: String) -> void:
	if def(id).get("main", false):
		return
	active.erase(id)
	bounties.erase(id)
	if tracked == id:
		tracked = current_main()
	quests_changed.emit()


func make_bounty(dimid: String, lvl: int) -> String:
	var d := Data.dim(dimid)
	bounty_counter += 1
	var e: String = d["enemies"][randi() % d["enemies"].size()]
	var n := randi_range(8, 20)
	var id := "b_%d_%d" % [bounty_counter, randi() % 10000]
	var ename: String = Data.enemies[e]["name"]
	bounties[id] = {"id": id, "title": "Bounty: %s x%d" % [ename, n], "dim": dimid, "type": "kill", "target": e, "count": n,
		"desc": "The village bounty board offers a reward for %d %ss. Endless work for an endless realm." % [n, ename],
		"giver": "guard", "giver_name": "Bounty Board", "main": false, "xp": int((80 + n * 14) * (1.0 + lvl * 0.2)),
		"emerald": 25 + lvl * 5 + n * 3, "item": 1, "story": [], "speaker": "", "bounty": true}
	return id


func notify(event: String, key: String, amount: int = 1) -> void:
	for id in active.keys():
		var q := def(id)
		if q.is_empty():
			continue
		match q["type"]:
			"kill":
				if event == "kill" and q["dim"] == State.current_dim and (q["target"] == "any" or q["target"] == key):
					_progress(id, amount)
			"boss":
				if event == "boss" and q["target"] == key:
					_progress(id, 1)
			"gather":
				if event == "gather" and q["target"] == key:
					_progress(id, amount)
			"talk":
				if event == "talk" and q["target"] == key and q["dim"] == State.current_dim:
					_progress(id, 1)
			"travel":
				if event == "travel" and q["target"] == key:
					_progress(id, 1)
			"lore":
				if event == "lore" and q["target"] == key:
					_progress(id, 1)
			"level":
				if event == "level":
					active[id] = amount
					_progress(id, 0)
			"cave", "chest", "shrine", "village":
				if event == q["type"] and q["dim"] == State.current_dim:
					_progress(id, amount)


func _progress(id: String, amount: int) -> void:
	var q := def(id)
	active[id] = active[id] + amount
	if active[id] >= q["count"]:
		_complete(id)
	else:
		quests_changed.emit()


func _complete(id: String) -> void:
	var q := def(id)
	active.erase(id)
	completed[id] = true
	bounties.erase(id)
	State.add_xp(q["xp"])
	State.add_resource("emerald", q["emerald"])
	if q.get("unlock", "") != "" and not q["unlock"] in State.unlocked_dims:
		State.unlocked_dims.append(q["unlock"])
	quest_completed.emit(q)
	if tracked == id:
		tracked = ""
	if q["main"]:
		var ix := main_order.find(id)
		if ix >= 0 and ix + 1 < main_order.size():
			_start(main_order[ix + 1])
	if tracked == "":
		tracked = current_main()
		if tracked == "" and not active.is_empty():
			tracked = active.keys()[0]
	quests_changed.emit()


func progress_of(id: String) -> int:
	return active.get(id, 0)


func serialize() -> Dictionary:
	return {"active": active, "completed": completed, "bounties": bounties, "tracked": tracked, "bounty_counter": bounty_counter}


func deserialize(d: Dictionary) -> void:
	reset()
	var a: Dictionary = d.get("active", {})
	for k in a:
		active[k] = int(a[k])
	completed = d.get("completed", {})
	bounties = d.get("bounties", {})
	for b in bounties.values():
		b["count"] = int(b["count"])
		b["xp"] = int(b["xp"])
		b["emerald"] = int(b["emerald"])
		b["item"] = int(b["item"])
	tracked = d.get("tracked", "")
	bounty_counter = int(d.get("bounty_counter", 0))
	if current_main() == "":
		for id in main_order:
			if not completed.has(id):
				_start(id)
				break
	quests_changed.emit()

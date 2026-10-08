## Codex: discovered lore, bestiary, boss records and journey statistics.
extends "res://scripts/ui/screen.gd"

var content: VBoxContainer
var tab := 0


func _ready() -> void:
	build("Wayfinder's Codex", Vector2(1200, 760))
	var tb := TabBar.new()
	for t in ["Lore", "Bestiary", "Bosses", "Journey"]:
		tb.add_tab(t)
	tb.tab_changed.connect(func(i): tab = i; refresh())
	body.add_child(tb)
	var s: Array = scroll()
	body.add_child(s[0])
	content = s[1]
	refresh()


func refresh() -> void:
	K.clear(content)
	match tab:
		0: _lore()
		1: _bestiary()
		2: _bosses()
		3: _journey()


func _lore() -> void:
	var n := 0
	for l in Story.lore:
		if State.lore_found.has(l["id"]):
			n += 1
	content.add_child(K.label("Lore entries discovered: %d / %d   (read glowing blue Lore Stones in the wilds)" % [n, Story.lore.size()], 17, K.DIM))
	for d in Data.dimensions:
		content.add_child(K.label(d["name"], 24, K.GOLD))
		for l in Story.lore_for_dim(d["id"]):
			if State.lore_found.has(l["id"]):
				var r := K.rich("[color=#f2c14e][b]%s[/b][/color]\n%s\n" % [l["title"], l["text"]])
				r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				content.add_child(r)
			else:
				content.add_child(K.label("??? - undiscovered", 16, K.DIM))


func _bestiary() -> void:
	content.add_child(K.label("Creatures defeated: %d" % State.total_kills, 18, K.DIM))
	for d in Data.dimensions:
		content.add_child(K.label(d["name"], 24, K.GOLD))
		for id in d["enemies"]:
			var e: Dictionary = Data.enemies[id]
			var kills: int = int(State.bestiary.get(id, 0))
			if kills > 0:
				var r := K.rich("[color=#ffd0a0][b]%s[/b][/color]  [color=#a89a86](defeated %d)[/color]\n%s" % [e["name"], kills, e["desc"]])
				r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				content.add_child(r)
			else:
				content.add_child(K.label("??? - not yet encountered", 16, K.DIM))


func _bosses() -> void:
	content.add_child(K.label("Bosses defeated: %d / %d. Bosses return to their lairs 8 minutes after defeat for a rematch." % [State.bosses_defeated.size(), Data.bosses.size()], 17, K.DIM))
	for d in Data.dimensions:
		content.add_child(K.label(d["name"], 24, K.GOLD))
		for id in d["bosses"]:
			var b: Dictionary = Data.bosses[id]
			if State.bosses_defeated.has(id):
				var r := K.rich("[color=#ff9a8a][b]%s, %s[/b][/color]\n%s\n" % [b["name"], b["title"], b["lore"]])
				r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				content.add_child(r)
			else:
				content.add_child(K.label("??? - undefeated", 16, K.DIM))


func _journey() -> void:
	var hrs := int(State.playtime / 3600.0)
	var mins := int(fmod(State.playtime, 3600.0) / 60.0)
	var t := "[font_size=22][color=#f2c14e]%s the %s[/color][/font_size]\n\n" % [State.profile.get("name", "Wayfinder"), State.profile.get("origin", "warrior").capitalize()]
	t += "Level: %d\nTime played: %dh %dm\nCreatures defeated: %d\nBosses defeated: %d / 20\nCaves cleared: %d\nVillages discovered: %d\n" % [State.level, hrs, mins, State.total_kills, State.bosses_defeated.size(), State.caves_cleared, State.visited_villages.size()]
	t += "Quests completed: %d / %d\nRealms unlocked: %d / 5\nAscension rank: %d\n" % [Quests.completed.size(), Quests.total_quests(), State.unlocked_dims.size(), State.ascension]
	t += "Prism Shards recovered: %d / 5\n" % _shards()
	if State.story_done:
		t += "\n[color=#ffd84a]The Prism of Ages is whole again. The road goes ever on.[/color]"
	var r := K.rich(t)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(r)
	var story := "\n[color=#f2c14e][b]The Story So Far[/b][/color]\n"
	for id in Quests.main_order:
		if Quests.completed.has(id):
			var q := Quests.def(id)
			story += "[color=#8aff8a]*[/color] %s\n" % q["title"]
	var r2 := K.rich(story)
	r2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(r2)


func _shards() -> int:
	var n := 0
	for id in ["stone_colossus", "soulforged_sentinel", "frostheart_wyrm", "overgrowth_heart", "malgrath"]:
		if State.bosses_defeated.has(id):
			n += 1
	return n

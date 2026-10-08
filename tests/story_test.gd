## Drives the entire main story through quest events to verify the chain completes and unlocks every realm.
extends Node


func _ready() -> void:
	State.new_game(State.default_profile())
	Quests.start_story()
	var guard := 0
	while Quests.current_main() != "" and guard < 200:
		guard += 1
		var id := Quests.current_main()
		var q := Quests.def(id)
		State.current_dim = q["dim"]
		match q["type"]:
			"talk": Quests.notify("talk", q["target"], 1)
			"kill":
				for i in q["count"]:
					Quests.notify("kill", Data.dim(q["dim"])["enemies"][0] if q["target"] == "any" else q["target"], 1)
			"gather": State.add_resource(q["target"], q["count"])
			"boss": Quests.notify("boss", q["target"], 1)
			"cave":
				for i in q["count"]:
					Quests.notify("cave", "", 1)
			"lore":
				for i in q["count"]:
					Quests.notify("lore", q["target"], 1)
			"travel": Quests.notify("travel", q["target"], 1)
			"level":
				while State.level < q["count"]:
					State.add_xp(State.xp_needed())
	var side_types := {}
	for sid in Quests.side_ids:
		var t: String = Quests.defs[sid]["type"]
		side_types[t] = side_types.get(t, 0) + 1
	print("main completed: ", Quests.completed.size(), "/", Quests.main_order.size(), " loops ", guard)
	print("unlocked: ", State.unlocked_dims, " level ", State.level)
	print("side quests: ", Quests.side_ids.size(), " by type ", side_types)
	var titles := {}
	var dup := 0
	for sid in Quests.side_ids:
		if titles.has(Quests.defs[sid]["title"]):
			dup += 1
		titles[Quests.defs[sid]["title"]] = true
	print("duplicate titles: ", dup)
	print("sample: ", Quests.defs[Quests.side_ids[0]]["title"], " | ", Quests.defs[Quests.side_ids[100]]["title"], " | ", Quests.defs[Quests.side_ids[200]]["title"])
	print("STORY TEST DONE")
	get_tree().quit()

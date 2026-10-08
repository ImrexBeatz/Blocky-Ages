## Realm Gate: travel between unlocked realms, return to the hub village, or Ascend.
extends "res://scripts/ui/screen.gd"

var unlock_quest := {"ember": "Heart of Stone", "frost": "The Soulforge", "spore": "The Frostheart Wyrm", "void": "The Overgrowth Heart"}


func _ready() -> void:
	build("Realm Gate", Vector2(1100, 760))
	var s: Array = scroll()
	body.add_child(s[0])
	var v: VBoxContainer = s[1]
	v.add_child(K.label("The Gate hums with the light of every Shard you carry.", 17, K.DIM))
	for d in Data.dimensions:
		var row := K.hbox(12)
		var unlocked: bool = d["id"] in State.unlocked_dims
		var here: bool = d["id"] == State.current_dim
		var txt := "[font_size=22][color=%s]%s[/color][/font_size]  [color=#a89a86]Recommended Lv %d+[/color]\n%s" % ["#f2c14e" if unlocked else "#6a6070", d["name"], d["base_level"], d["desc"] if unlocked else "Sealed. Complete \"%s\" to awaken this path." % unlock_quest.get(d["id"], "")]
		var r := K.rich(txt)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(r)
		var did: String = d["id"]
		var b := K.button("Travel" if not here else "Return to Hub", func():
			close()
			Game.main.travel_to(did), 170)
		b.disabled = not unlocked
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
		v.add_child(row)
	if State.story_done:
		v.add_child(HSeparator.new())
		var can: bool = State.level >= 50 + State.ascension * 5
		var r2 := K.rich("[font_size=22][color=#ff4f6d]Ascension %d -> %d[/color][/font_size]\nEnemies gain +10 levels, more health and damage. Loot luck increases and Mythic gear drops more often. Requires level %d." % [State.ascension, State.ascension + 1, 50 + State.ascension * 5])
		r2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row2 := K.hbox(12)
		row2.add_child(r2)
		var ab := K.button("Ascend", func():
			State.ascension += 1
			Game.toast("You have Ascended! Rank %d" % State.ascension, Color("#ff4f6d"))
			Sfx.play("boss", 1.5)
			State.save_game()
			close(), 140)
		ab.disabled = not can
		row2.add_child(ab)
		v.add_child(row2)

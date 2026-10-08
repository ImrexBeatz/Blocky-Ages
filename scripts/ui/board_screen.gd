## Village bounty board: endless, procedurally generated hunting contracts.
extends "res://scripts/ui/screen.gd"

var offered: Array = []


func _ready() -> void:
	build("Bounty Board", Vector2(980, 600))
	var lvl := maxi(State.level, Game.enemy_level_at(Game.player.global_position))
	for i in 3:
		offered.append(Quests.make_bounty(State.current_dim, lvl))
	refresh()


func refresh() -> void:
	K.clear(body)
	body.add_child(K.label("Active side quests & bounties: %d / %d" % [Quests.side_active_count(), Quests.MAX_SIDE], 17, K.DIM))
	for id in offered:
		var q := Quests.def(id)
		if q.is_empty():
			continue
		var row := K.hbox(10)
		var taken := Quests.active.has(id)
		var r := K.rich("[color=#f2c14e][b]%s[/b][/color]\n%s\n[color=#8aff8a]%d XP[/color], [color=#2fd37a]%d Emeralds[/color], gear" % [q["title"], q["desc"], q["xp"], q["emerald"]])
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(r)
		var qid: String = id
		var b := K.button("Taken" if taken else "Accept", func():
			if Quests.accept(qid):
				Sfx.play("quest", 1.3, -4.0)
			refresh(), 130)
		b.disabled = taken or Quests.side_active_count() >= Quests.MAX_SIDE
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
		body.add_child(row)


func close() -> void:
	for id in offered:
		if not Quests.active.has(id):
			Quests.bounties.erase(id)
	super.close()

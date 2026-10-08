## Level-up screen: spend attribute points, unlock perks and view the progression roadmap.
extends "res://scripts/ui/screen.gd"

var left: VBoxContainer
var right: VBoxContainer

const ATTR_DESC := {
	"might": "+4% melee damage, +3% ranged damage",
	"vitality": "+12 max health, +0.1 health regen",
	"arcana": "+5% artifact damage, +1.2% artifact recharge",
	"agility": "+1.2% move speed, +0.8% critical, +2% ranged",
	"fortune": "+3% luck (rarer loot), +3% emeralds",
}


func _ready() -> void:
	build("Skills & Progression", Vector2(1280, 760))
	var cols := K.hbox(20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	var ls: Array = scroll()
	ls[0].custom_minimum_size.x = 560
	ls[0].size_flags_horizontal = Control.SIZE_FILL
	cols.add_child(ls[0])
	left = ls[1]
	var rs: Array = scroll()
	cols.add_child(rs[0])
	right = rs[1]
	refresh()


func refresh() -> void:
	K.clear(left)
	K.clear(right)
	left.add_child(K.label("Level %d   (%d / %d XP)" % [State.level, State.xp, State.xp_needed()], 24, K.GOLD))
	left.add_child(K.label("Attribute points: %d" % State.attr_points, 20, Color("#8aff8a") if State.attr_points > 0 else K.DIM))
	for a in State.ATTRS:
		var row := K.hbox(10)
		var nl := K.label("%s  %d" % [a.capitalize(), State.attrs[a]], 20, K.PARCH)
		nl.custom_minimum_size.x = 150
		row.add_child(nl)
		var dl := K.label(ATTR_DESC[a], 15, K.DIM)
		dl.custom_minimum_size.x = 300
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(dl)
		var cb := func():
			if State.spend_attr(a):
				Sfx.play("pickup", 1.3)
				refresh()
		var b := K.button("+", cb, 44)
		b.disabled = State.attr_points <= 0
		row.add_child(b)
		left.add_child(row)
	left.add_child(HSeparator.new())
	left.add_child(K.label("Progression Roadmap", 22, K.GOLD))
	var road := [
		[1, "Melee, ranged, armor, artifact slot 1, ring slot"], [3, "Artifact slot 2"], [4, "Amulet slot"], [5, "Perks begin (1 perk point every 5 levels)"],
		[6, "Second ring slot"], [8, "Artifact slot 3"], [10, "Charm slot. The Ashen Underrealm's foes await (Lv 10+)"], [20, "Frostfall Wastes difficulty (Lv 20+)"],
		[30, "Sporelight Hollows difficulty (Lv 30+)"], [40, "Hollow Void difficulty (Lv 40+)"], [50, "Ascension: endless difficulty and Mythic loot"],
	]
	for r in road:
		var done: bool = State.level >= r[0]
		left.add_child(K.label("%s Lv %d - %s" % ["[x]" if done else "[ ]", r[0], r[1]], 16, Color("#8aff8a") if done else K.DIM))
	right.add_child(K.label("Perks  (points: %d)" % State.perk_points, 24, K.GOLD))
	right.add_child(K.label("Earn a perk point every 5 levels.", 15, K.DIM))
	for p in Data.perks:
		var row := K.hbox(10)
		var owned := State.has_perk(p["id"])
		var avail: bool = State.level >= p["req"]
		var col := Color("#8aff8a") if owned else (K.PARCH if avail else K.DIM)
		var txt := K.label("%s  (Lv %d)\n%s" % [p["name"], p["req"], p["desc"]], 16, col)
		txt.custom_minimum_size.x = 440
		txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(txt)
		if owned:
			row.add_child(K.label("Owned", 16, Color("#8aff8a")))
		else:
			var pid: String = p["id"]
			var cb2 := func():
				if State.buy_perk(pid):
					Sfx.play("levelup", 1.5, -6.0)
					refresh()
			var b := K.button("Unlock", cb2, 100)
			b.disabled = not avail or State.perk_points <= 0
			row.add_child(b)
		right.add_child(row)

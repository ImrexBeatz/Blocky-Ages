## World objects the player can use with [E]: chests, ore, crates, lore stones, shrines, caves, gates and boards.
extends Node3D

const U = preload("res://scripts/core/util.gd")
const FX = preload("res://scripts/entities/fx.gd")

var type := ""
var data := {}
var used := false
var lid: Node3D
var orb: Node3D
var t := 0.0
var shrine_power := ""
var mine_progress := 0.0


func setup(d: Dictionary) -> void:
	data = d
	type = d["type"]
	match type:
		"chest":
			var tier: int = d.get("tier", 1)
			var wood := Color("#8a5a2a") if tier < 3 else Color("#3a2a4a")
			var trim := Color("#c9a227") if tier >= 2 else Color("#5a5a5a")
			U.box(self, Vector3(1.0, 0.6, 0.7), Vector3(0, 0.3, 0), wood)
			U.box(self, Vector3(1.04, 0.08, 0.74), Vector3(0, 0.55, 0), trim)
			lid = Node3D.new()
			lid.position = Vector3(0, 0.62, 0.35)
			add_child(lid)
			U.box(lid, Vector3(1.0, 0.3, 0.7), Vector3(0, 0.15, -0.35), wood.lightened(0.05))
			U.box(lid, Vector3(0.16, 0.2, 0.06), Vector3(0, 0.0, -0.72), trim, 0.6)
			if tier >= 2:
				var l := OmniLight3D.new()
				l.visible = Settings.v["dynamic_lights"]
				l.light_color = Color("#ffd27a")
				l.light_energy = 0.8
				l.omni_range = 3.5
				l.position.y = 1.0
				add_child(l)
		"ore":
			var rc: Color = d["color"]
			var rock := Color("#6a6a6a")
			U.box(self, Vector3(1.4, 1.0, 1.2), Vector3(0, 0.5, 0), rock)
			U.box(self, Vector3(0.9, 0.7, 0.9), Vector3(0.2, 1.2, 0.1), rock.lightened(0.05))
			for i in 6:
				var p := Vector3(randf_range(-0.6, 0.6), randf_range(0.2, 1.4), randf_range(-0.5, 0.5))
				U.box(self, Vector3(0.22, 0.22, 0.22), p * Vector3(1.05, 1, 1.05), rc, 0.6)
		"crate":
			var wood := Color("#9c7a4a")
			U.box(self, Vector3(0.9, 0.9, 0.9), Vector3(-0.3, 0.45, 0), wood)
			U.box(self, Vector3(0.7, 0.7, 0.7), Vector3(0.55, 0.35, 0.2), wood.darkened(0.1))
			U.box(self, Vector3(0.6, 0.6, 0.6), Vector3(0.0, 1.2, 0.05), wood.lightened(0.05))
			U.box(self, Vector3(0.95, 0.1, 0.95), Vector3(-0.3, 0.45, 0), Color("#5a3a1a"))
		"shrine":
			var keys := Data.powerups.keys()
			shrine_power = keys[absi(hash(d["key"])) % keys.size()]
			if State.opened.has(d["key"]):
				used = true
			else:
				orb = Node3D.new()
				add_child(orb)
				var c: Color = Data.powerups[shrine_power]["color"]
				U.box(orb, Vector3(0.5, 0.5, 0.5), Vector3(0, 0.6, 0), c, 3.0)
				var l := OmniLight3D.new()
				l.visible = Settings.v["dynamic_lights"]
				l.light_color = c
				l.light_energy = 2.0
				l.omni_range = 6.0
				l.position.y = 0.8
				orb.add_child(l)


func prompt() -> String:
	match type:
		"chest": return "Open Chest"
		"ore": return "Mine %s" % Data.resources[data["res"]]["name"]
		"crate": return "Search Supplies"
		"lore": return "Read Lore Stone"
		"shrine": return "Draw Power: %s" % Data.powerups[shrine_power]["name"] if not used else ""
		"cave": return "Enter Cave"
		"cave_exit": return "Leave Cave" if not data.get("final", false) else "Claim Victory & Leave Cave"
		"gate": return "Use Realm Gate"
		"board": return "Check Bounty Board"
	return ""


func can_use() -> bool:
	return not used and prompt() != ""


func _process(delta: float) -> void:
	t += delta
	if orb:
		orb.position.y = sin(t * 2.0) * 0.15
		orb.rotation.y += delta


func use() -> void:
	if used:
		return
	var w = Game.world
	match type:
		"chest":
			used = true
			State.opened[data["key"]] = true
			Sfx.play("chest")
			var tw := create_tween()
			tw.tween_property(lid, "rotation:x", -1.9, 0.35).set_trans(Tween.TRANS_BACK)
			FX.burst(global_position + Vector3(0, 1, 0), Color("#ffd84a"), 20, 4.0)
			w.chest_loot(global_position + Vector3(0, 0.6, 0), data.get("tier", 1))
			Quests.notify("chest", "", 1)
		"ore", "crate":
			used = true
			State.opened[data["key"]] = true
			Sfx.play("hit", 0.7)
			var n := randi_range(3, 6) if type == "ore" else randi_range(2, 5)
			if State.has_perk("scavenger"):
				n = int(n * 1.5)
			for i in n:
				w.drop_resource(data["res"], 1, global_position + Vector3(0, 0.8, 0))
			if type == "crate" and randf() < 0.3:
				w.drop_resource("emerald", randi_range(3, 8), global_position)
			FX.burst(global_position + Vector3(0, 0.8, 0), Color("#8a8a8a") if type == "ore" else Color("#9c7a4a"), 18, 4.0, 0.2)
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector3(1.2, 0.1, 1.2), 0.25)
			tw.tween_callback(queue_free)
		"lore":
			w.read_lore(data["key"])
		"shrine":
			used = true
			State.opened[data["key"]] = true
			Game.player.add_powerup(shrine_power)
			Quests.notify("shrine", "", 1)
			if orb:
				FX.burst(orb.global_position, Data.powerups[shrine_power]["color"], 30, 6.0)
				orb.queue_free()
				orb = null
		"cave":
			w.enter_cave(data["key"], global_position)
		"cave_exit":
			w.exit_cave(data.get("final", false))
		"gate":
			Game.open_screen.emit("gate")
		"board":
			Game.open_screen.emit("board")

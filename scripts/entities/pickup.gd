## Loot on the ground: resources and emeralds magnetize to the player, gear drops glow with a rarity beam.
extends Node3D

const U = preload("res://scripts/core/util.gd")
const FX = preload("res://scripts/entities/fx.gd")

var kind := "res"
var res_id := ""
var amount := 1
var item: Dictionary = {}
var vel := Vector3.ZERO
var settle := 0.0
var age := 0.0
var visual: Node3D
var powerup := ""


func setup_resource(id: String, n: int, pos: Vector3) -> void:
	kind = "res"
	res_id = id
	amount = n
	var c: Color = Data.resources[id]["color"]
	visual = Node3D.new()
	add_child(visual)
	var s := 0.22 if id != "emerald" else 0.18
	U.box(visual, Vector3(s, s, s), Vector3.ZERO, c, 0.8 if id == "emerald" else 0.25)
	if id == "emerald":
		U.box(visual, Vector3(s * 0.6, s * 1.5, s * 0.6), Vector3.ZERO, c.lightened(0.2), 1.0)
	_launch(pos)


func setup_item(inst: Dictionary, pos: Vector3) -> void:
	kind = "item"
	item = inst
	var d: Dictionary = Data.items[inst["id"]]
	var rc: Color = Data.rarity_color(inst["rarity"])
	visual = Node3D.new()
	add_child(visual)
	var c: Color = d.get("color", Color.WHITE)
	match d["kind"]:
		"melee":
			var w := preload("res://scripts/entities/voxel_model.gd").weapon(d["sub"], c, d.get("accent", c), 0.4)
			w.rotation.x = -PI * 0.5
			w.position.y = 0.4
			visual.add_child(w)
		"ranged":
			var w2 := preload("res://scripts/entities/voxel_model.gd").weapon(d["sub"], c, c, 0.4)
			visual.add_child(w2)
		"armor":
			U.box(visual, Vector3(0.6, 0.55, 0.3), Vector3.ZERO, c, 0.2)
			U.box(visual, Vector3(0.7, 0.12, 0.34), Vector3(0, 0.2, 0), d.get("accent", c), 0.2)
		"artifact":
			U.box(visual, Vector3(0.35, 0.35, 0.35), Vector3.ZERO, c, 2.5)
		"accessory":
			U.box(visual, Vector3(0.3, 0.06, 0.3), Vector3.ZERO, Color("#ffd84a"), 0.6)
			U.box(visual, Vector3(0.12, 0.12, 0.12), Vector3(0, 0.08, 0), c, 2.0)
	# Rarity beam
	var beam := MeshInstance3D.new()
	beam.mesh = U.box_mesh(Vector3(0.12, 6.0, 0.12))
	beam.material_override = U.unshaded(Color(rc.r, rc.g, rc.b, 0.35 + inst["rarity"] * 0.1))
	beam.position.y = 3.0
	add_child(beam)
	var l := OmniLight3D.new()
	l.light_color = rc
	l.light_energy = 1.0 + inst["rarity"] * 0.5
	l.omni_range = 4.0
	l.position.y = 1.0
	add_child(l)
	_launch(pos)


func setup_powerup(id: String, pos: Vector3) -> void:
	kind = "powerup"
	powerup = id
	var c: Color = Data.powerups[id]["color"]
	visual = Node3D.new()
	add_child(visual)
	U.box(visual, Vector3(0.45, 0.45, 0.45), Vector3.ZERO, c, 3.0)
	U.box(visual, Vector3(0.25, 0.25, 0.25), Vector3.ZERO, Color.WHITE, 4.0)
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 2.0
	l.omni_range = 5.0
	add_child(l)
	_launch(pos)


func setup_potion(pos: Vector3) -> void:
	kind = "potion"
	visual = Node3D.new()
	add_child(visual)
	U.box(visual, Vector3(0.3, 0.32, 0.3), Vector3.ZERO, Color("#ff3a5a"), 1.5)
	U.box(visual, Vector3(0.12, 0.14, 0.12), Vector3(0, 0.22, 0), Color("#c0e0ff"), 0.3)
	_launch(pos)


func _launch(pos: Vector3) -> void:
	Game.world.fx_root.add_child(self)
	global_position = pos + Vector3(0, 0.6, 0)
	var a := randf() * TAU
	vel = Vector3(cos(a), 0, sin(a)) * randf_range(1.0, 3.0) + Vector3(0, randf_range(4.0, 6.5), 0)


func _process(delta: float) -> void:
	age += delta
	var p = Game.player
	var g: float = Game.world.ground_at(global_position.x, global_position.z)
	if g < -500.0:
		g = global_position.y - 0.1
	if settle < 1.0:
		vel.y -= 18.0 * delta
		global_position += vel * delta
		if global_position.y <= g + 0.3:
			global_position.y = g + 0.3
			vel = Vector3.ZERO
			settle = 1.0
	if visual:
		visual.rotation.y += delta * 2.0
		visual.position.y = 0.15 + sin(age * 3.0) * 0.1 if settle >= 1.0 else 0.0
	if p == null or p.dead or age < 0.45:
		return
	var d: float = U.flat_dist(p.global_position, global_position)
	var magnet: float = State.stats.get("magnet", 2.5)
	if kind == "item":
		magnet = 1.4
	if d < magnet:
		var target: Vector3 = p.global_position + Vector3(0, 1.0, 0)
		global_position = global_position.move_toward(target, delta * (8.0 + (magnet - d) * 4.0))
		if global_position.distance_to(target) < 0.9:
			_collect()
	if age > 240.0 and kind == "res":
		queue_free()


func _collect() -> void:
	match kind:
		"res":
			var n := amount
			if res_id == "emerald":
				n = int(ceil(n * (1.0 + State.stats.get("emerald", 0.0)) * (3.0 if Game.player.has_powerup("golden") else 1.0)))
				Sfx.play("coin", 1.0, -8.0)
			else:
				Sfx.play("pickup", 1.0, -6.0)
				Game.toast("+%d %s" % [n, Data.resources[res_id]["name"]], Data.resources[res_id]["color"])
			State.add_resource(res_id, n)
		"item":
			if State.add_item(item):
				Sfx.play("pickup", 0.8)
				Game.toast("Found: %s %s" % [Data.RARITIES[item["rarity"]]["name"], State.item_name(item)], Data.rarity_color(item["rarity"]))
			else:
				Game.toast("Inventory full! Salvage some gear.", Color("#ff5a5a"))
				age = -2.0
				return
		"powerup":
			Game.player.add_powerup(powerup)
		"potion":
			State.potions += 1
			Sfx.play("pickup", 1.3)
			Game.toast("+1 Health Potion", Color("#ff5a7a"))
	queue_free()

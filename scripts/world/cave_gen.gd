## Procedural cave dungeon: rooms joined by corridors, with ore, chests, guardians and an exit portal.
extends RefCounted

const U = preload("res://scripts/core/util.gd")
const Mesher = preload("res://scripts/world/mesher.gd")

const CHUNK := 16
const CELL := 22
const GRID := 5
const WALL_H := 3

var is_cave := true
var dimdef: Dictionary
var dim_id := ""
var seed_v := 0
var sea := -10
var liquid := "none"
var biomes: Array = []
var arenas: Array = []
var cave_key := ""
var cave_name := ""
var level_bonus := 0

var W := GRID * CELL
var floor_map := PackedByteArray()
var room_of := PackedByteArray()
var rooms: Array = []
var start_room := 0
var end_room := 0
var floor_col: Color
var wall_col: Color
var wall_top: Color
var glow_col: Color

const NAMES := {"verdant": "Mossy Caverns", "ember": "Magma Tunnels", "frost": "Frozen Grotto", "spore": "Fungal Burrows", "void": "Abyssal Rift"}


func setup(d: Dictionary, s: int, key: String) -> void:
	dimdef = d
	dim_id = d["id"]
	biomes = d["biomes"]
	cave_key = key
	seed_v = hash(key) ^ s
	cave_name = NAMES.get(dim_id, "Caverns")
	var b: Dictionary = biomes[0]
	floor_col = U.vary(b["deep"], 0.2, 0.3)
	wall_col = U.vary(b["deep"], 0.25, 0.75)
	wall_top = Color(0.2, 0.18, 0.22)
	glow_col = {"verdant": Color("#7affb0"), "ember": Color("#ff7a2a"), "frost": Color("#9ce0ff"), "spore": Color("#9cff6a"), "void": Color("#d07aff")}[dim_id]
	_generate()


func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	floor_map.resize(W * W)
	floor_map.fill(0)
	room_of.resize(W * W)
	room_of.fill(255)
	rooms.clear()
	for gy in GRID:
		for gx in GRID:
			var w := rng.randi_range(9, 16)
			var h := rng.randi_range(9, 16)
			var x := gx * CELL + rng.randi_range(2, CELL - w - 2)
			var y := gy * CELL + rng.randi_range(2, CELL - h - 2)
			rooms.append(Rect2i(x, y, w, h))
	for i in rooms.size():
		var r: Rect2i = rooms[i]
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				floor_map[y * W + x] = 1
				room_of[y * W + x] = i
	# Random spanning tree over the room grid, plus a few loops.
	var visited := {0: true}
	var frontier: Array = [0]
	var edges: Array = []
	while visited.size() < rooms.size():
		var a: int = frontier[rng.randi() % frontier.size()]
		var ax := a % GRID
		var ay := a / GRID
		var nbs: Array = []
		for dxy in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = ax + dxy.x
			var ny: int = ay + dxy.y
			if nx >= 0 and ny >= 0 and nx < GRID and ny < GRID and not visited.has(ny * GRID + nx):
				nbs.append(ny * GRID + nx)
		if nbs.is_empty():
			frontier.erase(a)
			continue
		var b: int = nbs[rng.randi() % nbs.size()]
		visited[b] = true
		frontier.append(b)
		edges.append(Vector2i(a, b))
	for i in 4:
		var a := rng.randi() % rooms.size()
		var b := a + 1 if (a % GRID) < GRID - 1 else a - 1
		edges.append(Vector2i(a, b))
	for e in edges:
		_corridor(rooms[e.x].get_center(), rooms[e.y].get_center())
	start_room = 0
	# Farthest room by BFS distance becomes the guardian's chamber.
	var dist := {0: 0}
	var q: Array = [0]
	while not q.is_empty():
		var c: int = q.pop_front()
		for e in edges:
			var o := -1
			if e.x == c: o = e.y
			elif e.y == c: o = e.x
			if o >= 0 and not dist.has(o):
				dist[o] = dist[c] + 1
				q.append(o)
	end_room = 0
	for k in dist:
		if dist[k] > dist[end_room]:
			end_room = k


func _corridor(a: Vector2i, b: Vector2i) -> void:
	var x := a.x
	var y := a.y
	while x != b.x:
		_carve(x, y)
		x += signi(b.x - x)
	while y != b.y:
		_carve(x, y)
		y += signi(b.y - y)
	_carve(x, y)


func _carve(x: int, y: int) -> void:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var px := x + dx
			var py := y + dy
			if px > 0 and py > 0 and px < W - 1 and py < W - 1:
				floor_map[py * W + px] = 1


func is_floor(x: int, z: int) -> bool:
	if x < 0 or z < 0 or x >= W or z >= W:
		return false
	return floor_map[z * W + x] == 1


func height_info(x: int, z: int) -> Vector3i:
	if is_floor(x, z):
		return Vector3i(0, 0, 0)
	return Vector3i(WALL_H, 0, 0)


func ground_from_info(info: Vector3i) -> float:
	return float(info.x) if info.x == 0 else -1000.0


func region_name(_fx: float, _fz: float) -> String:
	return cave_name


func map_color(x: int, z: int) -> Color:
	return Color(0.45, 0.42, 0.4) if is_floor(x, z) else Color(0.08, 0.07, 0.09)


func spawn_point() -> Vector3:
	var c: Vector2i = rooms[start_room].get_center()
	return Vector3(c.x + 0.5, 0, c.y + 2.5)


func village_for_pos(_fx: float, _fz: float) -> Dictionary:
	return {}


func villages_near(_p: Vector3, _r: float) -> Array:
	return []


func find_nearest_poi(type: String, _from: Vector3, _r := 0.0) -> Dictionary:
	if type == "cave_exit":
		var c: Vector2i = rooms[end_room].get_center()
		return {"x": c.x + 0.5, "z": c.y + 0.5}
	return {}


func begin_chunk(cx: int, cz: int) -> Dictionary:
	return {"cx": cx, "cz": cz, "out": {}}


func step_chunk(job: Dictionary, _rows: int) -> bool:
	job["out"] = build_chunk(job["cx"], job["cz"])
	return true


func build_chunk(cx: int, cz: int) -> Dictionary:
	var ox := cx * CHUNK
	var oz := cz * CHUNK
	var out := {"heights": PackedFloat32Array(), "blocked": {}, "interact": [], "people": [], "lights": [], "spawns": [], "elite": []}
	out["heights"].resize(CHUNK * CHUNK)
	var cols := PackedColorArray()
	cols.resize(CHUNK * CHUNK)
	out["colors"] = cols
	var m := Mesher.new()
	var any_floor := false
	for j in CHUNK:
		for i in CHUNK:
			var x := ox + i
			var z := oz + j
			var fl := is_floor(x, z)
			out["heights"][j * CHUNK + i] = 0.0 if fl else -1000.0
			cols[j * CHUNK + i] = floor_col.lightened(0.2) if fl else Color(0.06, 0.05, 0.07)
			var t := U.hashf(x, z, seed_v)
			if fl:
				any_floor = true
				var c := U.vary(floor_col, 0.08, t)
				m.quad(Vector3(x, 0, z), Vector3(x + 1, 0, z), Vector3(x + 1, 0, z + 1), Vector3(x, 0, z + 1), Vector3.UP, c)
				if t > 0.985:
					m.box(Vector3(x + 0.3, 0, z + 0.3), Vector3(x + 0.7, 0.25, z + 0.6), Color("#e8e2cf"))
			else:
				var near := is_floor(x + 1, z) or is_floor(x - 1, z) or is_floor(x, z + 1) or is_floor(x, z - 1)
				if not near:
					m.quad(Vector3(x, WALL_H, z), Vector3(x + 1, WALL_H, z), Vector3(x + 1, WALL_H, z + 1), Vector3(x, WALL_H, z + 1), Vector3.UP, wall_top)
					continue
				var wc := U.vary(wall_col, 0.1, t)
				m.box(Vector3(x, 0, z), Vector3(x + 1, WALL_H, z + 1), wc)
				m.quad(Vector3(x, WALL_H + 0.01, z), Vector3(x + 1, WALL_H + 0.01, z), Vector3(x + 1, WALL_H + 0.01, z + 1), Vector3(x, WALL_H + 0.01, z + 1), Vector3.UP, wall_top)
				if t > 0.93:
					var gc := Color(glow_col.r, glow_col.g, glow_col.b, 0.0)
					m.box(Vector3(x - 0.05, 1.0, z + 0.3), Vector3(x + 1.05, 1.5, z + 0.7), gc)
					if t > 0.975:
						out["lights"].append({"pos": Vector3(x + 0.5, 2.0, z + 0.5), "color": glow_col, "range": 7.0})
	if not any_floor:
		out["mesh"] = null if m.is_empty() else m.commit(Mesher.terrain_material())
		out["liquid"] = null
		out["props"] = null
		return out
	var rng := RandomNumberGenerator.new()
	for ri in rooms.size():
		var r: Rect2i = rooms[ri]
		var c := r.get_center()
		if c.x < ox or c.x >= ox + CHUNK or c.y < oz or c.y >= oz + CHUNK:
			continue
		rng.seed = seed_v + ri * 31
		var torch := Vector3(c.x + 0.5, 2.6, c.y + 0.5)
		out["lights"].append({"pos": torch, "color": Color("#ffb070"), "range": 12.0})
		if ri == start_room:
			out["interact"].append({"type": "cave_exit", "pos": Vector3(c.x + 0.5, 0, c.y - 1.5), "key": cave_key, "final": false})
			_portal(m, Vector3(c.x + 0.5, 0, c.y - 1.5), Color(0.5, 0.8, 1.0, 0.0))
			continue
		if ri == end_room:
			out["interact"].append({"type": "cave_exit", "pos": Vector3(c.x + 0.5, 0, c.y - 2.5), "key": cave_key, "final": true})
			_portal(m, Vector3(c.x + 0.5, 0, c.y - 2.5), Color(1.0, 0.85, 0.4, 0.0))
			var ck := "%s:end" % cave_key
			if not State.opened.has(ck):
				out["interact"].append({"type": "chest", "pos": Vector3(c.x + 3.5, 0, c.y + 1.5), "key": ck, "tier": 3})
			out["elite"].append(Vector3(c.x + 0.5, 0, c.y + 2.5))
			for s in 3:
				out["spawns"].append(Vector3(c.x - 3.5 + s * 3, 0, c.y + 4.5))
			continue
		var n := rng.randi_range(1, 3)
		for s in n:
			out["spawns"].append(Vector3(r.position.x + rng.randi_range(2, r.size.x - 2) + 0.5, 0, r.position.y + rng.randi_range(2, r.size.y - 2) + 0.5))
		if rng.randf() < 0.45:
			var ck := "%s:c%d" % [cave_key, ri]
			if not State.opened.has(ck):
				out["interact"].append({"type": "chest", "pos": Vector3(r.position.x + 1.5, 0, r.position.y + 1.5), "key": ck, "tier": 2})
		if rng.randf() < 0.75:
			var ok := "%s:o%d" % [cave_key, ri]
			var res: Array = dimdef["resources"]
			var rid: String = res[2 + rng.randi() % 3]
			if not State.opened.has(ok):
				out["interact"].append({"type": "ore", "pos": Vector3(r.end.x - 1.5, 0, r.position.y + 1.5), "key": ok, "res": rid, "color": Data.resources[rid]["color"]})
		# Stalagmites for cover.
		for s in rng.randi_range(1, 3):
			var sx := r.position.x + rng.randi_range(2, r.size.x - 3)
			var sz := r.position.y + rng.randi_range(2, r.size.y - 3)
			if Vector2(sx - c.x, sz - c.y).length() < 2.5:
				continue
			var sh := rng.randf_range(1.0, 2.6)
			m.box(Vector3(sx, 0, sz), Vector3(sx + 1, sh, sz + 1), U.vary(wall_col, 0.1, rng.randf()))
			m.box(Vector3(sx + 0.25, sh, sz + 0.25), Vector3(sx + 0.75, sh + 0.8, sz + 0.75), U.vary(wall_col, 0.1, rng.randf()))
			out["blocked"][Vector2i(sx, sz)] = true
	out["mesh"] = m.commit(Mesher.terrain_material())
	out["liquid"] = null
	out["props"] = null
	return out


func _portal(m: Mesher, p: Vector3, c: Color) -> void:
	var fc := Color("#2a1f3a")
	m.box(Vector3(p.x - 1.8, 0, p.z - 0.3), Vector3(p.x - 1.2, 3.4, p.z + 0.3), fc)
	m.box(Vector3(p.x + 1.2, 0, p.z - 0.3), Vector3(p.x + 1.8, 3.4, p.z + 0.3), fc)
	m.box(Vector3(p.x - 1.8, 3.4, p.z - 0.3), Vector3(p.x + 1.8, 4.0, p.z + 0.3), fc)
	m.box(Vector3(p.x - 1.2, 0, p.z - 0.1), Vector3(p.x + 1.2, 3.4, p.z + 0.1), c)

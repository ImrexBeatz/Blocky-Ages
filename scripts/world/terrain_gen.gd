## Infinite deterministic realm generator: terrain, biomes, villages, boss lairs and points of interest.
extends RefCounted

const U = preload("res://scripts/core/util.gd")
const Mesher = preload("res://scripts/world/mesher.gd")

const CHUNK := 16
const VCELL := 288
const VRADIUS := 30.0
const VBLEND := 16.0
const PCELL := 40
const ARENA_R := 17.0

var is_cave := false
var dimdef: Dictionary
var dim_id := ""
var seed_v := 0
var biomes: Array = []
var sea := 2
var liquid := "water"

var n_height := FastNoiseLite.new()
var n_detail := FastNoiseLite.new()
var n_biome := FastNoiseLite.new()
var n_river := FastNoiseLite.new()
var n_void := FastNoiseLite.new()

var village_cache := {}
var poi_cache := {}
var arenas: Array = []


func setup(d: Dictionary, s: int) -> void:
	dimdef = d
	dim_id = d["id"]
	seed_v = s + int(Data.dim_index[dim_id]) * 7919
	biomes = d["biomes"]
	sea = d["sea"]
	liquid = d["liquid"]
	n_height.seed = seed_v
	n_height.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n_height.frequency = 1.0 / 110.0
	n_height.fractal_type = FastNoiseLite.FRACTAL_FBM
	n_height.fractal_octaves = 4
	n_detail.seed = seed_v + 11
	n_detail.frequency = 1.0 / 22.0
	n_biome.seed = seed_v + 23
	n_biome.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n_biome.frequency = 1.0 / 420.0
	n_biome.fractal_octaves = 2
	n_biome.domain_warp_enabled = true
	n_biome.domain_warp_amplitude = 60.0
	n_biome.domain_warp_frequency = 0.01
	n_river.seed = seed_v + 37
	n_river.frequency = 1.0 / 260.0
	n_river.fractal_octaves = 2
	n_void.seed = seed_v + 53
	n_void.frequency = 1.0 / 38.0
	n_void.fractal_octaves = 2
	_place_arenas()


# ---------------------------------------------------------------- terrain

func biome_value(fx: float, fz: float) -> float:
	return clampf(n_biome.get_noise_2d(fx, fz) * 1.7 * 0.5 + 0.5, 0.0, 0.9999)


func biome_index(fx: float, fz: float) -> int:
	return int(biome_value(fx, fz) * biomes.size())


func _blend_param(bv: float, key: String, fallback: float) -> float:
	var nb := biomes.size()
	var p := bv * nb - 0.5
	var i0 := clampi(int(floor(p)), 0, nb - 1)
	var i1 := clampi(i0 + 1, 0, nb - 1)
	var t := clampf(p - floor(p), 0.0, 1.0)
	if p < 0.0:
		t = 0.0
	var a: float = biomes[i0].get(key, fallback)
	var b: float = biomes[i1].get(key, fallback)
	return lerpf(a, b, smoothstep(0.0, 1.0, t))


func _raw_height(fx: float, fz: float) -> float:
	var bv := biome_value(fx, fz)
	var amp := _blend_param(bv, "amp", 5.0)
	var wet := _blend_param(bv, "wetness", 0.0)
	var h := 7.0 + n_height.get_noise_2d(fx, fz) * amp * 1.6 + n_detail.get_noise_2d(fx, fz) * 1.4 - wet * 3.0
	if liquid == "water" or liquid == "toxic" or liquid == "lava":
		var rv := absf(n_river.get_noise_2d(fx, fz))
		if rv < 0.04:
			h = minf(h, lerpf(sea - 2.0, h, rv / 0.04))
	return h


## Returns Vector3i(height, biome, kind) where kind: 0 land, 1 liquid, 2 void, 3 ice.
func height_info(x: int, z: int) -> Vector3i:
	var fx := float(x) + 0.5
	var fz := float(z) + 0.5
	var h := _raw_height(fx, fz)
	var prot := 0.0
	var vil := village_for_pos(fx, fz)
	if not vil.is_empty():
		var d := Vector2(fx - vil["x"], fz - vil["z"]).length()
		var t := smoothstep(VRADIUS, VRADIUS + VBLEND, d)
		h = lerpf(vil["base"], h, t)
		prot = 1.0 - t
	for a in arenas:
		var d := Vector2(fx - a["x"], fz - a["z"]).length()
		if d < ARENA_R + 12.0:
			var t := smoothstep(ARENA_R, ARENA_R + 12.0, d)
			h = lerpf(a["base"], h, t)
			prot = maxf(prot, 1.0 - t)
	var hi := int(floor(h))
	var bi := biome_index(fx, fz)
	var kind := 0
	if liquid == "void":
		var gaps: float = biomes[bi].get("void_gaps", 0.3)
		var vn := n_void.get_noise_2d(fx, fz) * 0.5 + 0.5
		var r := Vector2(fx, fz).length()
		if prot < 0.4 and r > 40.0 and vn < gaps * 0.75:
			kind = 2
	elif hi < sea and prot < 0.5:
		kind = 1
		if liquid == "ice":
			kind = 3
			hi = sea
	if prot >= 0.5 and hi < sea:
		hi = sea
	return Vector3i(hi, bi, kind)


## Height an entity stands at; returns -1000 for impassable (void/lava).
func ground_from_info(info: Vector3i) -> float:
	match info.z:
		1:
			if liquid == "lava":
				return -1000.0
			return float(sea) - 0.45
		2:
			return -1000.0
	return float(info.x)


func region_name(fx: float, fz: float) -> String:
	var vil := village_for_pos(fx, fz)
	if not vil.is_empty() and Vector2(fx - vil["x"], fz - vil["z"]).length() < VRADIUS + 6.0:
		return vil["name"]
	for a in arenas:
		if Vector2(fx - a["x"], fz - a["z"]).length() < ARENA_R + 4.0:
			return "Lair of " + Data.bosses[a["boss"]]["name"]
	return biomes[biome_index(fx, fz)]["name"]


func map_color(x: int, z: int) -> Color:
	var info := height_info(x, z)
	if info.z == 2:
		return Color(0.02, 0.0, 0.05)
	if info.z == 1:
		return dimdef["liquid_color"] * Color(1, 1, 1, 1)
	var b: Dictionary = biomes[info.y]
	var c: Color = b["top"]
	if info.z == 3:
		c = Color("#bfe0f5")
	var shade := clampf(0.75 + (info.x - sea) * 0.025, 0.55, 1.25)
	return Color(c.r * shade, c.g * shade, c.b * shade)


# ---------------------------------------------------------------- villages & arenas

func _place_arenas() -> void:
	arenas.clear()
	var bl: Array = dimdef["bosses"]
	for i in bl.size():
		var ang := deg_to_rad(35.0 + i * 90.0 + U.hashf(i, 3, seed_v) * 40.0)
		var r := 170.0 + i * 120.0
		var x := cos(ang) * r
		var z := sin(ang) * r
		var base := maxf(_raw_height(x, z), float(sea) + 1.0)
		if liquid == "void":
			base = maxf(base, 6.0)
		arenas.append({"boss": bl[i], "x": x, "z": z, "base": floor(base), "index": i})


func village_in_cell(cx: int, cz: int) -> Dictionary:
	var key := Vector2i(cx, cz)
	if village_cache.has(key):
		return village_cache[key]
	var v := {}
	var origin := cx == 0 and cz == 0
	var forbidden := (cx == -1 and cz == -1) or (cx == -1 and cz == 0) or (cx == 0 and cz == -1)
	if origin or (not forbidden and U.hashf(cx, cz, seed_v + 101) < 0.62):
		var x := 0.0
		var z := 0.0
		if not origin:
			x = cx * VCELL + 60.0 + U.hashf(cx, cz, seed_v + 7) * (VCELL - 120.0)
			z = cz * VCELL + 60.0 + U.hashf(cx, cz, seed_v + 9) * (VCELL - 120.0)
		var ok := true
		for a in arenas:
			if Vector2(x - a["x"], z - a["z"]).length() < 85.0:
				ok = false
		if ok or origin:
			var base := maxf(_raw_height(x, z), float(sea) + 1.0)
			if liquid == "void":
				base = maxf(base, 6.0)
			var names: Array = dimdef["village_names"]
			var suf: Array = dimdef["village_suffix"]
			var nm: String = names[U.hash2(cx, cz, seed_v + 3) % names.size()] + suf[U.hash2(cx, cz, seed_v + 5) % suf.size()]
			if origin:
				nm = {"verdant": "Oakhollow", "ember": "Cinderhold", "frost": "Frosthearth", "spore": "Glowcap Dell", "void": "Starkeep Anchor"}.get(dim_id, nm)
			v = {"cx": cx, "cz": cz, "x": x, "z": z, "base": floor(base), "name": nm, "origin": origin, "key": "%s:%d:%d" % [dim_id, cx, cz]}
	village_cache[key] = v
	return v


func village_for_pos(fx: float, fz: float) -> Dictionary:
	if fx * fx + fz * fz < (VRADIUS + VBLEND) * (VRADIUS + VBLEND):
		return village_in_cell(0, 0)
	var v := village_in_cell(int(floor(fx / VCELL)), int(floor(fz / VCELL)))
	if v.is_empty():
		return v
	if Vector2(fx - v["x"], fz - v["z"]).length() > VRADIUS + VBLEND:
		return {}
	return v


func villages_near(p: Vector3, radius: float) -> Array:
	var out: Array = []
	var c0 := int(floor((p.x - radius) / VCELL))
	var c1 := int(floor((p.x + radius) / VCELL))
	var r0 := int(floor((p.z - radius) / VCELL))
	var r1 := int(floor((p.z + radius) / VCELL))
	for cx in range(c0, c1 + 1):
		for cz in range(r0, r1 + 1):
			var v := village_in_cell(cx, cz)
			if not v.is_empty() and Vector2(p.x - v["x"], p.z - v["z"]).length() < radius:
				out.append(v)
	var o := village_in_cell(0, 0)
	if not o in out and Vector2(p.x, p.z).length() < radius:
		out.append(o)
	return out


func _village_layout(v: Dictionary) -> Dictionary:
	if v.has("layout"):
		return v["layout"]
	var rng := RandomNumberGenerator.new()
	rng.seed = U.hash2(v["cx"], v["cz"], seed_v + 999)
	var pieces: Array = []
	var people: Array = []
	var cx: float = v["x"]
	var cz: float = v["z"]
	var by: float = v["base"]
	pieces.append({"type": "center", "x": cx, "z": cz, "y": by, "origin": v["origin"]})
	pieces.append({"type": "gate", "x": cx, "z": cz + 9.5, "y": by})
	pieces.append({"type": "board", "x": cx + 5.5, "z": cz - 4.0, "y": by})
	var n := rng.randi_range(5, 8)
	var start := rng.randf() * TAU
	var doors: Array = []
	for i in n:
		var ang := start + TAU * i / n + rng.randf_range(-0.15, 0.15)
		# Keep the south side (gate) open.
		if absf(wrapf(ang - PI * 0.5, -PI, PI)) < 0.35:
			ang += 0.5
		var r := rng.randf_range(15.0, 22.0)
		var hx := floorf(cx + cos(ang) * r)
		var hz := floorf(cz + sin(ang) * r)
		var w := rng.randi_range(5, 7)
		var d := rng.randi_range(5, 7)
		var door_x := hx + w / 2
		var door_z := hz + d / 2
		var face := Vector2(cx - hx, cz - hz)
		var dir := 0
		if absf(face.x) > absf(face.y):
			dir = 0 if face.x > 0 else 1
			door_x = hx + (w if dir == 0 else -1)
			door_z = hz + d / 2
		else:
			dir = 2 if face.y > 0 else 3
			door_z = hz + (d if dir == 2 else -1)
			door_x = hx + w / 2
		pieces.append({"type": "house", "x": hx, "z": hz, "w": w, "d": d, "y": by, "dir": dir, "h": rng.randi_range(4, 5), "variant": rng.randi() % 3})
		doors.append(Vector2(door_x + 0.5, door_z + 0.5))
	for i in 4:
		var ang := start + PI / 4 + TAU * i / 4
		pieces.append({"type": "lamp", "x": floor(cx + cos(ang) * 10.0), "z": floor(cz + sin(ang) * 10.0), "y": by})
	if rng.randf() < 0.7:
		var ang := start + PI / n
		pieces.append({"type": "farm", "x": floor(cx + cos(ang) * 26.0) - 3, "z": floor(cz + sin(ang) * 26.0) - 2, "y": by})
	var roles := ["elder", "blacksmith", "merchant", "enchanter", "mystic", "alchemist"]
	var extras := ["farmer", "guard", "cartographer", "bard", "guard", "farmer"]
	for i in rng.randi_range(2, 4):
		roles.append(extras[rng.randi() % extras.size()])
	for i in roles.size():
		var p: Vector2 = doors[i % doors.size()] if i < doors.size() else Vector2(cx + rng.randf_range(-7, 7), cz + rng.randf_range(-7, 7))
		var nm: String = Story.VILLAGER_FIRST[rng.randi() % Story.VILLAGER_FIRST.size()]
		people.append({"role": roles[i], "name": nm, "x": p.x, "z": p.y, "y": by, "seed": rng.randi()})
	var layout := {"pieces": pieces, "people": people, "doors": doors}
	v["layout"] = layout
	return layout


func _on_path(v: Dictionary, fx: float, fz: float) -> bool:
	var lay := _village_layout(v)
	var c := Vector2(v["x"], v["z"])
	var p := Vector2(fx, fz)
	if p.distance_to(c) < 7.0:
		return true
	for d in lay["doors"]:
		var seg: Vector2 = d - c
		var t := clampf((p - c).dot(seg) / seg.length_squared(), 0.0, 1.0)
		if p.distance_to(c + seg * t) < 1.1:
			return true
	var gate := c + Vector2(0, 9.5)
	if absf(p.x - c.x) < 1.1 and p.y > c.y and p.y < gate.y:
		return true
	return false


# ---------------------------------------------------------------- points of interest

func poi_in_cell(px: int, pz: int) -> Dictionary:
	var key := Vector2i(px, pz)
	if poi_cache.has(key):
		return poi_cache[key]
	var poi := {}
	var r := U.hashf(px, pz, seed_v + 77)
	var type := ""
	if r < 0.10: type = "cave"
	elif r < 0.19: type = "chest"
	elif r < 0.245: type = "lore"
	elif r < 0.30: type = "shrine"
	elif r < 0.41: type = "ore"
	elif r < 0.49: type = "crate"
	elif r < 0.54: type = "camp"
	var x: float = px * PCELL + 6.0 + floorf(U.hashf(px, pz, seed_v + 78) * 28.0)
	var z: float = pz * PCELL + 6.0 + floorf(U.hashf(px, pz, seed_v + 79) * 28.0)
	# Guaranteed early discoveries near the starting village.
	if px == 1 and pz == 1:
		type = "cave"; x = 62.0; z = 58.0
	elif px == -2 and pz == 1:
		type = "lore"; x = -58.0; z = 64.0
	elif px == 1 and pz == -2:
		type = "shrine"; x = 52.0; z = -62.0
	elif px == -2 and pz == -2:
		type = "lore"; x = -66.0; z = -60.0
	if type != "":
		var ok := village_for_pos(x, z).is_empty()
		for a in arenas:
			if Vector2(x - a["x"], z - a["z"]).length() < ARENA_R + 16.0:
				ok = false
		var info := height_info(int(x), int(z))
		if info.z != 0 and info.z != 3:
			ok = false
		if ok:
			var sub := ""
			var res: Array = dimdef["resources"]
			if type == "ore":
				sub = res[2 + U.hash2(px, pz, seed_v + 80) % 3]
			elif type == "crate":
				sub = res[U.hash2(px, pz, seed_v + 81) % 2]
			poi = {"type": type, "x": x + 0.5, "z": z + 0.5, "y": float(info.x), "key": "%s:%d:%d" % [dim_id, px, pz], "sub": sub}
	poi_cache[key] = poi
	return poi


func pois_in_rect(x0: float, z0: float, x1: float, z1: float) -> Array:
	var out: Array = []
	for px in range(int(floor(x0 / PCELL)), int(floor(x1 / PCELL)) + 1):
		for pz in range(int(floor(z0 / PCELL)), int(floor(z1 / PCELL)) + 1):
			var p := poi_in_cell(px, pz)
			if not p.is_empty() and p["x"] >= x0 and p["x"] < x1 and p["z"] >= z0 and p["z"] < z1:
				out.append(p)
	return out


func find_nearest_poi(type: String, from: Vector3, max_r := 400.0) -> Dictionary:
	var best := {}
	var bd := INF
	var c := Vector2i(int(floor(from.x / PCELL)), int(floor(from.z / PCELL)))
	var rad := int(max_r / PCELL)
	for ring in range(0, rad + 1):
		for px in range(c.x - ring, c.x + ring + 1):
			for pz in range(c.y - ring, c.y + ring + 1):
				if maxi(absi(px - c.x), absi(pz - c.y)) != ring:
					continue
				var p := poi_in_cell(px, pz)
				if p.is_empty() or p["type"] != type:
					continue
				if type == "lore" and State.opened.has(p["key"]):
					continue
				if type == "shrine" and State.opened.has(p["key"]):
					continue
				var d := Vector2(p["x"] - from.x, p["z"] - from.z).length()
				if d < bd:
					bd = d
					best = p
		if not best.is_empty() and bd < (ring - 1) * PCELL:
			return best
	return best


func spawn_point() -> Vector3:
	var v := village_in_cell(0, 0)
	return Vector3(v["x"] + 3.5, v["base"], v["z"] + 6.0)


# ---------------------------------------------------------------- chunk building

func build_chunk(cx: int, cz: int) -> Dictionary:
	var ox := cx * CHUNK
	var oz := cz * CHUNK
	var S := CHUNK + 2
	var H := PackedInt32Array()
	H.resize(S * S)
	var K := PackedByteArray()
	K.resize(S * S)
	var B := PackedByteArray()
	B.resize(S * S)
	for j in S:
		for i in S:
			var info := height_info(ox + i - 1, oz + j - 1)
			var k := j * S + i
			H[k] = info.x
			B[k] = info.y
			K[k] = info.z
	var m := Mesher.new()
	var lm := Mesher.new()
	var out := {"heights": PackedFloat32Array(), "blocked": {}, "interact": [], "people": [], "lights": [], "spawns": [], "decor": []}
	out["heights"].resize(CHUNK * CHUNK)
	var cols := PackedColorArray()
	cols.resize(CHUNK * CHUNK)
	out["colors"] = cols
	var vil_here := village_for_pos(ox + 8.0, oz + 8.0)
	var lq: Color = dimdef["liquid_color"]
	for j in range(1, S - 1):
		for i in range(1, S - 1):
			var k := j * S + i
			var x := ox + i - 1
			var z := oz + j - 1
			var h := H[k]
			var kind := K[k]
			var b: Dictionary = biomes[B[k]]
			out["heights"][(j - 1) * CHUNK + (i - 1)] = ground_from_info(Vector3i(h, B[k], kind))
			if kind == 2:
				cols[(j - 1) * CHUNK + (i - 1)] = Color(0.03, 0.0, 0.06)
				continue
			var t := U.hashf(x, z, seed_v)
			var top: Color = U.vary(b["top"], 0.05, t)
			var side: Color = b["side"]
			var deep: Color = b["deep"]
			if kind == 1:
				top = U.vary(deep, 0.08, t)
			elif kind == 3:
				top = U.vary(Color("#bfe0f5"), 0.04, t)
				side = Color("#9cc8f0")
			var fx := x + 0.5
			var fz := z + 0.5
			var vil := village_for_pos(fx, fz)
			if not vil.is_empty() and _on_path(vil, fx, fz):
				top = U.vary(Color("#9a8a6a") if dim_id != "void" else Color("#8a7aa8"), 0.08, t)
			for a in arenas:
				var ad := Vector2(fx - a["x"], fz - a["z"]).length()
				if ad < ARENA_R:
					var check := (int(floor(fx / 2.0)) + int(floor(fz / 2.0))) % 2 == 0
					top = U.vary(Color("#6e6a72") if check else Color("#5a5660"), 0.05, t)
					if ad > ARENA_R - 1.5:
						top = Color("#3a3640")
			var shade := clampf(0.8 + (h - sea) * 0.02, 0.6, 1.2)
			cols[(j - 1) * CHUNK + (i - 1)] = (lq if kind == 1 else top) * Color(shade, shade, shade, 1.0)
			# Top face with simple ambient occlusion from taller neighbours.
			var ao := Vector4(1, 1, 1, 1)
			var nW := H[k - 1] > h
			var nE := H[k + 1] > h
			var nN := H[k - S] > h
			var nS := H[k + S] > h
			ao.x = _ao(nW, nN, H[k - S - 1] > h)
			ao.y = _ao(nE, nN, H[k - S + 1] > h)
			ao.z = _ao(nE, nS, H[k + S + 1] > h)
			ao.w = _ao(nW, nS, H[k + S - 1] > h)
			var fy := float(h)
			m.quad(Vector3(x, fy, z), Vector3(x + 1, fy, z), Vector3(x + 1, fy, z + 1), Vector3(x, fy, z + 1), Vector3.UP, top, 1, 1, ao)
			_sides(m, x, z, h, [H[k + 1], H[k - 1], H[k + S], H[k - S]], [K[k + 1], K[k - 1], K[k + S], K[k - S]], side, deep, t)
			if kind == 1:
				var ly := float(sea) - (0.3 if liquid == "lava" else 0.12)
				lm.quad(Vector3(x, ly, z), Vector3(x + 1, ly, z), Vector3(x + 1, ly, z + 1), Vector3(x, ly, z + 1), Vector3.UP, Color(1, 1, 1, 1))
				continue
			# Vegetation and decoration.
			var prot := not vil.is_empty() or _near_arena(fx, fz, 4.0)
			var tr := U.hashf(x, z, seed_v + 13)
			if not prot and kind == 0 and tr < float(b["trees"]) and _flat_enough(H, k, S):
				_tree(m, b["tree"], x, h, z, U.hash2(x, z, seed_v + 17), out)
			elif kind == 0 and tr > 1.0 - float(b.get("flowers", 0.0)) and not prot:
				var fc: Color = [Color("#e83a3a"), Color("#f5d63a"), Color("#ffffff"), Color("#5a8aff"), Color("#d65ad6")][U.hash2(x, z, 5) % 5]
				m.box(Vector3(x + 0.45, fy, z + 0.45), Vector3(x + 0.55, fy + 0.35, z + 0.55), Color("#3a7a2a"))
				m.box(Vector3(x + 0.38, fy + 0.35, z + 0.38), Vector3(x + 0.62, fy + 0.55, z + 0.62), fc)
			elif kind == 0 and b.has("glow") and tr > 0.965 and not prot:
				var gc: Color = b["glow"]
				m.box(Vector3(x + 0.42, fy, z + 0.42), Vector3(x + 0.58, fy + 0.3, z + 0.58), Color("#d8d0c0"))
				m.box(Vector3(x + 0.3, fy + 0.3, z + 0.3), Vector3(x + 0.7, fy + 0.5, z + 0.7), Color(gc.r, gc.g, gc.b, 0.0))
	# Structures anchored in this chunk.
	if true:
		for v in villages_near(Vector3(ox + 8, 0, oz + 8), 60.0):
			var lay := _village_layout(v)
			for p in lay["pieces"]:
				if p["x"] >= ox and p["x"] < ox + CHUNK and p["z"] >= oz and p["z"] < oz + CHUNK:
					_build_piece(m, p, v, out)
			for person in lay["people"]:
				if person["x"] >= ox and person["x"] < ox + CHUNK and person["z"] >= oz and person["z"] < oz + CHUNK:
					var pp: Dictionary = person.duplicate()
					pp["village"] = v["name"]
					pp["vkey"] = v["key"]
					out["people"].append(pp)
	for a in arenas:
		_arena_pieces(m, a, ox, oz, out)
	for p in pois_in_rect(ox, oz, ox + CHUNK, oz + CHUNK):
		_build_poi(m, p, out)
	# Enemy spawn points (none in villages or arenas).
	if vil_here.is_empty():
		var dens := 0.55 + clampf(Vector2(ox, oz).length() / 600.0, 0.0, 0.6)
		var n := 0
		var roll := U.hashf(cx, cz, seed_v + 400)
		if roll < dens:
			n = 1
		if roll < dens * 0.35:
			n = 2
		for s in n:
			var sx := ox + 2 + U.hash2(cx, cz, seed_v + 401 + s) % 12
			var sz := oz + 2 + U.hash2(cx, cz, seed_v + 409 + s) % 12
			var si := (sz - oz + 1) * S + (sx - ox + 1)
			if K[si] == 0 or K[si] == 3:
				out["spawns"].append(Vector3(sx + 0.5, H[si], sz + 0.5))
	out["mesh"] = null if m.is_empty() else m.commit(Mesher.terrain_material())
	out["liquid"] = null if lm.is_empty() else lm.commit(Mesher.liquid_material(liquid, lq))
	return out


func _ao(a: bool, b: bool, c: bool) -> float:
	if a and b:
		return 0.55
	return 1.0 - 0.15 * (int(a) + int(b) + int(c))


func _flat_enough(H: PackedInt32Array, k: int, S: int) -> bool:
	var h := H[k]
	return absi(H[k + 1] - h) <= 1 and absi(H[k - 1] - h) <= 1 and absi(H[k + S] - h) <= 1 and absi(H[k - S] - h) <= 1


func _near_arena(fx: float, fz: float, extra: float) -> bool:
	for a in arenas:
		if Vector2(fx - a["x"], fz - a["z"]).length() < ARENA_R + extra:
			return true
	return false


func _sides(m: Mesher, x: int, z: int, h: int, nh: Array, nk: Array, side: Color, deep: Color, t: float) -> void:
	var dirs := [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]
	for d in 4:
		var other: int = nh[d]
		if nk[d] == 2:
			other = h - 7
		if other >= h:
			continue
		var lo := maxi(other, h - 14)
		for y in range(h - 1, lo - 1, -1):
			var c: Color = side if y == h - 1 else deep
			c = U.vary(c, 0.05, U.hashf(x * 3 + d, y, z))
			var shade := 0.88 if d < 2 else 0.78
			if y < h - 4:
				shade *= 0.9
			c = Color(c.r * shade, c.g * shade, c.b * shade, 1.0)
			var y0 := float(y)
			var y1 := float(y + 1)
			match d:
				0: m.quad(Vector3(x + 1, y0, z), Vector3(x + 1, y1, z), Vector3(x + 1, y1, z + 1), Vector3(x + 1, y0, z + 1), Vector3.RIGHT, c)
				1: m.quad(Vector3(x, y0, z), Vector3(x, y1, z), Vector3(x, y1, z + 1), Vector3(x, y0, z + 1), Vector3.LEFT, c)
				2: m.quad(Vector3(x, y0, z + 1), Vector3(x + 1, y0, z + 1), Vector3(x + 1, y1, z + 1), Vector3(x, y1, z + 1), Vector3.BACK, c)
				3: m.quad(Vector3(x, y0, z), Vector3(x + 1, y0, z), Vector3(x + 1, y1, z), Vector3(x, y1, z), Vector3.FORWARD, c)


# ---------------------------------------------------------------- vegetation

func _leaf_blob(m: Mesher, cx: float, cy: float, cz: float, r: int, hgt: int, c: Color, hsh: int) -> void:
	for dy in hgt:
		var rr := r - (1 if dy == hgt - 1 else 0)
		for dx in range(-rr, rr + 1):
			for dz in range(-rr, rr + 1):
				if absi(dx) == rr and absi(dz) == rr and (hsh + dx * 3 + dz + dy) % 3 != 0:
					continue
				var cc := U.vary(c, 0.08, U.hashf(dx + hsh, dy, dz))
				m.box(Vector3(cx + dx, cy + dy, cz + dz), Vector3(cx + dx + 1, cy + dy + 1, cz + dz + 1), cc)


func _tree(m: Mesher, type: String, x: int, h: int, z: int, hsh: int, out: Dictionary) -> void:
	var fx := float(x)
	var fz := float(z)
	var fy := float(h)
	var blocked: Dictionary = out["blocked"]
	match type:
		"oak", "swamp":
			var th := 4 + hsh % 3
			m.box(Vector3(fx, fy, fz), Vector3(fx + 1, fy + th, fz + 1), Color("#6b4a2b"))
			var lc := Color("#3f8a2a") if type == "oak" else Color("#4a7a2a")
			_leaf_blob(m, fx, fy + th - 1, fz, 2, 2, lc, hsh)
			_leaf_blob(m, fx, fy + th + 1, fz, 1, 1, lc, hsh + 1)
			if type == "swamp":
				for vv in 3:
					var vx: float = fx + [-2, 2, 0][vv]
					var vz: float = fz + [0, 1, -2][vv]
					m.box(Vector3(vx + 0.4, fy + th - 3, vz + 0.4), Vector3(vx + 0.6, fy + th - 1, vz + 0.6), Color("#2a4a1a"))
			blocked[Vector2i(x, z)] = true
		"birch":
			var th := 5 + hsh % 3
			m.box(Vector3(fx, fy, fz), Vector3(fx + 1, fy + th, fz + 1), Color("#e8e4d8"))
			for s in 3:
				var sy := fy + 1 + (hsh + s * 2) % th
				m.box(Vector3(fx - 0.01, sy, fz + 0.3), Vector3(fx + 1.01, sy + 0.3, fz + 0.6), Color("#2a2a2a"))
			_leaf_blob(m, fx, fy + th - 1, fz, 1, 3, Color("#7ab84a"), hsh)
			blocked[Vector2i(x, z)] = true
		"pine", "snowpine":
			var th := 6 + hsh % 4
			m.box(Vector3(fx, fy, fz), Vector3(fx + 1, fy + th, fz + 1), Color("#4a3420"))
			var lc := Color("#2a5a3a")
			for layer in 4:
				var r := 3 - layer
				if r < 1:
					r = 1
				var ly := fy + th - 5 + layer * 1.6
				m.box(Vector3(fx - r + 0.5, ly, fz - r + 0.5), Vector3(fx + r + 0.5, ly + 1.0, fz + r + 0.5), U.vary(lc, 0.08, layer * 0.3))
				if type == "snowpine":
					m.box(Vector3(fx - r + 0.6, ly + 1.0, fz - r + 0.6), Vector3(fx + r + 0.4, ly + 1.25, fz + r + 0.4), Color("#f4f8fc"))
			m.box(Vector3(fx + 0.2, fy + th + 1.2, fz + 0.2), Vector3(fx + 0.8, fy + th + 2.0, fz + 0.8), lc)
			blocked[Vector2i(x, z)] = true
		"cactus":
			var th := 2 + hsh % 3
			m.box(Vector3(fx + 0.15, fy, fz + 0.15), Vector3(fx + 0.85, fy + th, fz + 0.85), Color("#4a8a3a"))
			if th > 2:
				m.box(Vector3(fx + 0.85, fy + 1.2, fz + 0.35), Vector3(fx + 1.4, fy + 1.6, fz + 0.65), Color("#4a8a3a"))
				m.box(Vector3(fx + 1.1, fy + 1.6, fz + 0.35), Vector3(fx + 1.4, fy + 2.4, fz + 0.65), Color("#4a8a3a"))
			blocked[Vector2i(x, z)] = true
		"deadwood", "soul":
			var th := 3 + hsh % 3
			m.box(Vector3(fx + 0.2, fy, fz + 0.2), Vector3(fx + 0.8, fy + th, fz + 0.8), Color("#3a302a"))
			m.box(Vector3(fx + 0.8, fy + th - 1, fz + 0.3), Vector3(fx + 1.8, fy + th - 0.6, fz + 0.7), Color("#3a302a"))
			m.box(Vector3(fx - 0.8, fy + th - 2, fz + 0.3), Vector3(fx + 0.2, fy + th - 1.6, fz + 0.7), Color("#3a302a"))
			if type == "soul":
				m.box(Vector3(fx + 0.25, fy + th, fz + 0.25), Vector3(fx + 0.75, fy + th + 0.6, fz + 0.75), Color(0.27, 0.84, 1.0, 0.0))
				out["lights"].append({"pos": Vector3(fx + 0.5, fy + th + 1.0, fz + 0.5), "color": Color("#46d6ff"), "range": 6.0})
			blocked[Vector2i(x, z)] = true
		"crimson":
			var th := 4 + hsh % 3
			m.box(Vector3(fx, fy, fz), Vector3(fx + 1, fy + th, fz + 1), Color("#5a1a2a"))
			_leaf_blob(m, fx, fy + th - 1, fz, 2, 2, Color("#9a1a2a"), hsh)
			m.box(Vector3(fx - 1, fy + th - 2, fz), Vector3(fx, fy + th - 1, fz + 1), Color(1.0, 0.75, 0.2, 0.0))
			blocked[Vector2i(x, z)] = true
		"spire":
			var th := 5 + hsh % 7
			m.box(Vector3(fx, fy, fz), Vector3(fx + 1, fy + th, fz + 1), Color("#2d2d33"))
			m.box(Vector3(fx + 1, fy, fz), Vector3(fx + 2, fy + th / 2, fz + 1), Color("#36363c"))
			blocked[Vector2i(x, z)] = true
			blocked[Vector2i(x + 1, z)] = true
		"icespike":
			var th := 4 + hsh % 9
			m.box(Vector3(fx, fy, fz), Vector3(fx + 1, fy + th, fz + 1), Color("#bfe0ff"))
			m.box(Vector3(fx + 0.25, fy + th, fz + 0.25), Vector3(fx + 0.75, fy + th + 2, fz + 0.75), Color("#d8f0ff"))
			blocked[Vector2i(x, z)] = true
		"shroom_small":
			var cc := Color("#c23b5a") if hsh % 2 == 0 else Color("#9a7a5a")
			m.box(Vector3(fx + 0.35, fy, fz + 0.35), Vector3(fx + 0.65, fy + 0.9, fz + 0.65), Color("#e8dcc8"))
			m.box(Vector3(fx, fy + 0.9, fz), Vector3(fx + 1, fy + 1.3, fz + 1), cc)
		"shroom_giant":
			var th := 5 + hsh % 4
			var cc := Color("#c23b5a") if hsh % 3 != 0 else Color("#7a4a9a")
			m.box(Vector3(fx, fy, fz), Vector3(fx + 1, fy + th, fz + 1), Color("#e8dcc8"))
			m.box(Vector3(fx - 3, fy + th, fz - 3), Vector3(fx + 4, fy + th + 1, fz + 4), cc)
			m.box(Vector3(fx - 2, fy + th + 1, fz - 2), Vector3(fx + 3, fy + th + 2, fz + 3), cc)
			m.box(Vector3(fx - 2.5, fy + th - 0.2, fz - 2.5), Vector3(fx + 3.5, fy + th, fz + 3.5), Color(0.95, 0.85, 0.75, 1.0))
			blocked[Vector2i(x, z)] = true
		"glowcap":
			var th := 2 + hsh % 4
			m.box(Vector3(fx + 0.2, fy, fz + 0.2), Vector3(fx + 0.8, fy + th, fz + 0.8), Color("#c8d8d0"))
			m.box(Vector3(fx - 1, fy + th, fz - 1), Vector3(fx + 2, fy + th + 0.8, fz + 2), Color(0.37, 0.95, 1.0, 0.0))
			if hsh % 4 == 0:
				out["lights"].append({"pos": Vector3(fx + 0.5, fy + th + 1.5, fz + 0.5), "color": Color("#5ff3ff"), "range": 7.0})
			blocked[Vector2i(x, z)] = true
		"rotvine":
			var th := 4 + hsh % 3
			m.box(Vector3(fx, fy, fz), Vector3(fx + 1, fy + th, fz + 1), Color("#3a2a20"))
			_leaf_blob(m, fx, fy + th - 1, fz, 2, 2, Color("#4a6a2a"), hsh)
			m.box(Vector3(fx + 1.2, fy + th - 3, fz + 0.3), Vector3(fx + 1.4, fy + th - 1, fz + 0.5), Color(0.84, 0.54, 0.16, 0.0))
			blocked[Vector2i(x, z)] = true
		"chorus":
			var th := 3 + hsh % 4
			var cc := Color("#7a5a9a")
			m.box(Vector3(fx + 0.2, fy, fz + 0.2), Vector3(fx + 0.8, fy + th, fz + 0.8), cc)
			m.box(Vector3(fx + 0.8, fy + th - 1, fz + 0.2), Vector3(fx + 1.6, fy + th - 0.4, fz + 0.8), cc)
			m.box(Vector3(fx + 1.0, fy + th - 0.4, fz + 0.2), Vector3(fx + 1.6, fy + th + 1, fz + 0.8), cc)
			m.box(Vector3(fx + 0.1, fy + th, fz + 0.1), Vector3(fx + 0.9, fy + th + 0.8, fz + 0.9), Color(0.85, 0.75, 1.0, 0.0))
			m.box(Vector3(fx + 0.9, fy + th + 1, fz + 0.1), Vector3(fx + 1.7, fy + th + 1.8, fz + 0.9), Color(0.85, 0.75, 1.0, 0.0))
			blocked[Vector2i(x, z)] = true
		"obsidian":
			var th := 2 + hsh % 5
			m.box(Vector3(fx, fy, fz), Vector3(fx + 1, fy + th, fz + 1), Color("#1e162a"))
			m.box(Vector3(fx + 0.3, fy + th, fz + 0.3), Vector3(fx + 0.7, fy + th + 1, fz + 0.7), Color("#3a2a5a"))
			blocked[Vector2i(x, z)] = true
		"crystal":
			var th := 1 + hsh % 3
			var cc := Color(1.0, 0.9, 0.55, 0.0)
			m.box(Vector3(fx + 0.2, fy, fz + 0.2), Vector3(fx + 0.8, fy + th + 1, fz + 0.8), cc)
			m.box(Vector3(fx + 0.8, fy, fz + 0.3), Vector3(fx + 1.2, fy + th, fz + 0.7), cc)
			if hsh % 3 == 0:
				out["lights"].append({"pos": Vector3(fx + 0.5, fy + th + 1.5, fz + 0.5), "color": Color("#ffe58a"), "range": 6.0})
			blocked[Vector2i(x, z)] = true


# ---------------------------------------------------------------- structures

func _block_rect(out: Dictionary, x0: int, z0: int, w: int, d: int) -> void:
	var blocked: Dictionary = out["blocked"]
	for x in range(x0, x0 + w):
		for z in range(z0, z0 + d):
			blocked[Vector2i(x, z)] = true


func _build_piece(m: Mesher, p: Dictionary, v: Dictionary, out: Dictionary) -> void:
	var hc: Dictionary = dimdef["house"]
	var x: float = p["x"]
	var z: float = p["z"]
	var y: float = p["y"]
	match p["type"]:
		"house":
			var w: int = p["w"]
			var d: int = p["d"]
			var hh: int = p["h"]
			var wall: Color = hc["wall"]
			var frame: Color = hc["frame"]
			var roof: Color = hc["roof"]
			if p["variant"] == 1:
				wall = U.vary(wall, 0.1, 0.2)
			elif p["variant"] == 2:
				roof = U.vary(roof, 0.15, 0.8)
			m.box(Vector3(x, y, z), Vector3(x + w, y + 0.15, z + d), hc["floor"])
			m.box(Vector3(x + 0.1, y, z + 0.1), Vector3(x + w - 0.1, y + hh, z + d - 0.1), wall)
			for cxy in [Vector2(x, z), Vector2(x + w - 1, z), Vector2(x, z + d - 1), Vector2(x + w - 1, z + d - 1)]:
				m.box(Vector3(cxy.x, y, cxy.y), Vector3(cxy.x + 1, y + hh + 0.2, cxy.y + 1), frame)
			m.box(Vector3(x - 0.05, y + hh - 0.6, z - 0.05), Vector3(x + w + 0.05, y + hh, z + d + 0.05), frame)
			# Door and windows on the side facing the village centre.
			var dir: int = p["dir"]
			var win := Color(1.0, 0.82, 0.45, 0.0)
			match dir:
				0:
					m.box(Vector3(x + w - 0.05, y, z + d / 2 - 0.5), Vector3(x + w + 0.08, y + 2.2, z + d / 2 + 0.5), Color("#4a3018"))
					m.box(Vector3(x + w - 0.05, y + 2.4, z + 1.2), Vector3(x + w + 0.06, y + 3.2, z + 2.0), win)
				1:
					m.box(Vector3(x - 0.08, y, z + d / 2 - 0.5), Vector3(x + 0.05, y + 2.2, z + d / 2 + 0.5), Color("#4a3018"))
					m.box(Vector3(x - 0.06, y + 2.4, z + d - 2.0), Vector3(x + 0.05, y + 3.2, z + d - 1.2), win)
				2:
					m.box(Vector3(x + w / 2 - 0.5, y, z + d - 0.05), Vector3(x + w / 2 + 0.5, y + 2.2, z + d + 0.08), Color("#4a3018"))
					m.box(Vector3(x + 1.2, y + 2.4, z + d - 0.05), Vector3(x + 2.0, y + 3.2, z + d + 0.06), win)
				3:
					m.box(Vector3(x + w / 2 - 0.5, y, z - 0.08), Vector3(x + w / 2 + 0.5, y + 2.2, z + 0.05), Color("#4a3018"))
					m.box(Vector3(x + w - 2.0, y + 2.4, z - 0.06), Vector3(x + w - 1.2, y + 3.2, z + 0.05), win)
			# Stepped roof.
			var layers := int(ceil(mini(w, d) / 2.0)) + 1
			for l in layers:
				var inset := l * 1.0 - 0.6
				var ry := y + hh + l * 0.7
				if w - inset * 2 <= 0.2 or d - inset * 2 <= 0.2:
					break
				m.box(Vector3(x + inset, ry, z + inset), Vector3(x + w - inset, ry + 0.7, z + d - inset), U.vary(roof, 0.06, l * 0.27))
			m.box(Vector3(x + w - 1.6, y + hh, z + 0.6), Vector3(x + w - 0.8, y + hh + layers * 0.7 + 0.8, z + 1.4), Color("#5a5a5a"))
			_block_rect(out, int(x), int(z), w, d)
		"center":
			if p["origin"] and dim_id == "verdant":
				m.box(Vector3(x - 1.0, y, z - 1.0), Vector3(x + 1.0, y + 8, z + 1.0), Color("#5a3e22"))
				for r in [Vector3(-1.2, 0, 0), Vector3(1.2, 0, 0), Vector3(0, 0, 1.2), Vector3(0, 0, -1.2)]:
					m.box(Vector3(x + r.x - 0.5, y, z + r.z - 0.5), Vector3(x + r.x + 0.5, y + 1.0, z + r.z + 0.5), Color("#5a3e22"))
				_leaf_blob(m, x - 0.5, y + 7, z - 0.5, 4, 2, Color("#3f8a2a"), 7)
				_leaf_blob(m, x - 0.5, y + 9, z - 0.5, 2, 2, Color("#4a9a32"), 9)
				for i in 6:
					var ga := TAU * i / 6.0
					m.box(Vector3(x + cos(ga) * 3.5 - 0.15, y + 7.2, z + sin(ga) * 3.5 - 0.15), Vector3(x + cos(ga) * 3.5 + 0.15, y + 7.6, z + sin(ga) * 3.5 + 0.15), Color(1.0, 0.85, 0.4, 0.0))
				out["lights"].append({"pos": Vector3(x, y + 6.0, z), "color": Color("#ffd27a"), "range": 12.0})
				_block_rect(out, int(x) - 2, int(z) - 2, 4, 4)
			else:
				# Plaza well / centrepiece, themed per realm.
				var stone := Color("#8a8a8a") if dim_id != "void" else Color("#d9d3a4")
				m.box(Vector3(x - 1.5, y, z - 1.5), Vector3(x + 1.5, y + 1.0, z + 1.5), stone)
				var core: Color = {"verdant": Color(0.2, 0.45, 0.85, 1.0), "ember": Color(0.27, 0.84, 1.0, 0.0), "frost": Color(1.0, 0.6, 0.25, 0.0), "spore": Color(0.6, 1.0, 0.4, 0.0), "void": Color(0.8, 0.5, 1.0, 0.0)}[dim_id]
				m.box(Vector3(x - 1.0, y + 0.2, z - 1.0), Vector3(x + 1.0, y + 0.95, z + 1.0), core)
				for c in [Vector2(-1.5, -1.5), Vector2(1.0, -1.5), Vector2(-1.5, 1.0), Vector2(1.0, 1.0)]:
					m.box(Vector3(x + c.x, y + 1.0, z + c.y), Vector3(x + c.x + 0.5, y + 3.2, z + c.y + 0.5), hc["frame"])
				m.box(Vector3(x - 2.0, y + 3.2, z - 2.0), Vector3(x + 2.0, y + 3.7, z + 2.0), hc["roof"])
				if core.a < 0.5:
					out["lights"].append({"pos": Vector3(x, y + 2.0, z), "color": Color(core.r, core.g, core.b), "range": 10.0})
				_block_rect(out, int(x) - 2, int(z) - 2, 4, 4)
		"gate":
			var fc := Color("#2a1f3a")
			var big: bool = v["origin"]
			var gw := 2.5 if big else 1.8
			var gh := 6.0 if big else 4.5
			m.box(Vector3(x - gw - 1, y, z - 0.5), Vector3(x - gw, y + gh, z + 0.5), fc)
			m.box(Vector3(x + gw, y, z - 0.5), Vector3(x + gw + 1, y + gh, z + 0.5), fc)
			m.box(Vector3(x - gw - 1, y + gh, z - 0.5), Vector3(x + gw + 1, y + gh + 1, z + 0.5), fc)
			m.box(Vector3(x - gw - 1.5, y, z - 1.0), Vector3(x + gw + 1.5, y + 0.4, z + 1.0), Color("#3a3048"))
			var gc := Color(0.75, 0.45, 1.0, 0.0)
			m.box(Vector3(x - gw, y + 0.4, z - 0.15), Vector3(x + gw, y + gh, z + 0.15), gc)
			m.box(Vector3(x - 0.4, y + gh + 1.0, z - 0.4), Vector3(x + 0.4, y + gh + 1.8, z + 0.4), Color(1.0, 0.85, 0.4, 0.0))
			out["lights"].append({"pos": Vector3(x, y + gh * 0.5, z + 1.5), "color": Color("#b07aff"), "range": 9.0})
			out["interact"].append({"type": "gate", "pos": Vector3(x, y, z - 1.2), "key": v["key"], "village": v["name"]})
			_block_rect(out, int(floor(x - gw - 1)), int(floor(z - 0.5)), int(gw * 2 + 2), 1)
		"board":
			m.box(Vector3(x - 1.0, y, z - 0.1), Vector3(x - 0.8, y + 2.4, z + 0.1), hc["frame"])
			m.box(Vector3(x + 0.8, y, z - 0.1), Vector3(x + 1.0, y + 2.4, z + 0.1), hc["frame"])
			m.box(Vector3(x - 1.0, y + 1.0, z - 0.08), Vector3(x + 1.0, y + 2.2, z + 0.08), Color("#8a6a45"))
			for i in 3:
				m.box(Vector3(x - 0.8 + i * 0.55, y + 1.2 + (i % 2) * 0.3, z - 0.12), Vector3(x - 0.4 + i * 0.55, y + 1.7 + (i % 2) * 0.3, z + 0.12), Color("#f0e6c8"))
			out["interact"].append({"type": "board", "pos": Vector3(x, y, z + 0.8), "key": v["key"]})
			_block_rect(out, int(floor(x - 1)), int(floor(z)), 2, 1)
		"lamp":
			m.box(Vector3(x + 0.35, y, z + 0.35), Vector3(x + 0.65, y + 3.0, z + 0.65), hc["frame"])
			m.box(Vector3(x + 0.2, y + 3.0, z + 0.2), Vector3(x + 0.8, y + 3.6, z + 0.8), Color(1.0, 0.8, 0.4, 0.0))
			m.box(Vector3(x + 0.15, y + 3.6, z + 0.15), Vector3(x + 0.85, y + 3.8, z + 0.85), hc["roof"])
			out["lights"].append({"pos": Vector3(x + 0.5, y + 3.3, z + 0.5), "color": Color("#ffcc77"), "range": 9.0})
			out["blocked"][Vector2i(int(x), int(z))] = true
		"farm":
			var crop: Color = {"verdant": Color("#d8c04a"), "ember": Color("#c23b2a"), "frost": Color("#bfe0ff"), "spore": Color("#9cff6a"), "void": Color("#b38cff")}[dim_id]
			for i in 7:
				for j in 5:
					var cx2 := x + i
					var cz2 := z + j
					m.box(Vector3(cx2, y, cz2), Vector3(cx2 + 1, y + 0.1, cz2 + 1), Color("#5a3a20"))
					if j % 2 == 0:
						var gh2 := 0.4 + U.hashf(int(cx2), int(cz2), 3) * 0.4
						m.box(Vector3(cx2 + 0.2, y + 0.1, cz2 + 0.2), Vector3(cx2 + 0.8, y + 0.1 + gh2, cz2 + 0.8), U.vary(crop, 0.1, U.hashf(i, j, 9)))


func _arena_pieces(m: Mesher, a: Dictionary, ox: int, oz: int, out: Dictionary) -> void:
	var y: float = a["base"]
	for i in 10:
		var ang := TAU * i / 10.0
		var px := floorf(a["x"] + cos(ang) * (ARENA_R + 0.5))
		var pz := floorf(a["z"] + sin(ang) * (ARENA_R + 0.5))
		if px < ox or px >= ox + CHUNK or pz < oz or pz >= oz + CHUNK:
			continue
		var ph := 4.0 + (i % 3)
		var stone := Color("#5a5660") if dim_id != "void" else Color("#2a1f3a")
		m.box(Vector3(px, y, pz), Vector3(px + 1, y + ph, pz + 1), stone)
		m.box(Vector3(px - 0.2, y + ph, pz - 0.2), Vector3(px + 1.2, y + ph + 0.5, pz + 1.2), Color("#3a3640"))
		if i % 2 == 0:
			var fire := Color(1.0, 0.55, 0.2, 0.0)
			if dim_id == "ember" or dim_id == "void":
				fire = Color(0.75, 0.45, 1.0, 0.0)
			m.box(Vector3(px + 0.2, y + ph + 0.5, pz + 0.2), Vector3(px + 0.8, y + ph + 1.1, pz + 0.8), fire)
			out["lights"].append({"pos": Vector3(px + 0.5, y + ph + 1.5, pz + 0.5), "color": Color(fire.r, fire.g, fire.b), "range": 12.0})
		out["blocked"][Vector2i(int(px), int(pz))] = true


func _build_poi(m: Mesher, p: Dictionary, out: Dictionary) -> void:
	var x: float = p["x"]
	var z: float = p["z"]
	var y: float = p["y"]
	var stone := Color("#7a7a7a") if dim_id != "void" else Color("#b3ad80")
	match p["type"]:
		"cave":
			m.box(Vector3(x - 2.5, y, z - 2.5), Vector3(x + 2.5, y + 0.6, z + 2.5), U.vary(stone, 0.1, 0.3))
			m.box(Vector3(x - 1.5, y + 0.55, z - 1.5), Vector3(x + 1.5, y + 0.62, z + 1.5), Color("#050505"))
			m.box(Vector3(x - 2.5, y, z - 2.5), Vector3(x - 1.5, y + 2.2, z - 1.5), stone)
			m.box(Vector3(x + 1.5, y, z - 2.5), Vector3(x + 2.5, y + 1.6, z - 1.5), stone)
			m.box(Vector3(x - 2.5, y, z + 1.5), Vector3(x - 1.5, y + 1.2, z + 2.5), stone)
			m.box(Vector3(x + 1.5, y, z + 1.5), Vector3(x + 2.5, y + 2.6, z + 2.5), stone)
			m.box(Vector3(x - 2.2, y + 2.2, z - 2.2), Vector3(x - 1.8, y + 2.7, z - 1.8), Color(1.0, 0.7, 0.3, 0.0))
			out["lights"].append({"pos": Vector3(x - 2, y + 3, z - 2), "color": Color("#ffaa55"), "range": 6.0})
			out["interact"].append({"type": "cave", "pos": Vector3(x, y + 0.6, z), "key": p["key"]})
		"chest":
			for i in 5:
				var a := TAU * i / 5.0 + U.hashf(int(x), int(z), i) * 0.4
				var rx := floorf(x + cos(a) * 3.5)
				var rz := floorf(z + sin(a) * 3.5)
				var rh := 1.0 + U.hashf(int(rx), int(rz), 4) * 2.5
				m.box(Vector3(rx, y, rz), Vector3(rx + 1, y + rh, rz + 1), U.vary(stone, 0.12, U.hashf(i, 2, 3)))
				out["blocked"][Vector2i(int(rx), int(rz))] = true
			if not State.opened.has(p["key"]):
				out["interact"].append({"type": "chest", "pos": Vector3(x, y, z), "key": p["key"], "tier": 1})
		"lore":
			var lc := Color(0.35, 0.65, 1.0, 0.0)
			m.box(Vector3(x - 0.6, y, z - 0.6), Vector3(x + 0.6, y + 0.4, z + 0.6), stone)
			m.box(Vector3(x - 0.4, y + 0.4, z - 0.4), Vector3(x + 0.4, y + 3.2, z + 0.4), Color("#4a4a5a"))
			m.box(Vector3(x - 0.42, y + 1.2, z - 0.42), Vector3(x + 0.42, y + 1.5, z + 0.42), lc)
			m.box(Vector3(x - 0.42, y + 2.2, z - 0.42), Vector3(x + 0.42, y + 2.5, z + 0.42), lc)
			out["lights"].append({"pos": Vector3(x, y + 2.0, z), "color": Color("#5aa0ff"), "range": 7.0})
			out["interact"].append({"type": "lore", "pos": Vector3(x, y, z + 1.0), "key": p["key"]})
			out["blocked"][Vector2i(int(floor(x)), int(floor(z)))] = true
		"shrine":
			m.box(Vector3(x - 1.5, y, z - 1.5), Vector3(x + 1.5, y + 0.3, z + 1.5), stone)
			m.box(Vector3(x - 0.6, y + 0.3, z - 0.6), Vector3(x + 0.6, y + 1.3, z + 0.6), Color("#d8d0b8"))
			for c in [Vector2(-1.5, -1.5), Vector2(1.0, -1.5), Vector2(-1.5, 1.0), Vector2(1.0, 1.0)]:
				m.box(Vector3(x + c.x, y + 0.3, z + c.y), Vector3(x + c.x + 0.5, y + 2.5, z + c.y + 0.5), Color("#c8c0a8"))
			out["interact"].append({"type": "shrine", "pos": Vector3(x, y + 1.3, z), "key": p["key"]})
			out["blocked"][Vector2i(int(floor(x)), int(floor(z)))] = true
		"ore":
			var rc: Color = Data.resources[p["sub"]]["color"]
			if not State.opened.has(p["key"]):
				out["interact"].append({"type": "ore", "pos": Vector3(x, y, z), "key": p["key"], "res": p["sub"], "color": rc})
			m.box(Vector3(x - 2.5, y, z - 1.5), Vector3(x - 1.5, y + 1.0, z - 0.5), stone)
			m.box(Vector3(x + 1.5, y, z + 0.5), Vector3(x + 2.3, y + 0.8, z + 1.3), stone)
		"crate":
			if not State.opened.has(p["key"]):
				out["interact"].append({"type": "crate", "pos": Vector3(x, y, z), "key": p["key"], "res": p["sub"]})
		"camp":
			var tent := Color("#8a6a4a") if dim_id == "verdant" else U.vary(dimdef["house"]["roof"], 0.1, 0.4)
			for i in 2:
				var tx := x - 4.0 + i * 6.0
				var tz := z - 3.0
				m.box(Vector3(tx, y, tz), Vector3(tx + 3, y + 1.0, tz + 3), tent)
				m.box(Vector3(tx + 0.5, y + 1.0, tz + 0.5), Vector3(tx + 2.5, y + 2.0, tz + 2.5), tent)
				m.box(Vector3(tx + 1.0, y + 2.0, tz + 1.0), Vector3(tx + 2.0, y + 2.6, tz + 2.0), tent)
				_block_rect(out, int(tx), int(tz), 3, 3)
			m.box(Vector3(x - 0.6, y, z + 1.4), Vector3(x + 0.6, y + 0.3, z + 2.6), Color("#4a3a2a"))
			m.box(Vector3(x - 0.3, y + 0.3, z + 1.7), Vector3(x + 0.3, y + 0.9, z + 2.3), Color(1.0, 0.55, 0.15, 0.0))
			out["lights"].append({"pos": Vector3(x, y + 1.5, z + 2.0), "color": Color("#ff9a3a"), "range": 9.0})
			out["camp"] = Vector3(x, y, z + 4.0)
			if not State.opened.has(p["key"]):
				out["interact"].append({"type": "chest", "pos": Vector3(x + 3.0, y, z + 4.5), "key": p["key"], "tier": 2})

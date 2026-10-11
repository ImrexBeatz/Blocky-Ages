## Streams the infinite realm around the player and runs gameplay systems that span entities.
extends Node3D

const U = preload("res://scripts/core/util.gd")
const FX = preload("res://scripts/entities/fx.gd")
const TerrainGen = preload("res://scripts/world/terrain_gen.gd")
const CaveGen = preload("res://scripts/world/cave_gen.gd")
const Enemy = preload("res://scripts/entities/enemy.gd")
const Boss = preload("res://scripts/entities/boss.gd")
const Villager = preload("res://scripts/entities/villager.gd")
const Interactable = preload("res://scripts/entities/interactable.gd")
const Pickup = preload("res://scripts/entities/pickup.gd")

const CHUNK := 16
const Mesher = preload("res://scripts/world/mesher.gd")

var gen
var surface_gen
var chunks := {}
var queue: Array = []
var enemies: Array = []
var allies: Array = []
var villagers: Array = []
var zones: Array = []
var bosses_alive := {}
var chunk_cleared := {}

var env: WorldEnvironment
var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var chunks_root: Node3D
var entities_root: Node3D
var fx_root: Node3D
var cam_rig: Node3D
var camera: Camera3D
var particles: CPUParticles3D

var focus := Vector3.ZERO
var menu_mode := true
var menu_angle := 0.0
var zoom := 24.0
var cam_yaw := 45.0
var in_cave := false
var cave_return := Vector3.ZERO
var spawn_timer := 8.0
var save_timer := 60.0
var region := ""
var last_region_check := 0.0
var quest_target_cache = null
var quest_target_t := 0.0
var player: Node3D
var job := {}
var job_key := Vector2i.ZERO
var load_r := 3
var unload_r := 5
var max_enemies := 40
var streaming := false
var pending_spawns: Array = []
var last_center := Vector2i(999999, 999999)


func _ready() -> void:
	Game.world = self
	chunks_root = Node3D.new()
	add_child(chunks_root)
	entities_root = Node3D.new()
	add_child(entities_root)
	fx_root = Node3D.new()
	add_child(fx_root)
	_setup_environment()
	_setup_camera()
	apply_settings()


# ---------------------------------------------------------------- setup

func _setup_environment() -> void:
	env = WorldEnvironment.new()
	var e := Environment.new()
	sky_mat = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.0
	e.glow_enabled = true
	e.glow_intensity = 0.55
	e.glow_bloom = 0.04
	e.glow_hdr_threshold = 1.1
	e.ssao_enabled = true
	e.ssao_radius = 1.6
	e.ssao_intensity = 2.2
	e.fog_enabled = true
	e.fog_sky_affect = 0.6
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.15
	e.adjustment_contrast = 1.06
	env.environment = e
	add_child(env)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	sun.shadow_blur = 1.5
	sun.rotation_degrees = Vector3(-55, -30, 0)
	add_child(sun)


func _setup_camera() -> void:
	cam_rig = Node3D.new()
	add_child(cam_rig)
	camera = Camera3D.new()
	camera.fov = 38.0
	camera.far = 260.0
	cam_rig.add_child(camera)
	camera.current = true
	Game.camera = camera
	particles = CPUParticles3D.new()
	particles.amount = 140
	particles.lifetime = 6.0
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(26, 8, 26)
	add_child(particles)


## Applies the current graphics preset (see Settings) to lighting, effects and streaming.
func apply_settings() -> void:
	var v: Dictionary = Settings.v
	load_r = v["load_r"]
	unload_r = v["unload_r"]
	max_enemies = v["max_enemies"]
	var e := env.environment
	e.glow_enabled = v["glow"]
	e.ssao_enabled = v["ssao"] and Settings.forward_plus()
	e.adjustment_enabled = v["glow"]
	sun.shadow_enabled = v["shadows"]
	sun.directional_shadow_max_distance = maxf(v["shadow_distance"], 1.0)
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if v["shadow_distance"] < 50.0 else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	camera.far = v["camera_far"]
	particles.amount = v["particles"]
	Mesher.set_dither(v["dither"])
	if not v["sky"]:
		zoom = minf(zoom, 26.0)
	if gen:
		apply_environment()
	for k in chunks:
		for l in chunks[k]["node"].get_children():
			if l is OmniLight3D:
				l.visible = v["chunk_lights"] > 0


func _set_sky_colors(top: Color, horizon: Color) -> void:
	sky_mat.sky_top_color = top
	sky_mat.sky_horizon_color = horizon
	env.environment.background_color = horizon.lerp(top, 0.35)


func apply_environment() -> void:
	var d: Dictionary = Data.dim(State.current_dim)
	var e := env.environment
	e.background_mode = Environment.BG_SKY if Settings.v["sky"] else Environment.BG_COLOR
	if in_cave:
		_set_sky_colors(Color(0.02, 0.02, 0.03), Color(0.03, 0.03, 0.04))
		sky_mat.ground_horizon_color = Color(0.02, 0.02, 0.02)
		sky_mat.ground_bottom_color = Color(0, 0, 0)
		e.ambient_light_energy = 0.7
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.42, 0.38, 0.48)
		e.fog_light_color = Color(0.02, 0.02, 0.03)
		e.fog_density = 0.02
		sun.light_energy = 0.12
		sun.light_color = Color(0.6, 0.6, 0.8)
	else:
		_set_sky_colors(d["sky_top"], d["sky_horizon"])
		sky_mat.ground_horizon_color = d["ground_horizon"]
		sky_mat.ground_bottom_color = d["ground_horizon"].darkened(0.5)
		sky_mat.sun_angle_max = 20.0
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = d["ambient"]
		e.ambient_light_energy = 0.6
		e.fog_light_color = d["fog"]
		e.fog_density = d["fog_density"] * 0.35 * Settings.v["fog_mult"]
		sun.light_color = d["sun"]
		sun.light_energy = d["sun_energy"]
	_setup_particles(d["particles"] if not in_cave else "dust")


func _setup_particles(kind: String) -> void:
	var c := Color.WHITE
	var size := 0.08
	particles.gravity = Vector3.ZERO
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 0.1
	particles.initial_velocity_max = 0.5
	match kind:
		"fireflies":
			c = Color(1.0, 0.9, 0.4)
			size = 0.07
		"embers":
			c = Color(1.0, 0.5, 0.15)
			particles.gravity = Vector3(0.3, 0.8, 0)
			size = 0.07
		"snow":
			c = Color(1, 1, 1)
			particles.gravity = Vector3(0.6, -1.6, 0.2)
			size = 0.1
		"spores":
			c = Color(0.6, 1.0, 0.6)
			particles.gravity = Vector3(0, 0.25, 0)
			size = 0.08
		"void":
			c = Color(0.75, 0.5, 1.0)
			particles.gravity = Vector3(0, 0.4, 0)
		"dust":
			c = Color(0.8, 0.75, 0.6, 0.6)
			size = 0.05
	var m := BoxMesh.new()
	m.size = Vector3.ONE * size
	m.material = U.mat(c, 2.0 if kind != "snow" and kind != "dust" else 0.3, 0.8, false)
	particles.mesh = m


# ---------------------------------------------------------------- realm management

func load_realm(dimid: String, menu := false) -> void:
	menu_mode = menu
	State.current_dim = dimid
	in_cave = false
	clear_world()
	surface_gen = TerrainGen.new()
	surface_gen.setup(Data.dim(dimid), State.world_seed)
	gen = surface_gen
	apply_environment()
	Sfx.play_music(dimid)


func clear_world() -> void:
	for k in chunks.keys():
		_unload_chunk(k)
	chunks.clear()
	queue.clear()
	job = {}
	pending_spawns.clear()
	last_center = Vector2i(999999, 999999)
	for e in enemies + allies + villagers:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	allies.clear()
	villagers.clear()
	bosses_alive.clear()
	for z in zones:
		if is_instance_valid(z["node"]):
			z["node"].queue_free()
	zones.clear()
	for c in fx_root.get_children():
		c.queue_free()
	quest_target_cache = null
	Game.boss_cleared.emit()


## Synchronously builds the chunks around a point (used behind loading screens).
func prebuild(center: Vector3, r: int = -1) -> void:
	if r < 0:
		r = load_r
	r = mini(r, load_r)
	job = {}
	focus = center
	var c := _chunk_of(center.x, center.z)
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var k := Vector2i(c.x + dx, c.y + dz)
			if not chunks.has(k):
				_build_chunk(k)


func attach_player(p: Node3D) -> void:
	player = p
	Game.player = p
	if p.get_parent() == null:
		entities_root.add_child(p)


func travel(dimid: String, pos = null) -> void:
	if player and not in_cave:
		State.positions[State.current_dim] = [player.global_position.x, player.global_position.y, player.global_position.z]
	load_realm(dimid)
	var sp: Vector3 = surface_gen.spawn_point() if pos == null else pos
	prebuild(sp, 2)
	sp.y = ground_at(sp.x, sp.z)
	if sp.y < -500:
		sp = surface_gen.spawn_point()
		sp.y = ground_at(sp.x, sp.z)
	player.global_position = sp
	_snap_camera()
	var d := Data.dim(dimid)
	Game.banner.emit(d["name"], Story.DIM_ARRIVAL.get(dimid, ""))
	Quests.notify("travel", dimid, 1)
	Sfx.play("portal", 0.8)
	State.save_game()


func enter_cave(key: String, at: Vector3) -> void:
	cave_return = at + Vector3(0, 0, 3.2)
	State.positions[State.current_dim] = [cave_return.x, cave_return.y, cave_return.z]
	clear_world()
	in_cave = true
	var cg := CaveGen.new()
	cg.setup(Data.dim(State.current_dim), State.world_seed, key)
	gen = cg
	apply_environment()
	var sp: Vector3 = cg.spawn_point()
	prebuild(sp, 2)
	player.global_position = sp
	_snap_camera()
	Game.banner.emit(cg.cave_name, "Find the guardian's chamber and claim its treasure.")
	Sfx.play("portal", 0.6)


func exit_cave(final: bool) -> void:
	if final:
		State.caves_cleared += 1
		Quests.notify("cave", "", 1)
		var xp := int(80 * Game.hp_scale(Game.enemy_level_at(cave_return)))
		State.add_xp(xp)
		Game.banner.emit("Cave Cleared!", "+%d XP" % xp)
		Sfx.play("quest")
	clear_world()
	in_cave = false
	gen = surface_gen
	apply_environment()
	prebuild(cave_return, 2)
	cave_return.y = ground_at(cave_return.x, cave_return.z)
	player.global_position = cave_return
	_snap_camera()
	State.save_game()


func safe_point_near(p: Vector3) -> Vector3:
	for r in range(0, 30):
		for i in 12:
			var a := TAU * i / 12.0
			var q := p + Vector3(cos(a), 0, sin(a)) * r
			var g := ground_at(q.x, q.z)
			if g > -500.0 and not is_blocked(q.x, q.z):
				return Vector3(q.x, g, q.z)
	return gen.spawn_point()


# ---------------------------------------------------------------- queries

func _chunk_of(x: float, z: float) -> Vector2i:
	return Vector2i(int(floor(x / CHUNK)), int(floor(z / CHUNK)))


func ground_at(x: float, z: float) -> float:
	var k := _chunk_of(x, z)
	var ch = chunks.get(k)
	var xi := int(floor(x))
	var zi := int(floor(z))
	if ch != null:
		var h: PackedFloat32Array = ch["heights"]
		return h[(zi - k.y * CHUNK) * CHUNK + (xi - k.x * CHUNK)]
	if gen == null:
		return 0.0
	return gen.ground_from_info(gen.height_info(xi, zi))


func is_blocked(x: float, z: float) -> bool:
	var k := _chunk_of(x, z)
	var ch = chunks.get(k)
	if ch == null:
		return false
	return ch["blocked"].has(Vector2i(int(floor(x)), int(floor(z))))


func targets_for(team: int) -> Array:
	var out: Array = []
	if team == 1:
		if player and not player.dead:
			out.append(player)
		for a in allies:
			if is_instance_valid(a) and not a.dead:
				out.append(a)
	else:
		for e in enemies:
			if is_instance_valid(e) and not e.dead:
				out.append(e)
	return out


func interactables() -> Array:
	var out: Array = []
	var pc := _chunk_of(player.global_position.x, player.global_position.z) if player else Vector2i.ZERO
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var ch = chunks.get(Vector2i(pc.x + dx, pc.y + dz))
			if ch == null:
				continue
			for n in ch["nodes"]:
				if is_instance_valid(n):
					out.append(n)
	for v in villagers:
		if is_instance_valid(v):
			out.append(v)
	return out


func is_night() -> bool:
	if in_cave or not Data.dim(State.current_dim)["day_cycle"]:
		return false
	var t := Game.time_of_day
	return t > 0.78 or t < 0.22


func region_name() -> String:
	if gen == null or player == null:
		return ""
	return gen.region_name(player.global_position.x, player.global_position.z)


# ---------------------------------------------------------------- chunk streaming

func _process(delta: float) -> void:
	if gen == null:
		return
	if menu_mode:
		menu_angle += delta * 0.05
		focus = Vector3(cos(menu_angle) * 18.0, 0, sin(menu_angle) * 18.0)
		focus.y = maxf(ground_at(focus.x, focus.z), 4.0)
	elif player:
		focus = player.global_position
	_stream(delta)
	_update_camera(delta)
	particles.global_position = focus + Vector3(0, 5, 0)
	_day_night(delta)
	if not menu_mode and player:
		State.playtime += delta
		_gameplay_tick(delta)


func _stream(_delta: float) -> void:
	_run_pending_spawn()
	var c := _chunk_of(focus.x, focus.z)
	if c == last_center and queue.is_empty() and job.is_empty():
		return
	last_center = c
	var wanted := {}
	for dz in range(-load_r, load_r + 1):
		for dx in range(-load_r, load_r + 1):
			var k := Vector2i(c.x + dx, c.y + dz)
			wanted[k] = true
			if not chunks.has(k) and not queue.has(k):
				queue.append(k)
	for k in chunks.keys():
		if absi(k.x - c.x) > unload_r or absi(k.y - c.y) > unload_r:
			_unload_chunk(k)
	var lr := load_r
	queue = queue.filter(func(k): return absi(k.x - c.x) <= lr + 1 and absi(k.y - c.y) <= lr + 1)
	queue.sort_custom(func(a, b): return (a - c).length_squared() < (b - c).length_squared())
	# Chunks are generated a few rows at a time so slow CPUs (phones) never hitch.
	var budget: int = Settings.v["chunk_budget_us"]
	var rows: int = Settings.v["chunk_rows"]
	var start := Time.get_ticks_usec()
	var steps := 0
	# Always make progress (one step), then only start another step while well inside the budget.
	while steps == 0 or Time.get_ticks_usec() - start < budget / 2:
		steps += 1
		if job.is_empty():
			if queue.is_empty():
				break
			var k: Vector2i = queue.pop_front()
			if chunks.has(k):
				continue
			job_key = k
			job = gen.begin_chunk(k.x, k.y)
		if gen.step_chunk(job, rows):
			var data: Dictionary = job["out"]
			job = {}
			if not chunks.has(job_key):
				streaming = true
				_finalize_chunk(job_key, data)
				streaming = false


func _build_chunk(k: Vector2i) -> void:
	_finalize_chunk(k, gen.build_chunk(k.x, k.y))


func _finalize_chunk(k: Vector2i, data: Dictionary) -> void:
	var node := Node3D.new()
	chunks_root.add_child(node)
	if data["mesh"]:
		var mi := MeshInstance3D.new()
		mi.mesh = data["mesh"]
		node.add_child(mi)
	if data.get("props"):
		var pmi := MeshInstance3D.new()
		pmi.mesh = data["props"]
		node.add_child(pmi)
	if data["liquid"]:
		var lm := MeshInstance3D.new()
		lm.mesh = data["liquid"]
		lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(lm)
	var lights := 0
	for l in data["lights"]:
		if lights >= int(Settings.v["chunk_lights"]):
			break
		lights += 1
		var ol := OmniLight3D.new()
		ol.light_color = l["color"]
		ol.light_energy = 1.4
		ol.omni_range = l["range"]
		ol.omni_attenuation = 1.4
		ol.distance_fade_enabled = true
		ol.distance_fade_begin = 38.0
		ol.distance_fade_length = 10.0
		node.add_child(ol)
		ol.position = l["pos"]
	var rec := {"node": node, "heights": data["heights"], "colors": data["colors"], "blocked": data["blocked"], "nodes": [], "mobs": []}
	chunks[k] = rec
	for d in data["interact"]:
		var it := Interactable.new()
		node.add_child(it)
		it.position = d["pos"]
		it.setup(d)
		rec["nodes"].append(it)
	for p in data["people"]:
		_later(k, func(): _spawn_villager(p))
	if menu_mode:
		return
	# Enemy packs
	var key_s := "%s:%d:%d" % [State.current_dim, k.x, k.y]
	var recently: bool = chunk_cleared.has(key_s) and State.playtime - chunk_cleared[key_s] < 180.0
	if not recently and player:
		var pool := _enemy_pool()
		for sp in data["spawns"]:
			if U.flat_dist(sp, player.global_position) < 14.0 or enemies.size() >= max_enemies:
				continue
			var n := 1 + U.hash2(k.x, k.y, int(sp.x)) % 3
			_later(k, func(): _spawn_pack(sp, pool, rec, n))
		if data.has("camp"):
			var cp: Vector3 = data["camp"]
			_later(k, func(): _spawn_pack(cp, pool, rec, 4))
			_later(k, func():
				var el = spawn_enemy(pool[randi() % pool.size()], cp + Vector3(1, 0, 1), Game.enemy_level_at(cp), true)
				if el:
					rec["mobs"].append(el))
		for ep in data.get("elite", []):
			_later(k, func():
				var el2 = spawn_enemy(pool[randi() % pool.size()], ep, Game.enemy_level_at(cave_return) + 1, true)
				if el2:
					rec["mobs"].append(el2))


## While streaming, entity spawns are spread out (one per frame) so slow devices never hitch.
func _later(k: Vector2i, f: Callable) -> void:
	if streaming:
		pending_spawns.append([k, f])
	else:
		f.call()


func _run_pending_spawn() -> void:
	while not pending_spawns.is_empty():
		var e: Array = pending_spawns.pop_front()
		if chunks.has(e[0]):
			e[1].call()
			return


func _enemy_pool() -> Array:
	var d := Data.dim(State.current_dim)
	return d["enemies"]


func _spawn_pack(sp: Vector3, pool: Array, rec: Dictionary, n: int) -> void:
	var type: String = pool[randi() % pool.size()]
	var lvl := Game.enemy_level_at(sp if not in_cave else cave_return)
	if in_cave:
		lvl += 1
	for i in n:
		var p := sp + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		var e = spawn_enemy(type, p, lvl, false)
		if e:
			rec["mobs"].append(e)
		if randf() < 0.3:
			type = pool[randi() % pool.size()]


func _unload_chunk(k: Vector2i) -> void:
	var rec = chunks.get(k)
	if rec == null:
		return
	for e in rec["mobs"]:
		if is_instance_valid(e) and not e.dead and not e.is_boss:
			if player and U.flat_dist(e.global_position, player.global_position) < 40.0:
				continue
			enemies.erase(e)
			e.queue_free()
	for v in villagers.duplicate():
		if is_instance_valid(v) and _chunk_of(v.home.x, v.home.z) == k:
			villagers.erase(v)
			v.queue_free()
	rec["node"].queue_free()
	chunks.erase(k)


func _spawn_villager(p: Dictionary) -> void:
	var v := Villager.new()
	entities_root.add_child(v)
	var g := ground_at(p["x"], p["z"])
	v.global_position = Vector3(p["x"], g if g > -500 else p["y"], p["z"])
	v.setup(p)
	villagers.append(v)


func spawn_enemy(id: String, pos: Vector3, lvl: int, elite := false, team := 1) -> Node3D:
	if not Data.enemies.has(id):
		return null
	if team == 1 and enemies.size() >= max_enemies + 12:
		return null
	var g := ground_at(pos.x, pos.z)
	if g < -500.0 or is_blocked(pos.x, pos.z):
		if Data.enemies[id]["model"] != "flyer":
			return null
		g = pos.y
	var e := Enemy.new()
	entities_root.add_child(e)
	e.global_position = Vector3(pos.x, g, pos.z)
	e.home = e.global_position
	e.setup(Data.enemies[id], lvl, elite, team)
	if team == 1:
		enemies.append(e)
	else:
		allies.append(e)
	return e


func spawn_ally(id: String, pos: Vector3, power: float) -> Node3D:
	var e = spawn_enemy(id, pos, State.level, false, 0)
	if e == null:
		e = spawn_enemy(id, player.global_position, State.level, false, 0)
	if e == null:
		return null
	var pack := 2.0 if State.has_perk("pack_leader") else 1.0
	e.dmg = power * pack * (1.0 + State.stats.get("artifact_pct", 0.0))
	e.max_hp = State.stats["max_hp"] * 0.6 * pack
	e.hp = e.max_hp
	e.ally_life = 20.0 * (1.5 if pack > 1.0 else 1.0)
	e.aggro_range = 12.0
	return e


func _spawn_boss(a: Dictionary) -> void:
	var bdef: Dictionary = Data.bosses[a["boss"]]
	var lvl := int(Data.dim(State.current_dim)["base_level"]) + int(a["index"]) * 2 + 1 + State.ascension * 10
	if State.bosses_defeated.has(a["boss"]):
		lvl = maxi(lvl, State.level)
	var b := Boss.new()
	entities_root.add_child(b)
	var center := Vector3(a["x"], a["base"], a["z"])
	b.global_position = center
	b.setup_boss(bdef, lvl, center)
	enemies.append(b)
	bosses_alive[a["boss"]] = b


# ---------------------------------------------------------------- gameplay tick

func _gameplay_tick(delta: float) -> void:
	_process_zones(delta)
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if not is_instance_valid(e) or e.dead:
			enemies.remove_at(i)
			continue
		if not e.is_boss and U.flat_dist(e.global_position, player.global_position) > 90.0:
			enemies.remove_at(i)
			e.queue_free()
	for i in range(allies.size() - 1, -1, -1):
		if not is_instance_valid(allies[i]) or allies[i].dead:
			allies.remove_at(i)
	if not in_cave:
		for a in surface_gen.arenas:
			var id: String = a["boss"]
			if bosses_alive.has(id) and is_instance_valid(bosses_alive[id]):
				continue
			bosses_alive.erase(id)
			var dd := Vector2(player.global_position.x - a["x"], player.global_position.z - a["z"]).length()
			if dd < 30.0 and chunks.has(_chunk_of(a["x"], a["z"])):
				var t: float = State.bosses_defeated.get(id, -9999.0)
				if State.playtime - t > 480.0:
					_spawn_boss(a)
		spawn_timer -= delta * (1.8 if is_night() else 1.0)
		if spawn_timer <= 0.0:
			spawn_timer = randf_range(10.0, 18.0)
			_ambient_spawn()
	save_timer -= delta
	if save_timer <= 0.0:
		save_timer = 60.0
		if not in_cave:
			State.positions[State.current_dim] = [player.global_position.x, player.global_position.y, player.global_position.z]
		State.save_game()
	last_region_check -= delta
	if last_region_check <= 0.0:
		last_region_check = 1.0
		_check_villages()


func _ambient_spawn() -> void:
	if enemies.size() >= mini(16, max_enemies - 6):
		return
	if not gen.village_for_pos(player.global_position.x, player.global_position.z).is_empty():
		return
	for tries in 6:
		var a := randf() * TAU
		var r := randf_range(24.0, 34.0)
		var p := player.global_position + Vector3(cos(a), 0, sin(a)) * r
		var g := ground_at(p.x, p.z)
		if g < -500.0 or is_blocked(p.x, p.z) or not chunks.has(_chunk_of(p.x, p.z)):
			continue
		if not gen.village_for_pos(p.x, p.z).is_empty():
			continue
		p.y = g
		var rec: Dictionary = chunks[_chunk_of(p.x, p.z)]
		_spawn_pack(p, _enemy_pool(), rec, randi_range(2, 4))
		return


func _check_villages() -> void:
	if in_cave:
		return
	for v in surface_gen.villages_near(player.global_position, 26.0):
		if not State.visited_villages.has(v["key"]):
			State.visited_villages[v["key"]] = true
			Game.banner.emit(v["name"], "Village discovered")
			if not v["origin"]:
				Quests.notify("village", "", 1)
				State.add_xp(int(30 * Game.hp_scale(Game.enemy_level_at(player.global_position))))


# ---------------------------------------------------------------- camera & sky

func _snap_camera() -> void:
	focus = player.global_position if player else focus
	_update_camera(10.0)


func _update_camera(delta: float) -> void:
	if not menu_mode:
		if Input.is_action_just_pressed("zoom_in") and not Game.ui_open:
			zoom = clampf(zoom - 2.0, 12.0, 38.0)
		if Input.is_action_just_pressed("zoom_out") and not Game.ui_open:
			zoom = clampf(zoom + 2.0, 12.0, 38.0 if Settings.v["sky"] else 26.0)
	var dist := zoom if not menu_mode else 46.0
	var pitch := deg_to_rad(52.0 if not menu_mode else 35.0)
	var yaw := deg_to_rad(cam_yaw + (rad_to_deg(menu_angle) * 2.0 if menu_mode else 0.0))
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	var target := focus + Vector3(0, 1.0, 0)
	var desired := target + offset
	cam_rig.global_position = cam_rig.global_position.lerp(desired, clampf(delta * 6.0, 0.0, 1.0))
	if delta >= 10.0:
		cam_rig.global_position = desired
	var shake := Vector3.ZERO
	if Game.shake > 0.0:
		shake = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * Game.shake * 0.35
		Game.shake = maxf(0.0, Game.shake - delta * 2.5)
	camera.global_position = cam_rig.global_position + shake
	camera.look_at(cam_rig.global_position - offset, Vector3.UP)
	if not menu_mode and player:
		RenderingServer.global_shader_parameter_set("player_pos", player.global_position)
		RenderingServer.global_shader_parameter_set("cam_pos", camera.global_position)
	else:
		RenderingServer.global_shader_parameter_set("player_pos", Vector3(0, -9999, 0))


func _day_night(delta: float) -> void:
	var d := Data.dim(State.current_dim)
	if in_cave:
		return
	if not d["day_cycle"]:
		sun.rotation_degrees = Vector3(-55, -30, 0)
		return
	if not menu_mode:
		Game.time_of_day = fmod(Game.time_of_day + delta / 720.0, 1.0)
	var t := Game.time_of_day
	var elev := sin((t - 0.0) * TAU)
	var day := smoothstep(-0.15, 0.25, elev)
	sun.rotation_degrees = Vector3(-lerpf(25.0, 70.0, clampf(elev, 0, 1)), t * 360.0, 0)
	var e := env.environment
	sun.light_energy = lerpf(0.18, d["sun_energy"], day)
	sun.light_color = Color(0.55, 0.65, 1.0).lerp(d["sun"], day)
	e.ambient_light_energy = lerpf(0.3, 0.6, day)
	_set_sky_colors(Color(0.02, 0.03, 0.09).lerp(d["sky_top"], day), Color(0.08, 0.08, 0.18).lerp(d["sky_horizon"], day))
	e.fog_light_color = Color(0.06, 0.07, 0.14).lerp(d["fog"], day)


# ---------------------------------------------------------------- combat resolution

func deal_damage(source, target, amount: float, opts := {}) -> float:
	if target == null or not is_instance_valid(target) or target.dead:
		return 0.0
	var amt := amount
	var is_player_target: bool = target == player
	if is_player_target:
		var armor: float = State.stats.get("armor", 0.0)
		if player.buffs.has("iron_hide"):
			armor = 1.0 - (1.0 - armor) * (1.0 - player.buffs["iron_hide"]["power"])
		amt *= 1.0 - clampf(armor, -0.5, 0.92)
		var thorns: float = State.stats.get("thorns", 0.0)
		if thorns > 0.0 and source and is_instance_valid(source) and source.get("team") == 1 and not opts.get("ranged", false):
			source.take_damage(amount * thorns, player, {"color": Color("#8aff5a")})
	elif target.get("is_boss"):
		pass
	var dealt: float = target.take_damage(amt, source, opts)
	if dealt <= 0.0 or not is_instance_valid(target):
		return dealt
	var eff: String = opts.get("effect", "")
	var ep: float = opts.get("effect_power", amt * 0.2)
	if source == player:
		ep *= 1.0 + State.stats.get("burn_pct", 0.0)
	match eff:
		"burn":
			target.apply_status("burn", 3.0, ep * 0.5)
		"freeze":
			target.apply_status("freeze", 2.0)
		"poison":
			target.apply_status("poison", 4.0, ep * 0.4)
		"shock":
			target.apply_status("stun", 0.35)
	var kb: float = opts.get("knock", 0.0)
	if kb > 0.0 and opts.has("dir"):
		var res := 0.12 if target.get("is_boss") else 1.0
		target.knockback(opts["dir"], kb * res)
	if source == player and not target.dead:
		var ls: float = State.stats.get("lifesteal", 0.0)
		if ls > 0.0 and opts.get("melee", false):
			player.heal(dealt * ls)
	if source == player:
		player.combat_t = 0.0
	return dealt


func on_enemy_died(e, _source) -> void:
	enemies.erase(e)
	allies.erase(e)
	if e.team != 1:
		return
	var d: Dictionary = e.def
	var lvl: int = e.level
	var p := e.global_position as Vector3
	if e.is_boss:
		_boss_defeated(e)
		return
	State.total_kills += 1
	State.bestiary[d["id"]] = int(State.bestiary.get(d["id"], 0)) + 1
	var xp := int(d["xp"] * (1.0 + 0.09 * (lvl - 1)) * (3.0 if e.elite else 1.0))
	State.add_xp(xp)
	Quests.notify("kill", d["id"], 1)
	var k := _chunk_of(p.x, p.z)
	var all_dead := true
	var rec = chunks.get(k)
	if rec != null:
		for m in rec["mobs"]:
			if is_instance_valid(m) and not m.dead and m != e:
				all_dead = false
		if all_dead:
			chunk_cleared["%s:%d:%d" % [State.current_dim, k.x, k.y]] = State.playtime
	# Drops
	var scav := 1.5 if State.has_perk("scavenger") else 1.0
	if randf() < 0.65:
		drop_resource("emerald", maxi(1, int(randi_range(1, 3) * (1.0 + lvl * 0.06))), p)
	for dr in d["drops"]:
		if randf() < dr[1] * scav:
			drop_resource(dr[0], randi_range(dr[2], dr[3]), p)
	var item_chance: float = 0.045 + State.stats.get("luck", 0.0) * 0.03
	if e.elite or randf() < item_chance:
		_drop_item(State.roll_item(maxi(1, lvl + randi_range(-1, 1)), 0.4 if e.elite else 0.0, 1 if e.elite else 0), p)
	if randf() < (0.2 if e.elite else 0.035):
		var pk := Pickup.new()
		pk.setup_potion(p)
	if randf() < (0.2 if e.elite else 0.012):
		var keys := Data.powerups.keys()
		var pu := Pickup.new()
		pu.setup_powerup(keys[randi() % keys.size()], p)
	if randf() < 0.08:
		drop_resource("arcane_dust", 1, p)


func _boss_defeated(b) -> void:
	var d: Dictionary = b.def
	var first: bool = not State.bosses_defeated.has(d["id"])
	State.bosses_defeated[d["id"]] = State.playtime
	bosses_alive.erase(d["id"])
	var p: Vector3 = b.global_position
	State.add_xp(int(d["xp"] * Game.hp_scale(b.level) * 0.5))
	Quests.notify("boss", d["id"], 1)
	State.lore_found["boss:" + d["id"]] = true
	Game.banner.emit("%s DEFEATED" % d["name"].to_upper(), "First victory!" if first else "Victory!")
	Sfx.play("levelup", 0.7)
	Game.add_shake(0.8)
	FX.burst(p + Vector3(0, 2, 0), d["c3"], 60, 10.0, 0.3, 1.2)
	FX.ring(p, 12.0, d["c3"], 1.0)
	var n := 3 + (2 if first else 0)
	for i in n:
		_drop_item(State.roll_item(b.level + 1, 1.0, 3 if first and i == 0 else 2), p)
	drop_resource("prism_shard", 1 + (1 if first else 0) + int(d["index"]) / 2, p)
	drop_resource("emerald", 40 + b.level * 6, p)
	drop_resource("arcane_dust", 4 + b.level / 5, p)
	for i in 3:
		var pk := Pickup.new()
		pk.setup_potion(p)
	State.save_game()
	if d["id"] == "malgrath" and not State.story_done:
		State.story_done = true
		Game.open_screen.emit("epilogue")


func drop_resource(id: String, n: int, pos: Vector3) -> void:
	if id == "emerald":
		while n > 0:
			var chunk := mini(n, maxi(1, n / 5 + 1))
			var pk := Pickup.new()
			pk.setup_resource(id, chunk, pos)
			n -= chunk
		return
	for i in n:
		var pk := Pickup.new()
		pk.setup_resource(id, 1, pos)


func _drop_item(inst: Dictionary, pos: Vector3) -> void:
	var pk := Pickup.new()
	pk.setup_item(inst, pos)


func chest_loot(pos: Vector3, tier: int) -> void:
	var lvl := Game.enemy_level_at(pos if not in_cave else cave_return) + (1 if in_cave else 0)
	var n := tier
	if State.has_perk("treasure_hunter"):
		n += 1
	for i in n:
		_drop_item(State.roll_item(lvl, 0.3 * tier, 1 if tier >= 3 and i == 0 else 0), pos)
	drop_resource("emerald", randi_range(5, 12) * tier + lvl, pos)
	var d := Data.dim(State.current_dim)
	var res: Array = d["resources"]
	drop_resource(res[randi() % res.size()], randi_range(1, 3), pos)
	if randf() < 0.5:
		var pk := Pickup.new()
		pk.setup_potion(pos)


func read_lore(key: String) -> void:
	var dimid := State.current_dim
	var entry := {}
	if not State.opened.has(key):
		State.opened[key] = true
		for l in Story.lore_for_dim(dimid):
			if not State.lore_found.has(l["id"]):
				entry = l
				break
		Quests.notify("lore", dimid, 1)
		State.add_xp(int(40 * Game.hp_scale(Game.enemy_level_at(player.global_position))))
		if entry.is_empty():
			State.add_resource("arcane_dust", 3)
			Game.toast("The stone's memories echo ones you already know. +3 Arcane Dust", Color("#9ac8ff"))
			return
		State.lore_found[entry["id"]] = true
		Sfx.play("quest", 1.2)
		Game.open_screen.emit("lore:" + entry["id"])
	else:
		Game.toast("This stone has already shared its memory.", Color("#9ac8ff"))


# ---------------------------------------------------------------- zones

func spawn_zone(pos: Vector3, r: float, dur: float, power: float, team: int, color: Color, kind: String, source) -> void:
	var node := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.08
	cm.radial_segments = 28
	node.mesh = cm
	node.material_override = U.unshaded(color)
	fx_root.add_child(node)
	node.global_position = pos + Vector3(0, 0.08, 0)
	var parts := CPUParticles3D.new()
	parts.amount = 24
	parts.lifetime = 1.2
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	parts.emission_sphere_radius = r * 0.8
	parts.direction = Vector3.UP
	parts.gravity = Vector3(0, 1.5, 0)
	parts.initial_velocity_min = 0.2
	parts.initial_velocity_max = 1.0
	var pm := BoxMesh.new()
	pm.size = Vector3.ONE * 0.14
	pm.material = U.mat(Color(color.r, color.g, color.b), 2.0, 0.8, false)
	parts.mesh = pm
	node.add_child(parts)
	zones.append({"node": node, "pos": pos, "r": r, "t": dur, "power": power, "team": team, "kind": kind, "source": source, "tick": 0.0})


func _process_zones(delta: float) -> void:
	for i in range(zones.size() - 1, -1, -1):
		var z: Dictionary = zones[i]
		z["t"] -= delta
		z["tick"] -= delta
		var node: Node3D = z["node"]
		if z["t"] <= 0.0:
			if is_instance_valid(node):
				node.queue_free()
			zones.remove_at(i)
			continue
		if z["tick"] > 0.0:
			if z["kind"] == "vortex":
				for e in targets_for(z["team"]):
					var dd := U.flat_dist(e.global_position, z["pos"])
					if dd < z["r"] + 1.0 and dd > 0.6 and not e.get("is_boss"):
						e.move_flat(U.flat_dir(e.global_position, z["pos"]) * delta * 6.0)
				node.rotation.y += delta * 4.0
			continue
		z["tick"] = 0.5 if z["kind"] != "arrows" else 0.3
		var src = z["source"] if is_instance_valid(z["source"]) else null
		match z["kind"]:
			"heal":
				if player and U.flat_dist(player.global_position, z["pos"]) < z["r"]:
					player.heal(z["power"] * 0.5)
				for a in allies:
					if is_instance_valid(a) and U.flat_dist(a.global_position, z["pos"]) < z["r"]:
						a.heal(z["power"])
			"poison":
				for e in targets_for(z["team"]):
					if U.flat_dist(e.global_position, z["pos"]) < z["r"] + e.radius:
						e.apply_status("poison", 1.5, z["power"])
			"arrows":
				for j in 4:
					var ap: Vector3 = z["pos"] + Vector3(randf_range(-z["r"], z["r"]), 0, randf_range(-z["r"], z["r"]))
					FX.beam(ap + Vector3(0, 6, 0), ap, Color("#e8d8a0"), 0.06, 0.15)
				for e in targets_for(z["team"]):
					if U.flat_dist(e.global_position, z["pos"]) < z["r"] + e.radius:
						deal_damage(src, e, z["power"] * 0.35, {})
			"vortex":
				for e in targets_for(z["team"]):
					if U.flat_dist(e.global_position, z["pos"]) < z["r"] + e.radius:
						deal_damage(src, e, z["power"] * 0.25, {})


# ---------------------------------------------------------------- quest targeting & map

func quest_target():
	quest_target_t -= get_process_delta_time()
	if quest_target_t > 0.0:
		return quest_target_cache
	quest_target_t = 1.5
	quest_target_cache = _compute_quest_target()
	return quest_target_cache


func _compute_quest_target():
	if player == null or gen == null:
		return null
	var id := Quests.tracked
	if id == "":
		return null
	var q := Quests.def(id)
	if q.is_empty():
		return null
	var p := player.global_position
	if in_cave:
		var ex: Dictionary = gen.find_nearest_poi("cave_exit", p)
		return Vector3(ex["x"], 0, ex["z"]) if not ex.is_empty() else null
	if q["dim"] != State.current_dim or q["type"] == "travel":
		var o: Dictionary = surface_gen.village_in_cell(0, 0)
		return Vector3(o["x"], 0, o["z"] + 9.5)
	match q["type"]:
		"boss":
			for a in surface_gen.arenas:
				if a["boss"] == q["target"]:
					return Vector3(a["x"], a["base"], a["z"])
		"talk", "level":
			var vs: Array = surface_gen.villages_near(p, 600.0)
			var best = null
			var bd := INF
			for v in vs:
				var d := Vector2(v["x"] - p.x, v["z"] - p.z).length()
				if d < bd:
					bd = d
					best = Vector3(v["x"], v["base"], v["z"])
			return best
		"village":
			var vs2: Array = surface_gen.villages_near(p, 900.0)
			var best2 = null
			var bd2 := INF
			for v in vs2:
				if State.visited_villages.has(v["key"]):
					continue
				var d := Vector2(v["x"] - p.x, v["z"] - p.z).length()
				if d < bd2:
					bd2 = d
					best2 = Vector3(v["x"], v["base"], v["z"])
			return best2
		"cave", "lore", "shrine", "chest":
			var poi: Dictionary = surface_gen.find_nearest_poi(q["type"], p, 360.0)
			if not poi.is_empty():
				return Vector3(poi["x"], poi["y"], poi["z"])
	return null


## Minimap colour from already-loaded chunk data (cheap); black when unloaded.
func map_color_loaded(x: float, z: float) -> Color:
	var k := _chunk_of(x, z)
	var ch = chunks.get(k)
	if ch == null:
		return Color(0.05, 0.05, 0.07)
	var c: PackedColorArray = ch["colors"]
	return c[(int(floor(z)) - k.y * CHUNK) * CHUNK + (int(floor(x)) - k.x * CHUNK)]


func map_image(center: Vector3, px: int, scale: float) -> Image:
	var img := Image.create(px, px, false, Image.FORMAT_RGB8)
	var half := px / 2
	for j in px:
		for i in px:
			var x := int(floor(center.x + (i - half) * scale))
			var z := int(floor(center.z + (j - half) * scale))
			img.set_pixel(i, j, gen.map_color(x, z))
	return img

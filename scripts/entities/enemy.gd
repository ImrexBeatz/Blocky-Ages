## Data-driven creature AI. Also used for summoned allies (team 0).
extends "res://scripts/entities/entity.gd"

const Projectile = preload("res://scripts/entities/projectile.gd")

var def: Dictionary
var dmg := 10.0
var ai := "melee"
var atk_range := 1.6
var atk_cd := 1.4
var cooldown := 0.0
var state := "idle"
var state_t := 0.0
var target: Node3D
var home := Vector3.ZERO
var wander_target := Vector3.ZERO
var aggro_range := 15.0
var elite := false
var is_boss := false
var summons: Array = []
var charge_dir := Vector3.ZERO
var hp_bar: Node3D
var hp_fill: MeshInstance3D
var ally_life := -1.0
var summoner_owner: Node
var think_t := 0.0
var spawn_key := ""


func setup(d: Dictionary, lvl: int, p_elite := false, p_team := 1) -> void:
	def = d
	level = lvl
	elite = p_elite
	team = p_team
	ai = d["ai"]
	var hs: float = Game.hp_scale(lvl)
	max_hp = d["hp"] * hs * (3.2 if elite else 1.0) * (1.0 + State.ascension * 0.5)
	hp = max_hp
	dmg = d["dmg"] * Game.dmg_scale(lvl) * (1.5 if elite else 1.0) * (1.0 + State.ascension * 0.3)
	speed = d["speed"]
	atk_range = d["range"]
	atk_cd = d["atk_cd"]
	scale_f = d["scale"] * (1.3 if elite else 1.0)
	radius = 0.45 * scale_f
	flying = d["model"] == "flyer"
	var m := VM.creature(d)
	m.scale = Vector3.ONE * scale_f
	set_model(m, d["model"])
	cooldown = randf_range(0.3, atk_cd)
	if elite:
		var aura := OmniLight3D.new()
		aura.visible = Settings.v["dynamic_lights"]
		aura.light_color = Color("#ff4a2a") if team == 1 else Color("#7ad6ff")
		aura.light_energy = 1.5
		aura.omni_range = 4.0
		aura.position.y = 1.5
		add_child(aura)
	_make_bar()


func _make_bar() -> void:
	hp_bar = Node3D.new()
	hp_bar.position.y = 2.3 * scale_f + (1.0 if flying else 0.0)
	add_child(hp_bar)
	var bg := MeshInstance3D.new()
	bg.mesh = U.box_mesh(Vector3(1.0, 0.1, 0.02))
	bg.material_override = U.unshaded(Color(0, 0, 0, 0.6))
	hp_bar.add_child(bg)
	hp_fill = MeshInstance3D.new()
	hp_fill.mesh = U.box_mesh(Vector3(1.0, 0.1, 0.03))
	var c := Color("#e83a3a") if team == 1 else Color("#4ae86a")
	if elite:
		c = Color("#ffb52e")
	hp_fill.material_override = U.unshaded(c)
	hp_bar.add_child(hp_fill)
	hp_bar.visible = false


func _physics_process(delta: float) -> void:
	if dead:
		return
	process_common(delta)
	if dead:
		return
	if hp_bar.visible:
		var k := clampf(hp / max_hp, 0.0, 1.0)
		hp_fill.scale.x = maxf(k, 0.001)
		hp_fill.position.x = -(1.0 - k) * 0.5
		if Game.camera:
			hp_bar.look_at(hp_bar.global_position + Game.camera.global_transform.basis.z, Vector3.UP)
	if ally_life > 0.0:
		ally_life -= delta
		if ally_life <= 0.0:
			FX.burst(global_position + Vector3(0, 1, 0), Color("#9ce0ff"), 16, 3.0)
			die(null)
			return
	cooldown -= delta
	think_t -= delta
	if think_t <= 0.0:
		think_t = 0.25
		_pick_target()
	move_amount = lerpf(move_amount, 0.0, delta * 5.0)
	if status.has("stun"):
		attack_anim = 0.0
		update_vertical(delta, 1.2 if flying else 0.0)
		return
	_think(delta)
	update_vertical(delta, 1.2 if flying else 0.0)


func _pick_target() -> void:
	var best: Node3D = null
	var bd := aggro_range
	if is_instance_valid(target) and not target.dead:
		bd = U.flat_dist(target.global_position, global_position)
		if bd < aggro_range * 1.6:
			best = target
			bd = bd * 0.8
	for t in Game.world.targets_for(team):
		var d := U.flat_dist(t.global_position, global_position)
		if d < bd:
			bd = d
			best = t
	target = best


func _walk(dir: Vector3, delta: float, mult := 1.0) -> void:
	var sm := speed_mult()
	var moved := move_flat(dir * speed * mult * sm * delta)
	move_amount = clampf(moved.length() / maxf(speed * delta, 0.001), 0.0, 1.0)
	face_dir(dir, delta)


func _separate(delta: float) -> void:
	for o in Game.world.enemies:
		if o == self or not is_instance_valid(o):
			continue
		var d: Vector3 = global_position - o.global_position
		d.y = 0
		var l := d.length()
		var min_d: float = radius + o.radius
		if l < min_d and l > 0.001:
			move_flat(d / l * (min_d - l) * delta * 4.0)


func _think(delta: float) -> void:
	state_t -= delta
	if target == null:
		attack_anim = 0.0
		_wander(delta)
		return
	var to_t := target.global_position - global_position
	to_t.y = 0
	var dist := to_t.length()
	var dir := to_t.normalized() if dist > 0.01 else facing
	if hp_bar and team == 1:
		hp_bar.visible = true
	match state:
		"windup":
			face_dir(dir, delta)
			attack_anim = clampf(1.0 - state_t / 0.4, 0.0, 1.0) * 0.3
			if state_t <= 0.0:
				_attack(dir, dist)
		"fuse":
			model.scale = Vector3.ONE * scale_f * (1.0 + (1.2 - state_t) * 0.25)
			if int(state_t * 10.0) % 2 == 0:
				flash()
			if state_t <= 0.0:
				_explode()
		"charge":
			attack_anim = 1.0
			var moved := move_flat(charge_dir * speed * 3.2 * delta)
			move_amount = 1.0
			if U.flat_dist(target.global_position, global_position) < radius + target.radius + 0.4 and not target.get("invuln") > 0.0:
				Game.world.deal_damage(self, target, dmg * 1.3, {"knock": 2.0, "dir": charge_dir})
				state = "recover"
				state_t = 0.8
			elif state_t <= 0.0 or moved.length() < 0.001:
				state = "recover"
				state_t = 0.8
		"recover":
			attack_anim = lerpf(attack_anim, 0.0, delta * 6.0)
			if state_t <= 0.0:
				state = "chase"
		_:
			attack_anim = lerpf(attack_anim, 0.0, delta * 8.0)
			_chase(dir, dist, delta)
	_separate(delta)


func _wander(delta: float) -> void:
	state_t -= delta
	if state_t <= 0.0:
		state_t = randf_range(2.0, 5.0)
		wander_target = home + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
	var d := wander_target - global_position
	d.y = 0
	if team == 0 and Game.player:
		d = Game.player.global_position - global_position
		d.y = 0
		if d.length() < 3.0:
			move_amount = 0.0
			return
	if d.length() > 0.5:
		_walk(d.normalized(), delta, 0.45 if team == 1 else 1.2)
	else:
		move_amount = 0.0


func _chase(dir: Vector3, dist: float, delta: float) -> void:
	match ai:
		"ranged", "caster", "summoner":
			var want := atk_range * 0.75
			if dist > atk_range:
				_walk(dir, delta)
			elif dist < want * 0.6:
				_walk(-dir, delta, 0.8)
			else:
				face_dir(dir, delta)
				move_amount = 0.0
			if dist <= atk_range and cooldown <= 0.0:
				_begin_windup(0.5)
		"turret":
			face_dir(dir, delta)
			if dist <= atk_range and cooldown <= 0.0:
				_begin_windup(0.6)
		"exploder":
			if dist > atk_range * 0.8:
				_walk(dir, delta)
			else:
				state = "fuse"
				state_t = 1.2
				Sfx.play("magic", 0.5, -8.0)
		"charger":
			if dist > atk_range:
				_walk(dir, delta)
			elif cooldown <= 0.0:
				_begin_windup(0.6)
			elif dist > 2.0:
				_walk(dir, delta)
			else:
				_melee_or_wait(dir, dist, delta)
		"teleporter":
			if dist > 6.0 and cooldown <= 0.0:
				_teleport_near(target.global_position)
				cooldown = 1.0
			elif dist > atk_range:
				_walk(dir, delta)
			else:
				_melee_or_wait(dir, dist, delta)
		_:
			_melee_or_wait(dir, dist, delta)


func _melee_or_wait(dir: Vector3, dist: float, delta: float) -> void:
	var reach := atk_range * scale_f * 0.8 + radius
	if dist > reach:
		_walk(dir, delta)
	else:
		face_dir(dir, delta)
		move_amount = 0.0
		if cooldown <= 0.0:
			_begin_windup(0.4)


func _begin_windup(t: float) -> void:
	state = "windup"
	state_t = t
	flash()


func _attack(dir: Vector3, dist: float) -> void:
	cooldown = atk_cd * randf_range(0.85, 1.15)
	state = "recover"
	state_t = 0.35
	attack_anim = 1.0
	match ai:
		"ranged", "turret":
			var p := Projectile.new()
			var from := global_position + Vector3(0, 1.3 * scale_f + (1.2 if flying else 0.0), 0)
			var aim: Vector3 = target.global_position + Vector3(0, 1.0, 0) - from
			p.setup("orb" if ai == "turret" or def.has("glow") else "arrow", from, aim, 16.0 if ai == "turret" else 20.0, team, dmg, def.get("proj_color", Color.WHITE))
			p.source = self
			p.effect = def.get("effect", "")
			p.effect_power = dmg * 0.3
			if def.get("homing", false):
				p.homing = target
				p.life = 4.0
			Sfx.play("bow", 1.2, -10.0)
		"caster":
			var p := Projectile.new()
			var from := global_position + Vector3(0, 1.6 * scale_f, 0)
			p.setup("orb", from, Vector3.FORWARD, 0.0, team, dmg, def.get("proj_color", Color.WHITE))
			p.source = self
			p.effect = def.get("effect", "")
			p.effect_power = dmg * 0.35
			p.explode = 1.8
			var tp: Vector3 = target.global_position + Vector3(randf_range(-1, 1), 0.2, randf_range(-1, 1))
			p.lob(tp, 0.9)
			FX.telegraph(tp, 1.8, 0.9, Color(0.8, 0.3, 1.0))
			Sfx.play("magic", 0.9, -10.0)
		"summoner":
			summons = summons.filter(func(s): return is_instance_valid(s) and not s.dead)
			if summons.size() < 5 and def.has("summon"):
				for i in 2:
					var a := randf() * TAU
					var sp := global_position + Vector3(cos(a), 0, sin(a)) * 1.5
					var s = Game.world.spawn_enemy(def["summon"], sp, level, false, team)
					if s:
						summons.append(s)
						FX.burst(sp + Vector3(0, 1, 0), Color("#c9a227"), 14, 3.0)
				Sfx.play("magic", 0.6, -6.0)
			else:
				var p := Projectile.new()
				var from := global_position + Vector3(0, 1.5, 0)
				p.setup("orb", from, target.global_position + Vector3(0, 1, 0) - from, 12.0, team, dmg, Color("#c9a227"))
				p.source = self
		"charger":
			charge_dir = dir
			state = "charge"
			state_t = 0.9
			Sfx.play("roll", 0.6, -6.0)
		_:
			var reach := atk_range * scale_f + radius + 0.5
			if dist <= reach and target.get("invuln") <= 0.0:
				Game.world.deal_damage(self, target, dmg, {"effect": def.get("effect", ""), "effect_power": dmg * 0.25, "dir": dir, "knock": 0.6})
			Sfx.play("swing", 0.8, -10.0)


func _explode() -> void:
	var r := 3.2
	FX.burst(global_position + Vector3(0, 0.8, 0), Color("#f0f0f0"), 30, 8.0, 0.25, 0.7)
	FX.ring(global_position, r, Color("#ffcc66"))
	FX.light_flash(global_position, Color("#ffcc66"), 6.0, 10.0)
	Sfx.play("explode")
	Game.add_shake(0.35)
	for t in Game.world.targets_for(team):
		if U.flat_dist(t.global_position, global_position) < r + t.radius:
			Game.world.deal_damage(self, t, dmg, {"knock": 3.0, "dir": U.flat_dir(global_position, t.global_position), "effect": def.get("effect", ""), "effect_power": dmg * 0.2})
	if def.get("effect", "") == "poison":
		Game.world.spawn_zone(global_position, 3.0, 5.0, dmg * 0.2, team, Color(0.5, 1.0, 0.3, 0.35), "poison", self)
	die(null)


func _teleport_near(p: Vector3) -> void:
	FX.burst(global_position + Vector3(0, 1, 0), Color("#b07aff"), 16, 3.0)
	for i in 8:
		var a := randf() * TAU
		var q := p + Vector3(cos(a), 0, sin(a)) * randf_range(1.8, 3.0)
		var g: float = Game.world.ground_at(q.x, q.z)
		if g > -500.0 and not Game.world.is_blocked(q.x, q.z):
			global_position = Vector3(q.x, g, q.z)
			break
	FX.burst(global_position + Vector3(0, 1, 0), Color("#b07aff"), 16, 3.0)
	Sfx.play("portal", 2.0, -12.0)


func take_damage(amount: float, source, opts := {}) -> float:
	if dead:
		return 0.0
	if source and is_instance_valid(source) and source.get("team") != team:
		target = source
	if hp_bar and team == 1:
		hp_bar.visible = true
	return super.take_damage(amount, source, opts)


func die(source) -> void:
	if dead:
		return
	if Game.world:
		Game.world.on_enemy_died(self, source)
	FX.burst(global_position + Vector3(0, 1, 0), def.get("c1", Color.GRAY), 18, 4.0, 0.18, 0.7, 0.5)
	super.die(source)

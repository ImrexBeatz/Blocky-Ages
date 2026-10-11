## Boss controller: phased attack patterns with telegraphs, summons, novas, meteors and charges.
extends "res://scripts/entities/enemy.gd"

var attacks: Array = []
var attack_ix := 0
var special_cd := 3.0
var phase := 1
var arena_center := Vector3.ZERO
var arena_radius := 30.0
var busy := 0.0
var pending: Array = []
var boss_order := 0
var engaged := false


func setup_boss(d: Dictionary, lvl: int, center: Vector3) -> void:
	def = d
	is_boss = true
	level = lvl
	team = 1
	ai = "boss"
	boss_order = int(Data.dim_index[d["dim"]]) * 4 + int(d["index"])
	max_hp = 650.0 * (1.0 + boss_order * 0.28) * Game.hp_scale(lvl) * (1.0 + State.ascension * 0.6)
	hp = max_hp
	dmg = 11.0 * (1.0 + boss_order * 0.12) * Game.dmg_scale(lvl) * (1.0 + State.ascension * 0.3)
	speed = d["speed"]
	atk_range = 2.2
	atk_cd = 1.5
	scale_f = d["scale"]
	radius = 0.5 * scale_f
	flying = d["model"] in ["flyer", "wyrm"]
	attacks = d["attacks"]
	arena_center = center
	home = center
	aggro_range = 34.0
	var m := VM.creature(d)
	m.scale = Vector3.ONE * scale_f
	set_model(m, d["model"])
	var l := OmniLight3D.new()
	l.visible = Settings.v["dynamic_lights"]
	l.light_color = Color(d["c3"]).lerp(Color.WHITE, 0.55)
	l.light_energy = 0.9
	l.omni_range = 3.0 * scale_f
	l.position.y = 0.4
	add_child(l)
	_make_bar()
	hp_bar.visible = false


func _physics_process(delta: float) -> void:
	if dead:
		return
	process_common(delta)
	if dead:
		return
	cooldown -= delta
	special_cd -= delta
	busy -= delta
	think_t -= delta
	if think_t <= 0.0:
		think_t = 0.3
		_pick_target()
	_process_pending(delta)
	if not engaged and target != null:
		engaged = true
		Game.boss_engaged.emit(self)
		Sfx.play("boss")
		Game.banner.emit(def["name"], def["title"])
		Game.toast(def["intro"], Color("#ffb0a0"))
	if engaged and (target == null or U.flat_dist(Game.player.global_position, arena_center) > arena_radius + 14.0):
		_reset()
		update_vertical(delta, 1.6 if flying else 0.0)
		return
	var new_phase := 1
	if hp < max_hp * 0.5:
		new_phase = 2
	if hp < max_hp * 0.2:
		new_phase = 3
	if new_phase != phase:
		phase = new_phase
		Game.toast("%s grows enraged!" % def["name"], Color("#ff6a4a"))
		FX.ring(global_position, 8.0, def["c3"])
		Game.add_shake(0.4)
		Sfx.play("boss", 1.2)
		speed = def["speed"] * (1.0 + (phase - 1) * 0.2)
	if status.has("stun"):
		update_vertical(delta, 1.6 if flying else 0.0)
		return
	if target and busy <= 0.0:
		_think(delta)
		if special_cd <= 0.0 and state != "charge":
			_special()
	update_vertical(delta, 1.6 if flying else 0.0)


func _reset() -> void:
	engaged = false
	target = null
	hp = max_hp
	state = "idle"
	global_position = Vector3(arena_center.x, global_position.y, arena_center.z)
	Game.boss_cleared.emit()
	Game.toast("%s returns to its lair." % def["name"], Color("#cccccc"))


func _chase(dir: Vector3, dist: float, delta: float) -> void:
	if def["model"] == "heart" or speed <= 0.0:
		face_dir(dir, delta)
		if dist < 4.0 and cooldown <= 0.0:
			_begin_windup(0.5)
		return
	_melee_or_wait(dir, dist, delta)


func _attack(dir: Vector3, dist: float) -> void:
	if ai == "charger":
		super._attack(dir, dist)
		return
	cooldown = atk_cd / (1.0 + (phase - 1) * 0.3)
	state = "recover"
	state_t = 0.4
	attack_anim = 1.0
	var reach := atk_range * scale_f * 0.6 + radius + 0.8
	if def["model"] == "heart":
		reach = 4.5
	if dist <= reach and target.get("invuln") <= 0.0:
		Game.world.deal_damage(self, target, dmg, {"dir": dir, "knock": 1.5})
		Game.add_shake(0.15)
	Sfx.play("swing", 0.6, -4.0)


func _special() -> void:
	var name: String = attacks[attack_ix % attacks.size()]
	attack_ix += 1
	special_cd = randf_range(3.2, 4.4) / (1.0 + (phase - 1) * 0.35)
	var tp: Vector3 = target.global_position
	match name:
		"slam":
			var r := 4.0 + scale_f * 0.6
			_telegraph_then(global_position, r, 1.0, func(): _aoe(global_position, r, dmg * 1.4, 2.5, def["c3"]))
			busy = 1.1
			attack_anim = 0.2
		"charge":
			if speed > 0.0:
				charge_dir = U.flat_dir(global_position, tp)
				state = "windup"
				state_t = 0.7
				ai = "charger"
				_queue(0.75, func(): ai = "boss")
				flash()
		"volley":
			var n := 7 + phase * 2
			for v in (1 if phase == 1 else 2):
				_queue(0.4 + v * 0.6, func(): _fan(n, 0.9))
			busy = 0.5
		"nova":
			_queue(0.3, func(): _ring_shot(14 + phase * 4))
			if phase >= 2:
				_queue(1.0, func(): _ring_shot(14 + phase * 4, 0.2))
			busy = 0.6
		"summon":
			var mdef: String = def["minions"]
			var count := 2 + phase
			Game.toast("%s calls for aid!" % def["name"], Color("#ffcc88"))
			for i in count:
				var a := TAU * i / count
				var sp := global_position + Vector3(cos(a), 0, sin(a)) * (radius + 2.0)
				_queue(0.2 * i, func(): Game.world.spawn_enemy(mdef, sp, level, false, 1))
			FX.ring(global_position, 5.0, def["c3"])
			Sfx.play("magic", 0.5)
			busy = 0.8
		"meteor":
			var count := 4 + phase * 2
			for i in count:
				var p: Vector3 = tp + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
				if i == 0:
					p = tp
				var gy: float = Game.world.ground_at(p.x, p.z)
				if gy < -500:
					continue
				p.y = gy
				_telegraph_then(p, 2.4, 1.3 + i * 0.12, func(): _aoe(p, 2.4, dmg * 1.2, 1.0, Color("#ff7a2a"), true))
			busy = 0.6
		"teleport":
			_teleport_near(tp)
			var r2 := 3.5 + scale_f * 0.4
			_telegraph_then(global_position, r2, 0.75, func(): _aoe(global_position, r2, dmg * 1.2, 2.0, def["c3"]))
			busy = 0.9
		"poison_pool":
			for i in 3:
				var p2: Vector3 = tp + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
				var gy2: float = Game.world.ground_at(p2.x, p2.z)
				if gy2 < -500:
					continue
				p2.y = gy2
				Game.world.spawn_zone(p2, 2.6, 7.0, dmg * 0.35, 1, Color(0.5, 1.0, 0.3, 0.35), "poison", self)
			Sfx.play("magic", 0.7)
			busy = 0.5


func _queue(t: float, f: Callable) -> void:
	pending.append([t, f])


func _process_pending(delta: float) -> void:
	for i in range(pending.size() - 1, -1, -1):
		pending[i][0] -= delta
		if pending[i][0] <= 0.0:
			var f: Callable = pending[i][1]
			pending.remove_at(i)
			if not dead:
				f.call()


func _telegraph_then(p: Vector3, r: float, t: float, f: Callable) -> void:
	FX.telegraph(p, r, t)
	_queue(t, f)


func _aoe(p: Vector3, r: float, amount: float, kb: float, c: Color, meteor := false) -> void:
	if meteor:
		FX.beam(p + Vector3(0, 14, 0), p, Color("#ff9a3a"), 0.8, 0.25)
	FX.ring(p, r, c)
	FX.burst(p + Vector3(0, 0.3, 0), c, 26, 7.0, 0.2, 0.6)
	FX.light_flash(p, c, 4.0, r * 3.0)
	Game.add_shake(0.3)
	Sfx.play("explode", 0.8, -4.0)
	for t in Game.world.targets_for(1):
		if U.flat_dist(t.global_position, p) < r + t.radius and absf(t.global_position.y - p.y) < 3.0:
			Game.world.deal_damage(self, t, amount, {"knock": kb, "dir": U.flat_dir(p, t.global_position)})


func _fan(n: int, spread: float) -> void:
	if target == null:
		return
	var from := global_position + Vector3(0, 1.4 * scale_f * 0.6 + (1.2 if flying else 0.0), 0)
	var base := U.flat_dir(global_position, target.global_position)
	var ang := atan2(base.x, base.z)
	for i in n:
		var a := ang + (float(i) / maxf(n - 1, 1) - 0.5) * spread
		var p := Projectile.new()
		p.setup("orb", from, Vector3(sin(a), 0, cos(a)), 14.0, 1, dmg * 0.7, def["c3"])
		p.source = self
		p.life = 3.0
	Sfx.play("magic", 1.4, -6.0)


func _ring_shot(n: int, offset := 0.0) -> void:
	var from := global_position + Vector3(0, 1.0 + (1.2 if flying else 0.0), 0)
	for i in n:
		var a := TAU * i / n + offset
		var p := Projectile.new()
		p.setup("orb", from, Vector3(cos(a), 0, sin(a)), 11.0, 1, dmg * 0.6, def["c2"])
		p.source = self
		p.life = 3.0
	FX.ring(global_position, 3.0, def["c2"])
	Sfx.play("magic", 0.8, -4.0)


func die(source) -> void:
	if dead:
		return
	Game.boss_cleared.emit()
	super.die(source)

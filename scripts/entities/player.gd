## The Wayfinder: input, melee combos, ranged shots, dodge rolls, potions, artifacts and power-ups.
extends "res://scripts/entities/entity.gd"

const Projectile = preload("res://scripts/entities/projectile.gd")
const Abilities = preload("res://scripts/entities/abilities.gd")

var attack_t := 0.0
var attack_dur := 0.45
var attack_cd := 0.0
var combo := 0
var combo_timer := 0.0
var swing_hit := false
var ranged_cd := 0.0
var roll_t := 0.0
var roll_cd := 0.0
var roll_dir := Vector3.ZERO
var potion_cd := 0.0
var art_cd := [0.0, 0.0, 0.0]
var art_cd_max := [1.0, 1.0, 1.0]
var powerups := {}
var buffs := {}
var aim_point := Vector3.ZERO
var combat_t := 10.0
var second_wind_cd := 0.0
var light: OmniLight3D
var interact_target: Node
var bow_node: Node3D
var blades_node: Node3D
var blade_tick := 0.0
var aura_tick := 0.0
var actions: Array = []
var dash_t := 0.0
var dash_dir := Vector3.ZERO
var dash_speed := 0.0
var dash_dmg := 0.0
var dash_hit := {}
var bow_show := 0.0
var step_t := 0.0
var interact_scan := 0.0


func _ready() -> void:
	team = 0
	radius = 0.4
	step_up = 1.3
	light = OmniLight3D.new()
	light.light_color = Color("#ffe2b0")
	light.light_energy = 0.6
	light.omni_range = 7.0
	light.position = Vector3(0, 2.2, 0)
	light.shadow_enabled = false
	add_child(light)
	rebuild_model()
	State.inventory_changed.connect(rebuild_model)
	State.stats_changed.connect(_on_stats)
	State.leveled_up.connect(func(_l):
		if is_inside_tree():
			hp = max_hp
			FX.burst(global_position + Vector3(0, 1, 0), Color("#ffd84a"), 40, 6.0, 0.16, 1.0, 3.0)
			FX.ring(global_position, 4.0, Color("#ffd84a"), 0.7)
			FX.light_flash(global_position, Color("#ffd84a"), 6.0, 12.0, 0.8)
			FX.beam(global_position, global_position + Vector3(0, 14, 0), Color("#ffe9a0"), 0.8, 0.8))
	_on_stats()
	hp = max_hp


func _on_stats() -> void:
	var old := max_hp
	max_hp = State.stats.get("max_hp", 100.0) * (1.5 if has_powerup("giant") else 1.0)
	if old > 0.0:
		hp = minf(max_hp, hp * max_hp / old) if hp > 0 else hp


func rebuild_model() -> void:
	var pr := State.profile
	var opts := {
		"skin": State.color("skin"), "hair": State.color("hair"), "hair_style": int(pr.get("hair_style", 0)), "eyes": State.color("eyes"),
		"shirt": State.color("shirt"), "pants": State.color("pants"), "boots": State.color("boots"), "cape": pr.get("cape", true),
		"cape_color": State.color("cape_color"), "hat": int(pr.get("hat", 0)), "brow": true,
	}
	var armor = State.equipment.get("armor")
	if armor != null:
		var ad := State.def_of(armor)
		if armor["id"] != "tunic":
			opts["armor"] = ad["color"]
			opts["armor_accent"] = ad["accent"]
	var m := VM.humanoid(opts)
	var parts: Dictionary = m.get_meta("parts")
	var melee = State.equipment.get("melee")
	if melee != null:
		var md := State.def_of(melee)
		var wm := VM.weapon(md["sub"], md["color"], md["accent"], 0.3 * melee["rarity"])
		parts["hand"].add_child(wm)
		if md["sub"] == "gauntlets" or md["sub"] == "dagger":
			var wl := VM.weapon(md["sub"], md["color"], md["accent"], 0.3 * melee["rarity"])
			parts["hand_l"].add_child(wl)
	var ranged = State.equipment.get("ranged")
	if ranged != null:
		var rd := State.def_of(ranged)
		bow_node = VM.weapon(rd["sub"], rd["color"], rd["color"], rd.get("glow", 0.0))
		bow_node.rotation.x = PI * 0.5
		parts["hand_l"].add_child(bow_node)
		bow_node.visible = false
	var rot := model.rotation.y if model else 0.0
	set_model(m, "player")
	model.rotation.y = rot
	if has_powerup("giant"):
		model.scale = Vector3.ONE * 1.5


func has_powerup(id: String) -> bool:
	return powerups.has(id)


func add_powerup(id: String) -> void:
	var p: Dictionary = Data.powerups[id]
	powerups[id] = p["dur"]
	Game.banner.emit(p["name"], p["desc"])
	Sfx.play("levelup", 1.4, -4.0)
	FX.burst(global_position + Vector3(0, 1, 0), p["color"], 30, 5.0)
	if id == "giant":
		model.scale = Vector3.ONE * 1.5
		_on_stats()
		hp = max_hp
	Game.powerup_changed.emit()


func add_buff(id: String, dur: float, power: float) -> void:
	buffs[id] = {"t": dur, "power": power}
	if id == "blades":
		_make_blades()


func queue_action(t: float, f: Callable) -> void:
	actions.append([t, f])


func start_dash(dir: Vector3, t: float, spd: float, dmg_v: float) -> void:
	dash_t = t
	dash_dir = dir
	dash_speed = spd
	dash_dmg = dmg_v
	dash_hit = {}
	invuln = t + 0.1
	face_now(dir)


func _make_blades() -> void:
	if blades_node:
		blades_node.queue_free()
	blades_node = Node3D.new()
	add_child(blades_node)
	for i in 3:
		var b := Node3D.new()
		var a := TAU * i / 3.0
		b.position = Vector3(cos(a) * 2.2, 1.1, sin(a) * 2.2)
		b.rotation.y = -a
		blades_node.add_child(b)
		U.box(b, Vector3(0.12, 0.08, 0.9), Vector3.ZERO, Color("#c48aff"), 3.0)


func _physics_process(delta: float) -> void:
	if dead:
		return
	process_common(delta)
	_timers(delta)
	_aim()
	var active: bool = Game.in_game and not Game.ui_open
	var move_dir := Vector3.ZERO
	if active:
		var iv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if Game.camera:
			var b := Game.camera.global_transform.basis
			var fwd := -b.z
			fwd.y = 0
			fwd = fwd.normalized()
			var right := b.x
			right.y = 0
			right = right.normalized()
			move_dir = right * iv.x - fwd * iv.y
		if move_dir.length() > 1.0:
			move_dir = move_dir.normalized()
	var spd: float = 5.6 * (1.0 + State.stats.get("speed_pct", 0.0)) * speed_mult()
	if has_powerup("swift"):
		spd *= 1.5
	if buffs.has("haste"):
		spd *= 1.0 + buffs["haste"]["power"]
	if attack_t > 0.0:
		spd *= 0.45
	var gnow: float = Game.world.ground_at(global_position.x, global_position.z) if Game.world else 0.0
	var wading := gnow > -500.0 and absf(gnow - round(gnow)) > 0.3
	if wading:
		spd *= 0.7
		if Game.world.surface_gen and Game.world.surface_gen.liquid == "toxic" and not Game.world.in_cave and not status.has("poison"):
			apply_status("poison", 2.0, max_hp * 0.02)
	if dash_t > 0.0:
		dash_t -= delta
		move_flat(dash_dir * dash_speed * delta)
		move_amount = 1.0
		FX.burst(global_position + Vector3(0, 0.8, 0), Color("#ffb52e"), 2, 1.0, 0.18, 0.3)
		for e in Game.world.targets_for(0):
			if not dash_hit.has(e.get_instance_id()) and U.flat_dist(e.global_position, global_position) < 1.6 + e.radius:
				dash_hit[e.get_instance_id()] = true
				Game.world.deal_damage(self, e, dash_dmg, {"effect": "burn", "effect_power": dash_dmg * 0.1, "knock": 1.5, "dir": dash_dir})
	elif roll_t > 0.0:
		roll_t -= delta
		move_flat(roll_dir * 15.0 * delta)
		move_amount = 1.0
		if model:
			model.rotation.x = 0.0
	elif move_dir.length() > 0.05:
		var moved := move_flat(move_dir * spd * delta)
		move_amount = clampf(moved.length() / maxf(spd * delta, 0.0001), 0.0, 1.0) * move_dir.length()
		if attack_t <= 0.0:
			face_dir(move_dir, delta)
		step_t += delta * move_amount
	else:
		move_amount = lerpf(move_amount, 0.0, delta * 10.0)
	update_vertical(delta)
	if global_position.y < -40.0:
		_fall_rescue()
	if active:
		_handle_actions(move_dir)
	_update_attack(delta)
	_update_interact(delta)
	if Game.world:
		light.visible = Game.world.in_cave or Settings.v["dynamic_lights"]
		light.omni_range = 14.0 if Game.world.in_cave else (9.0 if Game.world.is_night() else 6.0)
		light.light_energy = 1.6 if Game.world.in_cave else (1.0 if Game.world.is_night() else 0.35)


func _fall_rescue() -> void:
	var sp: Vector3 = Game.world.safe_point_near(global_position)
	global_position = sp
	take_damage(max_hp * 0.1, null, {})


func _timers(delta: float) -> void:
	attack_cd -= delta
	ranged_cd -= delta
	roll_cd -= delta
	potion_cd -= delta
	second_wind_cd -= delta
	combo_timer -= delta
	combat_t += delta
	bow_show -= delta
	if bow_node:
		bow_node.visible = bow_show > 0.0
	if combo_timer <= 0.0:
		combo = 0
	var arcane := 4.0 if has_powerup("arcane") else 1.0
	for i in 3:
		art_cd[i] = maxf(0.0, art_cd[i] - delta * arcane)
	for k in powerups.keys():
		powerups[k] -= delta
		if powerups[k] <= 0.0:
			powerups.erase(k)
			if k == "giant" and model:
				model.scale = Vector3.ONE
				_on_stats()
			Game.powerup_changed.emit()
	for k in buffs.keys():
		buffs[k]["t"] -= delta
		if buffs[k]["t"] <= 0.0:
			buffs.erase(k)
			if k == "blades" and blades_node:
				blades_node.queue_free()
				blades_node = null
	for i in range(actions.size() - 1, -1, -1):
		actions[i][0] -= delta
		if actions[i][0] <= 0.0:
			var f: Callable = actions[i][1]
			actions.remove_at(i)
			f.call()
	# Regeneration
	var regen: float = State.stats.get("regen", 0.5)
	if combat_t > 5.0:
		regen *= 4.0
	if has_powerup("regen"):
		regen += max_hp * 0.06
	if buffs.has("regen"):
		regen += buffs["regen"]["power"]
	heal(regen * delta)
	# Spirit blades
	if blades_node:
		blades_node.rotation.y += delta * 6.0
		blade_tick -= delta
		if blade_tick <= 0.0:
			blade_tick = 0.25
			for e in Game.world.targets_for(0):
				var dd := U.flat_dist(e.global_position, global_position)
				if dd < 2.9 + e.radius and dd > 1.2:
					Game.world.deal_damage(self, e, buffs["blades"]["power"] * 0.35, {})
	var aura: float = State.stats.get("aura_burn", 0.0)
	if aura > 0.0:
		aura_tick -= delta
		if aura_tick <= 0.0:
			aura_tick = 1.0
			for e in Game.world.targets_for(0):
				if U.flat_dist(e.global_position, global_position) < 3.5:
					e.apply_status("burn", 2.0, 4.0 * aura * Game.dmg_scale(State.level))


func _nearest_enemy(max_d: float) -> Node3D:
	var best: Node3D = null
	var bd := max_d
	for e in Game.world.targets_for(0):
		var d := U.flat_dist(e.global_position, global_position)
		if d < bd:
			bd = d
			best = e
	return best


func _aim() -> void:
	if Game.camera == null:
		return
	if Settings.is_mobile:
		var t := _nearest_enemy(13.0)
		aim_point = t.global_position if t else global_position + facing * 6.0
		return
	if not Input.get_connected_joypads().is_empty() and Input.get_vector("move_left", "move_right", "move_up", "move_down").length() > 0.2:
		aim_point = global_position + facing * 6.0
		return
	var vp := get_viewport()
	var mp := vp.get_mouse_position()
	var from := Game.camera.project_ray_origin(mp)
	var dir := Game.camera.project_ray_normal(mp)
	var plane_y := global_position.y + 1.0
	if absf(dir.y) > 0.001:
		var t := (plane_y - from.y) / dir.y
		if t > 0.0:
			aim_point = from + dir * t
			aim_point.y = global_position.y
			return
	aim_point = global_position + facing * 5.0


func _handle_actions(move_dir: Vector3) -> void:
	if Input.is_action_just_pressed("roll") and roll_cd <= 0.0 and roll_t <= 0.0:
		roll_dir = move_dir.normalized() if move_dir.length() > 0.1 else facing
		roll_t = 0.32
		invuln = 0.36
		var cd: float = 1.1 * (1.0 - State.stats.get("roll_cd", 0.0))
		if State.has_perk("swift_roll"):
			cd *= 0.6
		roll_cd = cd
		attack_t = 0.0
		face_now(roll_dir)
		Sfx.play("roll")
		FX.burst(global_position + Vector3(0, 0.3, 0), Color("#d8d0c0"), 8, 2.0, 0.12, 0.4, 0.0)
		return
	if roll_t > 0.0 or dash_t > 0.0:
		return
	if Settings.is_mobile and Settings.auto_attack and _auto_attack():
		pass
	elif Input.is_action_pressed("attack") and attack_cd <= 0.0:
		_start_swing()
	elif Input.is_action_pressed("ranged") and ranged_cd <= 0.0 and attack_t <= 0.0:
		_fire()
	if Input.is_action_just_pressed("potion"):
		drink_potion()
	for i in 3:
		if Input.is_action_just_pressed("art%d" % (i + 1)):
			use_artifact(i)
	if Input.is_action_just_pressed("interact") and interact_target and is_instance_valid(interact_target):
		if interact_target.has_method("interact"):
			interact_target.interact()
		elif interact_target.has_method("use"):
			interact_target.use()


## Phone-only: swing at enemies in reach, otherwise shoot the nearest enemy in range. True if it acted.
func _auto_attack() -> bool:
	if attack_t > 0.0:
		return true
	var reach: float = State.def_of(State.equipment.get("melee")).get("range", 2.4) if State.equipment.get("melee") != null else 0.0
	var close := _nearest_enemy(reach + 0.6)
	if close and attack_cd <= 0.0:
		aim_point = close.global_position
		_start_swing()
		return true
	if close:
		return false
	var far := _nearest_enemy(12.0)
	if far and ranged_cd <= 0.0 and State.equipment.get("ranged") != null:
		aim_point = far.global_position
		_fire()
		return true
	return false


func _weapon_speed() -> float:
	var melee = State.equipment.get("melee")
	var s: float = State.def_of(melee).get("speed", 0.45) if melee != null else 0.45
	if buffs.has("haste"):
		s /= 1.3
	return s


func _start_swing() -> void:
	var melee = State.equipment.get("melee")
	if melee == null:
		return
	var aim_dir := U.flat_dir(global_position, aim_point)
	face_now(aim_dir)
	attack_dur = _weapon_speed()
	if combo == 2:
		attack_dur *= 1.35
	attack_t = attack_dur
	attack_cd = attack_dur
	swing_hit = false
	combat_t = 0.0
	Sfx.play("swing", 1.0 + combo * 0.1, -6.0)


func _update_attack(delta: float) -> void:
	if attack_t <= 0.0:
		attack_anim = lerpf(attack_anim, 0.0, delta * 10.0)
		return
	attack_t -= delta
	var k := 1.0 - attack_t / attack_dur
	attack_anim = clampf(k * 1.4, 0.0, 1.0)
	if not swing_hit and k >= 0.35:
		swing_hit = true
		_melee_hit()
	if attack_t <= 0.0:
		combo = (combo + 1) % 3
		combo_timer = 0.9


func _melee_hit() -> void:
	var melee = State.equipment.get("melee")
	var md := State.def_of(melee)
	var finisher := combo == 2
	var rng: float = md.get("range", 2.4) * (1.5 if has_powerup("giant") else 1.0)
	var arc: float = md.get("arc", 100.0)
	if finisher and State.ench_level(melee, "swirling") > 0:
		arc = 360.0
		rng *= 1.2
	var base: float = State.weapon_damage(melee) * (1.0 + State.stats.get("melee_pct", 0.0))
	if finisher:
		base *= 1.5 + (0.6 if State.has_perk("combo_master") else 0.0)
	base *= _global_mult()
	var hit_any := false
	var cos_half := cos(deg_to_rad(arc * 0.5))
	for e in Game.world.targets_for(0):
		var to_e: Vector3 = e.global_position - global_position
		to_e.y = 0
		var dist := to_e.length()
		if dist > rng + e.radius:
			continue
		if dist > 0.4 and to_e.normalized().dot(facing) < cos_half:
			continue
		var crit: bool = randf() < State.stats.get("crit", 0.05)
		var amount := base * (2.0 if crit else 1.0) * randf_range(0.92, 1.08)
		if State.has_perk("executioner") and e.hp < e.max_hp * 0.3:
			amount *= 1.5
		var eff: String = md.get("effect", "")
		if State.ench_level(melee, "fire_aspect") > 0:
			eff = "burn"
		elif State.ench_level(melee, "freezing") > 0 and eff == "":
			eff = "freeze"
		var kb: float = md.get("knockback", 0.6) * (2.0 if finisher else 1.0)
		var dealt: float = Game.world.deal_damage(self, e, amount, {"crit": crit, "effect": eff, "effect_power": amount * 0.25, "knock": kb, "dir": to_e.normalized(), "melee": true})
		hit_any = true
		var cdr_hit: float = md.get("cdr_on_hit", 0.0)
		if cdr_hit > 0.0:
			for i in 3:
				art_cd[i] = maxf(0.0, art_cd[i] - cdr_hit * 2.0)
		var chains := State.ench_level(melee, "chains")
		if chains > 0 and randf() < 0.15 * chains:
			var hit := {e.get_instance_id(): true}
			var from: Vector3 = e.global_position + Vector3(0, 1, 0)
			for e2 in Game.world.targets_for(0):
				if hit.size() > 3:
					break
				if not hit.has(e2.get_instance_id()) and U.flat_dist(e2.global_position, e.global_position) < 5.0:
					hit[e2.get_instance_id()] = true
					FX.lightning(from, e2.global_position + Vector3(0, 1, 0))
					Game.world.deal_damage(self, e2, dealt * 0.5, {"effect": "shock"})
		if md.get("effect", "") == "shock" and finisher:
			FX.lightning(e.global_position + Vector3(0, 12, 0), e.global_position)
			Game.world.deal_damage(self, e, amount * 0.6, {"effect": "shock"})
	if hit_any:
		Sfx.play("hit", randf_range(0.9, 1.1), -4.0)
		if finisher:
			Game.add_shake(0.12)
	var sc: Color = md.get("color", Color.WHITE)
	FX.swipe(global_position, facing, rng, arc, sc.lerp(Color.WHITE, 0.6) if not finisher else Color("#ffd84a"))


func _global_mult() -> float:
	var m := 1.0
	if has_powerup("rage"):
		m *= 2.0
	if has_powerup("giant"):
		m *= 1.5
	if State.has_perk("berserker"):
		m *= 1.0 + 0.4 * (1.0 - hp / max_hp)
	if State.has_perk("wayfinder"):
		m *= 1.05
	return m


func _fire() -> void:
	var ranged = State.equipment.get("ranged")
	if ranged == null:
		return
	var rd := State.def_of(ranged)
	var aim_dir := U.flat_dir(global_position, aim_point)
	face_now(aim_dir)
	var cd: float = rd["speed"]
	if State.ench_level(ranged, "infinity") > 0:
		cd *= 0.75
	if buffs.has("haste"):
		cd /= 1.3
	ranged_cd = cd
	combat_t = 0.0
	bow_show = 0.5
	attack_anim = 0.0
	var n: int = rd["multishot"] + State.ench_level(ranged, "multishot")
	var spread := 0.12 * (n - 1)
	var base: float = State.weapon_damage(ranged) * (1.0 + State.stats.get("ranged_pct", 0.0)) * _global_mult()
	var ang := atan2(aim_dir.x, aim_dir.z)
	for i in n:
		var a := ang + (0.0 if n == 1 else (float(i) / (n - 1) - 0.5) * spread * 2.0)
		var dir := Vector3(sin(a), 0, cos(a))
		var p := Projectile.new()
		var crit: bool = randf() < State.stats.get("crit", 0.05) + rd.get("crit", 0.0)
		var mult := (3.0 if State.has_perk("deadeye") else 2.0) if crit else 1.0
		p.setup("arrow" if rd["sub"] == "bow" else "bolt", global_position + Vector3(0, 1.3, 0) + dir * 0.6, dir, rd["proj_speed"], 0, base * mult, rd["color"].lightened(0.3))
		p.source = self
		p.crit = crit
		p.pierce = rd["pierce"] + State.ench_level(ranged, "piercing")
		p.effect = rd.get("effect", "")
		p.effect_power = base * 0.2
		p.knock = rd.get("knockback", 0.3)
		var ex: float = rd.get("explode", 0.0)
		if State.ench_level(ranged, "explosive") > 0:
			ex = maxf(ex, 1.8 + 0.3 * State.ench_level(ranged, "explosive"))
		p.explode = ex
		p.life = 1.4
	Sfx.play("bow", 1.0, -4.0)


func drink_potion() -> void:
	if State.potions <= 0:
		Game.toast("No potions left! Buy more from an Alchemist.", Color("#ff8a8a"))
		return
	if potion_cd > 0.0:
		return
	State.potions -= 1
	potion_cd = 10.0 if State.has_perk("potion_master") else 20.0
	heal(max_hp * 0.5 * (1.0 + State.stats.get("potion", 0.0)))
	FX.burst(global_position + Vector3(0, 1, 0), Color("#ff3a5a"), 24, 3.0)
	Sfx.play("pickup", 0.7)
	State.resources_changed.emit()


func use_artifact(i: int) -> void:
	var slot := "art%d" % (i + 1)
	var inst = State.equipment.get(slot)
	if inst == null or art_cd[i] > 0.0:
		return
	face_now(U.flat_dir(global_position, aim_point))
	Abilities.cast(self, inst)
	if State.has_perk("arcane_echo") and randf() < 0.2:
		queue_action(0.35, func(): Abilities.cast(self, inst))
	var cd: float = State.artifact_cooldown(inst)
	art_cd[i] = cd
	art_cd_max[i] = cd
	combat_t = 0.0
	attack_anim = 0.6


func _update_interact(delta: float) -> void:
	interact_scan -= delta
	if interact_scan > 0.0:
		return
	interact_scan = 0.15
	var best: Node = null
	var bd := 2.8
	if Game.world:
		for n in Game.world.interactables():
			if not is_instance_valid(n):
				continue
			if n.has_method("can_use") and not n.can_use():
				continue
			var d := U.flat_dist(n.global_position, global_position)
			if d < bd:
				bd = d
				best = n
	if best != interact_target:
		interact_target = best
		if best == null:
			Game.interact_prompt.emit("")
		elif best.has_method("interact"):
			Game.interact_prompt.emit("Talk to %s the %s" % [best.vname, Data.role(best.role)["name"]])
		else:
			Game.interact_prompt.emit(best.prompt())


func take_damage(amount: float, source, opts := {}) -> float:
	if dead or invuln > 0.0 or roll_t > 0.0:
		return 0.0
	if has_powerup("ghost"):
		return 0.0
	combat_t = 0.0
	Sfx.play("hurt", 1.0, -6.0)
	Game.add_shake(0.12)
	if hp - amount <= 0.0 and State.has_perk("second_wind") and second_wind_cd <= 0.0:
		second_wind_cd = 60.0
		hp = max_hp * 0.3
		invuln = 1.5
		Game.banner.emit("Second Wind!", "You refuse to fall.")
		FX.burst(global_position + Vector3(0, 1, 0), Color("#ffd84a"), 30, 5.0)
		return 0.0
	return super.take_damage(amount, source, opts)


func die(_source) -> void:
	dead = true
	visible = false
	FX.burst(global_position + Vector3(0, 1, 0), State.color("shirt"), 30, 5.0, 0.2, 1.0)
	Game.player_died.emit()


func respawn(at: Vector3) -> void:
	dead = false
	visible = true
	hp = max_hp
	status.clear()
	knock = Vector3.ZERO
	global_position = at
	invuln = 2.0

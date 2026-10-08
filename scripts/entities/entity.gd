## Base for everything that walks, fights and dies: heightfield movement, status effects and damage.
extends Node3D

const U = preload("res://scripts/core/util.gd")
const FX = preload("res://scripts/entities/fx.gd")
const VM = preload("res://scripts/entities/voxel_model.gd")

signal died(e: Node)

var max_hp := 100.0
var hp := 100.0
var team := 1
var radius := 0.45
var speed := 4.0
var step_up := 1.3
var flying := false
var vel_y := 0.0
var knock := Vector3.ZERO
var status := {}
var dead := false
var model: Node3D
var model_kind := "humanoid"
var anim_t := 0.0
var attack_anim := 0.0
var move_amount := 0.0
var flash_t := 0.0
var meshes: Array = []
var facing := Vector3.FORWARD
var level := 1
var invuln := 0.0
var hit_cooldown := 0.0
var scale_f := 1.0


func set_model(m: Node3D, kind: String) -> void:
	if model:
		model.queue_free()
	model = m
	model_kind = kind
	add_child(model)
	meshes.clear()
	_collect_meshes(model)


func _collect_meshes(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			meshes.append(c)
		_collect_meshes(c)


func face_dir(d: Vector3, delta: float, rate := 14.0) -> void:
	if d.length_squared() < 0.0001:
		return
	facing = Vector3(d.x, 0, d.z).normalized()
	var target := atan2(-facing.x, -facing.z)
	if model:
		model.rotation.y = lerp_angle(model.rotation.y, target, clampf(delta * rate, 0.0, 1.0))


func face_now(d: Vector3) -> void:
	if d.length_squared() < 0.0001:
		return
	facing = Vector3(d.x, 0, d.z).normalized()
	if model:
		model.rotation.y = atan2(-facing.x, -facing.z)


func speed_mult() -> float:
	var m := 1.0
	if status.has("freeze"):
		m *= 0.45
	if status.has("slow"):
		m *= 0.55
	if status.has("stun"):
		m = 0.0
	return m


## Moves horizontally, sliding along obstacles and refusing ledges that are too tall.
func move_flat(d: Vector3) -> Vector3:
	var w = Game.world
	var start := global_position
	var p := start
	if d.length_squared() < 1e-8:
		return Vector3.ZERO
	var tx := Vector3(p.x + d.x, p.y, p.z)
	if _can_enter(w, p, tx):
		p = tx
	var tz := Vector3(p.x, p.y, p.z + d.z)
	if _can_enter(w, p, tz):
		p = tz
	global_position = p
	return p - start


func _can_enter(w, from: Vector3, to: Vector3) -> bool:
	var r := radius * 0.8
	for o in [Vector3.ZERO, Vector3(r, 0, 0), Vector3(-r, 0, 0), Vector3(0, 0, r), Vector3(0, 0, -r)]:
		var q: Vector3 = to + o
		if w.is_blocked(q.x, q.z):
			var qf: Vector3 = from + o
			if not w.is_blocked(qf.x, qf.z):
				return false
	var g: float = w.ground_at(to.x, to.z)
	if flying:
		return true
	if g < -500.0:
		return false
	var cur: float = w.ground_at(from.x, from.z)
	if cur < -500.0:
		cur = from.y
	return g - cur <= step_up


func update_vertical(delta: float, hover := 0.0) -> void:
	var g: float = Game.world.ground_at(global_position.x, global_position.z)
	if flying:
		if g < -500.0:
			g = global_position.y - hover
		global_position.y = lerpf(global_position.y, g + hover, clampf(delta * 4.0, 0, 1))
		return
	if g < -500.0:
		g = global_position.y - 0.0
	if global_position.y < g:
		global_position.y = move_toward(global_position.y, g, delta * 14.0)
		vel_y = 0.0
	else:
		vel_y -= 30.0 * delta
		global_position.y = maxf(g, global_position.y + vel_y * delta)
		if global_position.y <= g:
			vel_y = 0.0


func process_common(delta: float) -> void:
	anim_t += delta
	if invuln > 0.0:
		invuln -= delta
	if knock.length_squared() > 0.01:
		move_flat(knock * delta)
		knock = knock.move_toward(Vector3.ZERO, delta * 30.0)
	if flash_t > 0.0:
		flash_t -= delta
		if flash_t <= 0.0:
			_set_flash(false)
	_process_status(delta)
	if model:
		VM.animate(model, anim_t, move_amount, attack_anim, model_kind)


func _process_status(delta: float) -> void:
	for k in status.keys():
		var s: Dictionary = status[k]
		s["t"] -= delta
		if s.has("dps"):
			s["tick"] = s.get("tick", 0.0) + delta
			if s["tick"] >= 0.5:
				s["tick"] = 0.0
				var c := Color("#ff8a3a") if k == "burn" else Color("#8aff5a")
				take_damage(s["dps"] * 0.5, null, {"color": c, "dot": true})
				if dead:
					return
		if s["t"] <= 0.0:
			status.erase(k)


func apply_status(kind: String, dur: float, dps := 0.0) -> void:
	if dead:
		return
	var s: Dictionary = status.get(kind, {"t": 0.0})
	s["t"] = maxf(s["t"], dur)
	if dps > 0.0:
		s["dps"] = maxf(s.get("dps", 0.0), dps)
	status[kind] = s
	if kind == "freeze" and model:
		FX.burst(global_position + Vector3(0, 1, 0), Color("#bff0ff"), 8, 2.0)


func knockback(dir: Vector3, force: float) -> void:
	knock += Vector3(dir.x, 0, dir.z).normalized() * force * 8.0


func _set_flash(on: bool) -> void:
	for mi in meshes:
		if is_instance_valid(mi):
			mi.material_overlay = U.flash_material() if on else null


func flash() -> void:
	flash_t = 0.1
	_set_flash(true)


## Returns damage actually taken. opts: crit, color, dot, source_pos, knock
func take_damage(amount: float, source, opts := {}) -> float:
	if dead or invuln > 0.0:
		return 0.0
	hp -= amount
	if not opts.get("dot", false):
		flash()
	var col: Color = opts.get("color", Color.WHITE if team == 1 else Color("#ff5a5a"))
	var txt := U.fmt_num(maxf(1.0, round(amount)))
	if opts.get("crit", false):
		txt += "!"
		col = Color("#ffd84a")
	FX.damage_number(global_position + Vector3(0, 1.8 * scale_f, 0), txt, col, opts.get("crit", false))
	if hp <= 0.0:
		hp = 0.0
		die(source)
	return amount


func heal(amount: float) -> void:
	if dead:
		return
	hp = minf(max_hp, hp + amount)


func die(_source) -> void:
	dead = true
	died.emit(self)
	queue_free()

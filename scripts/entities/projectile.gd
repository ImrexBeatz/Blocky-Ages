## Arrows, bolts, fireballs and magic orbs. Moves manually and checks hits against the opposing team.
extends Node3D

const U = preload("res://scripts/core/util.gd")
const FX = preload("res://scripts/entities/fx.gd")

var vel := Vector3.ZERO
var team := 0
var dmg := 10.0
var pierce := 0
var life := 2.0
var hit_radius := 0.6
var effect := ""
var effect_power := 0.0
var explode := 0.0
var homing: Node3D
var source: Node
var crit := false
var color := Color.WHITE
var kind := "arrow"
var knock := 0.0
var hits := {}
var lob_target := Vector3.INF
var lob_time := 0.0
var lob_total := 0.0
var lob_start := Vector3.ZERO
var on_hit: Callable


func setup(p_kind: String, from: Vector3, dir: Vector3, spd: float, p_team: int, p_dmg: float, p_color: Color) -> void:
	kind = p_kind
	team = p_team
	dmg = p_dmg
	color = p_color
	vel = dir.normalized() * spd
	var mesh := MeshInstance3D.new()
	match kind:
		"arrow":
			mesh.mesh = U.box_mesh(Vector3(0.07, 0.07, 0.7))
			mesh.material_override = U.mat(color, 0.6)
		"bolt":
			mesh.mesh = U.box_mesh(Vector3(0.1, 0.1, 0.55))
			mesh.material_override = U.mat(color, 1.2)
		"orb", "fireball", "homing":
			mesh.mesh = U.box_mesh(Vector3(0.35, 0.35, 0.35))
			mesh.material_override = U.mat(color, 3.0, 0.5, false)
			var l := OmniLight3D.new()
			l.visible = Settings.v["dynamic_lights"]
			l.light_color = color
			l.light_energy = 1.5
			l.omni_range = 3.5
			add_child(l)
		_:
			mesh.mesh = U.box_mesh(Vector3(0.25, 0.25, 0.25))
			mesh.material_override = U.mat(color, 2.0, 0.5, false)
	add_child(mesh)
	if kind in ["orb", "fireball", "homing"]:
		var trail := CPUParticles3D.new()
		trail.amount = 16
		trail.lifetime = 0.35
		trail.local_coords = false
		trail.direction = Vector3.UP
		trail.spread = 180
		trail.initial_velocity_min = 0.2
		trail.initial_velocity_max = 0.8
		trail.gravity = Vector3.ZERO
		var tm := BoxMesh.new()
		tm.size = Vector3.ONE * 0.12
		tm.material = U.mat(color, 2.5, 0.5, false)
		trail.mesh = tm
		add_child(trail)
	Game.world.fx_root.add_child(self)
	global_position = from
	if vel.length_squared() > 0.001:
		look_at(from + vel, Vector3.UP)


## Lobbed projectile that lands at `target` after `t` seconds, then bursts.
func lob(target: Vector3, t: float) -> void:
	lob_target = target
	lob_total = t
	lob_time = 0.0
	lob_start = global_position


func _physics_process(delta: float) -> void:
	life -= delta
	if lob_target != Vector3.INF:
		lob_time += delta
		var k := clampf(lob_time / lob_total, 0.0, 1.0)
		var p := lob_start.lerp(lob_target, k)
		p.y += sin(k * PI) * 3.0
		global_position = p
		rotation.x += delta * 8.0
		if k >= 1.0:
			_burst()
		return
	if is_instance_valid(homing) and not homing.get("dead"):
		var want: Vector3 = (homing.global_position + Vector3(0, 1.0, 0) - global_position).normalized() * vel.length()
		vel = vel.lerp(want, clampf(delta * 2.5, 0, 1))
	global_position += vel * delta
	if vel.length_squared() > 0.01:
		look_at(global_position + vel, Vector3.UP)
	var g: float = Game.world.ground_at(global_position.x, global_position.z)
	if (g > -500.0 and global_position.y < g - 0.05) or Game.world.is_blocked(global_position.x, global_position.z) or life <= 0.0:
		if explode > 0.0 or kind in ["orb", "fireball"]:
			_burst()
		else:
			FX.burst(global_position, color, 4, 2.0, 0.08, 0.3)
			queue_free()
		return
	for e in Game.world.targets_for(team):
		if hits.has(e.get_instance_id()):
			continue
		var ep: Vector3 = e.global_position
		var er: float = e.radius
		if U.flat_dist(ep, global_position) < hit_radius + er and global_position.y > ep.y - 0.5 and global_position.y < ep.y + 2.6 * e.scale_f:
			hits[e.get_instance_id()] = true
			if explode > 0.0:
				_burst()
				return
			_hit(e)
			if pierce <= 0:
				queue_free()
				return
			pierce -= 1


func _hit(e: Node) -> void:
	var dealt: float = Game.world.deal_damage(source, e, dmg, {"crit": crit, "effect": effect, "effect_power": effect_power, "knock": knock, "dir": vel.normalized(), "ranged": true})
	if on_hit.is_valid():
		on_hit.call(e, dealt)
	FX.burst(global_position, color, 6, 2.5, 0.08, 0.3)


func _burst() -> void:
	var r := maxf(explode, 1.8)
	FX.burst(global_position, color, 22, 6.0, 0.16, 0.6, 2.5)
	FX.ring(global_position - Vector3(0, 0.5, 0), r, color)
	FX.light_flash(global_position, color, 5.0, r * 3.0)
	if kind == "fireball" or explode > 2.0:
		Sfx.play("explode", 1.2, -6.0)
		Game.add_shake(0.15)
	for e in Game.world.targets_for(team):
		if U.flat_dist(e.global_position, global_position) < r + e.radius:
			Game.world.deal_damage(source, e, dmg, {"crit": crit, "effect": effect, "effect_power": effect_power, "knock": knock, "dir": U.flat_dir(global_position, e.global_position), "ranged": true})
	if effect == "poison_cloud":
		Game.world.spawn_zone(global_position, 3.0, 5.0, dmg * 0.6, team, Color(0.5, 1.0, 0.3, 0.35), "poison", source)
	queue_free()

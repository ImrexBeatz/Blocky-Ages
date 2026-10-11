## Artifact (magic power) implementations, cast by the player.
extends RefCounted

const U = preload("res://scripts/core/util.gd")
const FX = preload("res://scripts/entities/fx.gd")
const Projectile = preload("res://scripts/entities/projectile.gd")


static func _dmg(power: float) -> float:
	var m: float = 1.0 + State.stats.get("artifact_pct", 0.0)
	if Game.player.has_powerup("rage"):
		m *= 2.0
	if Game.player.has_powerup("giant"):
		m *= 1.5
	return power * m


static func _enemies_in(p: Vector3, r: float) -> Array:
	var out: Array = []
	for e in Game.world.targets_for(0):
		if U.flat_dist(e.global_position, p) < r + e.radius:
			out.append(e)
	return out


static func _nearest(p: Vector3, r: float, exclude := {}) -> Node3D:
	var best: Node3D = null
	var bd := r
	for e in Game.world.targets_for(0):
		if exclude.has(e.get_instance_id()):
			continue
		var d := U.flat_dist(e.global_position, p)
		if d < bd:
			bd = d
			best = e
	return best


static func cast(pl: Node3D, inst: Dictionary) -> void:
	var d: Dictionary = Data.items[inst["id"]]
	var power: float = State.artifact_power(inst)
	var c: Color = d["color"]
	var w = Game.world
	var pos: Vector3 = pl.global_position
	var aim: Vector3 = pl.aim_point
	var adir: Vector3 = U.flat_dir(pos, aim)
	var aim_clamped: Vector3 = pos + adir * minf(U.flat_dist(pos, aim), 14.0)
	var ag: float = w.ground_at(aim_clamped.x, aim_clamped.z)
	aim_clamped.y = ag if ag > -500.0 else pos.y
	Sfx.play("magic", randf_range(0.9, 1.2), -4.0)
	match d["ability"]:
		"fireball":
			var p := Projectile.new()
			p.setup("fireball", pos + Vector3(0, 1.3, 0), adir, 18.0, 0, _dmg(power), c)
			p.source = pl
			p.explode = 3.0
			p.effect = "burn"
			p.effect_power = _dmg(power) * 0.15
			p.life = 1.6
		"frost_nova":
			FX.ring(pos, 6.5, c, 0.6)
			FX.burst(pos + Vector3(0, 1, 0), c, 40, 8.0, 0.18)
			Sfx.play("freeze")
			for e in _enemies_in(pos, 6.5):
				w.deal_damage(pl, e, _dmg(power), {"effect": "freeze", "dir": U.flat_dir(pos, e.global_position), "knock": 1.0})
				e.apply_status("freeze", 4.0)
		"chain_lightning":
			var hit := {}
			var from := pos + Vector3(0, 1.4, 0)
			var e := _nearest(pos, 12.0)
			for i in 5:
				if e == null:
					break
				hit[e.get_instance_id()] = true
				var to: Vector3 = e.global_position + Vector3(0, 1.0, 0)
				FX.lightning(from, to, c)
				w.deal_damage(pl, e, _dmg(power) * (1.0 - i * 0.1), {"effect": "shock"})
				from = to
				e = _nearest(e.global_position, 7.0, hit)
			Sfx.play("zap")
		"heal_totem":
			w.spawn_zone(pos, 6.0, 8.0, power * 0.01 * State.stats["max_hp"], 0, Color(0.4, 1.0, 0.5, 0.25), "heal", pl)
			_totem(pos, c)
		"blink":
			var target := pos
			for i in range(1, 17):
				var q := pos + adir * (i * 0.5)
				var g: float = w.ground_at(q.x, q.z)
				if g < -500.0 or w.is_blocked(q.x, q.z) or g - target.y > 3.0:
					break
				target = Vector3(q.x, g, q.z)
			FX.burst(pos + Vector3(0, 1, 0), c, 18, 3.0)
			pl.global_position = target
			pl.invuln = 0.3
			FX.burst(target + Vector3(0, 1, 0), c, 18, 3.0)
			Sfx.play("portal", 2.0, -6.0)
		"meteor":
			var p2 := aim_clamped
			FX.telegraph(p2, 4.0, 0.8, Color(1, 0.5, 0.1))
			pl.queue_action(0.8, func():
				FX.beam(p2 + Vector3(0, 16, 0), p2, Color("#ff7a2a"), 1.2, 0.3)
				FX.ring(p2, 4.5, Color("#ff7a2a"))
				FX.burst(p2 + Vector3(0, 0.5, 0), Color("#ff7a2a"), 40, 10.0, 0.25, 0.8)
				FX.light_flash(p2, Color("#ff9a3a"), 8.0, 14.0)
				Game.add_shake(0.5)
				Sfx.play("explode", 0.7)
				for e2 in _enemies_in(p2, 4.0):
					w.deal_damage(pl, e2, _dmg(power), {"effect": "burn", "effect_power": _dmg(power) * 0.1, "knock": 2.5, "dir": U.flat_dir(p2, e2.global_position)}))
		"soul_drain":
			var total := 0.0
			for e in _enemies_in(pos, 7.0):
				var to_e := U.flat_dir(pos, e.global_position)
				if to_e.dot(adir) > 0.35:
					FX.beam(pos + Vector3(0, 1.3, 0), e.global_position + Vector3(0, 1, 0), c, 0.15, 0.4)
					total += w.deal_damage(pl, e, _dmg(power), {})
			pl.heal(total * 0.3 + State.stats["max_hp"] * 0.03)
			FX.burst(pos + Vector3(0, 1, 0), c, 14, 2.0)
		"summon_wolf":
			for i in 2:
				var a := TAU * i / 2.0
				var sp := pos + Vector3(cos(a), 0, sin(a)) * 1.5
				var al = w.spawn_ally("spirit_wolf", sp, power)
				if al:
					FX.burst(sp + Vector3(0, 1, 0), c, 16, 3.0)
		"summon_golem":
			var sp2 := pos + adir * 2.0
			w.spawn_ally("iron_golem", sp2, power)
			FX.ring(sp2, 3.0, c)
		"iron_hide":
			pl.add_buff("iron_hide", 6.0, power)
			FX.ring(pos, 2.5, c)
		"haste":
			pl.add_buff("haste", 6.0, power)
			FX.burst(pos + Vector3(0, 0.5, 0), c, 20, 3.0)
		"arrow_rain":
			w.spawn_zone(aim_clamped, 4.5, 3.0, _dmg(power), 0, Color(1.0, 0.85, 0.3, 0.2), "arrows", pl)
		"earthquake":
			FX.ring(pos, 6.0, c, 0.5)
			FX.ring(pos, 4.0, c, 0.35)
			FX.burst(pos + Vector3(0, 0.3, 0), Color("#8a6a4a"), 36, 7.0, 0.25)
			Game.add_shake(0.6)
			Sfx.play("explode", 0.5)
			for e in _enemies_in(pos, 6.0):
				w.deal_damage(pl, e, _dmg(power), {"knock": 1.5, "dir": U.flat_dir(pos, e.global_position)})
				e.apply_status("stun", 1.5)
		"poison_cloud":
			var p3 := Projectile.new()
			p3.setup("orb", pos + Vector3(0, 1.4, 0), adir, 0.0, 0, _dmg(power) * 0.5, c)
			p3.source = pl
			p3.effect = "poison_cloud"
			p3.explode = 2.5
			p3.lob(aim_clamped + Vector3(0, 0.2, 0), 0.6)
		"spirit_blades":
			pl.add_buff("blades", 8.0, _dmg(power))
		"vortex":
			w.spawn_zone(aim_clamped, 6.0, 3.0, _dmg(power), 0, Color(0.5, 0.2, 0.8, 0.3), "vortex", pl)
		"time_slow":
			FX.ring(pos, 12.0, c, 0.8)
			for e in _enemies_in(pos, 12.0):
				e.apply_status("slow", 6.0)
			Sfx.play("freeze", 0.5)
		"void_beam":
			var end := pos + adir * 15.0
			FX.beam(pos + Vector3(0, 1.3, 0), end + Vector3(0, 1.3, 0), c, 0.6, 0.5)
			FX.light_flash(pos + adir * 4.0, c, 5.0, 10.0)
			for e in Game.world.targets_for(0):
				var rel: Vector3 = e.global_position - pos
				rel.y = 0
				var along := rel.dot(adir)
				if along > 0.0 and along < 15.0 and (rel - adir * along).length() < 1.3 + e.radius:
					w.deal_damage(pl, e, _dmg(power), {"knock": 0.8, "dir": adir})
			Game.add_shake(0.2)
		"flame_dash":
			pl.start_dash(adir, 0.28, 26.0, _dmg(power))
		"starfall":
			for i in 10:
				var sp3 := pos + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
				var sg: float = w.ground_at(sp3.x, sp3.z)
				if sg < -500.0:
					continue
				sp3.y = sg
				FX.telegraph(sp3, 2.0, 0.5 + i * 0.15, Color(1, 0.9, 0.4))
				pl.queue_action(0.5 + i * 0.15, func():
					FX.beam(sp3 + Vector3(0, 14, 0), sp3, Color("#ffe58a"), 0.5, 0.2)
					FX.burst(sp3 + Vector3(0, 0.3, 0), Color("#ffe58a"), 14, 5.0)
					Sfx.play("zap", 0.6, -10.0)
					for e3 in _enemies_in(sp3, 2.0):
						w.deal_damage(pl, e3, _dmg(power), {}))
		"lifebloom":
			pl.heal(State.stats["max_hp"] * power)
			pl.add_buff("regen", 6.0, State.stats["max_hp"] * 0.03)
			FX.burst(pos + Vector3(0, 1, 0), c, 30, 3.0)
			FX.ring(pos, 3.0, c)
		"thunder":
			var tgt := _nearest(aim_clamped, 4.0)
			var hp2: Vector3 = tgt.global_position if tgt else aim_clamped
			FX.lightning(hp2 + Vector3(0, 18, 0), hp2, Color("#bfe0ff"))
			FX.lightning(hp2 + Vector3(1, 18, 0), hp2, Color("#ffffff"))
			FX.ring(hp2, 2.5, c)
			FX.light_flash(hp2, Color("#bfe0ff"), 10.0, 16.0)
			Game.add_shake(0.35)
			Sfx.play("zap", 0.5)
			for e in _enemies_in(hp2, 2.5):
				w.deal_damage(pl, e, _dmg(power) * (1.6 if e == tgt else 0.6), {})
				e.apply_status("stun", 1.0)


static func _totem(p: Vector3, c: Color) -> void:
	var t := Node3D.new()
	Game.world.fx_root.add_child(t)
	t.global_position = p
	U.box(t, Vector3(0.4, 1.6, 0.4), Vector3(0, 0.8, 0), Color("#6b4a2b"))
	U.box(t, Vector3(0.6, 0.6, 0.6), Vector3(0, 1.8, 0), c, 2.0)
	var l := OmniLight3D.new()
	l.visible = Settings.v["dynamic_lights"]
	l.light_color = c
	l.omni_range = 6.0
	l.position.y = 2.0
	t.add_child(l)
	var tw := t.create_tween()
	tw.tween_interval(8.0)
	tw.tween_property(t, "scale", Vector3(0.01, 0.01, 0.01), 0.3)
	tw.tween_callback(t.queue_free)

## One-shot visual effects: damage numbers, particle bursts, rings, telegraphs, beams.
extends RefCounted

const U = preload("res://scripts/core/util.gd")

static var _ring_mesh: CylinderMesh
static var _disc_mesh: CylinderMesh


static func _parent() -> Node:
	return Game.world.fx_root if Game.world else null


static func damage_number(pos: Vector3, text: String, color: Color, big := false) -> void:
	var parent := _parent()
	if parent == null:
		return
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0022 if big else 0.0016
	l.font_size = 40 if big else 32
	l.outline_size = 10
	l.modulate = color
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.render_priority = 10
	parent.add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.3, 0.3), 0.2, randf_range(-0.3, 0.3))
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position", l.global_position + Vector3(0, 1.4, 0), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


static func burst(pos: Vector3, color: Color, amount := 14, speed := 4.0, size := 0.14, life := 0.6, glow := 1.5) -> void:
	var parent := _parent()
	if parent == null:
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -9.0, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var m := BoxMesh.new()
	m.size = Vector3.ONE * size
	m.material = U.mat(color, glow, 0.8, false)
	p.mesh = m
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


static func ring(pos: Vector3, radius: float, color: Color, dur := 0.45) -> void:
	var parent := _parent()
	if parent == null:
		return
	if _ring_mesh == null:
		_ring_mesh = CylinderMesh.new()
		_ring_mesh.top_radius = 1.0
		_ring_mesh.bottom_radius = 1.0
		_ring_mesh.height = 0.15
		_ring_mesh.radial_segments = 32
		_ring_mesh.cap_top = false
		_ring_mesh.cap_bottom = false
	var mi := MeshInstance3D.new()
	mi.mesh = _ring_mesh
	var c := color
	c.a = 0.8
	var mat := U.unshaded(c).duplicate()
	mi.material_override = mat
	parent.add_child(mi)
	mi.global_position = pos + Vector3(0, 0.15, 0)
	mi.scale = Vector3(0.3, 1, 0.3)
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(radius, 1.5, radius), dur).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, dur)
	tw.chain().tween_callback(mi.queue_free)


## A red ground disc that fills in over `dur` seconds, warning of an incoming attack.
static func telegraph(pos: Vector3, radius: float, dur: float, color := Color(1, 0.15, 0.1)) -> Node3D:
	var parent := _parent()
	if parent == null:
		return null
	if _disc_mesh == null:
		_disc_mesh = CylinderMesh.new()
		_disc_mesh.top_radius = 1.0
		_disc_mesh.bottom_radius = 1.0
		_disc_mesh.height = 0.04
		_disc_mesh.radial_segments = 32
	var root := Node3D.new()
	parent.add_child(root)
	root.global_position = pos + Vector3(0, 0.06, 0)
	var outer := MeshInstance3D.new()
	outer.mesh = _disc_mesh
	outer.material_override = U.unshaded(Color(color.r, color.g, color.b, 0.22))
	outer.scale = Vector3(radius, 1, radius)
	root.add_child(outer)
	var inner := MeshInstance3D.new()
	inner.mesh = _disc_mesh
	inner.material_override = U.unshaded(Color(color.r, color.g, color.b, 0.45))
	inner.scale = Vector3(0.05, 1.2, 0.05)
	root.add_child(inner)
	var tw := root.create_tween()
	tw.tween_property(inner, "scale", Vector3(radius, 1.2, radius), dur)
	tw.tween_callback(root.queue_free)
	return root


static func beam(from: Vector3, to: Vector3, color: Color, width := 0.2, dur := 0.25) -> void:
	var parent := _parent()
	if parent == null:
		return
	var len := from.distance_to(to)
	if len < 0.01:
		return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, width, len)
	mi.mesh = bm
	var mat := U.mat(color, 4.0, 0.5, false).duplicate()
	mi.material_override = mat
	parent.add_child(mi)
	mi.global_position = (from + to) * 0.5
	mi.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.RIGHT)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(0.1, 0.1, 1.0), dur)
	tw.tween_callback(mi.queue_free)


static func lightning(from: Vector3, to: Vector3, color := Color(0.75, 0.85, 1.0)) -> void:
	var pts: Array = [from]
	var segs := 6
	for i in range(1, segs):
		var p := from.lerp(to, float(i) / segs)
		p += Vector3(randf_range(-0.5, 0.5), randf_range(-0.3, 0.3), randf_range(-0.5, 0.5))
		pts.append(p)
	pts.append(to)
	for i in range(pts.size() - 1):
		beam(pts[i], pts[i + 1], color, 0.12, 0.2)


static func light_flash(pos: Vector3, color: Color, energy := 4.0, rng := 8.0, dur := 0.3) -> void:
	var parent := _parent()
	if parent == null:
		return
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	parent.add_child(l)
	l.global_position = pos + Vector3(0, 1, 0)
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, dur)
	tw.tween_callback(l.queue_free)


## A quick translucent arc showing the sweep of a melee swing.
static func swipe(pos: Vector3, facing: Vector3, radius: float, arc_deg: float, color: Color) -> void:
	var parent := _parent()
	if parent == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 14
	var half := deg_to_rad(minf(arc_deg, 359.0) * 0.5)
	var base := atan2(facing.x, facing.z)
	var r_in := radius * 0.45
	for i in segs:
		var a0 := base - half + (2.0 * half) * i / segs
		var a1 := base - half + (2.0 * half) * (i + 1) / segs
		var p0 := Vector3(sin(a0), 0, cos(a0))
		var p1 := Vector3(sin(a1), 0, cos(a1))
		st.add_vertex(p0 * r_in)
		st.add_vertex(p0 * radius)
		st.add_vertex(p1 * radius)
		st.add_vertex(p0 * r_in)
		st.add_vertex(p1 * radius)
		st.add_vertex(p1 * r_in)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := U.unshaded(Color(color.r, color.g, color.b, 0.45)).duplicate()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = pos + Vector3(0, 1.0, 0)
	var tw := mi.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.18)
	tw.tween_callback(mi.queue_free)

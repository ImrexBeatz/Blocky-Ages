## Shared helpers: cached materials, pixel textures, box building and hashing.
extends RefCounted

static var _mat_cache := {}
static var _mesh_cache := {}
static var _tex_atlas: ImageTexture
static var _tex_face: ImageTexture
static var _overlay_flash: StandardMaterial3D
static var _silhouette: StandardMaterial3D


## 48x32 grayscale noise atlas so every face of a BoxMesh gets a 16x16 "pixel" pattern.
static func atlas_texture() -> ImageTexture:
	if _tex_atlas:
		return _tex_atlas
	var img := Image.create(48, 32, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for y in 32:
		for x in 48:
			var v := 0.82 + rng.randf() * 0.18
			if (x % 16 == 0 or y % 16 == 0) and rng.randf() < 0.5:
				v *= 0.9
			img.set_pixel(x, y, Color(v, v, v))
	_tex_atlas = ImageTexture.create_from_image(img)
	return _tex_atlas


## 16x16 grayscale noise for terrain faces (UV 0..1 per block face).
static func face_texture() -> ImageTexture:
	if _tex_face:
		return _tex_face
	var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for y in 16:
		for x in 16:
			var v := 0.80 + rng.randf() * 0.20
			if rng.randf() < 0.08:
				v *= 0.85
			if x == 0 or y == 0:
				v *= 0.93
			img.set_pixel(x, y, Color(v, v, v))
	_tex_face = ImageTexture.create_from_image(img)
	return _tex_face


static func mat(c: Color, emissive := 0.0, rough := 0.85, textured := true) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f_%s" % [c.to_html(), emissive, rough, textured]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if textured:
		m.albedo_texture = atlas_texture()
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if emissive > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emissive
	if c.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_cache[key] = m
	return m


static func unshaded(c: Color) -> StandardMaterial3D:
	var key := "u_%s" % c.to_html()
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if c.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_cache[key] = m
	return m


static func flash_material() -> StandardMaterial3D:
	if _overlay_flash:
		return _overlay_flash
	_overlay_flash = StandardMaterial3D.new()
	_overlay_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay_flash.albedo_color = Color(1, 0.35, 0.3, 0.55)
	_overlay_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _overlay_flash


## Faint see-through silhouette so the hero stays visible behind trees and walls.
static func silhouette_material() -> StandardMaterial3D:
	if _silhouette:
		return _silhouette
	_silhouette = StandardMaterial3D.new()
	_silhouette.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_silhouette.albedo_color = Color(0.45, 0.8, 1.0, 0.14)
	_silhouette.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_silhouette.no_depth_test = true
	_silhouette.render_priority = -1
	return _silhouette


static func box_mesh(size: Vector3) -> BoxMesh:
	var key := "%.3f_%.3f_%.3f" % [size.x, size.y, size.z]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var bm := BoxMesh.new()
	bm.size = size
	_mesh_cache[key] = bm
	return bm


static func box(parent: Node, size: Vector3, pos: Vector3, color: Color, emissive := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = box_mesh(size)
	mi.material_override = mat(color, emissive)
	mi.position = pos
	parent.add_child(mi)
	return mi


## A pivot node with a box hanging below it, used for limbs that swing from the joint.
static func limb(parent: Node, size: Vector3, joint: Vector3, color: Color, emissive := 0.0) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = joint
	parent.add_child(pivot)
	box(pivot, size, Vector3(0, -size.y * 0.5, 0), color, emissive)
	return pivot


static func hash2(x: int, z: int, s: int = 0) -> int:
	var h := (x * 374761393 + z * 668265263 + s * 2147483647) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return h ^ (h >> 16)


static func hashf(x: int, z: int, s: int = 0) -> float:
	return float(hash2(x, z, s) % 100000) / 100000.0


static func vary(c: Color, amount: float, t: float) -> Color:
	var f := 1.0 + (t - 0.5) * 2.0 * amount
	return Color(clampf(c.r * f, 0, 1), clampf(c.g * f, 0, 1), clampf(c.b * f, 0, 1), c.a)


static func fmt_num(n: float) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 10000:
		return "%.1fk" % (n / 1000.0)
	return str(int(n))


static func flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func flat_dir(from: Vector3, to: Vector3) -> Vector3:
	var d := Vector3(to.x - from.x, 0, to.z - from.z)
	if d.length_squared() < 0.0001:
		return Vector3.FORWARD
	return d.normalized()

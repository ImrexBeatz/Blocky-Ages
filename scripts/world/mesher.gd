## Accumulates voxel-style quads/boxes into packed arrays and commits them as an ArrayMesh.
extends RefCounted

const U = preload("res://scripts/core/util.gd")

static var _terrain_mat: ShaderMaterial
static var _liquid_mats := {}

var v := PackedVector3Array()
var nrm := PackedVector3Array()
var col := PackedColorArray()
var uv := PackedVector2Array()
var idx := PackedInt32Array()


static func terrain_material() -> ShaderMaterial:
	if _terrain_mat:
		return _terrain_mat
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley;
uniform sampler2D detail : filter_nearest, repeat_enable, source_color;
global uniform vec3 player_pos;
global uniform vec3 cam_pos;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	// Dither away geometry between the camera and the hero so they are never hidden.
	vec3 a = cam_pos;
	vec3 ab = player_pos + vec3(0.0, 1.0, 0.0) - a;
	float t = clamp(dot(wpos - a, ab) / dot(ab, ab), 0.0, 1.0);
	float dist = length(wpos - (a + ab * t));
	if (t < 0.985 && wpos.y > player_pos.y + 1.4 && dist < 3.2) {
		ivec2 px = ivec2(FRAGCOORD.xy);
		if (dist < 2.3 || (px.x + px.y) % 2 == 0) {
			discard;
		}
	}
	vec3 d = texture(detail, UV).rgb;
	vec3 c = pow(COLOR.rgb, vec3(2.2)) * d;
	ALBEDO = c;
	ROUGHNESS = 0.92;
	EMISSION = c * (1.0 - COLOR.a) * 2.2;
}
"""
	_terrain_mat = ShaderMaterial.new()
	_terrain_mat.shader = sh
	_terrain_mat.set_shader_parameter("detail", U.face_texture())
	return _terrain_mat


static func liquid_material(kind: String, c: Color) -> ShaderMaterial:
	if _liquid_mats.has(kind):
		return _liquid_mats[kind]
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
uniform vec4 tint : source_color;
uniform float emit = 0.0;
uniform float wave = 0.06;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(TIME * 1.4 + wpos.x * 0.7 + wpos.z * 0.5) * wave;
}
void fragment() {
	float r = sin(TIME * 0.9 + wpos.x * 1.3) * cos(TIME * 0.7 + wpos.z * 1.1);
	vec2 cell = floor(wpos.xz * 4.0);
	float px = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 c = tint.rgb * (0.9 + r * 0.08 + px * 0.06);
	ALBEDO = c;
	ALPHA = tint.a;
	ROUGHNESS = 0.08;
	SPECULAR = 0.7;
	EMISSION = c * emit * (0.85 + r * 0.25);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tint", c)
	match kind:
		"lava":
			m.set_shader_parameter("emit", 1.15)
			m.set_shader_parameter("wave", 0.04)
		"toxic":
			m.set_shader_parameter("emit", 0.6)
		"ice":
			m.set_shader_parameter("wave", 0.0)
	_liquid_mats[kind] = m
	return m


func is_empty() -> bool:
	return v.is_empty()


## Adds a quad from four corners; winding is fixed automatically so it faces `normal`.
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, color: Color, u_len := 1.0, v_len := 1.0, ao := Vector4(1, 1, 1, 1)) -> void:
	var base := v.size()
	if (b - a).cross(c - a).dot(normal) > 0.0:
		var t := b
		b = d
		d = t
		var ta := ao.y
		ao.y = ao.w
		ao.w = ta
	v.append(a); v.append(b); v.append(c); v.append(d)
	for i in 4:
		nrm.append(normal)
	col.append(Color(color.r * ao.x, color.g * ao.x, color.b * ao.x, color.a))
	col.append(Color(color.r * ao.y, color.g * ao.y, color.b * ao.y, color.a))
	col.append(Color(color.r * ao.z, color.g * ao.z, color.b * ao.z, color.a))
	col.append(Color(color.r * ao.w, color.g * ao.w, color.b * ao.w, color.a))
	uv.append(Vector2(0, 0)); uv.append(Vector2(u_len, 0)); uv.append(Vector2(u_len, v_len)); uv.append(Vector2(0, v_len))
	idx.append(base); idx.append(base + 1); idx.append(base + 2)
	idx.append(base); idx.append(base + 2); idx.append(base + 3)


## Axis-aligned box. Side faces are shaded slightly darker for the classic voxel look.
func box(mn: Vector3, mx: Vector3, color: Color, bottom := false) -> void:
	var sx := mx.x - mn.x
	var sy := mx.y - mn.y
	var sz := mx.z - mn.z
	quad(Vector3(mn.x, mx.y, mn.z), Vector3(mx.x, mx.y, mn.z), Vector3(mx.x, mx.y, mx.z), Vector3(mn.x, mx.y, mx.z), Vector3.UP, color, sx, sz)
	var cs := Color(color.r * 0.86, color.g * 0.86, color.b * 0.86, color.a)
	var cz := Color(color.r * 0.76, color.g * 0.76, color.b * 0.76, color.a)
	quad(Vector3(mx.x, mn.y, mn.z), Vector3(mx.x, mx.y, mn.z), Vector3(mx.x, mx.y, mx.z), Vector3(mx.x, mn.y, mx.z), Vector3.RIGHT, cs, sz, sy)
	quad(Vector3(mn.x, mn.y, mn.z), Vector3(mn.x, mx.y, mn.z), Vector3(mn.x, mx.y, mx.z), Vector3(mn.x, mn.y, mx.z), Vector3.LEFT, cs, sz, sy)
	quad(Vector3(mn.x, mn.y, mx.z), Vector3(mx.x, mn.y, mx.z), Vector3(mx.x, mx.y, mx.z), Vector3(mn.x, mx.y, mx.z), Vector3.BACK, cz, sx, sy)
	quad(Vector3(mn.x, mn.y, mn.z), Vector3(mx.x, mn.y, mn.z), Vector3(mx.x, mx.y, mn.z), Vector3(mn.x, mx.y, mn.z), Vector3.FORWARD, cz, sx, sy)
	if bottom:
		quad(Vector3(mn.x, mn.y, mn.z), Vector3(mx.x, mn.y, mn.z), Vector3(mx.x, mn.y, mx.z), Vector3(mn.x, mn.y, mx.z), Vector3.DOWN, cz, sx, sz)


func commit(material: Material) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = nrm
	arrays[Mesh.ARRAY_COLOR] = col
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	m.surface_set_material(0, material)
	return m

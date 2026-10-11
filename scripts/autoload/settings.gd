## Graphics/gameplay settings with quality presets. Phones and low-memory devices automatically
## get the "low" preset, tuned for weak mobile GPUs such as the PowerVR GE8322 (Galaxy A03 Core).
extends Node

signal changed

const PATH := "user://settings.cfg"
const PRESET_NAMES := {"auto": "Auto (Recommended)", "low": "Low (Phone)", "medium": "Medium", "high": "High", "ultra": "Ultra"}

## Per-preset values. Everything the renderer, world streamer and effects read lives here.
const PRESETS := {
	"low": {
		"render_scale": 0.7, "msaa": 0, "shadows": false, "shadow_size": 1024, "shadow_distance": 0.0, "ssao": false, "glow": false,
		"sky": false, "chunk_lights": 0, "dynamic_lights": false, "particles": 36, "fx_scale": 0.35, "load_r": 2, "unload_r": 3,
		"max_enemies": 22, "dither": false, "camera_far": 110.0, "minimap_px": 56, "minimap_rate": 0.7, "chunk_rows": 1,
		"chunk_budget_us": 2500, "fog_mult": 1.6, "music_rate": 11025,
	},
	"medium": {
		"render_scale": 0.85, "msaa": 0, "shadows": true, "shadow_size": 2048, "shadow_distance": 40.0, "ssao": false, "glow": true,
		"sky": true, "chunk_lights": 2, "dynamic_lights": true, "particles": 80, "fx_scale": 0.7, "load_r": 3, "unload_r": 4,
		"max_enemies": 32, "dither": true, "camera_far": 180.0, "minimap_px": 72, "minimap_rate": 0.5, "chunk_rows": 8,
		"chunk_budget_us": 5000, "fog_mult": 1.0, "music_rate": 16000,
	},
	"high": {
		"render_scale": 1.0, "msaa": 2, "shadows": true, "shadow_size": 4096, "shadow_distance": 70.0, "ssao": true, "glow": true,
		"sky": true, "chunk_lights": 4, "dynamic_lights": true, "particles": 140, "fx_scale": 1.0, "load_r": 3, "unload_r": 5,
		"max_enemies": 40, "dither": true, "camera_far": 260.0, "minimap_px": 90, "minimap_rate": 0.35, "chunk_rows": 1000,
		"chunk_budget_us": 7000, "fog_mult": 1.0, "music_rate": 16000,
	},
	"ultra": {
		"render_scale": 1.0, "msaa": 4, "shadows": true, "shadow_size": 8192, "shadow_distance": 90.0, "ssao": true, "glow": true,
		"sky": true, "chunk_lights": 6, "dynamic_lights": true, "particles": 220, "fx_scale": 1.25, "load_r": 4, "unload_r": 6,
		"max_enemies": 48, "dither": true, "camera_far": 320.0, "minimap_px": 90, "minimap_rate": 0.3, "chunk_rows": 1000,
		"chunk_budget_us": 9000, "fog_mult": 0.8, "music_rate": 22050,
	},
}

var quality := "auto"
var show_fps := false
var auto_attack := false
var touch_controls := true
var music_volume := 0.5
var sfx_volume := 0.8
var is_mobile := false
var low_memory := false
var v := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_mobile = OS.has_feature("mobile") or OS.get_name() in ["Android", "iOS"] or OS.has_feature("web_android") or OS.has_feature("web_ios")
	# Lets the phone experience be tried (and tested) on a desktop: godot --path . -- --force-mobile
	if "--force-mobile" in OS.get_cmdline_user_args():
		is_mobile = true
	var mem: Dictionary = OS.get_memory_info()
	var phys: int = int(mem.get("physical", -1))
	low_memory = phys > 0 and phys < 3 * 1024 * 1024 * 1024
	_load()
	v = PRESETS[effective()]
	Engine.max_fps = 60 if is_mobile else 0


## The preset actually in use; "auto" resolves to low on phones / low-RAM machines.
func effective() -> String:
	if quality != "auto" and PRESETS.has(quality):
		return quality
	return "low" if (is_mobile or low_memory) else "high"


func get_v(key: String):
	return v.get(key)


func set_quality(q: String) -> void:
	quality = q
	v = PRESETS[effective()]
	save()
	apply()


func _load() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	quality = cf.get_value("graphics", "quality", "auto")
	if not PRESETS.has(quality) and quality != "auto":
		quality = "auto"
	show_fps = cf.get_value("graphics", "show_fps", false)
	auto_attack = cf.get_value("gameplay", "auto_attack", false)
	touch_controls = cf.get_value("gameplay", "touch_controls", true)
	music_volume = cf.get_value("audio", "music", 0.5)
	sfx_volume = cf.get_value("audio", "sfx", 0.8)


func save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("graphics", "quality", quality)
	cf.set_value("graphics", "show_fps", show_fps)
	cf.set_value("gameplay", "auto_attack", auto_attack)
	cf.set_value("gameplay", "touch_controls", touch_controls)
	cf.set_value("audio", "music", music_volume)
	cf.set_value("audio", "sfx", sfx_volume)
	cf.save(PATH)


## Pushes the current preset into the viewport, environment, lights and world streamer.
func apply() -> void:
	var vp := get_viewport()
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = v["render_scale"]
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_2X, Viewport.MSAA_4X][int(v["msaa"])]
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	RenderingServer.directional_shadow_atlas_set_size(int(v["shadow_size"]), true)
	Sfx.music_volume = music_volume
	Sfx.sfx_volume = sfx_volume
	if Game.world and Game.world.has_method("apply_settings"):
		Game.world.apply_settings()
	changed.emit()


func forward_plus() -> bool:
	return RenderingServer.get_rendering_device() != null and str(ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method")) == "forward_plus"

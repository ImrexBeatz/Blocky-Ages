## Title screen shown over a slowly orbiting live view of the world.
extends Control

const K = preload("res://scripts/ui/ui_kit.gd")

signal new_game
signal continue_game
signal show_controls


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = K.theme()
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	float l = smoothstep(0.15, 0.75, UV.x);
	float v = smoothstep(0.4, 0.95, length(UV - vec2(0.5)));
	COLOR = vec4(0.03, 0.02, 0.06, clamp((1.0 - l) * 0.85 + v * 0.6, 0.0, 0.95));
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	shade.material = sm
	add_child(shade)
	var v := K.vbox(14)
	v.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	v.position = Vector2(110, -250)
	add_child(v)
	var t1 := K.label("BLOCKY", 96, Color("#f2c14e"))
	t1.add_theme_constant_override("outline_size", 18)
	t1.add_theme_color_override("font_outline_color", Color("#3a2410"))
	var t2 := K.label("DUNGEONS", 96, Color("#ffe9b0"))
	t2.add_theme_constant_override("outline_size", 18)
	t2.add_theme_color_override("font_outline_color", Color("#3a2410"))
	t2.position.y = -30
	v.add_child(t1)
	v.add_child(t2)
	var sub := K.label("SHARDS OF THE PRISM", 26, Color("#c48aff"))
	sub.add_theme_constant_override("outline_size", 8)
	v.add_child(sub)
	v.add_child(Control.new())
	var cont := K.button("Continue Journey", func(): continue_game.emit(), 320, 24)
	cont.disabled = not State.has_save()
	v.add_child(cont)
	v.add_child(K.button("New Adventure", func():
		if State.has_save():
			_confirm_new()
		else:
			new_game.emit(), 320, 24))
	v.add_child(K.button("Controls", func(): show_controls.emit(), 320, 24))
	v.add_child(K.button("Quit", func(): get_tree().quit(), 320, 24))
	var foot := K.label("Five realms. Twenty bosses. An endless world.   v1.0", 16, K.DIM)
	foot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	foot.position = Vector2(110, -46)
	add_child(foot)
	if not cont.disabled:
		cont.grab_focus()


func _confirm_new() -> void:
	var d := ConfirmationDialog.new()
	d.dialog_text = "Starting a new adventure will overwrite your saved journey. Continue?"
	d.title = "New Adventure"
	add_child(d)
	d.confirmed.connect(func(): new_game.emit())
	d.popup_centered()

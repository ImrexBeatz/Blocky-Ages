## Settings: graphics quality presets, FPS counter, audio, and phone-only touch / auto-attack options.
extends "res://scripts/ui/screen.gd"

const DESC := {
	"low": "Built for budget phones (e.g. Galaxy A03 Core / PowerVR GE8322, 2 GB RAM): 70% render scale, no shadows, glow or dynamic lights, shorter view distance, fewer enemies and particles, capped at 60 FPS.",
	"medium": "Soft shadows, glow and some lights. Good for mid-range phones and integrated graphics.",
	"high": "Full shadows, ambient occlusion, MSAA 2x and village lights. Recommended for desktop GPUs.",
	"ultra": "Maximum view distance, 4x MSAA and extra lights and particles. For powerful PCs.",
}

var content: VBoxContainer


func _ready() -> void:
	build("Settings", Vector2(1000, 760))
	var s: Array = scroll()
	body.add_child(s[0])
	content = s[1]
	refresh()


func refresh() -> void:
	K.clear(content)
	var dev := "Phone / tablet detected" if Settings.is_mobile else ("Low-memory device detected" if Settings.low_memory else "Desktop detected")
	content.add_child(K.label("Graphics Quality", 24, K.GOLD))
	content.add_child(K.label("%s  -  currently using: %s" % [dev, Settings.PRESET_NAMES[Settings.effective()]], 16, K.DIM))
	var row := K.hbox(8)
	for q in ["auto", "low", "medium", "high", "ultra"]:
		var qq: String = q
		var b := K.button(Settings.PRESET_NAMES[q], func():
			Settings.set_quality(qq)
			refresh(), 170, 16)
		if Settings.quality == q:
			b.add_theme_color_override("font_color", K.GOLD)
			b.text = "> " + b.text
		row.add_child(b)
	content.add_child(row)
	var d := K.rich("[color=#cbbba0]%s[/color]" % DESC[Settings.effective()])
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(d)
	content.add_child(_toggle("Show FPS counter", Settings.show_fps, func(on): Settings.show_fps = on))
	if Settings.is_mobile:
		content.add_child(HSeparator.new())
		content.add_child(K.label("Phone Controls", 24, K.GOLD))
		content.add_child(_toggle("Auto-Attack (automatically strikes and shoots nearby enemies)", Settings.auto_attack, func(on): Settings.auto_attack = on))
		content.add_child(_toggle("On-screen touch controls", Settings.touch_controls, func(on): Settings.touch_controls = on))
	content.add_child(HSeparator.new())
	content.add_child(K.label("Audio", 24, K.GOLD))
	content.add_child(_slider("Music volume", Settings.music_volume, func(val):
		Settings.music_volume = val
		Sfx.music_volume = val
		Sfx.music_player.volume_db = linear_to_db(maxf(val, 0.001)) - 10.0))
	content.add_child(_slider("Effects volume", Settings.sfx_volume, func(val):
		Settings.sfx_volume = val
		Sfx.sfx_volume = val))
	if not Settings.is_mobile:
		content.add_child(HSeparator.new())
		content.add_child(K.button("Toggle Fullscreen", func():
			var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN), 300))


func _toggle(text: String, on: bool, cb: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = on
	c.add_theme_font_size_override("font_size", 18)
	c.add_theme_color_override("font_color", K.PARCH)
	c.toggled.connect(func(v):
		cb.call(v)
		Settings.save())
	return c


func _slider(text: String, val: float, cb: Callable) -> HBoxContainer:
	var h := K.hbox(10)
	var l := K.label(text, 17, K.PARCH)
	l.custom_minimum_size.x = 200
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = val
	s.custom_minimum_size.x = 400
	s.value_changed.connect(cb)
	s.drag_ended.connect(func(_c): Settings.save())
	h.add_child(s)
	return h

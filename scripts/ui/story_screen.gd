## Story presentation: full-screen slides (prologue/epilogue) or bottom dialogue lines.
extends Control

const K = preload("res://scripts/ui/ui_kit.gd")

signal finished

var lines: Array = []
var ix := 0
var speaker := ""
var slides := true
var text: RichTextLabel
var speaker_label: Label
var tween: Tween


func setup(p_lines: Array, p_speaker := "", p_slides := true) -> void:
	lines = p_lines
	speaker = p_speaker
	slides = p_slides


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = K.theme()
	if slides:
		var bg := ColorRect.new()
		bg.color = Color(0.01, 0.01, 0.02, 1.0)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(center)
		var v := K.vbox(30)
		center.add_child(v)
		text = K.rich("")
		text.custom_minimum_size = Vector2(1000, 220)
		text.add_theme_font_size_override("normal_font_size", 30)
		text.add_theme_font_size_override("italics_font_size", 30)
		v.add_child(text)
		var row := K.hbox(12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(K.button("Continue", _next, 200))
		row.add_child(K.button("Skip", _finish, 140))
		v.add_child(row)
	else:
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.35)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var panel := PanelContainer.new()
		panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		panel.custom_minimum_size = Vector2(1100, 230)
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
		panel.position.y = -40
		add_child(panel)
		var v := K.vbox(10)
		panel.add_child(v)
		speaker_label = K.label(speaker, 26, K.GOLD)
		v.add_child(speaker_label)
		text = K.rich("")
		text.custom_minimum_size = Vector2(1060, 110)
		text.add_theme_font_size_override("normal_font_size", 21)
		v.add_child(text)
		var row := K.hbox(12)
		row.alignment = BoxContainer.ALIGNMENT_END
		row.add_child(K.button("Continue  [Space]", _next, 220))
		v.add_child(row)
	_show()


func _show() -> void:
	if slides:
		text.text = "[center][i]%s[/i][/center]" % lines[ix]
	else:
		text.text = lines[ix]
	text.visible_ratio = 0.0
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(text, "visible_ratio", 1.0, clampf(lines[ix].length() * 0.025, 0.4, 3.5))


func _next() -> void:
	if text.visible_ratio < 1.0:
		if tween:
			tween.kill()
		text.visible_ratio = 1.0
		return
	ix += 1
	if ix >= lines.size():
		_finish()
		return
	_show()


func _finish() -> void:
	finished.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_E):
		get_viewport().set_input_as_handled()
		_next()

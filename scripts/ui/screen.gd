## Base for full-screen panels (inventory, quests, map...). Pauses gameplay while open.
extends Control

const K = preload("res://scripts/ui/ui_kit.gd")

signal closed

var panel: PanelContainer
var body: VBoxContainer
var title_label: Label
var panel_size := Vector2(1280, 760)


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func build(title: String, size := Vector2(1280, 760)) -> void:
	panel_size = size
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = K.theme()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.custom_minimum_size = size
	center.add_child(panel)
	var outer := K.vbox(10)
	panel.add_child(outer)
	var head := K.hbox(10)
	outer.add_child(head)
	title_label = K.label(title, 30, K.GOLD)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_label)
	head.add_child(K.button("Close  [Esc]", close, 140))
	var sep := HSeparator.new()
	outer.add_child(sep)
	body = K.vbox(10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func scroll(min_size := Vector2(0, 0)) -> Array:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = min_size
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := K.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	return [sc, v]

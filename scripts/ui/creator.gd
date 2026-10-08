## Character creator with a live rotating 3D preview.
extends Control

const K = preload("res://scripts/ui/ui_kit.gd")
const VM = preload("res://scripts/entities/voxel_model.gd")

signal done(profile: Dictionary)
signal back

const SKINS := ["#f6d2b3", "#e0ac7e", "#c68a5a", "#a86a42", "#8a5a3a", "#6a4a2a", "#4a3020", "#9ad0a0"]
const HAIRS := ["#1a1410", "#4a2e1a", "#7a4a2a", "#c08a4a", "#e8d08a", "#e8e8e8", "#a33a2a", "#3a6ad6", "#8a3aa3", "#3aa36a"]
const EYES := ["#3a6ad6", "#3a8a3a", "#6a4a2a", "#7a7a7a", "#a33a2a", "#8a3aa3", "#d6a33a", "#3ad6d6"]
const CLOTH := ["#3a7ad6", "#a33a2a", "#3a8a3a", "#6a3a8a", "#d6a33a", "#2a2a3a", "#e8e8e8", "#8a5a3a", "#2a6a6a", "#c23b5a", "#4a4a4a", "#f2c14e"]
const BOOTS := ["#4a2e1a", "#2a2a2a", "#6a4a2a", "#5a5a6a", "#8a3a2a", "#e8e8e8"]
const HAIR_STYLES := ["Short", "Long", "Mohawk", "Bald", "Ponytail", "Spiky"]
const HATS := ["None", "Hood", "Helmet", "Crown", "Wizard Hat", "Headband"]

var profile := {}
var preview_root: Node3D
var model: Node3D
var name_edit: LineEdit
var origin_text: RichTextLabel
var value_labels := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = K.theme()
	profile = State.default_profile()
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.06, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1240, 780)
	center.add_child(panel)
	var outer := K.vbox(10)
	panel.add_child(outer)
	outer.add_child(K.label("Create Your Wayfinder", 34, K.GOLD))
	var cols := K.hbox(20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(cols)
	# Preview
	var pv := K.vbox(8)
	cols.add_child(pv)
	var svc := SubViewportContainer.new()
	svc.custom_minimum_size = Vector2(440, 560)
	svc.stretch = true
	pv.add_child(svc)
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.transparent_bg = false
	sv.msaa_3d = Viewport.MSAA_4X
	svc.add_child(sv)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#120e1c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b0a8d0")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	we.environment = env
	sv.add_child(we)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.4, 4.2)
	cam.fov = 40
	sv.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3(0, 1.1, 0))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.3
	sv.add_child(light)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-2, 2.5, -2)
	rim.light_color = Color("#c48aff")
	rim.light_energy = 2.0
	rim.omni_range = 6
	sv.add_child(rim)
	preview_root = Node3D.new()
	sv.add_child(preview_root)
	var floor_mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.2
	cm.bottom_radius = 1.3
	cm.height = 0.2
	floor_mi.mesh = cm
	floor_mi.material_override = preload("res://scripts/core/util.gd").mat(Color("#4a3f5a"))
	floor_mi.position.y = -0.1
	sv.add_child(floor_mi)
	pv.add_child(K.label("Name", 18, K.PARCH))
	name_edit = LineEdit.new()
	name_edit.text = "Wayfinder"
	name_edit.max_length = 18
	name_edit.text_changed.connect(func(t): profile["name"] = t)
	pv.add_child(name_edit)
	# Options
	var opts := K.vbox(6)
	opts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(opts)
	opts.add_child(K.label("Origin", 22, K.GOLD))
	var orow := K.hbox(8)
	for o in Data.origins:
		var oid: String = o["id"]
		orow.add_child(K.button(o["name"], func(): profile["origin"] = oid; _refresh(), 150))
	opts.add_child(orow)
	origin_text = K.rich("")
	origin_text.custom_minimum_size.y = 64
	opts.add_child(origin_text)
	opts.add_child(K.label("Appearance", 22, K.GOLD))
	_option(opts, "Skin", "skin", SKINS)
	_option(opts, "Hair Style", "hair_style", HAIR_STYLES)
	_option(opts, "Hair Color", "hair", HAIRS)
	_option(opts, "Eyes", "eyes", EYES)
	_option(opts, "Shirt", "shirt", CLOTH)
	_option(opts, "Pants", "pants", CLOTH)
	_option(opts, "Boots", "boots", BOOTS)
	_option(opts, "Headwear", "hat", HATS)
	_option(opts, "Cape", "cape", ["Off", "On"])
	_option(opts, "Cape Color", "cape_color", CLOTH)
	var brow := K.hbox(10)
	brow.alignment = BoxContainer.ALIGNMENT_END
	outer.add_child(brow)
	brow.add_child(K.button("Back", func(): back.emit(), 140))
	brow.add_child(K.button("Randomize", _randomize, 160))
	brow.add_child(K.button("Begin Adventure", func():
		profile["name"] = name_edit.text.strip_edges() if name_edit.text.strip_edges() != "" else "Wayfinder"
		done.emit(profile), 240, 22))
	_refresh()


func _option(parent: Node, title: String, key: String, values: Array) -> void:
	var row := K.hbox(8)
	var l := K.label(title, 18, K.PARCH)
	l.custom_minimum_size.x = 150
	row.add_child(l)
	row.add_child(K.button("<", func(): _cycle(key, values, -1), 44))
	var val := Control.new()
	val.custom_minimum_size = Vector2(220, 36)
	row.add_child(val)
	value_labels[key] = [val, values]
	row.add_child(K.button(">", func(): _cycle(key, values, 1), 44))
	parent.add_child(row)


func _index_of(key: String, values: Array) -> int:
	var cur = profile.get(key)
	if typeof(cur) == TYPE_BOOL:
		return 1 if cur else 0
	if typeof(cur) == TYPE_INT or typeof(cur) == TYPE_FLOAT:
		return int(cur)
	var ix := values.find(cur)
	return maxi(ix, 0)


func _cycle(key: String, values: Array, dir: int) -> void:
	var ix := wrapi(_index_of(key, values) + dir, 0, values.size())
	_set_value(key, values, ix)
	_refresh()


func _set_value(key: String, values: Array, ix: int) -> void:
	if key == "cape":
		profile[key] = ix == 1
	elif key in ["hair_style", "hat"]:
		profile[key] = ix
	else:
		profile[key] = values[ix]


func _randomize() -> void:
	for key in value_labels:
		var values: Array = value_labels[key][1]
		_set_value(key, values, randi() % values.size())
	profile["origin"] = Data.origins[randi() % Data.origins.size()]["id"]
	_refresh()


func _refresh() -> void:
	for key in value_labels:
		var holder: Control = value_labels[key][0]
		var values: Array = value_labels[key][1]
		K.clear(holder)
		var ix := _index_of(key, values)
		var v = values[ix]
		if typeof(v) == TYPE_STRING and v.begins_with("#"):
			var sw := K.color_box(Color(v), Vector2(220, 32), Color("#1a1522"))
			holder.add_child(sw)
		else:
			holder.add_child(K.label(str(v), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
			holder.get_child(0).custom_minimum_size.x = 220
	for o in Data.origins:
		if o["id"] == profile["origin"]:
			origin_text.text = "[color=#f2c14e][b]%s[/b][/color] - %s" % [o["name"], o["desc"]]
	if model:
		model.queue_free()
	var mopts := {"skin": Color(profile["skin"]), "hair": Color(profile["hair"]), "hair_style": int(profile["hair_style"]), "eyes": Color(profile["eyes"]),
		"shirt": Color(profile["shirt"]), "pants": Color(profile["pants"]), "boots": Color(profile["boots"]), "cape": profile["cape"],
		"cape_color": Color(profile["cape_color"]), "hat": int(profile["hat"]), "brow": true}
	model = VM.humanoid(mopts)
	var kit: Array = []
	for o in Data.origins:
		if o["id"] == profile["origin"]:
			kit = o["kit"]
	if not kit.is_empty():
		var wd: Dictionary = Data.items[kit[0]]
		model.get_meta("parts")["hand"].add_child(VM.weapon(wd["sub"], wd["color"], wd["accent"]))
	preview_root.add_child(model)


func _process(delta: float) -> void:
	if preview_root:
		preview_root.rotation.y += delta * 0.6
		if model:
			VM.animate(model, Time.get_ticks_msec() / 1000.0, 0.0, 0.0, "player")

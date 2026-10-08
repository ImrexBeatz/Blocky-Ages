## Friendly villager: wanders near home, turns to greet the player and opens dialogue.
extends "res://scripts/entities/entity.gd"

var role := "farmer"
var vname := "Villager"
var village := ""
var home := Vector3.ZERO
var wander_target := Vector3.ZERO
var wander_t := 0.0
var seed_v := 0
var label: Label3D
var quest_mark: Label3D


func setup(p: Dictionary) -> void:
	role = p["role"]
	vname = p["name"]
	village = p.get("village", "")
	seed_v = int(p.get("seed", 0))
	team = 0
	speed = 1.4
	max_hp = 99999.0
	hp = max_hp
	home = Vector3(p["x"], p["y"], p["z"])
	var r := Data.role(role)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var skins := [Color("#e0ac7e"), Color("#c68a5a"), Color("#8a5a3a"), Color("#f0c8a0"), Color("#6a4a2a")]
	var dim_tint := {"verdant": Color("#e0ac7e"), "ember": Color("#c08070"), "frost": Color("#f0d8c8"), "spore": Color("#c8b0d0"), "void": Color("#b0a8d0")}
	var skin: Color = skins[rng.randi() % skins.size()].lerp(dim_tint.get(State.current_dim, Color.WHITE), 0.3)
	var opts := {"skin": skin, "shirt": r["robe"], "pants": r["robe"].darkened(0.3), "boots": Color("#3a2a1a"), "eyes": Color("#3a8a3a"),
		"robe": true, "nose": true, "brow": true, "hair": [Color("#3a2a1a"), Color("#8a8a8a"), Color("#d8c08a"), Color("#6a2a1a")][rng.randi() % 4],
		"hair_style": [0, 3, 1, 2][rng.randi() % 4]}
	if role == "guard":
		opts["armor"] = Color("#9aa0a8")
		opts["hat"] = 2
	elif role == "elder":
		opts["hair"] = Color("#e8e8e8")
		opts["hair_style"] = 1
	elif role in ["mystic", "enchanter"]:
		opts["hat"] = 4
	elif role == "farmer":
		opts["hat"] = 5
		opts["cape_color"] = Color("#d8c08a")
	var m := VM.humanoid(opts)
	if role == "blacksmith":
		m.get_meta("parts")["hand"].add_child(VM.weapon("hammer", Color("#7a7a7a"), Color("#4a3a2a")))
	elif role == "guard":
		m.get_meta("parts")["hand"].add_child(VM.weapon("spear", Color("#c0c0c0"), Color("#6b4a2b")))
	elif role in ["mystic", "enchanter"]:
		m.get_meta("parts")["hand"].add_child(VM.weapon("staff", Color("#c48aff"), Color("#5a3a2a")))
	set_model(m, "humanoid")
	label = Label3D.new()
	label.text = "%s\n%s" % [vname, r["name"]]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 26
	label.pixel_size = 0.01
	label.outline_size = 8
	label.modulate = Color("#ffe9b0")
	label.position.y = 2.6
	add_child(label)
	quest_mark = Label3D.new()
	quest_mark.text = "!"
	quest_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	quest_mark.font_size = 80
	quest_mark.pixel_size = 0.01
	quest_mark.outline_size = 12
	quest_mark.modulate = Color("#ffd84a")
	quest_mark.position.y = 3.3
	quest_mark.visible = false
	add_child(quest_mark)
	wander_target = home


func _physics_process(delta: float) -> void:
	process_common(delta)
	var p = Game.player
	move_amount = 0.0
	if p and U.flat_dist(p.global_position, global_position) < 4.0:
		face_dir(U.flat_dir(global_position, p.global_position), delta, 6.0)
	else:
		wander_t -= delta
		if wander_t <= 0.0:
			wander_t = randf_range(3.0, 7.0)
			wander_target = home + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
		var d := wander_target - global_position
		d.y = 0
		if d.length() > 0.4:
			var dir := d.normalized()
			var moved := move_flat(dir * speed * delta)
			move_amount = 1.0 if moved.length() > 0.001 else 0.0
			face_dir(dir, delta, 6.0)
			if moved.length() < 0.0005:
				wander_t = 0.0
	update_vertical(delta)
	if Engine.get_process_frames() % 30 == 0:
		_update_mark()


func _update_mark() -> void:
	var main := Quests.current_main()
	var show := false
	if main != "":
		var q := Quests.def(main)
		if q["type"] == "talk" and q["target"] == role and q["dim"] == State.current_dim:
			show = true
	if not show and not Quests.offers_for(role, State.current_dim, 1).is_empty():
		show = true
		quest_mark.modulate = Color("#ffd84a")
	quest_mark.visible = show


func take_damage(_amount: float, _source, _opts := {}) -> float:
	return 0.0


func interact() -> void:
	Quests.notify("talk", role, 1)
	Game.open_dialogue.emit(self)

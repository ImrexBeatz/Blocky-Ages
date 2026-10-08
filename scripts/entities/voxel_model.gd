## Builds blocky creature models from boxes and animates them procedurally.
extends RefCounted

const U = preload("res://scripts/core/util.gd")


static func _root() -> Node3D:
	var r := Node3D.new()
	r.set_meta("parts", {})
	return r


static func _part(root: Node3D, name: String, n) -> void:
	var parts: Dictionary = root.get_meta("parts")
	parts[name] = n


## Humanoid with Minecraft-like proportions. opts: skin, hair, hair_style, eyes, shirt, pants, boots, cape, cape_color, hat, armor, armor_accent, thin, robe
static func humanoid(opts: Dictionary) -> Node3D:
	var root := _root()
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	_part(root, "body", body)
	var skin: Color = opts.get("skin", Color("#e0ac7e"))
	var shirt: Color = opts.get("shirt", Color("#3a7ad6"))
	var pants: Color = opts.get("pants", Color("#3a3a5a"))
	var boots: Color = opts.get("boots", Color("#4a2e1a"))
	var thin: bool = opts.get("thin", false)
	var lw := 0.18 if thin else 0.28
	var leg_h := 1.05 if thin else 0.75
	var hip := leg_h
	var leg_l := Node3D.new()
	leg_l.position = Vector3(-0.15, hip, 0)
	body.add_child(leg_l)
	U.box(leg_l, Vector3(lw, leg_h, lw), Vector3(0, -leg_h * 0.5, 0), pants)
	U.box(leg_l, Vector3(lw + 0.04, 0.2, lw + 0.06), Vector3(0, -leg_h + 0.1, -0.02), boots)
	var leg_r := Node3D.new()
	leg_r.position = Vector3(0.15, hip, 0)
	body.add_child(leg_r)
	U.box(leg_r, Vector3(lw, leg_h, lw), Vector3(0, -leg_h * 0.5, 0), pants)
	U.box(leg_r, Vector3(lw + 0.04, 0.2, lw + 0.06), Vector3(0, -leg_h + 0.1, -0.02), boots)
	_part(root, "leg_l", leg_l)
	_part(root, "leg_r", leg_r)
	var torso := Node3D.new()
	torso.position = Vector3(0, hip, 0)
	body.add_child(torso)
	_part(root, "torso", torso)
	var tw := 0.42 if thin else 0.6
	U.box(torso, Vector3(tw, 0.75, 0.32), Vector3(0, 0.375, 0), shirt)
	U.box(torso, Vector3(tw + 0.02, 0.1, 0.34), Vector3(0, 0.05, 0), boots.darkened(0.2))
	if opts.get("robe", false):
		U.box(torso, Vector3(tw + 0.08, 0.6, 0.4), Vector3(0, -0.25, 0), shirt.darkened(0.1))
	if opts.has("armor"):
		var ac: Color = opts["armor"]
		var acc: Color = opts.get("armor_accent", ac.darkened(0.3))
		U.box(torso, Vector3(tw + 0.08, 0.5, 0.4), Vector3(0, 0.48, 0), ac)
		U.box(torso, Vector3(tw + 0.1, 0.08, 0.42), Vector3(0, 0.3, 0), acc)
		U.box(torso, Vector3(0.3, 0.18, 0.4), Vector3(-tw * 0.5 - 0.08, 0.72, 0), acc)
		U.box(torso, Vector3(0.3, 0.18, 0.4), Vector3(tw * 0.5 + 0.08, 0.72, 0), acc)
	# Arms
	var aw := 0.16 if thin else 0.24
	var arm_len := 1.0 if thin else 0.72
	var arm_l := Node3D.new()
	arm_l.position = Vector3(-tw * 0.5 - aw * 0.5, hip + 0.7, 0)
	body.add_child(arm_l)
	U.box(arm_l, Vector3(aw, arm_len, aw), Vector3(0, -arm_len * 0.5 + 0.05, 0), shirt)
	U.box(arm_l, Vector3(aw - 0.01, 0.2, aw - 0.01), Vector3(0, -arm_len + 0.12, 0), skin)
	var arm_r := Node3D.new()
	arm_r.position = Vector3(tw * 0.5 + aw * 0.5, hip + 0.7, 0)
	body.add_child(arm_r)
	U.box(arm_r, Vector3(aw, arm_len, aw), Vector3(0, -arm_len * 0.5 + 0.05, 0), shirt)
	U.box(arm_r, Vector3(aw - 0.01, 0.2, aw - 0.01), Vector3(0, -arm_len + 0.12, 0), skin)
	_part(root, "arm_l", arm_l)
	_part(root, "arm_r", arm_r)
	var hand := Node3D.new()
	hand.position = Vector3(0, -arm_len + 0.1, 0)
	arm_r.add_child(hand)
	_part(root, "hand", hand)
	var hand_l := Node3D.new()
	hand_l.position = Vector3(0, -arm_len + 0.1, 0)
	arm_l.add_child(hand_l)
	_part(root, "hand_l", hand_l)
	# Head
	var head := Node3D.new()
	head.position = Vector3(0, hip + 0.75, 0)
	body.add_child(head)
	_part(root, "head", head)
	var hs := 0.5 if thin else 0.56
	U.box(head, Vector3(hs, hs, hs), Vector3(0, hs * 0.5, 0), skin)
	var eyes: Color = opts.get("eyes", Color("#3a6ad6"))
	var eye_glow: float = opts.get("eye_glow", 0.0)
	U.box(head, Vector3(0.11, 0.08, 0.02), Vector3(-0.12, hs * 0.5, -hs * 0.5 - 0.005), Color.WHITE if eye_glow == 0.0 else eyes, eye_glow)
	U.box(head, Vector3(0.11, 0.08, 0.02), Vector3(0.12, hs * 0.5, -hs * 0.5 - 0.005), Color.WHITE if eye_glow == 0.0 else eyes, eye_glow)
	if eye_glow == 0.0:
		U.box(head, Vector3(0.055, 0.08, 0.025), Vector3(-0.09, hs * 0.5, -hs * 0.5 - 0.008), eyes)
		U.box(head, Vector3(0.055, 0.08, 0.025), Vector3(0.09, hs * 0.5, -hs * 0.5 - 0.008), eyes)
	if opts.get("nose", false):
		U.box(head, Vector3(0.12, 0.2, 0.12), Vector3(0, hs * 0.32, -hs * 0.5 - 0.06), skin.darkened(0.1))
	if opts.get("brow", false):
		U.box(head, Vector3(hs * 0.8, 0.06, 0.03), Vector3(0, hs * 0.62, -hs * 0.5 - 0.01), Color(0.1, 0.1, 0.1))
	var hair: Color = opts.get("hair", Color("#4a2e1a"))
	match int(opts.get("hair_style", -1)):
		0:
			U.box(head, Vector3(hs + 0.04, 0.14, hs + 0.04), Vector3(0, hs - 0.02, 0), hair)
			U.box(head, Vector3(hs + 0.04, hs * 0.6, 0.06), Vector3(0, hs * 0.65, hs * 0.5), hair)
		1:
			U.box(head, Vector3(hs + 0.04, 0.14, hs + 0.04), Vector3(0, hs - 0.02, 0), hair)
			U.box(head, Vector3(hs + 0.06, hs + 0.3, 0.1), Vector3(0, hs * 0.4, hs * 0.5 + 0.02), hair)
			U.box(head, Vector3(0.06, hs * 0.7, hs * 0.7), Vector3(-hs * 0.5 - 0.02, hs * 0.55, 0.05), hair)
			U.box(head, Vector3(0.06, hs * 0.7, hs * 0.7), Vector3(hs * 0.5 + 0.02, hs * 0.55, 0.05), hair)
		2:
			U.box(head, Vector3(0.14, 0.22, hs + 0.08), Vector3(0, hs + 0.08, 0), hair)
		4:
			U.box(head, Vector3(hs + 0.04, 0.14, hs + 0.04), Vector3(0, hs - 0.02, 0), hair)
			U.box(head, Vector3(0.16, 0.5, 0.14), Vector3(0, hs * 0.3, hs * 0.5 + 0.1), hair)
		5:
			U.box(head, Vector3(hs + 0.04, 0.12, hs + 0.04), Vector3(0, hs - 0.02, 0), hair)
			for i in 4:
				U.box(head, Vector3(0.12, 0.2, 0.12), Vector3(-0.18 + i * 0.12, hs + 0.12, -0.05 + (i % 2) * 0.12), hair)
	match int(opts.get("hat", 0)):
		1:
			var hc: Color = opts.get("cape_color", Color("#3a5a3a"))
			U.box(head, Vector3(hs + 0.1, hs * 0.75, hs + 0.1), Vector3(0, hs * 0.72, 0.03), hc)
			U.box(head, Vector3(hs + 0.12, 0.1, 0.1), Vector3(0, hs * 0.38, hs * 0.5), hc)
		2:
			U.box(head, Vector3(hs + 0.1, hs * 0.55, hs + 0.1), Vector3(0, hs * 0.8, 0), Color("#a8b0b8"))
			U.box(head, Vector3(0.08, 0.2, hs + 0.14), Vector3(0, hs + 0.15, 0), Color("#c9a227"))
		3:
			U.box(head, Vector3(hs + 0.04, 0.14, hs + 0.04), Vector3(0, hs + 0.06, 0), Color("#ffd84a"), 0.4)
			for i in 3:
				U.box(head, Vector3(0.1, 0.14, 0.1), Vector3(-0.18 + i * 0.18, hs + 0.2, -hs * 0.5 + 0.03), Color("#ffd84a"), 0.4)
		4:
			var wc: Color = opts.get("shirt", Color("#3a3a8a"))
			U.box(head, Vector3(hs + 0.3, 0.06, hs + 0.3), Vector3(0, hs, 0), wc)
			U.box(head, Vector3(hs * 0.7, 0.3, hs * 0.7), Vector3(0, hs + 0.18, 0), wc)
			U.box(head, Vector3(hs * 0.4, 0.3, hs * 0.4), Vector3(0, hs + 0.45, 0.05), wc)
		5:
			U.box(head, Vector3(hs + 0.03, 0.08, hs + 0.03), Vector3(0, hs * 0.75, 0), opts.get("cape_color", Color("#a33a2a")))
	if opts.get("witch_hat", false):
		var wh: Color = opts.get("hat_color", Color("#2a1a3a"))
		U.box(head, Vector3(hs + 0.3, 0.06, hs + 0.3), Vector3(0, hs, 0), wh)
		U.box(head, Vector3(hs * 0.6, 0.35, hs * 0.6), Vector3(0, hs + 0.2, 0), wh)
		U.box(head, Vector3(hs * 0.3, 0.3, hs * 0.3), Vector3(0.05, hs + 0.5, 0.05), wh)
	if opts.get("mushroom_hat", false):
		var mc: Color = opts.get("hat_color", Color("#c23b5a"))
		U.box(head, Vector3(hs + 0.4, 0.2, hs + 0.4), Vector3(0, hs + 0.1, 0), mc)
		U.box(head, Vector3(hs + 0.1, 0.15, hs + 0.1), Vector3(0, hs + 0.27, 0), mc)
		U.box(head, Vector3(0.1, 0.06, 0.1), Vector3(0.15, hs + 0.36, -0.1), Color.WHITE)
	if opts.get("crown", false):
		U.box(head, Vector3(hs + 0.06, 0.16, hs + 0.06), Vector3(0, hs + 0.08, 0), Color("#c9a227"), 0.6)
		for i in 4:
			U.box(head, Vector3(0.1, 0.22, 0.1), Vector3(-0.22 + i * 0.147, hs + 0.26, -hs * 0.5), Color("#c9a227"), 0.6)
	if opts.get("cape", false):
		var cape := Node3D.new()
		cape.position = Vector3(0, hip + 0.72, 0.18)
		body.add_child(cape)
		U.box(cape, Vector3(tw + 0.05, 1.1, 0.06), Vector3(0, -0.55, 0.0), opts.get("cape_color", Color("#a33a2a")))
		_part(root, "cape", cape)
	return root


static func weapon(sub: String, c: Color, accent: Color, glow := 0.0) -> Node3D:
	var w := Node3D.new()
	match sub:
		"sword":
			U.box(w, Vector3(0.08, 0.08, 0.28), Vector3(0, 0, 0), accent)
			U.box(w, Vector3(0.36, 0.07, 0.07), Vector3(0, 0, -0.16), accent)
			U.box(w, Vector3(0.12, 0.05, 0.95), Vector3(0, 0, -0.68), c, glow)
		"axe":
			U.box(w, Vector3(0.07, 0.07, 1.0), Vector3(0, 0, -0.35), Color("#6b4a2b"))
			U.box(w, Vector3(0.06, 0.42, 0.32), Vector3(0, 0.12, -0.75), c, glow)
		"hammer":
			U.box(w, Vector3(0.08, 0.08, 1.1), Vector3(0, 0, -0.4), Color("#6b4a2b"))
			U.box(w, Vector3(0.32, 0.32, 0.5), Vector3(0, 0, -0.95), c, glow)
			U.box(w, Vector3(0.34, 0.34, 0.08), Vector3(0, 0, -0.95), accent)
		"dagger":
			U.box(w, Vector3(0.07, 0.07, 0.18), Vector3(0, 0, 0), accent)
			U.box(w, Vector3(0.09, 0.04, 0.45), Vector3(0, 0, -0.3), c, glow)
		"spear":
			U.box(w, Vector3(0.06, 0.06, 1.9), Vector3(0, 0, -0.5), Color("#7a5a3a"))
			U.box(w, Vector3(0.12, 0.04, 0.35), Vector3(0, 0, -1.6), c, glow)
		"glaive":
			U.box(w, Vector3(0.06, 0.06, 1.7), Vector3(0, 0, -0.45), accent)
			U.box(w, Vector3(0.06, 0.3, 0.55), Vector3(0, 0.1, -1.4), c, glow)
		"scythe":
			U.box(w, Vector3(0.06, 0.06, 1.7), Vector3(0, 0, -0.45), accent)
			U.box(w, Vector3(0.05, 0.9, 0.12), Vector3(0, 0.4, -1.3), c, glow)
			U.box(w, Vector3(0.05, 0.12, 0.3), Vector3(0, 0.82, -1.15), c, glow)
		"gauntlets":
			U.box(w, Vector3(0.3, 0.3, 0.3), Vector3(0, 0, 0), c, glow)
		"bow":
			U.box(w, Vector3(0.06, 1.1, 0.06), Vector3(0, 0, -0.1), c, glow)
			U.box(w, Vector3(0.06, 0.06, 0.18), Vector3(0, 0.52, -0.02), c, glow)
			U.box(w, Vector3(0.06, 0.06, 0.18), Vector3(0, -0.52, -0.02), c, glow)
			U.box(w, Vector3(0.02, 1.1, 0.02), Vector3(0, 0, 0.06), Color(0.95, 0.95, 0.9))
		"crossbow":
			U.box(w, Vector3(0.1, 0.1, 0.7), Vector3(0, 0, -0.2), Color("#6b4a2b"))
			U.box(w, Vector3(0.8, 0.06, 0.08), Vector3(0, 0, -0.45), c, glow)
		"staff":
			U.box(w, Vector3(0.07, 0.07, 1.6), Vector3(0, 0, -0.5), Color("#5a3a2a"))
			U.box(w, Vector3(0.2, 0.2, 0.2), Vector3(0, 0, -1.35), c, 1.5)
	return w


static func _legs4(root: Node3D, body: Node3D, c: Color, w: float, h: float, xs: float, zs: float) -> void:
	var names := ["leg_fl", "leg_fr", "leg_bl", "leg_br"]
	var pos := [Vector3(-xs, h, -zs), Vector3(xs, h, -zs), Vector3(-xs, h, zs), Vector3(xs, h, zs)]
	for i in 4:
		var l := U.limb(body, Vector3(w, h, w), pos[i], c)
		_part(root, names[i], l)


## Builds a creature/boss model by archetype.
static func creature(def: Dictionary) -> Node3D:
	var model: String = def["model"]
	var c1: Color = def["c1"]
	var c2: Color = def["c2"]
	var c3: Color = def["c3"]
	var glow: float = def.get("glow", 0.0)
	var root: Node3D
	match model:
		"humanoid", "wraith":
			var opts := {"skin": c2, "shirt": c1, "pants": c1.darkened(0.25), "boots": c1.darkened(0.45), "eyes": c3, "eye_glow": 2.0,
				"thin": def.get("thin", false), "nose": def["id"] in ["vindicator", "hex_evoker", "velkar", "bog_witch"], "brow": true}
			if def.get("hat", false):
				if def["dim"] == "spore":
					opts["mushroom_hat"] = true
					opts["hat_color"] = c3 if c3 != Color("#2a2a2a") else Color("#c23b5a")
				else:
					opts["witch_hat"] = true
					opts["hat_color"] = c1.darkened(0.3)
			if def["id"] in ["malgrath", "grimtusk", "glaciara"]:
				opts["crown"] = true
				opts["cape"] = true
				opts["cape_color"] = c1.darkened(0.2)
			if def["id"] in ["hex_evoker", "velkar", "bog_witch", "spore_caster", "glaciara"]:
				opts["robe"] = true
			if def["id"] in ["tuskguard", "grimtusk", "charred_revenant", "frozen_revenant"]:
				opts["armor"] = c3 if def["id"] in ["tuskguard", "grimtusk"] else c1.lightened(0.2)
			root = humanoid(opts)
			var parts: Dictionary = root.get_meta("parts")
			if model == "wraith":
				parts["leg_l"].visible = false
				parts["leg_r"].visible = false
				var tail := U.box(parts["torso"], Vector3(0.5, 0.8, 0.28), Vector3(0, -0.35, 0.05), c1.darkened(0.15), glow)
				tail.rotation.x = 0.2
				parts["body"].position.y = 0.4
			var wsub: String = def.get("weapon", "")
			if def["ai"] in ["caster", "summoner"] and wsub == "":
				wsub = "staff"
			if def["ai"] in ["ranged"]:
				wsub = "bow" if def["dim"] != "frost" else "crossbow"
			if wsub != "":
				var wm := weapon(wsub, c3 if wsub == "staff" else Color("#c0c0c0"), c1.darkened(0.3), 1.0 if wsub == "staff" else 0.0)
				parts["hand"].add_child(wm)
				_part(root, "weapon", wm)
		"creeper":
			root = _root()
			var body := Node3D.new()
			root.add_child(body)
			_part(root, "body", body)
			U.box(body, Vector3(0.5, 0.95, 0.36), Vector3(0, 0.95, 0), c1)
			var head := Node3D.new()
			head.position = Vector3(0, 1.42, 0)
			body.add_child(head)
			_part(root, "head", head)
			U.box(head, Vector3(0.56, 0.56, 0.56), Vector3(0, 0.28, 0), c1.lightened(0.05))
			U.box(head, Vector3(0.13, 0.13, 0.02), Vector3(-0.12, 0.34, -0.29), c3)
			U.box(head, Vector3(0.13, 0.13, 0.02), Vector3(0.12, 0.34, -0.29), c3)
			U.box(head, Vector3(0.13, 0.2, 0.02), Vector3(0, 0.17, -0.29), c3)
			_legs4(root, body, c2, 0.22, 0.48, 0.13, 0.12)
		"quad":
			root = _root()
			var body := Node3D.new()
			root.add_child(body)
			_part(root, "body", body)
			var wolf: bool = def["id"] in ["frost_wolf", "rimefang", "voidstalker", "spirit_wolf"]
			var bl := 1.3 if not wolf else 1.2
			var bh := 0.7 if not wolf else 0.55
			U.box(body, Vector3(0.75, bh, bl), Vector3(0, 0.55 + bh * 0.5, 0), c1)
			var head := Node3D.new()
			head.position = Vector3(0, 0.55 + bh * 0.7, -bl * 0.5)
			body.add_child(head)
			_part(root, "head", head)
			U.box(head, Vector3(0.55, 0.5, 0.5), Vector3(0, 0, -0.2), c1.lightened(0.05))
			U.box(head, Vector3(0.36, 0.26, 0.24), Vector3(0, -0.08, -0.52), c2)
			U.box(head, Vector3(0.1, 0.08, 0.02), Vector3(-0.15, 0.08, -0.46), c3, 2.0)
			U.box(head, Vector3(0.1, 0.08, 0.02), Vector3(0.15, 0.08, -0.46), c3, 2.0)
			if wolf:
				U.box(head, Vector3(0.12, 0.18, 0.08), Vector3(-0.17, 0.32, -0.12), c1)
				U.box(head, Vector3(0.12, 0.18, 0.08), Vector3(0.17, 0.32, -0.12), c1)
				var _b292 := U.box(body, Vector3(0.14, 0.14, 0.6), Vector3(0, 0.95, bl * 0.5 + 0.25), c1)
				_b292.rotation.x = 0.5
			else:
				var _b295 := U.box(head, Vector3(0.08, 0.3, 0.08), Vector3(-0.22, -0.05, -0.62), Color("#f0e8d8"))
				_b295.rotation.x = -0.4
				var _b297 := U.box(head, Vector3(0.08, 0.3, 0.08), Vector3(0.22, -0.05, -0.62), Color("#f0e8d8"))
				_b297.rotation.x = -0.4
				U.box(body, Vector3(0.5, 0.15, bl * 0.8), Vector3(0, 0.6 + bh, 0), c2)
			_legs4(root, body, c1.darkened(0.15), 0.22, 0.6, 0.25, bl * 0.35)
		"spider":
			root = _root()
			var body := Node3D.new()
			root.add_child(body)
			_part(root, "body", body)
			U.box(body, Vector3(0.9, 0.6, 1.0), Vector3(0, 0.55, 0.35), c1)
			U.box(body, Vector3(0.6, 0.5, 0.5), Vector3(0, 0.5, -0.35), c2)
			var head := Node3D.new()
			head.position = Vector3(0, 0.5, -0.6)
			body.add_child(head)
			_part(root, "head", head)
			U.box(head, Vector3(0.55, 0.45, 0.4), Vector3(0, 0, -0.15), c1)
			for i in 4:
				U.box(head, Vector3(0.08, 0.08, 0.02), Vector3(-0.18 + i * 0.12, 0.08 + (i % 2) * 0.08, -0.36), c3, 2.5)
			var legs: Array = []
			for i in 8:
				var side := -1.0 if i < 4 else 1.0
				var zz := -0.3 + (i % 4) * 0.25
				var l := Node3D.new()
				l.position = Vector3(side * 0.3, 0.6, zz)
				body.add_child(l)
				var seg := U.box(l, Vector3(0.9, 0.09, 0.09), Vector3(side * 0.45, 0.0, 0), c2.darkened(0.2))
				seg.rotation.z = side * -0.5
				legs.append(l)
			_part(root, "legs", legs)
		"slime":
			root = _root()
			var body := Node3D.new()
			root.add_child(body)
			_part(root, "body", body)
			var outer := c1
			outer.a = 0.75 if glow == 0.0 else 1.0
			U.box(body, Vector3(1.0, 1.0, 1.0), Vector3(0, 0.5, 0), outer, glow * 0.5)
			U.box(body, Vector3(0.55, 0.55, 0.55), Vector3(0, 0.45, 0), c2, glow)
			U.box(body, Vector3(0.14, 0.14, 0.02), Vector3(-0.2, 0.65, -0.51), c3)
			U.box(body, Vector3(0.14, 0.14, 0.02), Vector3(0.2, 0.65, -0.51), c3)
			U.box(body, Vector3(0.2, 0.06, 0.02), Vector3(0, 0.38, -0.51), c3)
		"flyer":
			root = _root()
			var body := Node3D.new()
			root.add_child(body)
			_part(root, "body", body)
			body.position.y = 1.4
			U.box(body, Vector3(0.5, 0.5, 0.7), Vector3(0, 0, 0), c1, glow)
			var head := Node3D.new()
			head.position = Vector3(0, 0.1, -0.45)
			body.add_child(head)
			_part(root, "head", head)
			U.box(head, Vector3(0.45, 0.42, 0.4), Vector3(0, 0, -0.1), c1.lightened(0.1), glow)
			U.box(head, Vector3(0.1, 0.08, 0.02), Vector3(-0.12, 0.05, -0.31), c3, 3.0)
			U.box(head, Vector3(0.1, 0.08, 0.02), Vector3(0.12, 0.05, -0.31), c3, 3.0)
			var wl := Node3D.new()
			wl.position = Vector3(-0.25, 0.1, 0)
			body.add_child(wl)
			U.box(wl, Vector3(1.0, 0.05, 0.6), Vector3(-0.5, 0, 0), Color(c2.r, c2.g, c2.b, 0.85), glow)
			var wr := Node3D.new()
			wr.position = Vector3(0.25, 0.1, 0)
			body.add_child(wr)
			U.box(wr, Vector3(1.0, 0.05, 0.6), Vector3(0.5, 0, 0), Color(c2.r, c2.g, c2.b, 0.85), glow)
			_part(root, "wing_l", wl)
			_part(root, "wing_r", wr)
			U.box(body, Vector3(0.2, 0.15, 0.6), Vector3(0, 0, 0.6), c2, glow)
		"golem":
			root = _root()
			var body := Node3D.new()
			root.add_child(body)
			_part(root, "body", body)
			var turret: bool = def["ai"] == "turret"
			if turret:
				U.box(body, Vector3(1.0, 0.6, 1.0), Vector3(0, 0.3, 0), c1)
				var lid := Node3D.new()
				lid.position = Vector3(0, 0.6, 0)
				body.add_child(lid)
				U.box(lid, Vector3(1.0, 0.45, 1.0), Vector3(0, 0.22, 0), c2)
				U.box(body, Vector3(0.5, 0.4, 0.5), Vector3(0, 0.75, -0.1), c3, 1.5)
				_part(root, "head", lid)
			else:
				U.box(body, Vector3(1.2, 1.0, 0.7), Vector3(0, 1.6, 0), c1)
				U.box(body, Vector3(0.9, 0.5, 0.55), Vector3(0, 0.9, 0), c1.darkened(0.1))
				U.box(body, Vector3(0.3, 0.3, 0.05), Vector3(0, 1.6, -0.36), c3, 2.0)
				var head := Node3D.new()
				head.position = Vector3(0, 2.1, -0.1)
				body.add_child(head)
				_part(root, "head", head)
				U.box(head, Vector3(0.5, 0.55, 0.5), Vector3(0, 0.25, 0), c2)
				U.box(head, Vector3(0.1, 0.08, 0.02), Vector3(-0.12, 0.32, -0.26), c3, 3.0)
				U.box(head, Vector3(0.1, 0.08, 0.02), Vector3(0.12, 0.32, -0.26), c3, 3.0)
				var al := U.limb(body, Vector3(0.36, 1.3, 0.36), Vector3(-0.8, 2.0, 0), c2)
				var ar := U.limb(body, Vector3(0.36, 1.3, 0.36), Vector3(0.8, 2.0, 0), c2)
				_part(root, "arm_l", al)
				_part(root, "arm_r", ar)
				var ll := U.limb(body, Vector3(0.4, 0.75, 0.4), Vector3(-0.3, 0.75, 0), c1.darkened(0.2))
				var lr := U.limb(body, Vector3(0.4, 0.75, 0.4), Vector3(0.3, 0.75, 0), c1.darkened(0.2))
				_part(root, "leg_l", ll)
				_part(root, "leg_r", lr)
				if def["dim"] == "spore":
					U.box(body, Vector3(1.4, 0.3, 1.0), Vector3(0, 2.25, 0.1), Color("#c23b5a"))
				if def["dim"] == "verdant":
					U.box(body, Vector3(1.25, 0.2, 0.75), Vector3(0, 2.15, 0), Color("#4a7a3a"))
		"wyrm":
			root = _root()
			var body := Node3D.new()
			root.add_child(body)
			_part(root, "body", body)
			var segs: Array = []
			for i in 6:
				var s := Node3D.new()
				s.position = Vector3(0, 1.0, i * 0.7)
				body.add_child(s)
				var sz := 0.9 - i * 0.1
				U.box(s, Vector3(sz, sz, 0.75), Vector3.ZERO, c1 if i % 2 == 0 else c1.lightened(0.1))
				U.box(s, Vector3(0.12, 0.3, 0.3), Vector3(0, sz * 0.5 + 0.1, 0), c2, 1.0)
				segs.append(s)
			_part(root, "segments", segs)
			var head := Node3D.new()
			head.position = Vector3(0, 1.2, -0.6)
			body.add_child(head)
			_part(root, "head", head)
			U.box(head, Vector3(0.9, 0.6, 0.9), Vector3(0, 0, -0.2), c1)
			U.box(head, Vector3(0.7, 0.25, 0.6), Vector3(0, -0.25, -0.75), c2)
			U.box(head, Vector3(0.14, 0.1, 0.02), Vector3(-0.25, 0.12, -0.66), c3, 3.0)
			U.box(head, Vector3(0.14, 0.1, 0.02), Vector3(0.25, 0.12, -0.66), c3, 3.0)
			var _b423 := U.box(head, Vector3(0.1, 0.5, 0.1), Vector3(-0.3, 0.45, 0.1), c2)
			_b423.rotation.x = 0.5
			var _b425 := U.box(head, Vector3(0.1, 0.5, 0.1), Vector3(0.3, 0.45, 0.1), c2)
			_b425.rotation.x = 0.5
			var wl := Node3D.new()
			wl.position = Vector3(-0.4, 1.3, 0.6)
			body.add_child(wl)
			U.box(wl, Vector3(1.6, 0.06, 1.0), Vector3(-0.8, 0, 0), Color(c2.r, c2.g, c2.b, 0.8), 0.8)
			var wr := Node3D.new()
			wr.position = Vector3(0.4, 1.3, 0.6)
			body.add_child(wr)
			U.box(wr, Vector3(1.6, 0.06, 1.0), Vector3(0.8, 0, 0), Color(c2.r, c2.g, c2.b, 0.8), 0.8)
			_part(root, "wing_l", wl)
			_part(root, "wing_r", wr)
		"heart":
			root = _root()
			var body := Node3D.new()
			root.add_child(body)
			_part(root, "body", body)
			U.box(body, Vector3(1.6, 1.6, 1.6), Vector3(0, 1.4, 0), c1)
			U.box(body, Vector3(1.2, 1.2, 1.7), Vector3(0, 1.4, 0), c1.lightened(0.15))
			var eye := Node3D.new()
			eye.position = Vector3(0, 1.5, -0.85)
			body.add_child(eye)
			U.box(eye, Vector3(0.7, 0.7, 0.1), Vector3.ZERO, Color.WHITE, 0.5)
			U.box(eye, Vector3(0.3, 0.3, 0.12), Vector3(0, 0, -0.02), c3.darkened(0.8))
			_part(root, "head", eye)
			for i in 6:
				var a := TAU * i / 6.0
				var vine := U.box(body, Vector3(0.25, 0.25, 1.6), Vector3(cos(a) * 1.0, 0.3, sin(a) * 1.0), c2, 0.6)
				vine.rotation.y = -a
		_:
			root = humanoid({})
	return root


## Procedural animation: walk cycles, attack swings, wing flaps and squashes.
static func animate(root: Node3D, t: float, move: float, attack: float, model: String) -> void:
	var parts: Dictionary = root.get_meta("parts")
	var sw := sin(t * 10.0) * 0.7 * move
	match model:
		"humanoid", "wraith", "player":
			if parts.has("leg_l"):
				parts["leg_l"].rotation.x = sw
				parts["leg_r"].rotation.x = -sw
			var arm_r: Node3D = parts["arm_r"]
			if attack > 0.0:
				arm_r.rotation.x = lerpf(-2.4, 0.4, attack)
				arm_r.rotation.y = lerpf(0.6, -0.6, attack)
			else:
				arm_r.rotation.x = -sw * 0.8
				arm_r.rotation.y = 0.0
			parts["arm_l"].rotation.x = sw * 0.8
			if parts.has("cape"):
				parts["cape"].rotation.x = 0.15 + move * 0.5 + sin(t * 3.0) * 0.05
			parts["body"].position.y = (0.4 if model == "wraith" else 0.0) + absf(sin(t * 10.0)) * 0.05 * move + (sin(t * 2.0) * 0.08 if model == "wraith" else 0.0)
		"creeper", "quad", "golem":
			for k in ["leg_fl", "leg_br"]:
				if parts.has(k):
					parts[k].rotation.x = sw
			for k in ["leg_fr", "leg_bl"]:
				if parts.has(k):
					parts[k].rotation.x = -sw
			if parts.has("leg_l"):
				parts["leg_l"].rotation.x = sw * 0.6
				parts["leg_r"].rotation.x = -sw * 0.6
			if parts.has("arm_l"):
				if attack > 0.0:
					parts["arm_l"].rotation.x = lerpf(-2.6, 0.2, attack)
					parts["arm_r"].rotation.x = lerpf(-2.6, 0.2, attack)
				else:
					parts["arm_l"].rotation.x = -sw * 0.5
					parts["arm_r"].rotation.x = sw * 0.5
			if model == "quad" and parts.has("head"):
				parts["head"].rotation.x = -0.4 * attack
		"spider":
			var legs: Array = parts.get("legs", [])
			for i in legs.size():
				legs[i].rotation.x = sin(t * 14.0 + i * 1.3) * 0.4 * move
				legs[i].rotation.y = cos(t * 14.0 + i * 1.3) * 0.2 * move
		"slime":
			var s := absf(sin(t * 6.0)) * (0.3 if move > 0.1 else 0.06)
			parts["body"].scale = Vector3(1.0 + s * 0.4, 1.0 - s * 0.5 + attack * 0.3, 1.0 + s * 0.4)
			parts["body"].position.y = s * 1.2
		"flyer", "wyrm":
			var f := sin(t * 12.0) * 0.6
			if parts.has("wing_l"):
				parts["wing_l"].rotation.z = f
				parts["wing_r"].rotation.z = -f
			parts["body"].position.y = (1.4 if model == "flyer" else 0.6) + sin(t * 3.0) * 0.2
			if model == "wyrm":
				var segs: Array = parts.get("segments", [])
				for i in segs.size():
					segs[i].position.x = sin(t * 3.0 + i * 0.8) * 0.25
			if parts.has("head"):
				parts["head"].rotation.x = -0.5 * attack
		"heart":
			var beat := pow(absf(sin(t * 3.0)), 8.0) * 0.15
			parts["body"].scale = Vector3.ONE * (1.0 + beat)

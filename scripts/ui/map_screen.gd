## World map: progressively rendered terrain with villages, boss lairs and the quest target.
extends "res://scripts/ui/screen.gd"

const PX := 200
var img: Image
var tex: ImageTexture
var rect: TextureRect
var overlay: Control
var row := 0
var scale_u := 3.0
var center := Vector3.ZERO
var legend: RichTextLabel


func _ready() -> void:
	build("World Map", Vector2(1100, 780))
	var cols := K.hbox(16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	rect = TextureRect.new()
	rect.custom_minimum_size = Vector2(660, 660)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cols.add_child(rect)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.add_child(overlay)
	overlay.draw.connect(_draw_overlay)
	var side := K.vbox(10)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(side)
	side.add_child(K.button("Zoom In", func(): _rescale(maxf(1.0, scale_u / 2.0)), 160))
	side.add_child(K.button("Zoom Out", func(): _rescale(minf(8.0, scale_u * 2.0)), 160))
	legend = K.rich("")
	legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_child(legend)
	img = Image.create(PX, PX, false, Image.FORMAT_RGB8)
	img.fill(Color(0.05, 0.05, 0.07))
	tex = ImageTexture.create_from_image(img)
	rect.texture = tex
	_rescale(3.0)


func _rescale(s: float) -> void:
	scale_u = s
	center = Game.player.global_position
	row = 0
	img.fill(Color(0.05, 0.05, 0.07))
	var d := Data.dim(State.current_dim)
	legend.text = "[color=#f2c14e]%s[/color]\n\nShowing %d x %d blocks\n\n[color=#ffffff]White[/color] - You\n[color=#ffd84a]Gold[/color] - Quest target\n[color=#7aff7a]Green[/color] - Villages\n[color=#ff4aff]Magenta[/color] - Boss lairs (red: defeated recently)\n\nThe realm continues forever in every direction. Enemies grow stronger the farther you travel from the Realm Gate." % [d["name"] if not Game.world.in_cave else "Underground", int(PX * s), int(PX * s)]


func _process(_delta: float) -> void:
	if row >= PX:
		return
	var half := PX / 2
	var start := Time.get_ticks_usec()
	while row < PX and Time.get_ticks_usec() - start < 12000:
		for i in PX:
			var x := int(floor(center.x + (i - half) * scale_u))
			var z := int(floor(center.z + (row - half) * scale_u))
			img.set_pixel(i, row, Game.world.gen.map_color(x, z))
		row += 1
	tex.update(img)
	overlay.queue_redraw()


func _to_map(w: Vector3) -> Vector2:
	var s := rect.size.x / (PX * scale_u)
	return rect.size * 0.5 + Vector2(w.x - center.x, w.z - center.z) * s


func _draw_overlay() -> void:
	var sz := rect.size
	var font := get_theme_default_font()
	if not Game.world.in_cave:
		var g = Game.world.surface_gen
		for v in g.villages_near(center, PX * scale_u * 0.75):
			var p := _to_map(Vector3(v["x"], 0, v["z"]))
			if Rect2(Vector2.ZERO, sz).has_point(p):
				overlay.draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), Color("#7aff7a"))
				overlay.draw_string_outline(font, p + Vector2(8, 5), v["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
				overlay.draw_string(font, p + Vector2(8, 5), v["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d8ffd0"))
		for a in g.arenas:
			var p := _to_map(Vector3(a["x"], 0, a["z"]))
			var recent: bool = State.playtime - float(State.bosses_defeated.get(a["boss"], -9999.0)) < 480.0
			var col := Color("#ff4a4a") if recent else Color("#ff4aff")
			if Rect2(Vector2.ZERO, sz).has_point(p):
				overlay.draw_circle(p, 7, col)
				var nm: String = Data.bosses[a["boss"]]["name"] if State.bosses_defeated.has(a["boss"]) else "???"
				overlay.draw_string_outline(font, p + Vector2(9, 5), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
				overlay.draw_string(font, p + Vector2(9, 5), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ffd0ff"))
	var t = Game.world.quest_target()
	if t != null:
		var tp := _to_map(t)
		tp = tp.clamp(Vector2(6, 6), sz - Vector2(6, 6))
		overlay.draw_circle(tp, 8, Color("#ffd84a"))
		overlay.draw_circle(tp, 4, Color("#7a4a00"))
	var pp := _to_map(Game.player.global_position)
	overlay.draw_circle(pp, 6, Color.WHITE)
	overlay.draw_circle(pp, 3, Color("#3a7ad6"))
	overlay.draw_rect(Rect2(Vector2.ZERO, sz), Color("#6b5636"), false, 3.0)

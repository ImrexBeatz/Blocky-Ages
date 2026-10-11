## On-screen multi-touch controls for phones: a floating joystick plus action buttons.
## Gameplay buttons drive the same input actions as the keyboard, so the player code is shared.
extends Control

const K = preload("res://scripts/ui/ui_kit.gd")

var touches := {}           # touch index -> target id ("stick" or a button id)
var stick_index := -1
var stick_origin := Vector2.ZERO
var stick_pos := Vector2.ZERO
var stick_vec := Vector2.ZERO
const STICK_R := 120.0

## id, action, label, radius, offset from bottom-right corner
const BUTTONS := [
	["attack", "attack", "ATK", 82.0, Vector2(-160, -160)],
	["ranged", "ranged", "BOW", 52.0, Vector2(-330, -110)],
	["roll", "roll", "ROLL", 52.0, Vector2(-135, -345)],
	["art1", "art1", "1", 42.0, Vector2(-330, -265)],
	["art2", "art2", "2", 42.0, Vector2(-265, -390)],
	["art3", "art3", "3", 42.0, Vector2(-450, -190)],
	["potion", "potion", "POT", 40.0, Vector2(-470, -320)],
	["interact", "interact", "USE", 48.0, Vector2(-140, -490)],
]
const MENU := [["inventory", "BAG"], ["quests", "QST"], ["skills", "SKL"], ["map", "MAP"], ["codex", "LORE"], ["pause", "MENU"]]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


static func wanted() -> bool:
	return Settings.is_mobile and Settings.touch_controls


func _process(_delta: float) -> void:
	var show: bool = wanted() and Game.in_game and not Game.ui_open and Game.player != null and not Game.player.dead
	if show != visible:
		visible = show
		if not show:
			_release_all()
	if visible:
		queue_redraw()


func _button_center(b: Array) -> Vector2:
	var sz := get_viewport_rect().size
	return sz + b[4]


func _menu_rect(i: int) -> Rect2:
	return Rect2(Vector2(16, 160 + i * 64), Vector2(76, 54))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_press(event.index, event.position)
		else:
			_on_release(event.index)
	elif event is InputEventScreenDrag and event.index == stick_index:
		stick_pos = event.position
		var d := stick_pos - stick_origin
		if d.length() > STICK_R:
			d = d.normalized() * STICK_R
		stick_vec = d / STICK_R
		_apply_stick()


func _on_press(index: int, pos: Vector2) -> void:
	for i in MENU.size():
		if _menu_rect(i).grow(6).has_point(pos):
			var ev := InputEventAction.new()
			ev.action = MENU[i][0]
			ev.pressed = true
			Input.parse_input_event(ev)
			var up := InputEventAction.new()
			up.action = MENU[i][0]
			up.pressed = false
			Input.parse_input_event.call_deferred(up)
			get_viewport().set_input_as_handled()
			return
	for b in BUTTONS:
		if pos.distance_to(_button_center(b)) < b[3] * 1.2:
			touches[index] = b[0]
			Input.action_press(b[1])
			get_viewport().set_input_as_handled()
			return
	if pos.x < get_viewport_rect().size.x * 0.5 and stick_index == -1:
		stick_index = index
		touches[index] = "stick"
		stick_origin = pos
		stick_pos = pos
		stick_vec = Vector2.ZERO
		get_viewport().set_input_as_handled()


func _on_release(index: int) -> void:
	if not touches.has(index):
		return
	var t: String = touches[index]
	touches.erase(index)
	if t == "stick":
		stick_index = -1
		stick_vec = Vector2.ZERO
		_apply_stick()
		return
	for b in BUTTONS:
		if b[0] == t:
			Input.action_release(b[1])


func _apply_stick() -> void:
	var dead := 0.12
	var v := stick_vec if stick_vec.length() > dead else Vector2.ZERO
	for pair in [["move_left", -v.x], ["move_right", v.x], ["move_up", -v.y], ["move_down", v.y]]:
		if pair[1] > 0.0:
			Input.action_press(pair[0], clampf(pair[1], 0.0, 1.0))
		else:
			Input.action_release(pair[0])


func _release_all() -> void:
	touches.clear()
	stick_index = -1
	stick_vec = Vector2.ZERO
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)
	for b in BUTTONS:
		Input.action_release(b[1])


func _draw() -> void:
	var font := get_theme_default_font()
	var p = Game.player
	# Joystick
	if stick_index != -1:
		draw_circle(stick_origin, STICK_R, Color(1, 1, 1, 0.08))
		draw_arc(stick_origin, STICK_R, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
		draw_circle(stick_origin + stick_vec * STICK_R, 46, Color(1, 0.85, 0.4, 0.55))
	else:
		var hint := Vector2(230, get_viewport_rect().size.y - 230)
		draw_arc(hint, STICK_R, 0, TAU, 48, Color(1, 1, 1, 0.15), 3.0)
		draw_circle(hint, 40, Color(1, 1, 1, 0.1))
	for b in BUTTONS:
		var c := _button_center(b)
		var r: float = b[3]
		var held: bool = b[0] in touches.values()
		var col := Color(0.12, 0.1, 0.16, 0.55) if not held else Color(0.95, 0.75, 0.3, 0.6)
		if b[0] == "interact" and p and p.interact_target == null:
			col.a = 0.2
		draw_circle(c, r, col)
		draw_arc(c, r, 0, TAU, 40, Color(0.95, 0.76, 0.3, 0.8), 3.0)
		var label: String = b[2]
		if b[0] == "potion":
			label = "POT %d" % State.potions
		if b[0].begins_with("art") and p:
			var i := int(b[0].substr(3)) - 1
			var inst = State.equipment.get(b[0])
			if inst == null:
				label = "-"
			else:
				draw_circle(c, r * 0.55, Data.items[inst["id"]]["color"])
				if p.art_cd[i] > 0.0:
					var frac: float = clampf(p.art_cd[i] / maxf(p.art_cd_max[i], 0.01), 0.0, 1.0)
					draw_arc(c, r - 5, -PI * 0.5, -PI * 0.5 + TAU * frac, 32, Color(0, 0, 0, 0.75), 10.0)
		var fs := 22 if r > 45 else 18
		draw_string_outline(font, c + Vector2(-r, fs * 0.35), label, HORIZONTAL_ALIGNMENT_CENTER, r * 2, fs, 5, Color.BLACK)
		draw_string(font, c + Vector2(-r, fs * 0.35), label, HORIZONTAL_ALIGNMENT_CENTER, r * 2, fs, Color("#ffe9b0"))
	for i in MENU.size():
		var rc := _menu_rect(i)
		draw_rect(rc, Color(0.08, 0.06, 0.12, 0.7))
		draw_rect(rc, Color(0.42, 0.34, 0.21, 0.9), false, 2.0)
		draw_string(font, rc.position + Vector2(0, 34), MENU[i][1], HORIZONTAL_ALIGNMENT_CENTER, rc.size.x, 18, Color("#f3e6c4"))
	if Settings.auto_attack:
		var sz := get_viewport_rect().size
		draw_string_outline(font, Vector2(sz.x - 420, sz.y - 22), "AUTO-ATTACK ON", HORIZONTAL_ALIGNMENT_RIGHT, 400, 16, 4, Color.BLACK)
		draw_string(font, Vector2(sz.x - 420, sz.y - 22), "AUTO-ATTACK ON", HORIZONTAL_ALIGNMENT_RIGHT, 400, 16, Color("#8aff8a"))

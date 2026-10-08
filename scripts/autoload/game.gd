## Runtime hub: input setup, references to live systems and global gameplay events.
extends Node

signal notify(text: String, color: Color)
signal banner(title: String, subtitle: String)
signal boss_engaged(boss: Node)
signal boss_cleared
signal interact_prompt(text: String)
signal open_dialogue(villager: Node)
signal open_screen(name: String)
signal player_died
signal powerup_changed

var main: Node
var world: Node
var player: Node
var hud: Node
var camera: Camera3D
var in_game := false
var ui_open := false
var shake := 0.0
var time_of_day := 0.3


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	RenderingServer.global_shader_parameter_add("player_pos", RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3(0, -9999, 0))
	RenderingServer.global_shader_parameter_add("cam_pos", RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3(0, -9999, 0))


func _key(action: String, keys: Array, mouse := -1, joy := -1) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	if mouse >= 0:
		var m := InputEventMouseButton.new()
		m.button_index = mouse
		InputMap.action_add_event(action, m)
	if joy >= 0:
		var j := InputEventJoypadButton.new()
		j.button_index = joy
		InputMap.action_add_event(action, j)


func _axis(action: String, axis: int, value: float) -> void:
	var j := InputEventJoypadMotion.new()
	j.axis = axis
	j.axis_value = value
	InputMap.action_add_event(action, j)


func _setup_input() -> void:
	_key("move_up", [KEY_W, KEY_UP])
	_key("move_down", [KEY_S, KEY_DOWN])
	_key("move_left", [KEY_A, KEY_LEFT])
	_key("move_right", [KEY_D, KEY_RIGHT])
	_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_key("attack", [KEY_J], MOUSE_BUTTON_LEFT, JOY_BUTTON_X)
	_key("ranged", [KEY_K], MOUSE_BUTTON_RIGHT, JOY_BUTTON_RIGHT_SHOULDER)
	_key("roll", [KEY_SPACE], -1, JOY_BUTTON_A)
	_key("art1", [KEY_1], -1, JOY_BUTTON_Y)
	_key("art2", [KEY_2], -1, JOY_BUTTON_B)
	_key("art3", [KEY_3], -1, JOY_BUTTON_LEFT_SHOULDER)
	_key("potion", [KEY_Q], -1, JOY_BUTTON_DPAD_UP)
	_key("interact", [KEY_E, KEY_F], -1, JOY_BUTTON_DPAD_DOWN)
	_key("inventory", [KEY_I, KEY_TAB], -1, JOY_BUTTON_BACK)
	_key("quests", [KEY_L])
	_key("skills", [KEY_P])
	_key("map", [KEY_M])
	_key("codex", [KEY_C])
	_key("pause", [KEY_ESCAPE], -1, JOY_BUTTON_START)
	_key("zoom_in", [KEY_EQUAL], MOUSE_BUTTON_WHEEL_UP)
	_key("zoom_out", [KEY_MINUS], MOUSE_BUTTON_WHEEL_DOWN)


func toast(text: String, color := Color.WHITE) -> void:
	notify.emit(text, color)


func add_shake(amount: float) -> void:
	shake = minf(shake + amount, 1.2)


func dim_def() -> Dictionary:
	return Data.dim(State.current_dim)


func enemy_level_at(pos: Vector3) -> int:
	var d := dim_def()
	var dist := Vector2(pos.x, pos.z).length()
	return maxi(1, int(d["base_level"]) + int(dist / 160.0) + State.ascension * 10)


func hp_scale(lvl: int) -> float:
	return 1.0 + 0.07 * (lvl - 1)


func dmg_scale(lvl: int) -> float:
	return 1.0 + 0.065 * (lvl - 1)

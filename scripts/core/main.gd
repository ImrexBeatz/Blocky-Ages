## Top-level flow: title -> creator -> prologue -> game, plus screens, pausing, death and travel.
extends Node

const K = preload("res://scripts/ui/ui_kit.gd")
const World = preload("res://scripts/world/world.gd")
const Player = preload("res://scripts/entities/player.gd")
const HUD = preload("res://scripts/ui/hud.gd")
const MainMenu = preload("res://scripts/ui/main_menu.gd")
const Creator = preload("res://scripts/ui/creator.gd")
const StoryScreen = preload("res://scripts/ui/story_screen.gd")
const Screen = preload("res://scripts/ui/screen.gd")
const InventoryScreen = preload("res://scripts/ui/inventory_screen.gd")
const SkillsScreen = preload("res://scripts/ui/skills_screen.gd")
const QuestsScreen = preload("res://scripts/ui/quests_screen.gd")
const CodexScreen = preload("res://scripts/ui/codex_screen.gd")
const MapScreen = preload("res://scripts/ui/map_screen.gd")
const DialogueScreen = preload("res://scripts/ui/dialogue_screen.gd")
const GateScreen = preload("res://scripts/ui/gate_screen.gd")
const BoardScreen = preload("res://scripts/ui/board_screen.gd")
const SettingsScreen = preload("res://scripts/ui/settings_screen.gd")
const TouchControls = preload("res://scripts/ui/touch_controls.gd")

const CONTROLS := """[color=#f2c14e][b]Movement[/b][/color]   WASD / Arrow keys / Left stick
[color=#f2c14e][b]Melee attack[/b][/color]   Left mouse / J  (hold for a 3-hit combo; the 3rd hit is a heavy finisher)
[color=#f2c14e][b]Ranged attack[/b][/color]   Right mouse / K  (aims at the mouse cursor)
[color=#f2c14e][b]Dodge roll[/b][/color]   Space  (brief invulnerability)
[color=#f2c14e][b]Artifacts (magic)[/b][/color]   1, 2, 3
[color=#f2c14e][b]Health potion[/b][/color]   Q
[color=#f2c14e][b]Interact / Talk[/b][/color]   E or F
[color=#f2c14e][b]Inventory[/b][/color]   I or Tab      [color=#f2c14e][b]Quests[/b][/color]   L      [color=#f2c14e][b]Skills[/b][/color]   P
[color=#f2c14e][b]World map[/b][/color]   M      [color=#f2c14e][b]Codex[/b][/color]   C      [color=#f2c14e][b]Zoom[/b][/color]   Mouse wheel / + -
[color=#f2c14e][b]Pause menu[/b][/color]   Esc

[color=#a89a86]Tips: Follow the golden compass arrow to your tracked quest. Villagers marked with [!] offer quests.
Enemies grow stronger the farther you travel from the village, and so does their loot.
Spend attribute points (P), enchant gear at Enchanters, upgrade gear at Blacksmiths, and empower artifacts at Mystics.[/color]"""

var world: Node3D
var player: Node3D
var hud: Control
var ui: CanvasLayer
var overlay: CanvasLayer
var menu: Control
var screen: Control
var fade: ColorRect
var pending_story: Array = []
var playing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.main = self
	randomize()
	world = World.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	overlay = CanvasLayer.new()
	overlay.layer = 20
	add_child(overlay)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(fade)
	Settings.apply()
	var touch := TouchControls.new()
	ui.add_child(touch)
	Game.open_screen.connect(_on_open_screen)
	Game.open_dialogue.connect(_on_dialogue)
	Game.player_died.connect(_on_player_died)
	Quests.story_event.connect(_on_story_event)
	_show_title()


# ---------------------------------------------------------------- title & creation

func _show_title() -> void:
	playing = false
	Game.in_game = false
	get_tree().paused = false
	State.world_seed = 271828
	State.current_dim = "verdant"
	world.load_realm("verdant", true)
	world.prebuild(Vector3.ZERO, 3)
	menu = MainMenu.new()
	ui.add_child(menu)
	menu.new_game.connect(_on_new_game)
	menu.continue_game.connect(_on_continue)
	menu.show_controls.connect(func(): _info_screen("Controls & Tips", CONTROLS))
	menu.show_settings.connect(func(): _open(SettingsScreen.new()))


func _on_new_game() -> void:
	menu.queue_free()
	var c := Creator.new()
	ui.add_child(c)
	c.back.connect(func():
		c.queue_free()
		_show_title_menu_only())
	c.done.connect(func(profile):
		c.queue_free()
		State.new_game(profile)
		Quests.reset()
		var s := StoryScreen.new()
		s.setup(Story.PROLOGUE, "", true)
		ui.add_child(s)
		s.finished.connect(func():
			Quests.start_story()
			_begin_game()))


func _show_title_menu_only() -> void:
	menu = MainMenu.new()
	ui.add_child(menu)
	menu.new_game.connect(_on_new_game)
	menu.continue_game.connect(_on_continue)
	menu.show_controls.connect(func(): _info_screen("Controls & Tips", CONTROLS))
	menu.show_settings.connect(func(): _open(SettingsScreen.new()))


func _on_continue() -> void:
	if not State.load_game():
		Game.toast("Could not load save.", Color.RED)
		return
	menu.queue_free()
	_begin_game()


func _begin_game() -> void:
	await _fade_to(1.0, 0.35)
	_loading_text("Entering %s..." % Data.dim(State.current_dim)["name"])
	await get_tree().process_frame
	await get_tree().process_frame
	world.load_realm(State.current_dim, false)
	if player == null:
		player = Player.new()
	world.attach_player(player)
	var pos: Vector3 = world.surface_gen.spawn_point()
	var saved = State.positions.get(State.current_dim)
	if saved is Array and saved.size() == 3:
		pos = Vector3(saved[0], saved[1], saved[2])
	world.prebuild(pos, 3)
	var g: float = world.ground_at(pos.x, pos.z)
	if g < -500.0:
		pos = world.safe_point_near(pos)
		g = pos.y
	player.respawn(Vector3(pos.x, g, pos.z))
	player.rebuild_model()
	player._on_stats()
	player.hp = player.max_hp
	world.menu_mode = false
	world._snap_camera()
	if hud == null:
		hud = HUD.new()
		ui.add_child(hud)
		ui.move_child(hud, 0)
	hud.visible = true
	playing = true
	Game.in_game = true
	_clear_loading()
	await _fade_to(0.0, 0.6)
	Game.banner.emit(Data.dim(State.current_dim)["name"], world.region_name())
	_flush_story()


# ---------------------------------------------------------------- screens

func _open(s: Control) -> void:
	if screen and is_instance_valid(screen):
		screen.queue_free()
	screen = s
	Game.ui_open = true
	get_tree().paused = true
	ui.add_child(s)
	if s.has_signal("closed"):
		s.closed.connect(_on_screen_closed)
	elif s.has_signal("finished"):
		s.finished.connect(_on_screen_closed)


func _on_screen_closed() -> void:
	screen = null
	Game.ui_open = false
	get_tree().paused = false
	if playing:
		_flush_story()


func _info_screen(title: String, text: String, size := Vector2(1000, 640)) -> Control:
	var s := Screen.new()
	s.build(title, size)
	var sc: Array = s.scroll()
	s.body.add_child(sc[0])
	var r := K.rich(text)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc[1].add_child(r)
	_open(s)
	return s


func _unhandled_input(event: InputEvent) -> void:
	if not playing:
		return
	if player and player.dead:
		return
	var map := {"inventory": InventoryScreen, "quests": QuestsScreen, "skills": SkillsScreen, "map": MapScreen, "codex": CodexScreen}
	for action in map:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			if screen and is_instance_valid(screen):
				var same: bool = screen.get_script() == map[action]
				screen.close() if screen.has_method("close") else screen.queue_free()
				if same:
					return
			_open(map[action].new())
			return
	if event.is_action_pressed("pause") and screen == null:
		get_viewport().set_input_as_handled()
		_pause_menu()


func _pause_menu() -> void:
	var s := Screen.new()
	s.build("Paused", Vector2(560, 620))
	var v := K.vbox(10)
	s.body.add_child(v)
	v.add_child(K.button("Resume", s.close, 400, 22))
	v.add_child(K.button("Save Game", func():
		_store_position()
		State.save_game()
		Game.toast("Game saved.", Color("#8aff8a")), 400, 22))
	v.add_child(K.button("Controls & Tips", func():
		s.close()
		_info_screen("Controls & Tips", CONTROLS), 400, 22))
	v.add_child(K.button("Settings", func():
		s.close()
		_open(SettingsScreen.new()), 400, 22))
	v.add_child(K.button("Save & Quit to Title", func():
		_store_position()
		State.save_game()
		s.close()
		_quit_to_title(), 400, 22))
	_open(s)


func _store_position() -> void:
	if player and not world.in_cave:
		State.positions[State.current_dim] = [player.global_position.x, player.global_position.y, player.global_position.z]


func _quit_to_title() -> void:
	playing = false
	Game.in_game = false
	if hud:
		hud.visible = false
	if player and player.get_parent():
		player.get_parent().remove_child(player)
	Game.player = null
	world.player = null
	_show_title()


func _on_open_screen(name: String) -> void:
	if name == "gate":
		_open(GateScreen.new())
	elif name == "board":
		_open(BoardScreen.new())
	elif name.begins_with("lore:"):
		var l := Story.lore_entry(name.substr(5))
		_info_screen("Lore Stone: " + l["title"], "[i]%s[/i]\n\n[color=#a89a86]The Codex has been updated (C).[/color]" % l["text"], Vector2(900, 520))
	elif name == "epilogue":
		var s := StoryScreen.new()
		s.setup(Story.EPILOGUE, "", true)
		_open(s)


func _on_dialogue(v: Node) -> void:
	var s := DialogueScreen.new()
	s.setup(v)
	_open(s)


func _on_story_event(speaker: String, lines: Array) -> void:
	pending_story.append([speaker, lines])
	if playing:
		_flush_story.call_deferred()


func _flush_story() -> void:
	if pending_story.is_empty() or (screen and is_instance_valid(screen)) or not playing:
		return
	var e: Array = pending_story.pop_front()
	var s := StoryScreen.new()
	s.setup(e[1], e[0], false)
	_open(s)


# ---------------------------------------------------------------- death & travel

func _on_player_died() -> void:
	Sfx.play("hurt", 0.5)
	await get_tree().create_timer(1.2).timeout
	var s := Screen.new()
	s.build("You Have Fallen", Vector2(640, 380))
	s.body.add_child(K.label("The Prism's light pulls you back from the dark...", 20, K.PARCH))
	var lost := int(State.res("emerald") * 0.1)
	if lost > 0:
		s.body.add_child(K.label("You dropped %d emeralds." % lost, 17, Color("#ff9a9a")))
	s.body.add_child(K.button("Rise Again", func():
		State.resources["emerald"] = State.res("emerald") - lost
		s.close()
		_respawn(), 300, 22))
	_open(s)
	s.set_process_unhandled_input(false)


func _respawn() -> void:
	if world.in_cave:
		world.exit_cave(false)
	var p: Vector3 = player.global_position
	var best: Vector3 = world.surface_gen.spawn_point()
	var bd := Vector2(best.x - p.x, best.z - p.z).length()
	for v in world.surface_gen.villages_near(p, 500.0):
		var d := Vector2(v["x"] - p.x, v["z"] - p.z).length()
		if d < bd:
			bd = d
			best = Vector3(v["x"] + 0.5, v["base"], v["z"] - 3.5)
	world.prebuild(best, 2)
	best.y = world.ground_at(best.x, best.z)
	player.respawn(best)
	world._snap_camera()


func travel_to(dimid: String) -> void:
	await _fade_to(1.0, 0.4)
	_loading_text("Travelling to %s..." % Data.dim(dimid)["name"])
	await get_tree().process_frame
	await get_tree().process_frame
	world.travel(dimid)
	_clear_loading()
	await _fade_to(0.0, 0.6)


func _fade_to(a: float, t: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", a, t)
	await tw.finished


func _loading_text(t: String) -> void:
	_clear_loading()
	var l := K.label(t, 30, K.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	l.name = "Loading"
	overlay.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH


func _clear_loading() -> void:
	var l := overlay.get_node_or_null("Loading")
	if l:
		l.queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and playing:
		_store_position()
		State.save_game()

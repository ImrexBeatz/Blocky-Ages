## Phone-mode test (run with `-- --force-mobile`): low preset auto-selected, incremental chunk streaming
## stays within its frame budget, touch joystick/buttons drive the player, and auto-attack fights.
extends Node

var main: Node
var frame := 0
var worst_stream_us := 0
var kills_before := 0
var worst_spawn_us := 0


func _ready() -> void:
	print("mobile=", Settings.is_mobile, " effective=", Settings.effective(), " lights=", Settings.v["dynamic_lights"], " load_r=", Settings.v["load_r"])
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)


var tc: Node


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = pressed
	tc._input(e)


func _drag(index: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	tc._input(e)


func _process(_delta: float) -> void:
	frame += 1
	if main.world and main.playing and not Game.ui_open:
		var ts := Time.get_ticks_usec()
		main.world._run_pending_spawn()
		worst_spawn_us = maxi(worst_spawn_us, Time.get_ticks_usec() - ts)
		var t0 := Time.get_ticks_usec()
		main.world._stream(0.016)
		worst_stream_us = maxi(worst_stream_us, Time.get_ticks_usec() - t0)
	match frame:
		30:
			State.new_game(State.default_profile())
			Quests.reset()
			main.menu.queue_free()
			Quests.start_story()
			main._begin_game()
		150:
			if main.screen:
				main.screen._finish()
			print("vp scale ", get_viewport().scaling_3d_scale, " shadows ", main.world.sun.shadow_enabled, " glow ", main.world.env.environment.glow_enabled, " bg ", main.world.env.environment.background_mode)
		153:
			for c in main.ui.get_children():
				if c.get_script() == main.TouchControls:
					tc = c
			print("touch controls visible ", tc.visible)
			worst_stream_us = 0
			_touch(0, Vector2(230, 700), true)
		154:
			_drag(0, Vector2(350, 700))
		240:
			print("joystick moved player to ", main.player.global_position, " move_right strength ", Input.get_action_strength("move_right"), " move_up ", Input.get_action_strength("move_up"))
			_touch(0, Vector2(350, 700), false)
			var sz := get_viewport().get_visible_rect().size
			_touch(1, sz + Vector2(-160, -160), true)
		245:
			print("attack held via touch ", Input.is_action_pressed("attack"))
			var sz := get_viewport().get_visible_rect().size
			_touch(1, sz + Vector2(-160, -160), false)
			Settings.auto_attack = true
			main.player.global_position += Vector3(40, 0, 40)
			main.player.global_position.y = main.world.ground_at(main.player.global_position.x, main.player.global_position.z)
			kills_before = State.total_kills
			for i in 3:
				main.world.spawn_enemy("shambler", main.player.global_position + Vector3(1.5 + i, 0, 1), 1)
		700:
			print("auto-attack kills ", State.total_kills - kills_before, " enemies left near ", main.world.enemies.size())
			print("worst chunk-stream frame cost ms ", worst_stream_us / 1000.0, " (budget ", Settings.v["chunk_budget_us"] / 1000.0, ")")
			print("worst single entity-spawn frame ms ", worst_spawn_us / 1000.0)
			print("MOBILE TEST DONE")
			get_tree().quit()

## Headless smoke test: builds a realm, plays the player through combat, bosses, caves and travel.
extends Node

const World = preload("res://scripts/world/world.gd")
const Player = preload("res://scripts/entities/player.gd")

var world
var player
var frame := 0
var errors := 0


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	State.new_game(State.default_profile())
	Quests.start_story()
	world = World.new()
	add_child(world)
	world.load_realm("verdant")
	var sp: Vector3 = world.surface_gen.spawn_point()
	var tb := Time.get_ticks_msec()
	world.prebuild(sp, 3)
	print("prebuild 49 chunks ms: ", Time.get_ticks_msec() - tb)
	player = Player.new()
	world.attach_player(player)
	player.global_position = Vector3(sp.x, world.ground_at(sp.x, sp.z), sp.z)
	world.menu_mode = false
	Game.in_game = true
	print("spawn ", player.global_position, " villagers ", world.villagers.size(), " enemies ", world.enemies.size(), " setup ms ", Time.get_ticks_msec() - t0)
	var tm := Time.get_ticks_msec()
	var img: Image = world.map_image(sp, 64, 3.0)
	print("map 64px ms: ", Time.get_ticks_msec() - tm, " size ", img.get_size())


func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		10:
			var e = world.spawn_enemy("shambler", player.global_position + Vector3(2, 0, 0), 1)
			print("enemy spawned ", e != null)
			Input.action_press("attack")
		60:
			Input.action_release("attack")
			Input.action_press("ranged")
		90:
			Input.action_release("ranged")
			for i in 3:
				player.use_artifact(i)
			for id in Data.items:
				if Data.items[id]["kind"] == "artifact":
					var inst := State.make_item(id, 5, 2)
					State.add_item(inst)
					State.equip(inst["uid"], "art1")
					player.art_cd[0] = 0.0
					player.use_artifact(0)
			print("cast all artifacts ok; enemies ", world.enemies.size(), " allies ", world.allies.size())
		120:
			Input.action_press("move_right")
			Input.action_press("roll")
		200:
			Input.action_release("move_right")
			Input.action_release("roll")
			print("moved to ", player.global_position, " region ", world.region_name())
			for b in Data.bosses:
				var bd: Dictionary = Data.bosses[b]
				world._spawn_boss({"boss": b, "index": bd["index"], "x": player.global_position.x + 6, "z": player.global_position.z, "base": player.global_position.y})
			print("bosses spawned ", world.bosses_alive.size())
		400:
			for b in world.bosses_alive.values():
				if is_instance_valid(b):
					b.take_damage(b.max_hp * 2.0, player, {})
			print("bosses killed; xp ", State.xp, " lvl ", State.level, " inv ", State.inventory.size())
		420:
			world.enter_cave("verdant:1:1", player.global_position)
			print("in cave ", world.in_cave, " pos ", player.global_position, " enemies ", world.enemies.size())
		520:
			world.exit_cave(true)
			print("left cave; quests active ", Quests.active.keys())
		560:
			for d in ["ember", "frost", "spore", "void"]:
				var tt := Time.get_ticks_msec()
				world.travel(d)
				print("travel ", d, " ms ", Time.get_ticks_msec() - tt, " pos ", player.global_position, " villagers ", world.villagers.size())
		700:
			State.save_game()
			var ok := State.load_game()
			print("save/load ", ok, " level ", State.level, " dim ", State.current_dim)
			print("SMOKE TEST DONE frames=", frame, " fps=", Engine.get_frames_per_second())
			get_tree().quit()

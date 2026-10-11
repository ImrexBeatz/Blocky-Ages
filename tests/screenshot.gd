## Captures screenshots of the title screen and gameplay (run under a real/virtual display).
extends Node

var main: Node
var t := 0.0
var step := 0
var out_dir := "user://shots"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			out_dir = a
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)


func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)


func _process(delta: float) -> void:
	t += delta
	if t < 1.0:
		return
	t = 0.0
	step += 1
	match step:
		3:
			_shot("01_title")
			main.menu.new_game.emit()
		4:
			_shot("02_creator")
			var c = main.ui.get_child(main.ui.get_child_count() - 1)
			c.done.emit(c.profile)
		5:
			_shot("03_prologue")
			var s = main.ui.get_child(main.ui.get_child_count() - 1)
			s._finish()
		9:
			_shot("04_story")
			if main.screen:
				main.screen._finish()
		11:
			_shot("05_village")
			Game.time_of_day = 0.3
			main.player.global_position += Vector3(30, 0, 30)
		14:
			for i in 4:
				main.world.spawn_enemy(Data.dim(State.current_dim)["enemies"][i], main.player.global_position + Vector3(4 + i, 0, 2), 1)
		15:
			_shot("06_wilds_enemies")
			main.player.use_artifact(0)
			main.player._start_swing()
		16:
			_shot("07_combat")
			var a: Dictionary = main.world.surface_gen.arenas[0]
			main.world._spawn_boss(a)
			main.player.global_position = Vector3(a["x"] + 8, a["base"], a["z"] + 8)
		19:
			_shot("08_boss")
			main._open(main.InventoryScreen.new())
		20:
			_shot("09_inventory")
			main.screen.close()
			State.unlocked_dims.append_array(["ember", "frost", "spore", "void"])
			main.travel_to("ember")
		24:
			_shot("10_ember")
			main.travel_to("frost")
		28:
			_shot("11_frost")
			main.travel_to("spore")
		32:
			_shot("12_spore")
			main.travel_to("void")
		36:
			_shot("13_void")
			main.world.enter_cave("void:1:1", main.player.global_position)
		39:
			_shot("14_cave")
			get_tree().quit()

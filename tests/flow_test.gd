## Headless end-to-end flow test that drives the real UI and game loop.
extends Node

var main: Node
var t := 0.0
var step := 0


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)


func _find(n: Node, script_path: String) -> Node:
	for c in n.get_children():
		if c.get_script() and c.get_script().resource_path == script_path:
			return c
		var r := _find(c, script_path)
		if r:
			return r
	return null


func _process(delta: float) -> void:
	t += delta
	if t < 0.5:
		return
	t = 0.0
	step += 1
	match step:
		1:
			main.menu.new_game.emit()
		2:
			var c := _find(main, "res://scripts/ui/creator.gd")
			print("creator found ", c != null)
			c._randomize()
			c.done.emit(c.profile)
		3:
			var s := _find(main, "res://scripts/ui/story_screen.gd")
			print("prologue found ", s != null)
			s._finish()
		4, 5, 6:
			pass
		7:
			print("playing ", main.playing, " pos ", main.player.global_position, " hp ", main.player.hp)
			var s := _find(main, "res://scripts/ui/story_screen.gd")
			print("story dialogue shown ", s != null)
			if s:
				s._finish()
		8:
			for scr in [main.InventoryScreen, main.QuestsScreen, main.SkillsScreen, main.MapScreen, main.CodexScreen]:
				var inst = scr.new()
				main._open(inst)
				await get_tree().process_frame
				if inst.has_method("refresh"):
					for tab in 6:
						if "tab" in inst:
							inst.tab = tab
						inst.refresh()
				if inst.get_script() == main.InventoryScreen:
					inst.selected_uid = State.inventory[0]["uid"]
					inst.refresh()
				inst.close()
			print("screens ok")
		9:
			var v = main.world.villagers[0]
			for r in Data.villager_roles:
				v.role = r["id"]
				var d = main.DialogueScreen.new()
				d.setup(v)
				main._open(d)
				await get_tree().process_frame
				if not is_instance_valid(d):
					continue
				for sv in ["quests", "trade", "upgrade", "enchant", "artifact", "potions", "lore"]:
					d.service = sv
					d.refresh()
				d.ench_uid = State.equipment["melee"]["uid"]
				d.service = "enchant"
				d.refresh()
				d.close()
			print("dialogue services ok; talk progress main=", Quests.current_main())
		10:
			main._on_open_screen("gate")
			await get_tree().process_frame
			main.screen.close()
			main._on_open_screen("board")
			await get_tree().process_frame
			main.screen.close()
			main._on_open_screen("lore:v1")
			await get_tree().process_frame
			main.screen.close()
			print("gate/board/lore ok")
		11:
			main.player.invuln = 0.0
			main.player.take_damage(99999, null, {})
		14:
			print("death screen ", main.screen != null)
			main.screen.close()
			main._respawn()
			print("respawned at ", main.player.global_position, " dead=", main.player.dead)
		15:
			State.unlocked_dims.append("ember")
			main.travel_to("ember")
		19:
			print("traveled: ", State.current_dim, " pos ", main.player.global_position)
			main._pause_menu()
		20:
			main.screen.close()
			main._store_position()
			State.save_game()
			main._quit_to_title()
		21:
			print("back at title ", main.menu != null)
			main.menu.continue_game.emit()
		26:
			print("continued: playing ", main.playing, " dim ", State.current_dim, " lvl ", State.level)
			print("FLOW TEST DONE")
			get_tree().quit()

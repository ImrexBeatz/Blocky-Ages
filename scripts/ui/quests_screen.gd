## Quest journal: active quests, tracking, abandoning and story progress.
extends "res://scripts/ui/screen.gd"

var list: VBoxContainer
var detail: RichTextLabel
var actions: HBoxContainer
var selected := ""
var show_done := false


func _ready() -> void:
	build("Quest Journal", Vector2(1220, 740))
	var top := K.hbox(10)
	body.add_child(top)
	top.add_child(K.button("Active", func(): show_done = false; refresh(), 140))
	top.add_child(K.button("Completed", func(): show_done = true; refresh(), 140))
	var stats := K.label("", 17, K.DIM)
	stats.name = "Stats"
	top.add_child(stats)
	var cols := K.hbox(16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	var ls: Array = scroll()
	ls[0].custom_minimum_size.x = 480
	ls[0].size_flags_horizontal = Control.SIZE_FILL
	cols.add_child(ls[0])
	list = ls[1]
	var right := K.vbox(10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	var ds: Array = scroll()
	right.add_child(ds[0])
	detail = K.rich("")
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ds[1].add_child(detail)
	actions = K.hbox(8)
	right.add_child(actions)
	selected = Quests.tracked
	refresh()


func refresh() -> void:
	K.clear(list)
	var done := Quests.completed.size()
	var main_done := 0
	for id in Quests.main_order:
		if Quests.completed.has(id):
			main_done += 1
	var st: Label = body.get_child(0).get_node("Stats")
	st.text = "   Story: %d / %d    All quests: %d / %d (+ endless bounties)" % [main_done, Quests.main_order.size(), done, Quests.total_quests()]
	if show_done:
		var ids: Array = Quests.completed.keys()
		ids.reverse()
		for id in ids:
			var q := Quests.def(id)
			if q.is_empty():
				continue
			list.add_child(_entry(id, q, true))
	else:
		var ids: Array = Quests.active.keys()
		ids.sort_custom(func(a, b): return Quests.def(a).get("main", false) and not Quests.def(b).get("main", false))
		for id in ids:
			list.add_child(_entry(id, Quests.def(id), false))
		if ids.size() <= 1:
			list.add_child(K.label("\nVisit villagers marked with [!] for side quests,\nor check a village Bounty Board for endless bounties.", 15, K.DIM))
	_detail()


func _entry(id: String, q: Dictionary, done: bool) -> Button:
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(460, 48)
	var prefix := "[Main] " if q["main"] else ("[Bounty] " if q.get("bounty", false) else "")
	var prog := "" if done else "  (%d/%d)" % [Quests.progress_of(id), q["count"]]
	b.text = "%s%s%s%s" % ["> " if id == Quests.tracked else "", prefix, q["title"], prog]
	if q["main"]:
		b.add_theme_color_override("font_color", K.GOLD)
	b.pressed.connect(func(): selected = id; _detail())
	return b


func _detail() -> void:
	K.clear(actions)
	var q := Quests.def(selected)
	if q.is_empty():
		detail.text = "Select a quest."
		return
	var d := Data.dim(q["dim"])
	var t := "[font_size=24][color=#f2c14e]%s[/color][/font_size]\n" % q["title"]
	t += "[color=#a89a86]%s  -  %s%s[/color]\n\n" % [d["name"], "Main Story" if q["main"] else "Side Quest", ("  -  from %s" % q.get("giver_name", "")) if q.has("giver_name") else ""]
	t += q["desc"] + "\n\n"
	if not Quests.completed.has(selected):
		t += "Progress: [color=#8aff8a]%d / %d[/color]\n" % [Quests.progress_of(selected), q["count"]]
	t += "Rewards: [color=#8aff8a]%d XP[/color], [color=#2fd37a]%d Emeralds[/color]%s\n" % [q["xp"], q["emerald"], ", gear" if q.get("item", 0) > 0 else ""]
	if q["main"] and not q["story"].is_empty():
		t += "\n[i][color=#cbbba0]%s[/color][/i]" % "\n".join(q["story"])
	detail.text = t
	if Quests.active.has(selected):
		actions.add_child(K.button("Track", func(): Quests.tracked = selected; Quests.quests_changed.emit(); refresh(), 120))
		if not q["main"]:
			actions.add_child(K.button("Abandon", func(): Quests.abandon(selected); selected = Quests.tracked; refresh(), 120))

## Procedurally synthesized sound effects and per-realm ambient music loops.
extends Node

const RATE := 22050

var sounds := {}
var players: Array = []
var music_player: AudioStreamPlayer
var music_cache := {}
var current_music := ""
var _thread: Thread
var sfx_volume := 0.8
var music_volume := 0.5


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -14.0
	add_child(music_player)
	_build_sounds()


func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


func _gen(dur: float, f: Callable) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var r: Array = f.call(t, t / dur, phase)
		phase = r[1]
		out[i] = r[0]
	return out


func _build_sounds() -> void:
	sounds["swing"] = _wav(_gen(0.13, func(t: float, p: float, ph: float): return [randf_range(-1, 1) * (1.0 - p) * 0.35 * sin(p * PI), ph]))
	sounds["hit"] = _wav(_gen(0.14, func(t: float, p: float, ph: float):
		var f := 180.0 - 120.0 * p
		ph += f / RATE
		return [(sin(ph * TAU) * 0.7 + randf_range(-1, 1) * 0.35 * (1.0 - p)) * pow(1.0 - p, 2.0), ph]))
	sounds["crit"] = _wav(_gen(0.2, func(t: float, p: float, ph: float):
		var f := 900.0 - 500.0 * p
		ph += f / RATE
		return [(sign(sin(ph * TAU)) * 0.25 + randf_range(-1, 1) * 0.3) * pow(1.0 - p, 1.5), ph]))
	sounds["hurt"] = _wav(_gen(0.22, func(t: float, p: float, ph: float):
		var f := 320.0 - 170.0 * p
		ph += f / RATE
		return [sign(sin(ph * TAU)) * 0.25 * (1.0 - p), ph]))
	sounds["pickup"] = _wav(_gen(0.12, func(t: float, p: float, ph: float):
		var f := 660.0 if p < 0.5 else 990.0
		ph += f / RATE
		return [sin(ph * TAU) * 0.35 * (1.0 - p * 0.5), ph]))
	sounds["coin"] = _wav(_gen(0.16, func(t: float, p: float, ph: float):
		var f := 1320.0 if p < 0.35 else 1760.0
		ph += f / RATE
		return [sign(sin(ph * TAU)) * 0.12 * (1.0 - p), ph]))
	sounds["levelup"] = _wav(_gen(0.9, func(t: float, p: float, ph: float):
		var notes := [523.25, 659.25, 783.99, 1046.5]
		var f: float = notes[mini(int(p * 6.0), 3)]
		ph += f / RATE
		return [(sin(ph * TAU) * 0.3 + sin(ph * TAU * 2.0) * 0.08) * (1.0 - p * 0.7), ph]))
	sounds["quest"] = _wav(_gen(1.0, func(t: float, p: float, ph: float):
		var notes := [392.0, 523.25, 659.25, 783.99, 1046.5]
		var f: float = notes[mini(int(p * 8.0), 4)]
		ph += f / RATE
		return [(sin(ph * TAU) * 0.28 + sin(ph * TAU * 1.5) * 0.06) * (1.0 - p * 0.8), ph]))
	sounds["magic"] = _wav(_gen(0.4, func(t: float, p: float, ph: float):
		var f := 300.0 + 900.0 * p + sin(t * 60.0) * 40.0
		ph += f / RATE
		return [sin(ph * TAU) * 0.25 * sin(p * PI) + randf_range(-1, 1) * 0.05 * (1.0 - p), ph]))
	sounds["explode"] = _wav(_gen(0.7, func(t: float, p: float, ph: float):
		ph = lerpf(ph, randf_range(-1, 1), 0.15)
		return [ph * 1.6 * pow(1.0 - p, 2.0), ph]))
	sounds["ui"] = _wav(_gen(0.05, func(t: float, p: float, ph: float):
		ph += 880.0 / RATE
		return [sin(ph * TAU) * 0.25 * (1.0 - p), ph]))
	sounds["bow"] = _wav(_gen(0.16, func(t: float, p: float, ph: float):
		var f := 220.0 + 80.0 * (1.0 - p)
		ph += f / RATE
		return [(sin(ph * TAU) * 0.3 + randf_range(-1, 1) * 0.15 * (1.0 - p)) * pow(1.0 - p, 2.0), ph]))
	sounds["boss"] = _wav(_gen(1.4, func(t: float, p: float, ph: float):
		var f := 70.0 + sin(t * 9.0) * 12.0
		ph += f / RATE
		var saw := fmod(ph, 1.0) * 2.0 - 1.0
		return [(saw * 0.4 + randf_range(-1, 1) * 0.15) * sin(p * PI), ph]))
	sounds["portal"] = _wav(_gen(0.9, func(t: float, p: float, ph: float):
		var f := 200.0 + 600.0 * p
		ph += f / RATE
		return [(sin(ph * TAU) * 0.2 + sin(ph * TAU * 1.01) * 0.2) * sin(p * PI), ph]))
	sounds["roll"] = _wav(_gen(0.2, func(t: float, p: float, ph: float):
		ph = lerpf(ph, randf_range(-1, 1), 0.3)
		return [ph * 0.5 * sin(p * PI), ph]))
	sounds["chest"] = _wav(_gen(0.5, func(t: float, p: float, ph: float):
		var notes := [523.25, 783.99, 1046.5]
		var f: float = notes[mini(int(p * 4.0), 2)]
		ph += f / RATE
		return [sign(sin(ph * TAU)) * 0.1 * (1.0 - p), ph]))
	sounds["zap"] = _wav(_gen(0.25, func(t: float, p: float, ph: float):
		ph += (1500.0 + randf() * 2000.0) / RATE
		return [sign(sin(ph * TAU)) * 0.18 * (1.0 - p), ph]))
	sounds["freeze"] = _wav(_gen(0.35, func(t: float, p: float, ph: float):
		ph += (2000.0 - 1200.0 * p) / RATE
		return [(sin(ph * TAU) * 0.15 + randf_range(-1, 1) * 0.12) * (1.0 - p), ph]))


func play(name: String, pitch := 1.0, vol := 0.0) -> void:
	if not sounds.has(name):
		return
	for p in players:
		if not p.playing:
			p.stream = sounds[name]
			p.pitch_scale = pitch * randf_range(0.93, 1.07)
			p.volume_db = vol + linear_to_db(maxf(sfx_volume, 0.001))
			p.play()
			return


# ---------------------------------------------------------------- music

func play_music(dimid: String) -> void:
	if current_music == dimid:
		return
	current_music = dimid
	if music_cache.has(dimid):
		_start_music(music_cache[dimid])
		return
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	var scale: Array = Data.dim(dimid)["music"]
	var base := 110.0 if dimid != "void" else 98.0
	_thread = Thread.new()
	_thread.start(_render_music.bind(dimid, scale, base))


func stop_music() -> void:
	current_music = ""
	var tw := create_tween()
	tw.tween_property(music_player, "volume_db", -60.0, 1.0)
	tw.tween_callback(music_player.stop)


func _render_music(dimid: String, scale: Array, base: float) -> void:
	var rate: int = Settings.v.get("music_rate", 16000)
	var dur := 19.2
	var n := int(dur * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	var beat := 0.6
	var chord_roots := [0, 5, 3, 4]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(dimid)
	var melody: Array = []
	for i in 32:
		melody.append(scale[rng.randi() % scale.size()])
	for i in n:
		var t := float(i) / rate
		var bar := int(t / (beat * 8.0)) % 4
		var root: int = scale[chord_roots[bar] % scale.size()]
		var pad := 0.0
		for k in [0, 2, 4]:
			var semis: int = scale[(chord_roots[bar] + k) % scale.size()]
			var f := base * pow(2.0, semis / 12.0)
			pad += sin(TAU * f * t) * 0.06 + sin(TAU * f * 2.0 * t + 0.3) * 0.02
		var step := int(t / (beat * 0.5))
		var st := fmod(t, beat * 0.5) / (beat * 0.5)
		var mnote: int = melody[step % melody.size()]
		var mf := base * 4.0 * pow(2.0, mnote / 12.0)
		var env := exp(-st * 5.0)
		var arp := sin(TAU * mf * t) * 0.07 * env if step % 3 != 2 else 0.0
		var bass_f := base * 0.5 * pow(2.0, root / 12.0)
		var bass := sin(TAU * bass_f * t) * 0.12 * (0.6 + 0.4 * exp(-fmod(t, beat * 2.0) * 2.0))
		var fade := minf(1.0, minf(t, dur - t) * 4.0)
		out[i] = (pad + arp + bass) * fade
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(out[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = bytes
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	call_deferred("_music_ready", dimid, w)


func _music_ready(dimid: String, w: AudioStreamWAV) -> void:
	music_cache[dimid] = w
	if current_music == dimid:
		_start_music(w)


func _start_music(w: AudioStreamWAV) -> void:
	music_player.stream = w
	music_player.volume_db = -40.0
	music_player.play()
	var tw := create_tween()
	tw.tween_property(music_player, "volume_db", linear_to_db(maxf(music_volume, 0.001)) - 10.0, 2.0)


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()

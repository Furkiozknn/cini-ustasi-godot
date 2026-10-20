extends Node
## Audio: three buses (Master/Music/SFX), synthesised sound effects and a generative oud-like
## music loop on a Hicaz scale. Samples are generated a few per frame after start-up so nothing hitches.

const SCALE: Array[float] = [293.66, 311.13, 369.99, 392.0, 440.0, 466.16, 523.25, 587.33, 622.25, 739.99]
const NOTE_DUR: float = 2.4
const SFX_POOL: int = 10
const MUSIC_POOL: int = 8

var _sfx: Dictionary = {}
var _notes: Array[AudioStreamWAV] = []
var _low_note: AudioStreamWAV = null
var _drone: AudioStreamWAV = null
var _queue: Array[Callable] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_players: Array[AudioStreamPlayer] = []
var _drone_player: AudioStreamPlayer = null
var _sfx_next: int = 0
var _music_next: int = 0
var _music_time: float = 0.0
var _next_note: float = 1.0
var _degree: int = 0
var _pending: Array = [] # [time, stream, volume_db]
var _music_ready: bool = false
var _music_started: bool = false
var _rng := RandomNumberGenerator.new()
var _headless: bool = false
var _master_idx: int = 0
var _music_idx: int = 0
var _sfx_idx: int = 0
var _synth_ms: float = 0.0
var _synth_worst_ms: float = 0.0


func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	_rng.seed = 12345
	_setup_buses()
	for i in SFX_POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	for i in MUSIC_POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		add_child(p)
		_music_players.append(p)
	_drone_player = AudioStreamPlayer.new()
	_drone_player.bus = "Music"
	_drone_player.volume_db = -60.0
	add_child(_drone_player)
	Settings.changed.connect(_apply_volumes)
	_apply_volumes()
	if _headless or Args.has("mute"):
		return
	_enqueue_all()


func _setup_buses() -> void:
	_master_idx = AudioServer.get_bus_index("Master")
	_music_idx = AudioServer.get_bus_index("Music")
	if _music_idx < 0:
		AudioServer.add_bus()
		_music_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_music_idx, "Music")
		AudioServer.set_bus_send(_music_idx, "Master")
		var delay := AudioEffectDelay.new()
		delay.dry = 1.0
		delay.tap1_active = true
		delay.tap1_delay_ms = 270.0
		delay.tap1_level_db = -11.0
		delay.tap1_pan = 0.15
		delay.tap2_active = false
		delay.feedback_active = true
		delay.feedback_delay_ms = 270.0
		delay.feedback_level_db = -10.0
		delay.feedback_lowpass = 1800.0
		AudioServer.add_bus_effect(_music_idx, delay)
	_sfx_idx = AudioServer.get_bus_index("SFX")
	if _sfx_idx < 0:
		AudioServer.add_bus()
		_sfx_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_sfx_idx, "SFX")
		AudioServer.set_bus_send(_sfx_idx, "Master")


func _apply_volumes() -> void:
	AudioServer.set_bus_volume_db(_master_idx, linear_to_db(maxf(Settings.master_volume, 0.0001)))
	AudioServer.set_bus_mute(_master_idx, Settings.master_volume <= 0.001)
	AudioServer.set_bus_volume_db(_music_idx, linear_to_db(maxf(Settings.music_volume, 0.0001)))
	AudioServer.set_bus_mute(_music_idx, Settings.music_volume <= 0.001 or not Settings.music_on)
	AudioServer.set_bus_volume_db(_sfx_idx, linear_to_db(maxf(Settings.sfx_volume, 0.0001)))
	AudioServer.set_bus_mute(_sfx_idx, Settings.sfx_volume <= 0.001 or not Settings.sfx_on)


# ---------------------------------------------------------------- generation

func _enqueue_all() -> void:
	_queue.append(_gen_sfx.bind("ui"))
	_queue.append(_gen_sfx.bind("rotate"))
	_queue.append(_gen_sfx.bind("click"))
	_queue.append(_gen_sfx.bind("match1"))
	_queue.append(_gen_sfx.bind("match2"))
	_queue.append(_gen_sfx.bind("match3"))
	_queue.append(_gen_sfx.bind("swap"))
	_queue.append(_gen_sfx.bind("flip"))
	_queue.append(_gen_sfx.bind("lift"))
	_queue.append(_gen_sfx.bind("deny"))
	_queue.append(_gen_sfx.bind("star"))
	# the 8 s drone is the biggest job: render it one second per frame
	var drone_synth := Synth.new(8.0, 98)
	for sec in 8:
		_queue.append(drone_synth.drone.bind(8.0, float(sec), float(sec + 1)))
	_queue.append(_gen_drone.bind(drone_synth))
	for i in SCALE.size():
		_queue.append(_gen_note.bind(i))
	_queue.append(_gen_low_note)
	_queue.append(_gen_sfx.bind("whoosh"))
	_queue.append(_gen_sfx.bind("fire"))
	_queue.append(_gen_sfx.bind("fanfare"))


func _process(delta: float) -> void:
	# Spread sample synthesis over frames: one job per frame keeps start-up smooth.
	if not _queue.is_empty():
		var job: Callable = _queue.pop_front()
		var t0: int = Time.get_ticks_usec()
		job.call()
		var ms: float = (Time.get_ticks_usec() - t0) / 1000.0
		_synth_ms += ms
		_synth_worst_ms = maxf(_synth_worst_ms, ms)
		if _queue.is_empty():
			_music_ready = true
			if Args.has("stats"):
				print("SYNTH done frame=%d total_ms=%.0f worst_job_ms=%.0f" % [Engine.get_process_frames(), _synth_ms, _synth_worst_ms])
	_update_music(delta)


func _gen_sfx(name: String) -> void:
	var s: Synth
	match name:
		"click":
			s = Synth.new(0.12, 1)
			s.noise(0.0, 0.04, Synth.Filter.BANDPASS, 2600.0, 1.5, 0.25)
			s.tone(1900.0, 0.0, 0.05, 0.08)
		"rotate":
			s = Synth.new(0.25, 2)
			s.noise(0.0, 0.16, Synth.Filter.BANDPASS, 900.0, 1.2, 0.18, 2400.0)
			s.tone(660.0, 0.02, 0.12, 0.05, Synth.Wave.TRIANGLE)
		"swap":
			s = Synth.new(0.3, 3)
			s.noise(0.0, 0.22, Synth.Filter.BANDPASS, 500.0, 1.0, 0.2, 1600.0)
			s.tone(440.0, 0.0, 0.1, 0.05, Synth.Wave.TRIANGLE)
			s.tone(550.0, 0.12, 0.1, 0.05, Synth.Wave.TRIANGLE)
		"flip":
			s = Synth.new(0.25, 4)
			s.noise(0.0, 0.12, Synth.Filter.BANDPASS, 1400.0, 1.5, 0.2, 500.0)
			s.tone(880.0, 0.1, 0.08, 0.06)
		"lift":
			s = Synth.new(0.12, 5)
			s.noise(0.0, 0.08, Synth.Filter.HIGHPASS, 3000.0, 1.0, 0.12)
		"match1", "match2", "match3":
			var count: int = int(name.substr(5))
			s = Synth.new(0.8, 6)
			var base: Array[float] = [523.25, 659.25, 783.99]
			for i in count:
				s.tone(base[i], i * 0.06, 0.5, 0.07)
				s.tone(base[i] * 2.0, i * 0.06, 0.25, 0.02)
		"deny":
			s = Synth.new(0.3, 7)
			s.tone(220.0, 0.0, 0.12, 0.08, Synth.Wave.SQUARE)
			s.tone(196.0, 0.1, 0.14, 0.08, Synth.Wave.SQUARE)
		"whoosh":
			s = Synth.new(1.6, 8)
			s.noise(0.0, 1.4, Synth.Filter.LOWPASS, 300.0, 0.8, 0.5, 2800.0)
			s.noise(0.2, 1.2, Synth.Filter.BANDPASS, 120.0, 2.0, 0.35, 60.0)
		"fire":
			s = Synth.new(2.0, 9)
			s.noise(0.0, 1.8, Synth.Filter.LOWPASS, 900.0, 0.5, 0.3, 200.0)
			for i in 8:
				s.noise(0.2 + _rng.randf() * 1.3, 0.05, Synth.Filter.HIGHPASS, 4000.0, 1.0, 0.12)
		"fanfare":
			s = Synth.new(2.5, 10)
			var notes: Array[float] = [587.33, 739.99, 880.0, 1174.66, 1479.98]
			for i in notes.size():
				s.tone(notes[i], i * 0.11, 0.9, 0.09, Synth.Wave.TRIANGLE)
				s.tone(notes[i] * 0.5, i * 0.11, 0.9, 0.05)
			s.tone(1174.66, 0.7, 1.6, 0.08)
			s.tone(1479.98, 0.7, 1.6, 0.06)
			s.tone(1760.0, 0.7, 1.6, 0.05)
		"star":
			s = Synth.new(0.6, 11)
			s.tone(1567.98, 0.0, 0.4, 0.06)
			s.tone(2093.0, 0.05, 0.5, 0.04)
		_:
			s = Synth.new(0.1, 12)
			s.tone(1200.0, 0.0, 0.06, 0.05)
	_sfx[name] = s.to_wav()


func _gen_note(degree: int) -> void:
	var s := Synth.new(NOTE_DUR + 0.1, 100 + degree)
	s.pluck(SCALE[degree], 0.0, 0.5, NOTE_DUR)
	while _notes.size() <= degree:
		_notes.append(null)
	_notes[degree] = s.to_wav()


func _gen_low_note() -> void:
	var s := Synth.new(NOTE_DUR + 0.1, 99)
	s.pluck(SCALE[0] / 2.0, 0.0, 0.5, NOTE_DUR)
	_low_note = s.to_wav()


func _gen_drone(s: Synth) -> void:
	_drone = s.to_wav(true)


# ---------------------------------------------------------------- playback

## Plays a sound effect by name. gain is linear (1 = as designed).
func play(name: String, gain: float = 1.0, pitch: float = 1.0) -> void:
	if _headless or not _sfx.has(name):
		return
	var p: AudioStreamPlayer = _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % SFX_POOL
	p.stream = _sfx[name]
	p.volume_db = linear_to_db(maxf(gain, 0.001)) + 8.0
	p.pitch_scale = pitch
	p.play()


func match_sound(count: int) -> void:
	play("match%d" % clampi(count, 1, 3))


func _play_note(stream: AudioStreamWAV, vel: float) -> void:
	if stream == null:
		return
	var p: AudioStreamPlayer = _music_players[_music_next]
	_music_next = (_music_next + 1) % MUSIC_POOL
	p.stream = stream
	p.volume_db = linear_to_db(vel)
	p.play()


func _update_music(delta: float) -> void:
	if _headless or not _music_ready:
		return
	if Settings.music_volume <= 0.001 or not Settings.music_on:
		return
	if not _music_started:
		_music_started = true
		_drone_player.stream = _drone
		_drone_player.play()
		var tw := create_tween()
		tw.tween_property(_drone_player, "volume_db", linear_to_db(0.08), 4.0)
	_music_time += delta
	# flush scheduled grace notes
	var i: int = 0
	while i < _pending.size():
		if _pending[i][0] <= _music_time:
			_play_note(_pending[i][1], _pending[i][2])
			_pending.remove_at(i)
		else:
			i += 1
	if _music_time < _next_note:
		return
	# melodic random walk with a pull toward the tonic and the fifth
	var step: int = 0
	if _rng.randf() >= 0.25:
		step = (-1 if _rng.randf() < 0.5 else 1) * (1 if _rng.randf() < 0.75 else 2)
	_degree = clampi(_degree + step, 0, SCALE.size() - 1)
	if _rng.randf() < 0.12:
		_degree = 0 if _rng.randf() < 0.5 else 4
	var vel: float = 0.14 + _rng.randf() * 0.1
	_play_note(_notes[_degree], vel)
	if _rng.randf() < 0.25:
		var d2: int = clampi(_degree + (2 if _rng.randf() < 0.5 else -2), 0, SCALE.size() - 1)
		_pending.append([_music_time + 0.18, _notes[d2], vel * 0.5])
	if _rng.randf() < 0.1:
		_pending.append([_music_time + 0.02, _low_note, vel * 0.8])
	var gaps: Array[float] = [0.8, 1.0, 1.2, 1.6, 2.0, 2.6]
	_next_note = _music_time + gaps[_rng.randi_range(0, gaps.size() - 1)]

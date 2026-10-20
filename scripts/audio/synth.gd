class_name Synth
extends RefCounted
## Tiny offline synthesiser: mixes tones, filtered noise and plucks into a float buffer and
## turns it into an AudioStreamWAV. Everything the game plays is made here, no audio files.

const RATE: int = 22050

enum Wave { SINE, TRIANGLE, SQUARE }
enum Filter { LOWPASS, HIGHPASS, BANDPASS }

var data: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func _init(duration: float, seed_value: int = 1) -> void:
	data.resize(int(ceil(duration * RATE)) + 1)
	data.fill(0.0)
	_rng.seed = seed_value


func _ensure(samples: int) -> void:
	if samples > data.size():
		var old: int = data.size()
		data.resize(samples)
		for i in range(old, samples):
			data[i] = 0.0


## Web-Audio style envelope sampled per frame: exponential ramp 0.0001 -> gain over `attack`, then
## exponential decay to 0.0001 at `dur`. Both legs are a running multiply, so no pow() per sample
## (this runs in GDScript, several times slower in the browser).
static func _envelope(count: int, gain: float, attack: float, dur: float) -> PackedFloat32Array:
	var env := PackedFloat32Array()
	env.resize(count)
	var attack_n: int = mini(int(attack * RATE), count)
	var e: float = 0.0001
	var k_up: float = pow(gain / 0.0001, 1.0 / maxf(attack_n, 1.0))
	for i in attack_n:
		env[i] = e
		e *= k_up
	var decay_n: float = maxf(dur - attack, 0.0001) * RATE
	var k_down: float = pow(0.0001 / gain, 1.0 / decay_n)
	e = gain
	for i in range(attack_n, count):
		env[i] = e
		e *= k_down
	return env


func tone(freq: float, t0: float, dur: float, gain: float, kind: Wave = Wave.SINE, detune_cents: float = 0.0, attack: float = 0.012) -> void:
	var f: float = freq * pow(2.0, detune_cents / 1200.0)
	var start: int = int(t0 * RATE)
	var count: int = int(dur * RATE)
	_ensure(start + count + 1)
	var env := _envelope(count, gain, attack, dur)
	var ph: float = 0.0
	var step: float = f / RATE
	match kind:
		Wave.TRIANGLE:
			for i in count:
				var p: float = ph - floorf(ph)
				data[start + i] += (4.0 * absf(p - 0.5) - 1.0) * env[i]
				ph += step
		Wave.SQUARE:
			for i in count:
				data[start + i] += (1.0 if (ph - floorf(ph)) < 0.5 else -1.0) * env[i]
				ph += step
		_:
			for i in count:
				data[start + i] += sin(ph * TAU) * env[i]
				ph += step


## Filtered white noise with an optional exponential frequency sweep f0 -> f1 across the duration.
func noise(t0: float, dur: float, kind: Filter, f0: float, q: float, gain: float, f1: float = 0.0) -> void:
	var start: int = int(t0 * RATE)
	var count: int = int(dur * RATE)
	_ensure(start + count + 1)
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0
	var b0: float = 0.0
	var b1: float = 0.0
	var b2: float = 0.0
	var a1: float = 0.0
	var a2: float = 0.0
	var sweep: bool = f1 > 0.0
	var env := _envelope(count, gain, 0.01, dur)
	for i in count:
		if i % 32 == 0:
			var f: float = f0
			if sweep:
				f = f0 * pow(f1 / f0, float(i) / count)
			var w0: float = TAU * clampf(f, 20.0, RATE * 0.45) / RATE
			var cw: float = cos(w0)
			var sw: float = sin(w0)
			var alpha: float = sw / (2.0 * q)
			var a0: float = 1.0 + alpha
			match kind:
				Filter.LOWPASS:
					b0 = (1.0 - cw) / 2.0 / a0
					b1 = (1.0 - cw) / a0
					b2 = b0
				Filter.HIGHPASS:
					b0 = (1.0 + cw) / 2.0 / a0
					b1 = -(1.0 + cw) / a0
					b2 = b0
				_:
					b0 = alpha / a0
					b1 = 0.0
					b2 = -alpha / a0
			a1 = -2.0 * cw / a0
			a2 = (1.0 - alpha) / a0
		var x0: float = _rng.randf_range(-1.0, 1.0)
		var y0: float = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x0
		y2 = y1
		y1 = y0
		data[start + i] += y0 * env[i]


## Oud-ish pluck: two detuned triangle strings through a closing lowpass, an octave sine and a tiny attack noise.
func pluck(freq: float, t0: float, vel: float, dur: float) -> void:
	var start: int = int(t0 * RATE)
	var count: int = int(dur * RATE)
	_ensure(start + count + 1)
	var ph_a: float = 0.0
	var ph_b: float = 0.0
	var step_a: float = freq * pow(2.0, -5.0 / 1200.0) / RATE
	var step_b: float = freq * pow(2.0, 6.0 / 1200.0) / RATE
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0
	var b0: float = 0.0
	var b1: float = 0.0
	var b2: float = 0.0
	var a1: float = 0.0
	var a2: float = 0.0
	var sweep_len: float = dur * 0.8
	var env := _envelope(count, vel, 0.006, dur)
	for i in count:
		if i % 32 == 0:
			var u: float = minf(float(i) / RATE / sweep_len, 1.0)
			var f: float = freq * 6.0 * pow(1.5 / 6.0, u)
			var w0: float = TAU * clampf(f, 20.0, RATE * 0.45) / RATE
			var cw: float = cos(w0)
			var alpha: float = sin(w0) / (2.0 * 0.7)
			var a0: float = 1.0 + alpha
			b0 = (1.0 - cw) / 2.0 / a0
			b1 = (1.0 - cw) / a0
			b2 = b0
			a1 = -2.0 * cw / a0
			a2 = (1.0 - alpha) / a0
		var pa: float = ph_a - floorf(ph_a)
		var pb: float = ph_b - floorf(ph_b)
		var x0: float = (4.0 * absf(pa - 0.5) - 1.0 + 4.0 * absf(pb - 0.5) - 1.0) * 0.5
		ph_a += step_a
		ph_b += step_b
		var y0: float = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x0
		y2 = y1
		y1 = y0
		data[start + i] += y0 * env[i]
	# octave partial, fast decay (pure exponential, so a running multiply again)
	var ph2: float = 0.0
	var step2: float = freq * 2.0 / RATE
	var dur2: float = dur * 0.4
	var count2: int = int(dur2 * RATE)
	var e2: float = vel * 0.25
	var k2: float = pow(0.0001 / (vel * 0.25), 1.0 / (dur2 * RATE))
	for i in count2:
		data[start + i] += sin(ph2 * TAU) * e2
		e2 *= k2
		ph2 += step2
	noise(t0, 0.03, Filter.BANDPASS, freq * 3.0, 2.0, vel * 0.5)


## Steady drone of three sines with a slow amplitude wobble; loops seamlessly when the duration is a
## whole LFO cycle. `from`/`to` (seconds) render one slice so the 8 s loop can be spread over frames.
func drone(duration: float, from: float = 0.0, to: float = -1.0) -> void:
	var count: int = int(duration * RATE)
	_ensure(count)
	var parts: Array = [[73.375, 1.0], [110.0, 0.5], [146.75, 0.35]]
	var lfo_f: float = 1.0 / duration
	var i0: int = clampi(int(from * RATE), 0, count)
	var i1: int = count if to < 0.0 else clampi(int(to * RATE), 0, count)
	var wobble: Array[float] = [1.0, 1.0, 1.0]
	for i in range(i0, i1):
		var t: float = float(i) / RATE
		if i % 64 == 0:
			# the LFOs run at 1/8 - 3/8 Hz, so sampling them every 64 frames is inaudible
			for k in 3:
				wobble[k] = 1.0 + 0.3 * sin(TAU * lfo_f * (k + 1) * t + k * 1.7)
		var v: float = 0.0
		for k in 3:
			v += sin(TAU * parts[k][0] * t) * parts[k][1] * wobble[k]
		data[i] = v * 0.5


func to_wav(loop: bool = false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		var v: int = int(clampf(data[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = data.size()
	return wav

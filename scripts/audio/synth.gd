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


## Web-Audio style envelope: exponential ramp 0.0001 -> gain over `attack`, then exponential decay to 0.0001 at `dur`.
static func _env(t: float, gain: float, attack: float, dur: float) -> float:
	if t < attack:
		return 0.0001 * pow(gain / 0.0001, t / attack)
	var u: float = (t - attack) / maxf(dur - attack, 0.0001)
	return gain * pow(0.0001 / gain, minf(u, 1.0))


static func _wave(kind: Wave, ph: float) -> float:
	match kind:
		Wave.TRIANGLE:
			var p: float = ph - floorf(ph)
			return 4.0 * absf(p - 0.5) - 1.0
		Wave.SQUARE:
			return 1.0 if (ph - floorf(ph)) < 0.5 else -1.0
		_:
			return sin(ph * TAU)


func tone(freq: float, t0: float, dur: float, gain: float, kind: Wave = Wave.SINE, detune_cents: float = 0.0, attack: float = 0.012) -> void:
	var f: float = freq * pow(2.0, detune_cents / 1200.0)
	var start: int = int(t0 * RATE)
	var count: int = int(dur * RATE)
	_ensure(start + count + 1)
	var ph: float = 0.0
	var step: float = f / RATE
	for i in count:
		var t: float = float(i) / RATE
		data[start + i] += _wave(kind, ph) * _env(t, gain, attack, dur)
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
		var t: float = float(i) / RATE
		data[start + i] += y0 * _env(t, gain, 0.01, dur)


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
	for i in count:
		var t: float = float(i) / RATE
		if i % 32 == 0:
			var u: float = minf(t / sweep_len, 1.0)
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
		var x0: float = (_wave(Wave.TRIANGLE, ph_a) + _wave(Wave.TRIANGLE, ph_b)) * 0.5
		ph_a += step_a
		ph_b += step_b
		var y0: float = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x0
		y2 = y1
		y1 = y0
		data[start + i] += y0 * _env(t, vel, 0.006, dur)
	# octave partial, fast decay
	var ph2: float = 0.0
	var step2: float = freq * 2.0 / RATE
	var dur2: float = dur * 0.4
	var count2: int = int(dur2 * RATE)
	for i in count2:
		var t: float = float(i) / RATE
		data[start + i] += sin(ph2 * TAU) * vel * 0.25 * pow(0.0001 / (vel * 0.25), t / dur2)
		ph2 += step2
	noise(t0, 0.03, Filter.BANDPASS, freq * 3.0, 2.0, vel * 0.5)


## Steady drone of three sines with a slow amplitude wobble; loops seamlessly when the duration is a whole LFO cycle.
func drone(duration: float) -> void:
	var count: int = int(duration * RATE)
	_ensure(count)
	var parts: Array = [[73.375, 1.0], [110.0, 0.5], [146.75, 0.35]]
	var lfo_f: float = 1.0 / duration
	for i in count:
		var t: float = float(i) / RATE
		var v: float = 0.0
		for k in parts.size():
			var fq: float = parts[k][0]
			var g: float = parts[k][1]
			var wobble: float = 1.0 + 0.3 * sin(TAU * lfo_f * (k + 1) * t + k * 1.7)
			v += sin(TAU * fq * t) * g * wobble
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

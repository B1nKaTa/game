class_name SoundBank
extends RefCounted

enum { SINE, SQUARE, NOISE }

const RATE := 22050
const ATTACK_TIME := 0.004
const NOISE_SEED := 7
const SOUNDS := {
	"combo_hit": {"from": 220.0, "to": 110.0, "time": 0.08, "shape": SQUARE, "volume": 0.45},
	"charged_hit": {"from": 150.0, "to": 45.0, "time": 0.2, "shape": SQUARE, "volume": 0.6},
	"swing_miss": {"from": 0.0, "to": 0.0, "time": 0.1, "shape": NOISE, "volume": 0.2},
	"cane_throw": {"from": 300.0, "to": 700.0, "time": 0.12, "shape": SINE, "volume": 0.45},
	"cane_catch": {"from": 600.0, "to": 400.0, "time": 0.07, "shape": SINE, "volume": 0.4},
	"player_hurt": {"from": 300.0, "to": 100.0, "time": 0.25, "shape": SQUARE, "volume": 0.45},
	"enemy_death": {"from": 500.0, "to": 80.0, "time": 0.3, "shape": SQUARE, "volume": 0.4},
	"coin_pickup": {"from": 880.0, "to": 1320.0, "time": 0.08, "shape": SINE, "volume": 0.4},
	"door_open": {"from": 120.0, "to": 240.0, "time": 0.35, "shape": SINE, "volume": 0.5},
	"explosion": {"from": 0.0, "to": 0.0, "time": 0.4, "shape": NOISE, "volume": 0.65},
	"consumable_pickup": {"from": 520.0, "to": 780.0, "time": 0.14, "shape": SQUARE, "volume": 0.3},
}


static func names() -> Array:
	return SOUNDS.keys()


static func wave_bytes(from_hz: float, to_hz: float, seconds: float, shape: int, volume: float) -> PackedByteArray:
	var count := maxi(int(RATE * seconds), 0)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = NOISE_SEED
	var phase := 0.0
	var peak := clampf(volume, 0.0, 1.0) * 32767.0
	for i in count:
		var t := float(i) / float(count)
		phase += TAU * lerpf(from_hz, to_hz, t) / float(RATE)
		var raw := 0.0
		match shape:
			SINE:
				raw = sin(phase)
			SQUARE:
				raw = 1.0 if sin(phase) >= 0.0 else -1.0
			NOISE:
				raw = rng.randf_range(-1.0, 1.0)
		var envelope := minf(float(i) / (ATTACK_TIME * RATE), 1.0) * (1.0 - t)
		bytes.encode_s16(i * 2, clampi(int(raw * envelope * peak), -32768, 32767))
	return bytes


static func make_stream(sound_name: String) -> AudioStreamWAV:
	if not SOUNDS.has(sound_name):
		return null
	var spec: Dictionary = SOUNDS[sound_name]
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = wave_bytes(spec["from"], spec["to"], spec["time"], spec["shape"], spec["volume"])
	return stream

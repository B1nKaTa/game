extends TestCase

const EXPECTED := ["combo_hit", "charged_hit", "swing_miss", "teeth_throw", "teeth_catch", "player_hurt", "enemy_death", "coin_pickup", "door_open"]


func _samples(bytes: PackedByteArray) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in bytes.size() / 2:
		out.append(bytes.decode_s16(i * 2))
	return out


func test_every_needed_sound_exists() -> void:
	for sound_name in EXPECTED:
		assert_true(SoundBank.names().has(sound_name), sound_name)


func test_wave_length_matches_the_duration() -> void:
	var bytes := SoundBank.wave_bytes(440.0, 440.0, 0.1, SoundBank.SINE, 0.5)
	assert_eq(bytes.size(), int(SoundBank.RATE * 0.1) * 2)


func test_samples_stay_in_range_and_below_the_volume() -> void:
	for shape in [SoundBank.SINE, SoundBank.SQUARE, SoundBank.NOISE]:
		var peak := 0
		for sample in _samples(SoundBank.wave_bytes(300.0, 900.0, 0.12, shape, 0.4)):
			peak = maxi(peak, absi(sample))
		assert_true(peak <= int(0.4 * 32767.0) + 1, "shape %d stays under volume" % shape)
		assert_true(peak > 1000, "shape %d is audible" % shape)


func test_volume_above_one_is_clamped_to_16_bit() -> void:
	var peak := 0
	for sample in _samples(SoundBank.wave_bytes(200.0, 200.0, 0.05, SoundBank.SQUARE, 5.0)):
		peak = maxi(peak, absi(sample))
	assert_true(peak <= 32767)


func test_sound_fades_out_to_silence() -> void:
	var samples := _samples(SoundBank.wave_bytes(200.0, 200.0, 0.1, SoundBank.SQUARE, 0.5))
	assert_true(absi(samples[samples.size() - 1]) < 200)


func test_zero_length_wave_is_empty() -> void:
	assert_eq(SoundBank.wave_bytes(200.0, 200.0, 0.0, SoundBank.SINE, 0.5).size(), 0)


func test_each_sound_builds_a_16_bit_mono_stream() -> void:
	for sound_name in EXPECTED:
		var stream := SoundBank.make_stream(sound_name)
		assert_true(stream != null, sound_name)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, sound_name)
		assert_false(stream.stereo, sound_name)
		assert_eq(stream.mix_rate, SoundBank.RATE, sound_name)
		assert_true(stream.data.size() > 0, sound_name)


func test_sounds_are_short() -> void:
	for sound_name in EXPECTED:
		assert_true(SoundBank.make_stream(sound_name).get_length() <= 0.5, sound_name)


func test_sounds_differ_from_each_other() -> void:
	var seen := {}
	for sound_name in EXPECTED:
		var key := SoundBank.make_stream(sound_name).data.hex_encode()
		assert_false(seen.has(key), "%s duplicates another sound" % sound_name)
		seen[key] = true


func test_unknown_sound_gives_no_stream() -> void:
	assert_true(SoundBank.make_stream("nope") == null)


func test_streams_are_deterministic() -> void:
	assert_eq(SoundBank.make_stream("enemy_death").data, SoundBank.make_stream("enemy_death").data)

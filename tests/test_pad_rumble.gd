extends TestCase

# Rumble: short and weak for a hit taken, stronger for a heavy hit landed and the strongest for a boss
# slam, only while a pad plays and the Vibration option is on.


func _play_on_pad() -> void:
	ActiveDevice.reset()
	var press := PadInput.button(JOY_BUTTON_A)
	press.pressed = true
	ActiveDevice.note_named(press, "")
	PadRumble.reset()


func test_it_rumbles_only_while_a_pad_plays() -> void:
	ActiveDevice.reset()
	PadRumble.reset()
	assert_false(PadRumble.play(PadRumble.HIT_TAKEN), "nothing to rumble on the keyboard")
	assert_eq(PadRumble.last, "")
	_play_on_pad()
	assert_true(PadRumble.play(PadRumble.HIT_TAKEN))
	assert_eq(PadRumble.last, PadRumble.HIT_TAKEN)
	ActiveDevice.reset()


func test_the_vibration_option_turns_it_off() -> void:
	_play_on_pad()
	PadRumble.enabled = false
	assert_false(PadRumble.play(PadRumble.BOSS_SLAM))
	assert_eq(PadRumble.last, "")
	PadRumble.enabled = true
	ActiveDevice.reset()


func test_heavier_moments_rumble_harder_and_longer() -> void:
	var hit := PadRumble.strength(PadRumble.HIT_TAKEN)
	var heavy := PadRumble.strength(PadRumble.HEAVY_LANDED)
	var slam := PadRumble.strength(PadRumble.BOSS_SLAM)
	assert_true(hit.y < heavy.y and heavy.y < slam.y, "the strong motor grows")
	assert_true(hit.x <= heavy.x and heavy.x <= slam.x, "the weak motor grows")
	assert_true(hit.z <= heavy.z and heavy.z <= slam.z, "and each lasts at least as long")
	assert_true(hit.z <= 0.2, "a hit taken is short")
	assert_eq(PadRumble.strength("nonsense"), Vector3.ZERO)
	assert_false(PadRumble.play("nonsense"))


func test_a_lighter_rumble_never_cuts_a_stronger_one_short() -> void:
	_play_on_pad()
	assert_true(PadRumble.play(PadRumble.BOSS_SLAM))
	assert_false(PadRumble.play(PadRumble.HIT_TAKEN), "the slam is still going")
	assert_eq(PadRumble.last, PadRumble.BOSS_SLAM)
	assert_true(PadRumble.play(PadRumble.BOSS_SLAM), "an equal one may follow, as a row of strikes lands")
	ActiveDevice.reset()
	PadRumble.reset()


func test_the_heavy_moments_ask_for_rumble() -> void:
	var feedback := FileAccess.get_file_as_string("res://scripts/world/combat_feedback.gd")
	assert_true(feedback.contains("PadRumble.play(PadRumble.HIT_TAKEN)"), "hits taken")
	assert_true(feedback.contains("PadRumble.play(PadRumble.HEAVY_LANDED)"), "heavy hits landed")
	var strike := FileAccess.get_file_as_string("res://scripts/world/ground_strike.gd")
	assert_true(strike.contains("PadRumble.play(PadRumble.BOSS_SLAM)"), "boss slams")
	var settings := FileAccess.get_file_as_string("res://scripts/autoload/settings.gd")
	assert_true(settings.contains("PadRumble.enabled = settings.value(GameSettings.GAME, \"vibration\")"), "the option gates it")

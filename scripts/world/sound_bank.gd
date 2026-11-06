class_name SoundBank
extends RefCounted

# Every sound the game plays. Each is a rendered file in audio/sfx (made by tools/sfx), as <name>.wav
# or as variations <name>_1.wav to <name>_4.wav, one picked at random each play. A sound whose files
# are missing falls back to the older sound synthesized here from a simple sweep (SOUNDS), by FALLBACK.

enum { SINE, SQUARE, NOISE }

const RATE := 22050
const ATTACK_TIME := 0.004
const NOISE_SEED := 7
const SOUNDS := {
	"combo_hit": {"from": 220.0, "to": 110.0, "time": 0.08, "shape": SQUARE, "volume": 0.45},
	"charged_hit": {"from": 150.0, "to": 45.0, "time": 0.2, "shape": SQUARE, "volume": 0.6},
	"swing_miss": {"from": 0.0, "to": 0.0, "time": 0.1, "shape": NOISE, "volume": 0.2},
	# The dentures clack, so their sounds are short square chatters.
	"teeth_throw": {"from": 1100.0, "to": 1700.0, "time": 0.1, "shape": SQUARE, "volume": 0.28},
	"teeth_catch": {"from": 1500.0, "to": 1000.0, "time": 0.06, "shape": SQUARE, "volume": 0.3},
	"player_hurt": {"from": 300.0, "to": 100.0, "time": 0.25, "shape": SQUARE, "volume": 0.45},
	"enemy_death": {"from": 500.0, "to": 80.0, "time": 0.3, "shape": SQUARE, "volume": 0.4},
	"coin_pickup": {"from": 880.0, "to": 1320.0, "time": 0.08, "shape": SINE, "volume": 0.4},
	"door_open": {"from": 120.0, "to": 240.0, "time": 0.35, "shape": SINE, "volume": 0.5},
	"explosion": {"from": 0.0, "to": 0.0, "time": 0.4, "shape": NOISE, "volume": 0.65},
	"shield_block": {"from": 1400.0, "to": 900.0, "time": 0.09, "shape": SQUARE, "volume": 0.3},
	"consumable_pickup": {"from": 520.0, "to": 780.0, "time": 0.14, "shape": SQUARE, "volume": 0.3},
	# The items' own: a metal detector's chime, an alarm's beep and a bingo's ding.
	"chime": {"from": 1320.0, "to": 1320.0, "time": 0.18, "shape": SINE, "volume": 0.35},
	"alarm": {"from": 1000.0, "to": 700.0, "time": 0.3, "shape": SQUARE, "volume": 0.4},
	"bingo": {"from": 660.0, "to": 1320.0, "time": 0.22, "shape": SINE, "volume": 0.45},
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

const DIR := "res://audio/sfx/"
const MAX_VARIATIONS := 4
# Everything rendered by tools/sfx/sfx.py, which the game may ask for by name.
const NAMES: Array[String] = [
	"cane_swing", "charged_swing", "swing_miss", "combo_hit_a", "combo_hit_b", "combo_finisher",
	"charged_hit", "charge_hum", "charge_ready", "teeth_throw", "teeth_bite", "teeth_catch", "dodge",
	"player_hurt", "player_death", "lethal_save", "enemy_hit", "enemy_death", "boss_hit",
	"boss_death", "shield_block", "attack_warning", "summon", "ship_horn",
	"barrier_chime", "tape_snag", "tape_cut", "organ_chord", "steam_hiss",
	"fuse_hiss", "explosion", "small_blast", "coin", "pill_heal", "thermos_pickup", "slip_pickup",
	"item_fanfare", "potion_drink", "chest_open", "chest_rattle", "mimic_snarl", "wood_break",
	"rock_break", "grass_cut", "door_open", "door_close", "secret_reveal", "stairwell_appear",
	"landing_arrive", "card_shuffle", "card_deal", "card_flip", "chips_bet", "bj_win", "bj_lose",
	"bj_push", "slot_lever", "slot_spin", "slot_stop", "slot_win", "slot_jackpot", "blip_smooth",
	"blip_prim", "blip_gruff", "blip_plain", "blip_reedy", "blip_mystic", "blip_boom", "blip_nasal",
	"ui_move", "ui_confirm", "ui_back", "ui_ching", "ui_denied", "form_filed", "notice_pop",
	"ticket_ding", "letter_read", "pause_open", "pause_close", "slot_select", "form_buy",
	"form_milestone", "form_pick", "refile", "form_maxed", "form_denied", "plan_deposit",
	"plan_withdraw", "craft", "brew", "condolence", "poster_take", "bounty_paid", "department_open",
	"ticket_print", "trophy_hang",
]
# The nearest synthesized sound for a file that is missing. Sounds with the same name as one in
# SOUNDS fall back to it without an entry here.
const FALLBACK := {
	"combo_hit_a": "combo_hit", "combo_hit_b": "combo_hit", "combo_finisher": "charged_hit",
	"cane_swing": "swing_miss", "charged_swing": "swing_miss", "dodge": "swing_miss",
	"teeth_bite": "combo_hit", "enemy_hit": "combo_hit", "boss_hit": "charged_hit",
	"boss_death": "enemy_death", "player_death": "player_hurt", "small_blast": "explosion",
	"coin": "coin_pickup", "plan_deposit": "coin_pickup", "plan_withdraw": "coin_pickup",
	"pill_heal": "consumable_pickup", "thermos_pickup": "consumable_pickup",
	"slip_pickup": "consumable_pickup", "item_fanfare": "consumable_pickup",
	"potion_drink": "consumable_pickup", "chest_open": "door_open", "secret_reveal": "door_open",
	"stairwell_appear": "door_open", "wood_break": "enemy_death", "rock_break": "enemy_death",
	"ui_confirm": "coin_pickup", "ui_ching": "coin_pickup", "form_buy": "coin_pickup",
	"ui_denied": "shield_block", "form_denied": "shield_block",
}


# The files of one sound, as res:// paths: the plain file, or each variation found.
static func variation_paths(sound_name: String) -> Array[String]:
	var found: Array[String] = []
	var single := DIR + sound_name + ".wav"
	if ResourceLoader.exists(single):
		found.append(single)
	for i in range(1, MAX_VARIATIONS + 1):
		var path := "%s%s_%d.wav" % [DIR, sound_name, i]
		if ResourceLoader.exists(path):
			found.append(path)
	return found


# The synthesized sound standing in for a sound with no files, or "" when there is none.
static func fallback_of(sound_name: String) -> String:
	var old: String = FALLBACK.get(sound_name, sound_name)
	return old if SOUNDS.has(old) else ""


# Whether a sound can play at all: from its files, or else from its fallback.
static func can_play(sound_name: String) -> bool:
	return not variation_paths(sound_name).is_empty() or not fallback_of(sound_name).is_empty()


# Every stream one sound can play as. Empty for a name nothing answers.
static func load_streams(sound_name: String) -> Array[AudioStream]:
	var streams: Array[AudioStream] = []
	for path in variation_paths(sound_name):
		var stream := load(path) as AudioStream
		if stream != null:
			streams.append(stream)
	if streams.is_empty() and not fallback_of(sound_name).is_empty():
		streams.append(make_stream(fallback_of(sound_name)))
	return streams

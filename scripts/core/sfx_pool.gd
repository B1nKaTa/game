class_name SfxPool
extends Node

# Plays sound effects by name from SoundBank on a small pool of players on the Effects bus, so the
# Audio tab's Effects slider sets them all. The same sound never repeats closer than its gap, which
# keeps a burst of coins or a room of vents from stacking up, and each play wanders a little in
# pitch so repeats never sound machine-made. A quiet pool (the full loop and test runs) counts what
# would have played and plays nothing.

const POOL_SIZE := 12
const VOLUME_DB := -8.0
const MIN_REPEAT_GAP := 0.04
const BUS := "Effects"
# NPC blips share one gap whoever speaks, so a line never chatters faster than this many a second.
const BLIPS_PER_SECOND := 12.0
const BLIP_PREFIX := "blip_"
const BLIP_KEY := "blip"
# Sounds that come in bursts, or repeat with a hazard's rhythm, wait longer before playing again.
const GAPS := {
	BLIP_KEY: 1.0 / BLIPS_PER_SECOND,
	"coin": 0.06,
	"plan_deposit": 0.09,
	"sand_step": 0.22,
	"enemy_hit": 0.05,
	"boss_hit": 0.08,
	"wood_break": 0.05,
	"rock_break": 0.05,
	"grass_cut": 0.05,
	"steam_hiss": 0.3,
	"barrier_chime": 0.5,
	"escalator_hum": 0.6,
	"organ_chord": 0.4,
	"ship_horn": 1.0,
	"attack_warning": 0.25,
	"summon": 0.3,
	"small_blast": 0.08,
	"tape_snag": 0.3,
	"tape_cut": 0.1,
	"notice_pop": 0.15,
	"card_deal": 0.05,
	"slot_stop": 0.08,
}
# How far a play's pitch may wander either way. UI and music-like stings stay in tune.
const DEFAULT_JITTER := 0.04
const JITTER := {
	"ui_move": 0.0, "ui_confirm": 0.0, "ui_back": 0.0, "ui_denied": 0.0, "notice_pop": 0.0,
	"pause_open": 0.0, "pause_close": 0.0, "slot_select": 0.0, "ticket_ding": 0.0,
	"item_fanfare": 0.0, "bj_win": 0.0, "bj_lose": 0.0, "bj_push": 0.0, "slot_win": 0.0,
	"slot_jackpot": 0.0, "form_maxed": 0.0, "bounty_paid": 0.0, "department_open": 0.0,
	"craft": 0.0, "landing_arrive": 0.0, "organ_chord": 0.0, "barrier_chime": 0.0,
	"charge_hum": 0.0, "charge_ready": 0.0, "lethal_save": 0.0, "condolence": 0.0,
	"cane_swing": 0.08, "dodge": 0.06, "coin": 0.02, "sand_step": 0.1, "enemy_hit": 0.08,
}
# Loudness against the pool's level, in dB, for sounds that would crowd the others.
const VOLUMES := {
	"enemy_hit": -4.0,
	"sand_step": -3.0,
	"attack_warning": -2.0,
	"ui_move": -4.0,
	"fuse_hiss": -2.0,
}

var quiet := false
# How many sounds were asked for and passed their gap, quiet or not.
var plays := 0
var _players: Array[AudioStreamPlayer] = []
var _streams := {}
var _last_played := {}
var _last_variation := {}
var _later: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	if quiet:
		return
	GameSettings.ensure_buses()
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		player.volume_db = VOLUME_DB
		add_child(player)
		_players.append(player)


func players() -> Array[AudioStreamPlayer]:
	return _players


# The gap a sound waits on: every blip shares one, the rest each have their own.
static func gap_key(sound_name: String) -> String:
	return BLIP_KEY if sound_name.begins_with(BLIP_PREFIX) else sound_name


static func gap_of(sound_name: String) -> float:
	return float(GAPS.get(gap_key(sound_name), MIN_REPEAT_GAP))


# Whether a sound may play at this moment (microseconds), and marks it played if so.
func allows(sound_name: String, now_usec: int) -> bool:
	var key := gap_key(sound_name)
	var last := int(_last_played.get(key, -100000000))
	if now_usec - last < int(gap_of(sound_name) * 1000000.0):
		return false
	_last_played[key] = now_usec
	return true


func play(sound_name: String, pitch := 1.0) -> bool:
	if sound_name.is_empty() or not allows(sound_name, Time.get_ticks_usec()):
		return false
	plays += 1
	if quiet or _players.is_empty():
		return true
	var streams := _streams_for(sound_name)
	if streams.is_empty():
		return false
	var player := _free_player()
	var jitter: float = JITTER.get(sound_name, DEFAULT_JITTER)
	player.pitch_scale = maxf(pitch * (1.0 + _rng.randf_range(-jitter, jitter)), 0.05)
	player.volume_db = VOLUME_DB + float(VOLUMES.get(sound_name, 0.0))
	player.stream = streams[_pick(sound_name, streams.size())]
	player.play()
	return true


# A sound after a moment, in real time, so a sequence (deal, deal, flip) can be laid out at once.
func play_later(sound_name: String, delay: float, pitch := 1.0) -> void:
	if delay <= 0.0:
		play(sound_name, pitch)
		return
	_later.append({"at": Time.get_ticks_msec() + int(delay * 1000.0), "name": sound_name, "pitch": pitch})


# Forgets the sounds waiting to play, as leaving a table does.
func cancel_later() -> void:
	_later.clear()


func pending() -> int:
	return _later.size()


# One letter's blip in this NPC's voice.
func blip(voice_id: String) -> bool:
	var voice := NpcVoice.for_id(voice_id)
	return play(voice["sound"], voice["pitch"])


func _process(_delta: float) -> void:
	if _later.is_empty():
		return
	var now := Time.get_ticks_msec()
	var due: Array[Dictionary] = []
	for entry in _later:
		if int(entry["at"]) <= now:
			due.append(entry)
	for entry in due:
		_later.erase(entry)
		play(entry["name"], entry["pitch"])


func _streams_for(sound_name: String) -> Array:
	if not _streams.has(sound_name):
		_streams[sound_name] = SoundBank.load_streams(sound_name)
	return _streams[sound_name]


# A variation at random, never the one just played while there is another.
func _pick(sound_name: String, count: int) -> int:
	if count <= 1:
		return 0
	var last := int(_last_variation.get(sound_name, -1))
	var index := _rng.randi_range(0, count - 2)
	if index >= last and last >= 0:
		index += 1
	_last_variation[sound_name] = index
	return index


func _free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	# All busy: the one that has played longest gives way.
	var oldest := _players[0]
	for player in _players:
		if player.get_playback_position() > oldest.get_playback_position():
			oldest = player
	return oldest

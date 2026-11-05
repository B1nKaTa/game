extends Node

# Plays the music. Two players take turns, so a new song fades in while the old one fades out. It
# plays on the Music bus (or Master, if there is no Music bus) and keeps playing while the game is
# paused. MusicRules says which song; a song whose file is missing plays as silence, and the full loop
# (--smoke) and test runs (--script) play nothing at all. A sting (the game-over one) is let finish:
# a song asked for while it plays starts when it ends.

const FADE := 1.2
const BUS := "Music"
const SILENT_DB := -60.0

var _players: Array[AudioStreamPlayer] = []
var _tweens: Array[Tween] = [null, null]
var _active := 0
# The song asked for last, the one the active player holds, and one waiting for a sting to end.
var _current := ""
var _playing := ""
var _pending := ""
var _quiet := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_quiet = is_quiet()
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.volume_db = SILENT_DB
		player.finished.connect(_on_finished.bind(i))
		add_child(player)
		_players.append(player)


static func is_quiet() -> bool:
	return OS.get_cmdline_user_args().has("--smoke") or RunMode.is_script_run()


# The song asked for last, whether or not its file was there to play.
func current() -> String:
	return _current


func is_playing() -> bool:
	return not _players.is_empty() and _players[_active].playing


# Fades to a song. Asking for the song already asked for changes nothing, so scenes can ask freely.
func play(id: String, fade := FADE) -> void:
	if id == _current:
		return
	_current = id
	if _players.is_empty():
		return
	if MusicRules.loops(id) and _sting_playing():
		_pending = id
		return
	_pending = ""
	_start(id, fade)


# Fades the music out and forgets the song, so asking for it again starts it again.
func stop(fade := FADE) -> void:
	_current = ""
	_pending = ""
	_playing = ""
	if not _players.is_empty():
		_fade(_active, SILENT_DB, fade, true)


func _start(id: String, fade: float) -> void:
	_fade(_active, SILENT_DB, fade, true)
	_playing = ""
	var stream := _load(id)
	if stream == null:
		return
	_active = 1 - _active
	var player := _players[_active]
	player.stop()
	player.stream = stream
	player.bus = BUS if AudioServer.get_bus_index(BUS) != -1 else "Master"
	player.volume_db = SILENT_DB if fade > 0.0 else 0.0
	player.play()
	_playing = id
	_fade(_active, 0.0, fade, false)


func _sting_playing() -> bool:
	return not _playing.is_empty() and not MusicRules.loops(_playing) and _players[_active].playing


func _on_finished(index: int) -> void:
	if index != _active:
		return
	_playing = ""
	if not _pending.is_empty():
		var id := _pending
		_pending = ""
		_start(id, FADE)


func _load(id: String) -> AudioStream:
	if _quiet or id.is_empty():
		return null
	var path := MusicRules.path_for(id)
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	var wav := stream as AudioStreamWAV
	if wav != null:
		if MusicRules.loops(id):
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = roundi(wav.get_length() * wav.mix_rate)
		else:
			wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream


func _fade(index: int, to_db: float, time: float, stop_after: bool) -> void:
	var player := _players[index]
	if _tweens[index] != null:
		_tweens[index].kill()
		_tweens[index] = null
	if not player.playing:
		return
	if time <= 0.0:
		player.volume_db = to_db
		if stop_after:
			player.stop()
		return
	var tween := create_tween()
	tween.tween_method(func(linear: float): player.volume_db = linear_to_db(maxf(linear, 0.001)),
		db_to_linear(player.volume_db), db_to_linear(to_db), time)
	if stop_after:
		tween.tween_callback(player.stop)
	_tweens[index] = tween

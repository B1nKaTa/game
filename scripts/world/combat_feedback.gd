class_name CombatFeedback
extends Node

const POOL_SIZE := 8
const VOLUME_DB := -8.0
const MIN_REPEAT_GAP := 0.04
const MAX_REAL_DELTA := 0.1

var _hit_stop := HitStop.new()
var _shake := ScreenShake.new()
var _rng := RandomNumberGenerator.new()
var _camera: Camera2D
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _last_played := {}
var _last_ticks := 0


func setup(camera: Camera2D) -> void:
	_camera = camera


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_last_ticks = Time.get_ticks_usec()
	for sound_name in SoundBank.names():
		_streams[sound_name] = SoundBank.make_stream(sound_name)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.volume_db = VOLUME_DB
		add_child(player)
		_players.append(player)


func watch_player(player: Player) -> void:
	player.swing_landed.connect(on_swing_landed)
	player.swing_missed.connect(on_swing_missed)
	player.cane_thrown.connect(on_cane_thrown)
	player.cane_hit.connect(on_cane_hit)
	player.cane_caught.connect(on_cane_caught)
	player.hurt.connect(on_hurt)
	player.died.connect(on_player_died)


func watch_room(room: RoomView) -> void:
	room.enemy_died.connect(on_enemy_died)
	room.pension_earned.connect(on_pension_earned)
	room.doors_opened.connect(on_doors_opened)
	room.bomb_exploded.connect(on_bomb_exploded)
	room.consumable_taken.connect(on_consumable_taken)
	room.hit_blocked.connect(on_hit_blocked)


func on_swing_landed(heavy: bool, finisher: bool) -> void:
	_begin_hit_stop(HitStop.duration_for(heavy, finisher))
	if heavy:
		_shake.start(ScreenShake.CHARGED_HIT, ScreenShake.CHARGED_TIME)
	_play("charged_hit" if heavy else "combo_hit")


func on_swing_missed(_heavy: bool) -> void:
	_play("swing_miss")


func on_cane_thrown() -> void:
	_play("cane_throw")


func on_cane_hit() -> void:
	_begin_hit_stop(HitStop.CANE_HIT)
	_play("combo_hit")


func on_cane_caught() -> void:
	_play("cane_catch")


func on_hurt() -> void:
	_shake.start(ScreenShake.HURT, ScreenShake.HURT_TIME)
	_play("player_hurt")


func on_player_died() -> void:
	_hit_stop.cancel()
	_apply_time_scale()


func on_enemy_died(_at: Vector2, is_boss: bool) -> void:
	if is_boss:
		_shake.start(ScreenShake.BOSS_DEATH, ScreenShake.BOSS_DEATH_TIME)
	_play("enemy_death")


func on_pension_earned(_amount: int) -> void:
	_play("coin_pickup")


func on_doors_opened() -> void:
	_play("door_open")


func on_bomb_exploded() -> void:
	_shake.start(ScreenShake.CHARGED_HIT, ScreenShake.CHARGED_TIME)
	_play("explosion")


func on_hit_blocked() -> void:
	_play("shield_block")


func on_consumable_taken() -> void:
	_play("consumable_pickup")


func is_shaking() -> bool:
	return _shake.is_active()


func shake_magnitude() -> float:
	return _shake.current_magnitude()


func _begin_hit_stop(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_hit_stop.request(seconds)
	_last_ticks = Time.get_ticks_usec()
	_apply_time_scale()


func _apply_time_scale() -> void:
	Engine.time_scale = _hit_stop.time_scale()


# Hit stop and shake run on real time, since game time stands still during a freeze.
func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_delta := minf(float(now - _last_ticks) / 1000000.0, MAX_REAL_DELTA)
	_last_ticks = now
	tick_real(real_delta)


func tick_real(real_delta: float) -> void:
	_hit_stop.tick(real_delta)
	_shake.tick(real_delta)
	_apply_time_scale()
	if is_instance_valid(_camera):
		_camera.offset = _shake.offset(_rng)


func _exit_tree() -> void:
	_hit_stop.cancel()
	Engine.time_scale = 1.0
	if is_instance_valid(_camera):
		_camera.offset = Vector2.ZERO


func _play(sound_name: String) -> void:
	if _players.is_empty() or not _streams.has(sound_name):
		return
	var now := Time.get_ticks_usec()
	if now - int(_last_played.get(sound_name, -1000000)) < int(MIN_REPEAT_GAP * 1000000.0):
		return
	_last_played[sound_name] = now
	var player := _players[_next_player]
	for i in _players.size():
		var candidate := _players[(_next_player + i) % _players.size()]
		if not candidate.playing:
			player = candidate
			break
	_next_player = (_players.find(player) + 1) % _players.size()
	player.stream = _streams[sound_name]
	player.play()

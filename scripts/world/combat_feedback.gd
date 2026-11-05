class_name CombatFeedback
extends Node

const MAX_REAL_DELTA := 0.1
# Every sound here plays through the Sounds pool (Sfx) on the Effects bus, which the Audio tab's
# Effects slider sets.
const BUS := SfxPool.BUS

# The Game tab's Screen shake and Hit-stop. The floor scene sets them from Settings.
var shake_enabled := true
var hit_stop_enabled := true

var _hit_stop := HitStop.new()
var _shake := ScreenShake.new()
var _rng := RandomNumberGenerator.new()
var _camera: Camera2D
var _last_ticks := 0
# Light hits alternate between two knocks, so the combo's first two hits sound apart.
var _second_knock := false


func setup(camera: Camera2D) -> void:
	_camera = camera


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_last_ticks = Time.get_ticks_usec()


func watch_player(player: Player) -> void:
	player.swing_landed.connect(on_swing_landed)
	player.swing_missed.connect(on_swing_missed)
	player.teeth_thrown.connect(on_teeth_thrown)
	player.teeth_bit.connect(on_teeth_bit)
	player.teeth_caught.connect(on_teeth_caught)
	player.hurt.connect(on_hurt)
	player.died.connect(on_player_died)
	if player.run != null:
		player.run.health.rescued.connect(on_lethal_save)


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
		PadRumble.play(PadRumble.HEAVY_LANDED)
	_play(hit_sound(heavy, finisher))


# The knock a landed swing makes: the charge's big whack, the combo's last hit, or one of two knocks.
func hit_sound(heavy: bool, finisher: bool) -> String:
	if heavy or finisher:
		_second_knock = false
		return "charged_hit" if heavy else "combo_finisher"
	_second_knock = not _second_knock
	return "combo_hit_a" if _second_knock else "combo_hit_b"


func on_swing_missed(_heavy: bool) -> void:
	_play("swing_miss")


func on_teeth_thrown() -> void:
	_play("teeth_throw")


func on_teeth_bit() -> void:
	_begin_hit_stop(HitStop.BITE_HIT)
	_play("teeth_bite")


func on_teeth_caught() -> void:
	_play("teeth_catch")


func on_hurt() -> void:
	_shake.start(ScreenShake.HURT, ScreenShake.HURT_TIME)
	PadRumble.play(PadRumble.HIT_TAKEN)
	_play("player_hurt")


func on_player_died() -> void:
	_hit_stop.cancel()
	_apply_time_scale()
	_play("player_death")


# A hit that would have finished him left one pill instead.
func on_lethal_save() -> void:
	_play("lethal_save")


func on_enemy_died(_at: Vector2, is_boss: bool) -> void:
	if is_boss:
		_shake.start(ScreenShake.BOSS_DEATH, ScreenShake.BOSS_DEATH_TIME)
	_play("boss_death" if is_boss else "enemy_death")


func on_pension_earned(_amount: int) -> void:
	_play("coin")


func on_doors_opened() -> void:
	_play("door_open")


func on_bomb_exploded() -> void:
	_shake.start(ScreenShake.CHARGED_HIT, ScreenShake.CHARGED_TIME)
	_play("explosion")


func on_hit_blocked() -> void:
	_play("shield_block")


# Each pickup makes its own sound where it is taken (RoomView), so this only marks the moment.
func on_consumable_taken() -> void:
	pass


func is_shaking() -> bool:
	return shake_enabled and _shake.is_active()


func shake_magnitude() -> float:
	return _shake.current_magnitude() if shake_enabled else 0.0


func _begin_hit_stop(seconds: float) -> void:
	if seconds <= 0.0 or not hit_stop_enabled:
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
		_camera.offset = _shake.offset(_rng) if shake_enabled else Vector2.ZERO


func _exit_tree() -> void:
	_hit_stop.cancel()
	Engine.time_scale = 1.0
	if is_instance_valid(_camera):
		_camera.offset = Vector2.ZERO


func _play(sound_name: String) -> void:
	Sfx.play(sound_name)

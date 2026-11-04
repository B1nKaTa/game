class_name SunbatherBehavior
extends EnemyBehavior

# The Sunburnt Sunbather lies so still under his towel that he looks just like a deck chair, and the
# rolling deck does not move him. When Grandpa comes close, or hits him, he wakes with a warned snap
# of the chair, shown for its whole windup since he is right beside him, and then he chases and swats
# as any brawler does.
const WAKE_RANGE := 64.0
const SNAP_WINDUP := 0.6
const SNAP_RADIUS := 34.0
const START_RANGE := 30.0
const STRIKE_RANGE := 40.0
const STRIKE_WINDUP := 0.45
const COOLDOWN := 0.8
const WAKE_TEXT := "My tan!"
const SAY_TIME := 1.0

enum State { ASLEEP, SNAP, AWAKE }


# The chair he lies as, drawn over his body until he wakes.
class ChairLook extends Node2D:
	func _draw() -> void:
		DeckChair.draw_chair(self, Color("d9576b"))


var _telegraph := Telegraph.new()
var _state := State.ASLEEP
var _cooldown := 0.0
var _look: ChairLook


# He wakes once Grandpa is near enough to touch the chair, or the moment he is hit.
static func should_wake(distance: float, was_hit: bool) -> bool:
	return was_hit or distance <= WAKE_RANGE


static func snap_hits(at: Vector2, feet: Vector2) -> bool:
	return at.distance_to(feet) <= SNAP_RADIUS


func is_asleep() -> bool:
	return _state == State.ASLEEP


func tick(enemy: Enemy, delta: float) -> void:
	match _state:
		State.ASLEEP:
			_sleep(enemy)
		State.SNAP:
			enemy.hold_lane()
			if _telegraph.tick(delta):
				enemy.clear_warning()
				_wake_fully(enemy)
		State.AWAKE:
			_brawl(enemy, delta)


func _sleep(enemy: Enemy) -> void:
	# A chair stays put on a rolling deck, so he does too.
	enemy.hold_lane()
	if _look == null:
		_look = ChairLook.new()
		_look.z_index = 1
		enemy.add_child(_look)
	if should_wake(enemy.distance_to_target(), enemy.hp < enemy.max_hp()):
		_state = State.SNAP
		_telegraph.start(SNAP_WINDUP)
		enemy.set_warning(_telegraph, SNAP_RADIUS, true)
		enemy.say(WAKE_TEXT, SAY_TIME)


func _wake_fully(enemy: Enemy) -> void:
	if is_instance_valid(_look):
		_look.queue_free()
	_look = null
	if snap_hits(enemy.global_position, enemy.target_ground()):
		enemy.hit_target(enemy.def.damage)
	_state = State.AWAKE
	_cooldown = COOLDOWN


# Awake, he fights as a brawler: up close he winds up a swat, and otherwise he chases.
func _brawl(enemy: Enemy, delta: float) -> void:
	var distance := enemy.distance_to_target()
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = COOLDOWN
			if distance <= STRIKE_RANGE:
				enemy.hit_target(enemy.def.damage)
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if distance <= START_RANGE:
		if _cooldown <= 0.0:
			_telegraph.start(STRIKE_WINDUP)
			enemy.set_warning(_telegraph, STRIKE_RANGE)
		return
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed

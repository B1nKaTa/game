class_name CaddieBehavior
extends EnemyBehavior

# A caddie at the wheel of a golf cart. With Grandpa in range and in view he lines the cart up and shows
# the lane he will drive, then floors it down that lane, smashing props, and stops short at a wall or at
# the lane's end. He climbs out for a moment after each run, which is the time to hit him. Sand slows the
# cart as it slows anyone, so a run through a bunker ends early, never off its lane.
const START_RANGE := 220.0
const WINDUP := 0.8
const CHARGE_LENGTH := 250.0
const CHARGE_SPEED := 300.0
const LANE_WIDTH := 34.0
const HIT_RANGE := 18.0
const WARNING_RADIUS := 20.0
const SMASH_AHEAD := 20.0
const SMASH_RADIUS := 20.0
const REST := 0.8
const COOLDOWN := 2.4
const FIRST_CHARGE := 1.2
const WALL_GRACE := 0.05
const HONK := "Beep beep!"
const SAY_TIME := 0.9


# The cart drawn round him while he lines it up and while it runs.
class Cart extends Node2D:
	const BODY := Color("ece8da")
	const ROOF := Color("3f7a4a")
	const WHEEL := Color("1c1c22")
	const BAR := Color("9aa0a8")

	var way := Vector2.RIGHT

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, way.angle())
		for corner in [Vector2(-10, -11), Vector2(8, -11), Vector2(-10, 9), Vector2(8, 9)]:
			draw_rect(Rect2(corner, Vector2(6, 3)), WHEEL)
		draw_rect(Rect2(-14, -9, 30, 18), BODY)
		draw_rect(Rect2(-14, -9, 30, 18), Color.BLACK, false, 1.0)
		draw_rect(Rect2(-12, -10, 16, 20), Color(ROOF, 0.85))
		draw_line(Vector2(12, -8), Vector2(12, 8), BAR, 2.0)
		draw_set_transform(Vector2.ZERO)


var _telegraph := Telegraph.new()
var _cooldown := FIRST_CHARGE
var _charge_left := 0.0
var _charged_for := 0.0
var _rest_left := 0.0
var _way := Vector2.RIGHT
var _has_hit := false
var _cart: Cart


static func wants_to_charge(cooldown_left: float, distance: float, in_view: bool) -> bool:
	return cooldown_left <= 0.0 and distance <= START_RANGE and in_view


# How far the cart runs from a point: its whole lane, or just short of the first wall or hole.
static func lane_length(from: Vector2, way: Vector2, is_open: Callable) -> float:
	if not is_open.is_valid():
		return CHARGE_LENGTH
	return from.distance_to(MatronBehavior.charge_end(from, way, CHARGE_LENGTH, is_open))


func tick(enemy: Enemy, delta: float) -> void:
	if _charge_left > 0.0:
		_charge(enemy, delta)
		return
	if _rest_left > 0.0:
		_rest_left -= delta
		if _rest_left <= 0.0:
			_show_cart(enemy, false)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_charge_left = lane_length(enemy.global_position, _way, enemy.open_ground)
			_charged_for = 0.0
			_has_hit = false
			if _charge_left <= 0.0:
				_stop()
		return
	_cooldown -= delta
	if wants_to_charge(_cooldown, enemy.distance_to_target(), enemy.target_in_view()):
		_way = enemy.direction_to_target()
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.set_warning_lane(_way, lane_length(enemy.global_position, _way, enemy.open_ground), LANE_WIDTH)
		enemy.say(HONK, SAY_TIME)
		_show_cart(enemy, true)
		return
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _charge(enemy: Enemy, delta: float) -> void:
	if _charged_for > WALL_GRACE:
		for i in enemy.get_slide_collision_count():
			if BossDash.stops_at(enemy.get_slide_collision(i).get_collider()):
				_stop()
				return
	_charged_for += delta
	enemy.hold_lane()
	_charge_left -= CHARGE_SPEED * delta
	enemy.desired_velocity = _way * CHARGE_SPEED
	enemy.smash(enemy.global_position + _way * SMASH_AHEAD, SMASH_RADIUS)
	if not _has_hit and enemy.global_position.distance_to(enemy.target_ground()) <= HIT_RANGE:
		_has_hit = true
		enemy.hit_target(enemy.def.damage)
	if _charge_left <= 0.0:
		_stop()


# The cart rolls to a stop and he climbs out for a moment.
func _stop() -> void:
	_charge_left = 0.0
	_cooldown = COOLDOWN
	_rest_left = REST


func _show_cart(enemy: Enemy, shown: bool) -> void:
	if _cart == null:
		if not shown:
			return
		_cart = Cart.new()
		_cart.z_index = -1
		enemy.add_child(_cart)
	_cart.way = _way
	_cart.visible = shown
	_cart.queue_redraw()

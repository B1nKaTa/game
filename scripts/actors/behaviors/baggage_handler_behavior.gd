class_name BaggageHandlerBehavior
extends EnemyBehavior

# Pushes a laden luggage cart down a warned lane at Grandpa, smashing props on the way as it goes.
# Running head on into a wall spills the bags and dazes him for a moment. Between runs he trudges after
# Grandpa.
const START_RANGE := 200.0
const WINDUP := 1.0
const CHARGE_LENGTH := 260.0
const CHARGE_SPEED := 300.0
const LANE_WIDTH := 32.0
const HIT_RANGE := 18.0
const WARNING_RADIUS := 20.0
const SMASH_AHEAD := 20.0
const SMASH_RADIUS := 18.0
const COOLDOWN := 2.0
const FIRST_CHARGE := 1.2
const DAZE_TIME := 0.9
const WALL_GRACE := 0.05
# Only a wall struck this squarely counts as running into it.
const HEAD_ON := 0.5
const SPILL_TEXT := "Mind the bags!"


# The cart he pushes, drawn ahead of him on the way he last aimed.
class Cart extends Node2D:
	var way := Vector2.RIGHT
	var reach := 14.0

	func _draw() -> void:
		draw_set_transform(way * reach, way.angle())
		draw_rect(Rect2(-7.0, -10.0, 14.0, 20.0), Color("8a8f98"))
		draw_rect(Rect2(-7.0, -10.0, 14.0, 20.0), Color("2b2d33"), false, 1.0)
		var bags: Array[Color] = [Color("7a2f3a"), Color("3b7dd8"), Color("e8c04a")]
		for i in bags.size():
			draw_rect(Rect2(-5.0, -8.0 + i * 6.0, 10.0, 5.0), bags[i])
		draw_set_transform(Vector2.ZERO)


var _telegraph := Telegraph.new()
var _cooldown := FIRST_CHARGE
var _charge_left := 0.0
var _charged_for := 0.0
var _daze_left := 0.0
var _way := Vector2.RIGHT
var _has_hit := false
var _cart: Cart


# He sets off only once rested, near enough, and with the whole lane in view.
static func should_charge(distance: float, cooldown: float, in_view: bool) -> bool:
	return cooldown <= 0.0 and distance <= START_RANGE and in_view


# Whether a bump stops the run: something solid that will not break, struck head on.
static func runs_into(normal: Vector2, way: Vector2, unbreakable: bool) -> bool:
	return unbreakable and normal.dot(way) < -HEAD_ON


func is_dazed() -> bool:
	return _daze_left > 0.0


func tick(enemy: Enemy, delta: float) -> void:
	_show_cart(enemy)
	if _daze_left > 0.0:
		_daze_left -= delta
		return
	if _charge_left > 0.0:
		_charge(enemy, delta)
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_charge_left = CHARGE_LENGTH
			_charged_for = 0.0
			_has_hit = false
		return
	_cooldown -= delta
	if should_charge(enemy.distance_to_target(), _cooldown, enemy.target_in_view()):
		_way = enemy.direction_to_target()
		enemy.facing = _way
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.set_warning_lane(_way, CHARGE_LENGTH, LANE_WIDTH)
		return
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
	if not enemy.desired_velocity.is_zero_approx():
		_way = enemy.desired_velocity.normalized()


func _charge(enemy: Enemy, delta: float) -> void:
	if _charged_for > WALL_GRACE:
		for i in enemy.get_slide_collision_count():
			var collision := enemy.get_slide_collision(i)
			if runs_into(collision.get_normal(), _way, BossDash.stops_at(collision.get_collider())):
				_spill(enemy)
				return
	_charged_for += delta
	enemy.hold_lane()
	_charge_left -= CHARGE_SPEED * delta
	enemy.desired_velocity = _way * CHARGE_SPEED
	enemy.smash(enemy.global_position + _way * SMASH_AHEAD, SMASH_RADIUS)
	if not _has_hit and enemy.distance_to_target() <= HIT_RANGE:
		_has_hit = true
		enemy.hit_target(enemy.def.damage)
	if _charge_left <= 0.0:
		_charge_left = 0.0
		_cooldown = COOLDOWN


func _spill(enemy: Enemy) -> void:
	_charge_left = 0.0
	_cooldown = COOLDOWN
	_daze_left = DAZE_TIME
	enemy.daze(DAZE_TIME)
	enemy.say(SPILL_TEXT, DAZE_TIME)


func _show_cart(enemy: Enemy) -> void:
	if _cart == null:
		_cart = Cart.new()
		_cart.reach = enemy.def.body_size.x / 2.0 + 6.0
		_cart.z_index = -1
		enemy.add_child(_cart)
	if not _cart.way.is_equal_approx(_way):
		_cart.way = _way
		_cart.queue_redraw()

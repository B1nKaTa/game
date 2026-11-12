class_name PallbearerBehavior
extends EnemyBehavior

# Two Pallbearers carry a coffin between them and use it as a battering ram: after a warned lane each
# of them shows, both charge down it together, breaking props on the way and stopping at walls. When
# one falls the other drops the coffin, which lies there as a solid prop for a while, and fights on
# alone up close, by the rules of any plain melee reaper.
const META := &"pallbearer_pair"
# A leader looks this far for the bearer spawned beside it, and a bearer waits this long to be found.
const PAIR_REACH := 96.0
const PAIR_GRACE := 0.3
const CARRY_GAP := 30.0
const START_RANGE := 220.0
const WINDUP := 0.9
const LANE_WIDTH := 36.0
const RAM_LENGTH := 240.0
const RAM_SPEED := 300.0
const HIT_RANGE := 18.0
const SMASH_AHEAD := 18.0
const SMASH_RADIUS := 18.0
const WARNING_RADIUS := 20.0
const COOLDOWN := 3.4
const FIRST_RAM := 1.2
const WALL_GRACE := 0.05
const COFFIN_TIME := 6.0
const FOLLOW_SPEED := 1.5
# Alone, as the melee behavior fights.
const ALONE_START := 30.0
const ALONE_STRIKE := 40.0
const ALONE_WINDUP := 0.45
const ALONE_COOLDOWN := 0.7


# What the two share: the leader runs the pair's clock, and both read it.
class Pair extends RefCounted:
	var leader: Enemy
	var follower: Enemy
	var telegraph := Telegraph.new()
	var cooldown := 0.0
	var direction := Vector2.RIGHT
	var warned := 0
	var rams := 0
	var hit_in_ram := -1
	var broken := false

	func other(enemy: Enemy) -> Enemy:
		return follower if enemy == leader else leader

	func both_alive() -> bool:
		return not broken and _up(leader) and _up(follower)

	func _up(enemy: Enemy) -> bool:
		return is_instance_valid(enemy) and not enemy.is_dead()


# The coffin they carry, drawn from the leader to the follower under both of them.
class CoffinCarry extends Node2D:
	var pair: Pair

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if pair == null or not pair.both_alive():
			return
		var span: Vector2 = pair.follower.global_position - pair.leader.global_position
		var length := maxf(span.length() + 10.0, 28.0)
		draw_set_transform(span / 2.0 + Vector2(0, 4), span.angle())
		var box := Rect2(-length / 2.0, -6.0, length, 12.0)
		draw_rect(box, Color("4a2a1c"))
		draw_rect(box, Color.BLACK, false, 1.0)
		draw_line(Vector2(-length / 2.0 + 4.0, 0.0), Vector2(length / 2.0 - 4.0, 0.0), Color("6b3d26"), 2.0)
		draw_set_transform(Vector2.ZERO)


var _pair: Pair
var _wait := PAIR_GRACE
var _alone := false
var _carry: CoffinCarry
var _seen_warn := 0
var _seen_ram := 0
var _ram_left := 0.0
var _rammed_for := 0.0
var _ram_way := Vector2.RIGHT
var _telegraph := Telegraph.new()
var _cooldown := 0.0


# Whether a bearer fights on its own: only once its partner is gone.
static func alone(partner_alive: bool) -> bool:
	return not partner_alive


# Whether a point is struck by the ram: near either bearer, or near the coffin between them.
static func ram_hits(leader_at: Vector2, follower_at: Vector2, point: Vector2) -> bool:
	return Geometry2D.get_closest_point_to_segment(point, leader_at, follower_at).distance_to(point) <= HIT_RANGE


func tick(enemy: Enemy, delta: float) -> void:
	if _ram_left > 0.0:
		_ram(enemy, delta)
		return
	if not _alone and _pair == null:
		_find_pair(enemy, delta)
		if not _alone and _pair == null:
			return
	if not _alone and alone(_pair.both_alive()):
		_go_alone(enemy)
	if _alone:
		_fight_alone(enemy, delta)
		return
	_carry_on(enemy, delta)


func on_killed(enemy: Enemy) -> void:
	if _pair == null or _alone or _pair.broken:
		return
	var partner := _pair.other(enemy)
	_pair.broken = true
	# Finished with the Undertaker's Work Gloves, the coffin is set down gently instead of dropped.
	if enemy.harmless_death or not is_instance_valid(partner) or partner.is_dead() or enemy.get_parent() == null:
		return

	var feet := enemy.target_ground() if is_instance_valid(enemy.target) else Vector2.INF
	DroppedCoffin.drop(enemy.get_parent(), enemy.global_position.lerp(partner.global_position, 0.5), partner.global_position - enemy.global_position, feet, COFFIN_TIME)


func _find_pair(enemy: Enemy, delta: float) -> void:
	if enemy.has_meta(META):
		_pair = enemy.get_meta(META)
		return
	if enemy.is_group_follower:
		_wait -= delta
		if _wait <= 0.0:
			_alone = true
		return
	var best: Enemy = null
	var best_distance := PAIR_REACH
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemies"):
		if other == enemy or other.is_dead() or other.def != enemy.def or other.has_meta(META) or not other.is_group_follower:
			continue
		var distance := other.global_position.distance_to(enemy.global_position)
		if distance <= best_distance:
			best_distance = distance
			best = other
	if best == null:
		_alone = true
		return
	_pair = Pair.new()
	_pair.leader = enemy
	_pair.follower = best
	_pair.cooldown = FIRST_RAM
	enemy.set_meta(META, _pair)
	best.set_meta(META, _pair)
	_carry = CoffinCarry.new()
	_carry.pair = _pair
	_carry.z_index = -1
	enemy.add_child(_carry)


func _go_alone(enemy: Enemy) -> void:
	_alone = true
	_cooldown = ALONE_COOLDOWN
	enemy.clear_warning()
	if is_instance_valid(_carry):
		_carry.queue_free()
	_carry = null


func _carry_on(enemy: Enemy, delta: float) -> void:
	var leader := _pair.leader
	if enemy == leader:
		if _pair.telegraph.is_active():
			if _pair.telegraph.tick(delta):
				_pair.rams += 1
		else:
			_pair.cooldown -= delta
			if _pair.cooldown <= 0.0 and enemy.distance_to_target() <= START_RANGE and enemy.target_in_view() and enemy.can_strike_target():
				_pair.direction = enemy.direction_to_target()
				_pair.telegraph.start(WINDUP)
				_pair.warned += 1
				_pair.cooldown = COOLDOWN
	if _pair.rams != _seen_ram:
		_seen_ram = _pair.rams
		enemy.clear_warning()
		_ram_way = _pair.direction
		_ram_left = RAM_LENGTH
		_rammed_for = 0.0
		return
	if _pair.warned != _seen_warn:
		_seen_warn = _pair.warned
		enemy.set_warning(_pair.telegraph, WARNING_RADIUS)
		enemy.set_warning_lane(_pair.direction, RAM_LENGTH, LANE_WIDTH)
	if _pair.telegraph.is_active():
		return
	if enemy == leader:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed
		return
	# The follower keeps its end of the coffin, beside the leader across the way to Grandpa.
	var spot := leader.global_position + leader.direction_to_target().orthogonal() * CARRY_GAP
	if enemy.global_position.distance_to(spot) > 3.0:
		enemy.desired_velocity = enemy.walk_direction_to(spot) * enemy.def.speed * FOLLOW_SPEED


func _ram(enemy: Enemy, delta: float) -> void:
	if _rammed_for > WALL_GRACE:
		for i in enemy.get_slide_collision_count():
			if BossDash.stops_at(enemy.get_slide_collision(i).get_collider()):
				_ram_left = 0.0
				return
	_rammed_for += delta
	enemy.hold_lane()
	_ram_left -= RAM_SPEED * delta
	enemy.desired_velocity = _ram_way * RAM_SPEED
	enemy.smash(enemy.global_position + _ram_way * SMASH_AHEAD, SMASH_RADIUS)
	if _pair == null:
		return
	# One hit a ram for the pair, from either bearer or the coffin between them.
	if _pair.hit_in_ram == _pair.rams:
		return
	var other := _pair.other(enemy)
	var other_at := other.global_position if _pair.both_alive() else enemy.global_position
	if ram_hits(enemy.global_position, other_at, enemy.target_ground()) or enemy.distance_to_target() <= HIT_RANGE:
		_pair.hit_in_ram = _pair.rams
		enemy.hit_target(enemy.def.damage)


func _fight_alone(enemy: Enemy, delta: float) -> void:
	var distance := enemy.distance_to_target()
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_cooldown = ALONE_COOLDOWN
			if distance <= ALONE_STRIKE:
				enemy.hit_target(enemy.def.damage)
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if distance <= ALONE_START:
		if _cooldown <= 0.0:
			_telegraph.start(ALONE_WINDUP)
			enemy.set_warning(_telegraph, ALONE_STRIKE)
		return
	enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed

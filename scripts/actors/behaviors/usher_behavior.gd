class_name UsherBehavior
extends EnemyBehavior

# The Usher patrols the aisles with his torch, and its pale beam (UsherTorch) shows where he looks.
# Grandpa standing in the beam, with nothing solid between them, is taken notice of: SPOT_TIME in all
# spots him, and the notice ebbs again while he stays out of it. Spotted, the Usher hushes him
# ("Shh!"), turns the beam onto him and winds up with that line warned, then charges down it,
# stopping short at anything solid, as the Mall Cop's scooter did. Then he patrols on.
const TORCH_LENGTH := 150.0
const TORCH_HALF_ANGLE := 22.0
const SPOT_TIME := 0.6
const WINDUP := 0.7
const CHARGE_LENGTH := 240.0
const CHARGE_SPEED := 300.0
const LANE_WIDTH := 28.0
const HIT_RANGE := 16.0
const WARNING_RADIUS := 20.0
const COOLDOWN := 2.4
# He picks a new spot to walk to this often, somewhere this far round Grandpa, so his beam keeps
# passing near him, and walks there at this share of his speed.
const PATROL_EVERY := 2.2
const PATROL_REACH := 90.0
const PATROL_SPEED := 0.8
const PATROL_REACHED := 10.0
# The torch swings this far either side of the way he walks, this fast.
const SWING_DEG := 18.0
const SWING_SPEED := 1.7
const TURN_RATE := 5.0
const WALL_GRACE := 0.05
const SHH_TEXT := "Shh!"
const SAY_TIME := 0.9

var _telegraph := Telegraph.new()
var _cooldown := 1.0
var _charge_left := 0.0
var _charged_for := 0.0
var _way := Vector2.RIGHT
var _has_hit := false
var _seen := 0.0
var _look := Vector2.RIGHT
var _patrol := Vector2.INF
var _patrol_left := 0.0
var _clock := 0.0
var _torch: UsherTorch
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# Whether a point lies in a torch beam from origin looking along look: near enough and inside its
# angle. Walls are not this rule's business.
static func in_beam(origin: Vector2, look: Vector2, length: float, half_angle_deg: float, point: Vector2) -> bool:
	var offset := point - origin
	if offset.length() > length:
		return false
	if offset.length() < 1.0:
		return true
	return absf(look.angle_to(offset)) <= deg_to_rad(half_angle_deg)


# How long he has had Grandpa in view after one more frame: it builds while Grandpa is in the beam
# and ebbs as fast while he is out of it.
static func notice(seen: float, in_view: bool, delta: float) -> float:
	return seen + delta if in_view else maxf(seen - delta, 0.0)


static func is_spotted(seen: float) -> bool:
	return seen >= SPOT_TIME


func on_ready(enemy: Enemy) -> void:
	_torch = UsherTorch.new()
	_torch.length = TORCH_LENGTH
	_torch.half_angle_deg = TORCH_HALF_ANGLE
	enemy.add_child(_torch)


func tick(enemy: Enemy, delta: float) -> void:
	_clock += delta
	if _charge_left > 0.0:
		_charge(enemy, delta)
		_show_torch(0.0)
		return
	if _telegraph.is_active():
		_look = _way
		_show_torch(1.0)
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_charge_left = CHARGE_LENGTH
			_charged_for = 0.0
			_has_hit = false
		return
	_cooldown -= delta
	_patrol_on(enemy, delta)
	var feet := enemy.target_ground()
	var sees := in_beam(enemy.global_position, _look, TORCH_LENGTH, TORCH_HALF_ANGLE, feet) and _clear_to(enemy, feet)
	_seen = minf(notice(_seen, sees, delta), SPOT_TIME)
	_show_torch(clampf(_seen / SPOT_TIME, 0.0, 1.0))
	if is_spotted(_seen) and _cooldown <= 0.0:
		_seen = 0.0
		_way = enemy.direction_to_target()
		_look = _way
		_telegraph.start(WINDUP)
		enemy.set_warning(_telegraph, WARNING_RADIUS)
		enemy.set_warning_lane(_way, CHARGE_LENGTH, LANE_WIDTH, false)
		enemy.say(SHH_TEXT, SAY_TIME)


# Walks to his next patrol spot, the torch leading the way and swinging a little either side.
func _patrol_on(enemy: Enemy, delta: float) -> void:
	_patrol_left -= delta
	if _patrol == Vector2.INF or _patrol_left <= 0.0 or enemy.global_position.distance_to(_patrol) <= PATROL_REACHED:
		_patrol_left = PATROL_EVERY
		var room := ForemanBehavior.room_rect(enemy.room_cells).grow(-RoomBackdrop.TILE * 0.5)
		_patrol = (enemy.target_ground() + Vector2.from_angle(_rng.randf() * TAU) * PATROL_REACH).clamp(room.position, room.end)
	var walk := enemy.walk_direction_to(_patrol)
	enemy.desired_velocity = walk * enemy.def.speed * PATROL_SPEED
	if not walk.is_zero_approx():
		var swing := deg_to_rad(SWING_DEG) * sin(_clock * SWING_SPEED)
		var wanted := walk.rotated(swing)
		_look = Vector2.from_angle(lerp_angle(_look.angle(), wanted.angle(), minf(TURN_RATE * delta, 1.0)))


func _clear_to(enemy: Enemy, point: Vector2) -> bool:
	if not enemy.is_inside_tree():
		return true
	var query := PhysicsRayQueryParameters2D.create(enemy.global_position, point, 1)
	return enemy.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _show_torch(noticed: float) -> void:
	if _torch == null:
		return
	_torch.look = _look
	_torch.noticed = noticed
	_torch.visible = _charge_left <= 0.0


func _charge(enemy: Enemy, delta: float) -> void:
	if _charged_for > WALL_GRACE and enemy.get_slide_collision_count() > 0:
		_stop()
		return
	_charged_for += delta
	enemy.hold_lane()
	_charge_left -= CHARGE_SPEED * delta
	enemy.desired_velocity = _way * CHARGE_SPEED
	if not _has_hit and enemy.global_position.distance_to(enemy.target_ground()) <= HIT_RANGE:
		_has_hit = true
		enemy.hit_target(enemy.def.damage)
	if _charge_left <= 0.0:
		_stop()


func _stop() -> void:
	_charge_left = 0.0
	_cooldown = COOLDOWN
	_patrol = Vector2.INF

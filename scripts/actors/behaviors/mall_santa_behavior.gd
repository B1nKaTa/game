class_name MallSantaBehavior
extends EnemyBehavior

# The Mall Santa. His sleigh run charges down a warned lane, the one attack that costs three pills, so
# its warning always shows whole, with a second outline round the lane. He drops presents on warned
# spots that burst into rings of shots, closes a warned ring in round where Grandpa stood ("Ho ho hold
# still"), and takes over the room's escalator strips, reversing them or speeding them up after their
# own chime. Below half health he calls fast elves, never more than three at once, and every sleigh run
# chains straight into a present drop.
const SLEIGH_WINDUP := 1.2
const SLEIGH_DAMAGE := Enemy.HEAVIEST_DAMAGE
# The sleigh's warning shows for all of its windup, whatever the player's warning stat.
const SLEIGH_SHOWN_WHOLE := true
const SLEIGH_LENGTH := 380.0
const SLEIGH_SPEED := 430.0
const SLEIGH_HIT_RANGE := 28.0
const SLEIGH_LANE_WIDTH := 52.0
const PRESENT_WINDUP := 0.6
const PRESENTS := 4
# How far from his feet a present may land.
const PRESENT_REACH := 90.0
const PRESENT_TRIES := 40
const RING_WINDUP := 0.6
const RING_DAMAGE := Enemy.HEAVY_DAMAGE
const CONVEYOR_WINDUP := 0.5
const CONVEYOR_EVERY := 8.0
const FIRST_CONVEYOR := 4.0
const WARNING_RADIUS := 40.0
# As short as Mortimer's 0.65 and 0.45, shorter than Old Smokey's and Matron Mercy's.
const BASE_COOLDOWN := 0.65
const PHASE_TWO_COOLDOWN := 0.45
const PHASE_TWO_SPEED := 1.2
const PHASE_TWO_WINDUP_SCALE := 0.8
const KEEP_NEAR := 90.0
const MAX_ELVES := 3
const FIRST_ELVES := 1.5
const ELF_EVERY := 7.0
const ELF_DISTANCE := 90.0
const SAY_TIME := 1.0

enum Attack { NONE, SLEIGH, PRESENTS, RING, CONVEYOR }


# The sleigh drawn round him while it runs.
class Sleigh extends Node2D:
	var body := Vector2(44, 50)
	var way := Vector2.RIGHT

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, way.angle())
		var length := body.x + 20.0
		var width := body.y * 0.7
		draw_rect(Rect2(-length / 2.0, -width / 2.0, length, width), Color("b3202a"))
		draw_rect(Rect2(-length / 2.0, -width / 2.0, length, width), Color("e8c04a"), false, 2.0)
		draw_line(Vector2(-length / 2.0, width / 2.0 + 3.0), Vector2(length / 2.0 + 6.0, width / 2.0 + 3.0), Color("c9cdd6"), 2.0)
		draw_line(Vector2(-length / 2.0, -width / 2.0 - 3.0), Vector2(length / 2.0 + 6.0, -width / 2.0 - 3.0), Color("c9cdd6"), 2.0)
		draw_set_transform(Vector2.ZERO)


var _telegraph := Telegraph.new()
var _dash := BossDash.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _next := Attack.NONE
var _cooldown := 1.2
var _since_conveyor := CONVEYOR_EVERY - FIRST_CONVEYOR
var _elf_timer := FIRST_ELVES
var _aim := Vector2.RIGHT
var _sleigh: Sleigh
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


static func is_phase_two(hp: float, max_hp: float) -> bool:
	return hp <= max_hp * 0.5


static func cooldown_for(phase_two: bool) -> float:
	return PHASE_TWO_COOLDOWN if phase_two else BASE_COOLDOWN


static func calls_elves(phase_two: bool) -> bool:
	return phase_two


# As many elves as fit under the cap of three, never a negative number.
static func elves_to_call(alive: int) -> int:
	return clampi(MAX_ELVES - alive, 0, MAX_ELVES)


# The second phase quickens his windups, but never the sleigh's extra-clear warning.
static func windup_for(attack: int, phase_two: bool) -> float:
	var windup := PRESENT_WINDUP
	match attack:
		Attack.SLEIGH:
			return SLEIGH_WINDUP
		Attack.RING:
			windup = RING_WINDUP
		Attack.CONVEYOR:
			windup = CONVEYOR_WINDUP
	return windup * (PHASE_TWO_WINDUP_SCALE if phase_two else 1.0)


# In the second phase every sleigh run chains straight into a present drop.
static func followup(attack: int, phase_two: bool) -> int:
	if phase_two and attack == Attack.SLEIGH:
		return Attack.PRESENTS
	return Attack.NONE


# With no strips in the room there is no conveyor control: the present drop stands in for it.
static func choose_attack(last: int, has_strips: bool, roll: float) -> int:
	var options: Array[int] = [Attack.SLEIGH, Attack.PRESENTS, Attack.RING]
	if has_strips:
		options.append(Attack.CONVEYOR)
	if options.size() > 1:
		options.erase(last)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# Where the presents land: one right on him, the rest near him, apart from each other and in the room.
static func present_spots(feet: Vector2, rng: RandomNumberGenerator, room := Rect2()) -> Array[Vector2]:
	var inside := func(point: Vector2) -> Vector2: return point.clamp(room.position, room.end) if room.has_area() else point
	var spots: Array[Vector2] = [inside.call(feet)]
	var tries := 0
	while spots.size() < PRESENTS and tries < PRESENT_TRIES:
		tries += 1
		var spot: Vector2 = inside.call(feet + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(PresentDrop.RADIUS * 2.0, PRESENT_REACH))
		if _apart(spot, spots) and spot.distance_to(feet) <= PRESENT_REACH:
			spots.append(spot)
	# A cramped corner: walk round him at set distances until every present has a spot.
	for reach: float in [PRESENT_REACH, PRESENT_REACH * 0.75, PRESENT_REACH * 0.5]:
		for step in 24:
			if spots.size() >= PRESENTS:
				return spots
			var spot: Vector2 = inside.call(feet + Vector2.from_angle(TAU * step / 24.0) * reach)
			if _apart(spot, spots) and spot.distance_to(feet) <= PRESENT_REACH:
				spots.append(spot)
	return spots


static func _apart(spot: Vector2, others: Array[Vector2]) -> bool:
	for other in others:
		if spot.distance_to(other) < PresentDrop.RADIUS * 2.0:
			return false
	return true


func tick(enemy: Enemy, delta: float) -> void:
	var phase_two := is_phase_two(enemy.hp, enemy.max_hp())
	_since_conveyor += delta
	if calls_elves(phase_two):
		_call_elves(enemy, delta)
	if _dash.is_active():
		_dash.tick(enemy, delta)
		if not _dash.is_active():
			_cooldown = cooldown_for(phase_two)
			_climb_out()
		return
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy, phase_two)
		return
	_cooldown -= delta
	var speed := enemy.def.speed * (PHASE_TWO_SPEED if phase_two else 1.0)
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * speed * BossMoves.CATCH_UP_SPEED
		return
	if _cooldown <= 0.0 or (_next != Attack.NONE and _cooldown <= cooldown_for(phase_two) * 0.5):
		var attack := _next
		if attack == Attack.NONE:
			attack = choose_attack(_last, _has_strips(enemy) and _since_conveyor >= CONVEYOR_EVERY, _rng.randf())
		_next = Attack.NONE
		_begin(enemy, attack, phase_two)
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * speed


func _call_elves(enemy: Enemy, delta: float) -> void:
	_elf_timer -= delta
	if _elf_timer > 0.0 or not enemy.target_in_view():
		return
	_elf_timer = ELF_EVERY
	var alive := _elves(enemy)
	var count := elves_to_call(alive)
	if BossMoves.can_summon(alive, MAX_ELVES) and count > 0:
		enemy.say("Elves! To the floor!", SAY_TIME)
		enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, count, ELF_DISTANCE, 0.8), BossMoves.SUMMON_WARNING)


# Only his own elves count toward the cap of three.
func _elves(enemy: Enemy) -> int:
	var count := 0
	if not enemy.is_inside_tree():
		return count
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemies"):
		if other != enemy and other.is_summon and not other.is_dead() and other.def == enemy.def.summon:
			count += 1
	return count


func _strips(enemy: Enemy) -> Array:
	return ConveyorStrip.strips_in(enemy.get_tree()) if enemy.is_inside_tree() else []


func _has_strips(enemy: Enemy) -> bool:
	return not _strips(enemy).is_empty()


func _sleigh_end(enemy: Enemy) -> Vector2:
	if enemy.open_ground.is_valid():
		return MatronBehavior.charge_end(enemy.global_position, _aim, SLEIGH_LENGTH, enemy.open_ground)
	return enemy.global_position + _aim * SLEIGH_LENGTH


func _begin(enemy: Enemy, attack: int, phase_two: bool) -> void:
	if attack == Attack.CONVEYOR and not _has_strips(enemy):
		attack = Attack.PRESENTS
	_attack = attack
	_telegraph.start(windup_for(attack, phase_two))
	match attack:
		Attack.SLEIGH:
			# The windup on him and the lane both show whole, the lane with a second outline.
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, SLEIGH_HIT_RANGE, SLEIGH_SHOWN_WHOLE)
			enemy.set_warning_lane(_aim, enemy.global_position.distance_to(_sleigh_end(enemy)), SLEIGH_LANE_WIDTH)
			enemy.mark_lane_heaviest()
			enemy.say("On, my reindeer!", SAY_TIME)
		Attack.PRESENTS:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Presents for everyone!", SAY_TIME)
			_drop_presents(enemy)
		Attack.RING:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Ho ho hold still!", SAY_TIME)
			var ring := ClosingRing.new()
			ring.setup(enemy, windup_for(attack, phase_two), RING_DAMAGE)
			enemy.get_parent().add_child(ring)
			ring.global_position = enemy.target_ground()
		Attack.CONVEYOR:
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("All aboard!", SAY_TIME)


func _finish_attack(enemy: Enemy, phase_two: bool) -> void:
	var busy := 0.0
	match _attack:
		Attack.SLEIGH:
			_climb_in(enemy)
			_dash.start(_aim, enemy.global_position.distance_to(_sleigh_end(enemy)), SLEIGH_SPEED, SLEIGH_HIT_RANGE, SLEIGH_DAMAGE)
		Attack.PRESENTS:
			busy = maxf(PresentDrop.WARNING - windup_for(Attack.PRESENTS, phase_two), 0.0)
		Attack.RING:
			busy = ClosingRing.CLOSE_TIME * 0.5
		Attack.CONVEYOR:
			_since_conveyor = 0.0
			var kind := ConveyorStrip.REVERSE if _rng.randf() < 0.5 else ConveyorStrip.SPEED_UP
			for strip in _strips(enemy):
				strip.take_control(kind)
	_cooldown = cooldown_for(phase_two) + busy
	_last = _attack
	_next = followup(_attack, phase_two)


func _drop_presents(enemy: Enemy) -> void:
	var start := _rng.randf() * TAU
	for spot in present_spots(enemy.target_ground(), _rng, ForemanBehavior.room_rect(enemy.room_cells)):
		if enemy.open_ground.is_valid() and not enemy.open_ground.call(spot):
			continue
		var present := PresentDrop.new()
		present.setup(enemy, PresentDrop.WARNING, start)
		enemy.get_parent().add_child(present)
		present.global_position = spot


func _climb_in(enemy: Enemy) -> void:
	if _sleigh == null:
		_sleigh = Sleigh.new()
		_sleigh.body = enemy.def.body_size
		_sleigh.z_index = -1
		enemy.add_child(_sleigh)
	_sleigh.way = _aim
	_sleigh.visible = true
	_sleigh.queue_redraw()


func _climb_out() -> void:
	if _sleigh != null:
		_sleigh.visible = false

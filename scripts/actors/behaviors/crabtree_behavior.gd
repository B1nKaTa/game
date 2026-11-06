class_name CrabtreeBehavior
extends EnemyBehavior

# Cornelius Crabtree, Film Critic, the Cinema's mini boss in Gloria's old slot. His star rating
# announces a rating of one to five and throws that many gold stars in a fan down warned lanes: a low
# rating is a narrow fan of fast stars, a high one wide but slow. His thumbs down winds up and stamps,
# sending a ring out over the floor. On his own clock he writes a bad review: two or three Extras step
# out on marked spots as hecklers, never past five enemies in the room, and they pay nothing.
const STAR_WINDUP := 0.6
const STAR_LANE := 240.0
const STAR_LANE_WIDTH := 14.0
const MIN_RATING := 1
const MAX_RATING := 5
# The angle between neighbouring stars, and the speed of a one-star rating and how much each further
# star takes off it.
const STAR_STEP_DEG := 18.0
const FASTEST_STAR := 260.0
const STAR_SLOWING := 30.0
const THUMB_WINDUP := 0.8
const RING_FROM := 24.0
const RING_TO := 130.0
const RING_TIME := 0.7
const RING_WIDTH := 14.0
const WARNING_RADIUS := 34.0
# The Mall's mini boss's rest, shorter than Barbara's and Klaus's.
const COOLDOWN := 0.6
const KEEP_NEAR := 120.0
const FIRST_REVIEW := 4.0
const REVIEW_EVERY := 10.0
const MAX_ENEMIES := 5
const FEWEST_HECKLERS := 2
const MOST_HECKLERS := 3
const SUMMON_DISTANCE := 100.0
const SUMMON_SPREAD := 0.5
const SAY_TIME := 1.0
const RATING_TEXT: Array[String] = ["", "One star.", "Two stars.", "Three stars.", "Four stars!", "Five stars!"]

enum Attack { NONE, STARS, THUMBS }

var _telegraph := Telegraph.new()
var _attack := Attack.NONE
var _last := Attack.NONE
var _cooldown := 1.0
var _review_timer := FIRST_REVIEW
var _aim := Vector2.RIGHT
var _rating := 0
# A look probe's pick for his next rating; 0 lets him choose.
var forced_rating := 0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# He alternates, so a thumbs down always follows a rating and a rating a thumbs down.
static func choose_attack(last: int, roll: float) -> int:
	if last == Attack.STARS:
		return Attack.THUMBS
	if last == Attack.THUMBS:
		return Attack.STARS
	return Attack.STARS if roll < 0.5 else Attack.THUMBS


# A rating from one to five, never the one he gave last.
static func next_rating(last: int, roll: float) -> int:
	var options: Array[int] = []
	for rating in range(MIN_RATING, MAX_RATING + 1):
		if rating != last:
			options.append(rating)
	return options[mini(int(roll * options.size()), options.size() - 1)]


# How wide a rating's fan is, edge to edge, in degrees: none for one star, the widest for five.
static func star_spread(rating: int) -> float:
	return (clampi(rating, MIN_RATING, MAX_RATING) - 1) * STAR_STEP_DEG


static func star_speed(rating: int) -> float:
	return FASTEST_STAR - (clampi(rating, MIN_RATING, MAX_RATING) - 1) * STAR_SLOWING


static func star_lanes(aim: Vector2, rating: int) -> Array[Vector2]:
	return BossMoves.fan_directions(aim, clampi(rating, MIN_RATING, MAX_RATING), deg_to_rad(star_spread(rating)))


# How many hecklers come: two or three as rolled, but never past the cap, never a negative number.
static func hecklers(alive: int, cap: int, roll: float) -> int:
	var wanted := FEWEST_HECKLERS if roll < 0.5 else MOST_HECKLERS
	return clampi(cap - alive, 0, wanted)


func tick(enemy: Enemy, delta: float) -> void:
	_review_timer -= delta
	if _telegraph.is_active():
		if _telegraph.tick(delta):
			enemy.clear_warning()
			_finish_attack(enemy)
		return
	_cooldown -= delta
	if not enemy.target_in_view():
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed * BossMoves.CATCH_UP_SPEED
		return
	if _review_timer <= 0.0:
		_review_timer = REVIEW_EVERY
		_bad_review(enemy)
	if _cooldown <= 0.0:
		_begin(enemy, choose_attack(_last, _rng.randf()))
		return
	if enemy.distance_to_target() > KEEP_NEAR:
		enemy.desired_velocity = enemy.chase_direction() * enemy.def.speed


func _bad_review(enemy: Enemy) -> void:
	var alive := enemy.enemies_alive()
	var count := hecklers(alive, MAX_ENEMIES, _rng.randf())
	if not BossMoves.can_summon(alive, MAX_ENEMIES) or count <= 0:
		return
	enemy.say("A dreadful show!", SAY_TIME)
	enemy.play_anim("review", SAY_TIME)
	enemy.request_summon_at(BossMoves.cutoff_points(enemy.target_ground(), enemy.target_motion(), enemy.global_position, count, SUMMON_DISTANCE, SUMMON_SPREAD), BossMoves.SUMMON_WARNING)


func _begin(enemy: Enemy, attack: int) -> void:
	_attack = attack
	match attack:
		Attack.STARS:
			_telegraph.start(STAR_WINDUP)
			_rating = forced_rating if forced_rating > 0 else next_rating(_rating, _rng.randf())
			_aim = enemy.direction_to_target()
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			for way in star_lanes(_aim, _rating):
				enemy.add_warning_lane(way, STAR_LANE, STAR_LANE_WIDTH, false)
			enemy.say(RATING_TEXT[_rating], SAY_TIME)
		Attack.THUMBS:
			_telegraph.start(THUMB_WINDUP)
			enemy.set_warning(_telegraph, WARNING_RADIUS)
			enemy.say("Thumbs down.", SAY_TIME)
			var ring := Shockwave.new()
			ring.setup(enemy, RING_FROM, RING_TO, RING_TIME, RING_WIDTH, THUMB_WINDUP)
			enemy.get_parent().add_child(ring)
			ring.global_position = enemy.global_position


func _finish_attack(enemy: Enemy) -> void:
	_last = _attack
	_cooldown = COOLDOWN
	match _attack:
		Attack.STARS:
			for way in star_lanes(_aim, _rating):
				enemy.shoot(way, star_speed(_rating)).look = Projectile.LOOK_STAR
		Attack.THUMBS:
			enemy.smash(enemy.global_position, RING_FROM)
			# He waits while the ring runs out.
			_cooldown += RING_TIME * 0.5


# The rating he gave last, for a look probe.
func rating() -> int:
	return _rating

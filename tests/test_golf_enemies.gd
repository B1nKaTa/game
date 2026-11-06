extends TestCase

# What is left of Fairway's End's enemies: the Caddie, still the Club President's summon until his
# phase retires him. The hotline's regulars are in test_seance_enemies.gd.

const FRAME := 1.0 / 60.0


func _load(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


# An enemy out of the tree, with a plain point for Grandpa, so a behavior can be stepped by hand.
func _enemy(id: String, at: Vector2, grandpa: Node2D) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(_load(id), grandpa, 0.5)
	enemy.position = at
	return enemy


func _grandpa(at: Vector2) -> Node2D:
	var grandpa := Node2D.new()
	grandpa.position = at
	return grandpa


# One physics frame of a behavior, clearing what Enemy._physics_process clears before each tick.
func _step(behavior: EnemyBehavior, enemy: Enemy) -> void:
	enemy.desired_velocity = Vector2.ZERO
	enemy._holding_lane = false
	behavior.tick(enemy, FRAME)


# --- the Caddie ---

func test_the_caddie_drives_down_a_warned_lane() -> void:
	assert_near(CaddieBehavior.WINDUP, 0.8)
	var walk := PlayerStats.BASE_SPEED * (CaddieBehavior.WINDUP - 0.3)
	assert_true(walk > CaddieBehavior.LANE_WIDTH, "time to step out of the lane")
	assert_true(CaddieBehavior.CHARGE_SPEED > _load("caddie").speed * 3.0, "the cart is much faster than his walk")


func test_he_charges_only_when_ready_near_and_in_view() -> void:
	assert_true(CaddieBehavior.wants_to_charge(0.0, 100.0, true))
	assert_false(CaddieBehavior.wants_to_charge(0.5, 100.0, true), "still resting")
	assert_false(CaddieBehavior.wants_to_charge(0.0, CaddieBehavior.START_RANGE + 1.0, true), "too far")
	assert_false(CaddieBehavior.wants_to_charge(0.0, 100.0, false), "off screen")


func test_his_lane_stops_short_of_a_wall() -> void:
	assert_near(CaddieBehavior.lane_length(Vector2(100, 100), Vector2.RIGHT, Callable()), CaddieBehavior.CHARGE_LENGTH)
	var is_open := func(spot: Vector2) -> bool: return spot.x < 260.0
	var length := CaddieBehavior.lane_length(Vector2(100, 100), Vector2.RIGHT, is_open)
	assert_true(length < 160.0, "short of the wall at 260, got %f" % length)
	assert_true(length > 100.0, "but most of the way there, got %f" % length)


func test_a_caddie_warns_then_runs_holding_his_lane() -> void:
	var grandpa := _grandpa(Vector2(260, 160))
	var caddie := _enemy("caddie", Vector2(160, 160), grandpa)
	var behavior := CaddieBehavior.new()
	var time := 0.0
	while time < CaddieBehavior.FIRST_CHARGE + 0.05:
		_step(behavior, caddie)
		time += FRAME
	assert_true(caddie.warning_lane_length() > 0.0, "he shows his lane first")
	assert_true(caddie.warning_lane_direction().is_equal_approx(Vector2.RIGHT), "aimed at Grandpa")
	assert_true(caddie.desired_velocity.is_zero_approx(), "and waits while he lines up")
	time = 0.0
	while time < CaddieBehavior.WINDUP + 0.05:
		_step(behavior, caddie)
		time += FRAME
	assert_near(caddie.warning_lane_length(), 0.0, "the warning goes as he sets off")
	_step(behavior, caddie)
	assert_true(caddie.desired_velocity.normalized().is_equal_approx(Vector2.RIGHT), "down the lane he showed")
	assert_near(caddie.desired_velocity.length(), CaddieBehavior.CHARGE_SPEED)
	assert_false(caddie.slides_with_roll(), "a running cart holds its lane")
	caddie.free()
	grandpa.free()


# The cart is drawn behind his body, so it must be longer than him to show at all, and it stays inside
# the lane it warns, for him and for the Club President alike.
func test_a_cart_shows_past_its_driver_and_fits_its_lane() -> void:
	var caddie := CaddieBehavior.Cart.reach(CaddieBehavior.CART_STRETCH)
	var body := _load("caddie").body_size
	assert_true(caddie.x >= maxf(body.x, body.y) + 16.0, "the caddie's cart shows past him, got %s" % str(caddie))
	assert_true(caddie.y <= CaddieBehavior.LANE_WIDTH, "and fits his lane, got %s" % str(caddie))
	var president := CaddieBehavior.Cart.reach(ClubPresidentBehavior.CART_STRETCH)
	var boss := _load("thaddeus_fairweather").body_size
	assert_true(president.x >= maxf(boss.x, boss.y) + 16.0, "the President's cart shows past him, got %s" % str(president))
	assert_true(president.y <= ClubPresidentBehavior.CART_LANE_WIDTH, "and fits his lane, got %s" % str(president))


# --- the numbers ---

func test_new_enemies_match_the_first_floor_role_they_fill() -> void:
	var pairs := {"caddie": "debt_ghost"}
	for id: String in pairs:
		var def := _load(id)
		var theirs := _load(pairs[id])
		assert_false(def.is_boss, id)
		assert_false(def.display_name.is_empty(), id)
		assert_false(def.mark.is_empty(), id)
		assert_true(GolfMarks.draws(def.mark), "%s has a mark of its own" % id)
		assert_eq(def.pension_drop, theirs.pension_drop, id)
		assert_true(absf(def.max_hp - theirs.max_hp) <= 4.0, id)
		assert_true(def.behavior_script.new() is EnemyBehavior, id)


func test_each_behavior_says_what_it_is() -> void:
	assert_true(_load("caddie").behavior_script.new() is CaddieBehavior)

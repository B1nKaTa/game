extends TestCase

# The world attacks a regular enemy can start, each of which draws its red shapes only through
# AttackWarnings.drawn_by.
const REGULAR_WORLD_ATTACKS := ["popcorn_tub", "perfume_cloud", "write_up_mark", "phone_cord_lash",
	"crystal_ball", "steam_jet", "shuffleboard_puck", "ground_strike"]


class FakeSource extends RefCounted:
	var shown := false

	func shows_warnings() -> bool:
		return shown


func _restore(was: bool) -> void:
	AttackWarnings.shown = was


func test_a_boss_always_shows_its_warnings_and_a_regular_only_with_the_setting() -> void:
	var was := AttackWarnings.shown
	var boss := EnemyDef.new()
	boss.is_boss = true
	var regular := EnemyDef.new()
	AttackWarnings.shown = false
	assert_true(AttackWarnings.drawn_for(boss))
	assert_false(AttackWarnings.drawn_for(regular))
	AttackWarnings.shown = true
	assert_true(AttackWarnings.drawn_for(regular))
	_restore(was)


func test_a_world_attack_follows_its_source() -> void:
	var source := FakeSource.new()
	assert_false(AttackWarnings.drawn_by(source))
	source.shown = true
	assert_true(AttackWarnings.drawn_by(source))


func test_a_world_attack_with_no_source_left_keeps_its_shapes() -> void:
	assert_true(AttackWarnings.drawn_by(null))
	assert_true(AttackWarnings.drawn_by(RefCounted.new()), "a source that cannot say keeps them")


func test_every_world_attack_a_regular_starts_asks_before_drawing_red() -> void:
	for name: String in REGULAR_WORLD_ATTACKS:
		var source := FileAccess.get_file_as_string("res://scripts/world/%s.gd" % name)
		assert_true(source.contains("AttackWarnings.drawn_by(") or source.contains("shows_warnings()"), name)

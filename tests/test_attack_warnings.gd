extends TestCase

# The world attacks a regular enemy can start, each of which draws its red shapes only through
# AttackWarnings.drawn_by.
const REGULAR_WORLD_ATTACKS := ["popcorn_tub", "perfume_cloud", "write_up_mark", "phone_cord_lash",
	"crystal_ball", "steam_jet", "shuffleboard_puck", "ground_strike"]
# The world attacks a boss or mini boss starts that draw the warning red, each of which now asks too.
const BOSS_WORLD_ATTACKS := ["runway_lane", "scythe_sweep", "star_fall", "tower_tiles", "wheel_ring",
	"lane_drop", "takeover_tether", "red_tape", "anchor_drop", "deck_lane", "shockwave", "hold_music",
	"quoit_ring", "ouija_planchette", "possession_ghost", "spirit_swoop", "procession_lane", "lens_beam",
	"collection_plate", "xray_sweep", "summon_mark", "burn_ring", "desk_slam", "gavel_strike", "reel_lane",
	"splice_lane", "steam_jet", "ground_strike", "terminal_strike", "organ_pipe", "floor_vent"]


class FakeSource extends RefCounted:
	var shown := false

	func shows_warnings() -> bool:
		return shown


func _restore(was: bool) -> void:
	AttackWarnings.shown = was


func test_bosses_and_regulars_alike_show_their_warnings_only_with_the_setting() -> void:
	var was := AttackWarnings.shown
	var boss := EnemyDef.new()
	boss.is_boss = true
	var regular := EnemyDef.new()
	AttackWarnings.shown = false
	assert_false(AttackWarnings.drawn_for(boss), "a boss hides his too")
	assert_false(AttackWarnings.drawn_for(regular))
	assert_false(AttackWarnings.drawn_for(null))
	AttackWarnings.shown = true
	assert_true(AttackWarnings.drawn_for(boss))
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


# Every world object a boss or mini boss makes that draws the warning red asks first: through its
# source (drawn_by), or the setting itself where it has no source (the Chairman's red tape, a summon's
# spot).
func test_every_world_attack_a_boss_starts_asks_before_drawing_red() -> void:
	var red := RegEx.create_from_string("Color\\(\"e4524f\"\\)|WARNING_COLOR|HURT_EDGE")
	for name: String in BOSS_WORLD_ATTACKS:
		var source := FileAccess.get_file_as_string("res://scripts/world/%s.gd" % name)
		assert_false(source.is_empty(), name)
		assert_true(red.search(source) != null or source.contains("extends GroundStrike"), "%s draws red" % name)
		assert_true(source.contains("AttackWarnings.drawn_by(") or source.contains("AttackWarnings.shown") or source.contains("shows_warnings()"), name)


# The safe-spot marks show where to stand, not where it hurts, so they never ask.
func test_safe_spot_marks_always_show() -> void:
	for name in ["safe_spot_mark", "gap_mark"]:
		var source := FileAccess.get_file_as_string("res://scripts/world/%s.gd" % name)
		assert_false(source.contains("AttackWarnings"), name)


# The cue helpers draw in the cue's dark colour only, never the warning red.
func test_the_cue_helpers_draw_the_cue_colour() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/core/attack_warnings.gd")
	for helper in ["draw_cue_circle", "draw_cue_lane", "draw_cue_rect", "draw_cue_polygon"]:
		var body := source.substr(source.find("static func %s(" % helper), 700)
		assert_true(body.contains("cue_color(filled, pale)"), helper)
		assert_false(body.contains("e4524f"), helper)


# With the setting off a regular still shows its stun's stars and what it says: only the shapes hide.
func test_hidden_warnings_keep_the_stars_and_the_words() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd").replace("\r", "")
	var layer := source.substr(source.find("class WarningLayer"), 200)
	assert_false(layer.contains("if enemy.shows_warnings()"), "the layer always draws")
	var body := source.substr(source.find("func _draw_warning("), 4000)
	assert_true(body.contains("if shows_warnings() and _warning != null"), "only the shapes ask")
	assert_true(body.find("_dazed_left > 0.0") > body.find("if def == null:"), "the stars sit outside the shapes")


# A riser winds up under Grandpa, hidden by his body, so with no ring it kicks up earth he can see.
func test_a_hidden_riser_shows_a_cue_with_the_warnings_off() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd")
	assert_true(source.contains("elif submerged and def != null and def.hidden_look != \"smoke\" and is_winding_up():"))
	assert_true(source.contains("func _draw_rising_cue("))

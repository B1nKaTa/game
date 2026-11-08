extends TestCase

# With Attack warnings off, a regular enemy's red shapes hide, but no attack that hurts may become
# invisible: each keeps something to read, either a thing flying or sliding at Grandpa, its windup flash
# and its own body moving, or a faint dark cue on the ground where it will land (AttackWarnings.cue_color).

const ENEMY_DIR := "res://data/enemies/"
const FLOOR_DIR := "res://data/floors/"
const WORLD_DIR := "res://scripts/world/"

# What each world object a regular enemy makes shows with the warnings off, or why it needs nothing.
const TELLS := {
	"SteamJet": "cue",
	"PhoneCordLash": "cue",
	"WriteUpMark": "thrown",
	"PopcornTub": "thrown",
	"CrystalBall": "object",
	"ShuffleboardPuck": "object",
	"PerfumeCloud": "harmless",
	"EctoplasmTrail": "harmless",
	"FilmTrail": "harmless",
	"PaperTrail": "harmless",
	"UsherTorch": "harmless",
}


func _regular(def_id: String) -> Enemy:
	var made := Enemy.new()
	made.setup(load(ENEMY_DIR + def_id + ".tres"), null, 0.5)
	return made


func _strike(source: Enemy, delay := 0.0) -> GroundStrike:
	var strike := GroundStrike.new()
	strike.setup(source, 20.0, 1.0, delay)
	return strike


func test_the_cue_is_dark_neutral_and_grows_late() -> void:
	var early := AttackWarnings.cue_color(0.0)
	var late := AttackWarnings.cue_color(1.0)
	for color: Color in [early, late]:
		assert_true(color.r < 0.15 and color.g < 0.15 and color.b < 0.15, "dark, never red: %s" % color)
		assert_true(absf(color.r - color.g) < 0.05 and absf(color.r - color.b) < 0.05, "neutral: %s" % color)
	assert_near(early.a, 0.25)
	assert_near(late.a, 0.35)
	assert_near(AttackWarnings.cue_growth(0.5), 0.0)
	assert_near(AttackWarnings.cue_growth(1.0), 1.0)
	assert_true(AttackWarnings.cue_growth(0.8) > 0.0 and AttackWarnings.cue_growth(0.8) < 1.0, "it grows over the last part")
	assert_true(late.a < 0.45, "clearly fainter than a red mark's late fill")


func test_a_regular_spot_with_nothing_thrown_keeps_a_cue() -> void:
	var was := AttackWarnings.shown
	AttackWarnings.shown = false
	var caller := _regular("bingo_caller")
	var strike := _strike(caller)
	assert_eq(strike.cue(), GroundStrike.CUE_SHADOW, "the bingo caller's marks")
	var thrown := _strike(caller)
	thrown.throw_from(Vector2(40, 0))
	assert_eq(thrown.cue(), GroundStrike.CUE_THROWN)
	var later := _strike(caller, 0.5)
	assert_eq(later.cue(), GroundStrike.CUE_NONE, "nothing yet before a delayed spot starts")
	later.advance(0.6)
	assert_eq(later.cue(), GroundStrike.CUE_SHADOW)
	AttackWarnings.shown = true
	assert_eq(strike.cue(), GroundStrike.CUE_MARK)
	AttackWarnings.shown = was
	for made in [strike, thrown, later]:
		made.free()
	caller.free()


func test_the_ground_and_lane_attacks_draw_the_cue_when_hidden() -> void:
	for file in ["ground_strike", "steam_jet", "phone_cord_lash"]:
		assert_true(FileAccess.get_file_as_string(WORLD_DIR + file + ".gd").contains("AttackWarnings.cue_color("), file)


# Every regular enemy that hurts reads with the warnings off: its ground strikes always have a cue or
# a thrown thing (above), each world object it makes is in TELLS, and the rest are its own body moving
# after the windup flash.
func test_every_hurting_regular_attack_has_a_tell() -> void:
	var world := {}
	for file in DirAccess.get_files_at(WORLD_DIR):
		if not file.ends_with(".gd"):
			continue
		var found := RegEx.create_from_string("(?m)^class_name (\\w+)").search(FileAccess.get_file_as_string(WORLD_DIR + file))
		if found != null:
			world[found.get_string(1)] = file
	var made := RegEx.create_from_string("\\b([A-Z]\\w+)\\.new\\(")
	var regulars := 0
	for file in DirAccess.get_files_at(ENEMY_DIR):
		if not file.ends_with(".tres"):
			continue
		var def: EnemyDef = load(ENEMY_DIR + file)
		if def.is_boss or def.behavior_script == null:
			continue
		regulars += 1
		var source := FileAccess.get_file_as_string(def.behavior_script.resource_path)
		for found in made.search_all(source):
			var kind := found.get_string(1)
			if not world.has(kind):
				continue
			assert_true(TELLS.has(kind), "%s makes %s, which needs a tell with warnings off" % [file, kind])
			if TELLS.get(kind) == "cue":
				assert_true(FileAccess.get_file_as_string(WORLD_DIR + world[kind]).contains("AttackWarnings.cue_color("), kind)
	assert_true(regulars > 20, "the scan found the regular enemies")
	var enemy := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd")
	assert_true(enemy.contains("if not shows_warnings():") and enemy.contains("_visual.flash(WINDUP_CUE"), "a body attack's windup flashes")


# Mini bosses, like floor bosses, always draw their warnings.
func test_every_floor_boss_and_mini_boss_keeps_its_warnings() -> void:
	var was := AttackWarnings.shown
	AttackWarnings.shown = false
	var bosses := 0
	for file in DirAccess.get_files_at(FLOOR_DIR):
		if not file.ends_with(".tres"):
			continue
		var floor_def: FloorDef = load(FLOOR_DIR + file)
		for boss: EnemyDef in [floor_def.mini_boss, floor_def.floor_boss]:
			if boss == null:
				continue
			bosses += 1
			assert_true(boss.is_boss and AttackWarnings.drawn_for(boss), "%s in %s" % [boss.resource_path, file])
	AttackWarnings.shown = was
	assert_true(bosses >= 20, "the scan found the bosses")

extends TestCase


func test_the_player_tells_when_a_swing_or_dodge_starts() -> void:
	var player := Player.new()
	assert_true(player.has_signal("swing_started"))
	assert_true(player.has_signal("dodge_started"))
	player.free()
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	var swing := source.substr(source.find("func _swing("), 700)
	assert_true(swing.contains("swing_started.emit()"), "every swing, combo or charged, starts in _swing")
	var dodge := source.substr(source.find("func start_dodge("), 900)
	assert_true(dodge.contains("dodge_started.emit()"))


func test_a_prop_knows_whether_harold_broke_it() -> void:
	var block := BreakableBlock.new()
	block.last_source = BreakableBlock.SOURCE_CANE
	assert_true(block.broken_by_harold())
	block.last_source = BreakableBlock.SOURCE_BOSS
	assert_false(block.broken_by_harold())
	block.last_source = BreakableBlock.SOURCE_BLAST
	assert_false(block.broken_by_harold(), "an enemy's blast is not his")
	BreakableBlock.blame_harold = true
	assert_true(block.broken_by_harold(), "his Thermos is")
	BreakableBlock.blame_harold = false
	block.free()


func test_the_thermos_blames_harold_only_for_its_own_blast() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/thermos.gd")
	var at := source.find("BreakableBlock.smash(")
	var window := source.substr(at - 120, 520)
	var flagged := window.find("BreakableBlock.blame_harold = true")
	var reset := window.find("BreakableBlock.blame_harold = false")
	assert_true(flagged >= 0 and flagged < window.find("BreakableBlock.smash("))
	assert_true(reset > window.find("ReinforcedRock.blast("), "the flag stays up for the rock blast")
	assert_true(reset > window.find("SecretWall.blast("), "and for the secret wall")


func test_a_rock_or_wall_his_thermos_opens_is_his() -> void:
	var rock := ReinforcedRock.new()
	rock.needed_level = 1
	var wall := SecretWall.new()
	BreakableBlock.blame_harold = true
	assert_true(rock.break_with_level(1))
	assert_true(wall.hit_by(BreakableBlock.SOURCE_BLAST))
	assert_true(rock.broken_by_harold())
	assert_true(wall.broken_by_harold())
	BreakableBlock.blame_harold = false
	assert_false(rock.broken_by_harold(), "the same blast from an enemy is not his")
	assert_false(wall.broken_by_harold())
	rock.free()
	wall.free()

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
	var window := source.substr(at - 120, 260)
	assert_true(window.contains("BreakableBlock.blame_harold = true"))
	assert_true(window.contains("BreakableBlock.blame_harold = false"))

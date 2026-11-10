extends TestCase

const OPENING := "res://scripts/scenes/opening.gd"


func test_a_press_shows_the_next_card() -> void:
	var script: GDScript = load(OPENING)
	assert_eq(script.next_index(0, false), 1)
	assert_eq(script.next_index(5, false), 6)


func test_skip_ends_it_in_one_press() -> void:
	var script: GDScript = load(OPENING)
	var count: int = script.LINES.size()
	assert_eq(script.next_index(0, true), count)
	assert_eq(script.next_index(count - 1, false), count, "the last card's press ends it too")

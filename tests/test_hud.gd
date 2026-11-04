extends TestCase


func test_bar_fraction_is_hp_over_max() -> void:
	assert_near(Hud.bar_fraction(50.0, 200.0), 0.25)


func test_bar_fraction_is_clamped() -> void:
	assert_near(Hud.bar_fraction(-5.0, 100.0), 0.0)
	assert_near(Hud.bar_fraction(500.0, 100.0), 1.0)


func test_bar_fraction_handles_zero_max() -> void:
	assert_near(Hud.bar_fraction(10.0, 0.0), 0.0)


func test_the_waiting_room_shows_both_currencies_and_a_run_only_pension() -> void:
	assert_eq(Hud.status_text(12, 3, true), "Pension: 12   Condolences: 3")
	assert_eq(Hud.status_text(12, 3, false), "Pension: 12")


# The trophy wall's lines must not drop arrival news that is already marked seen.
func test_lines_asked_for_go_in_front_of_waiting_news() -> void:
	var waiting: Array[String] = ["New departments open: Bounty Office.", "Dolores pins up her first poster."]
	var wall := PackedStringArray(["Trophy one.", "Trophy two."])
	var queue := Hud.lines_in_front(wall, waiting)
	assert_eq(queue, ["Trophy one.", "Trophy two.", "New departments open: Bounty Office.", "Dolores pins up her first poster."])
	# Pressing the wall again while its lines wait queues them once.
	queue.pop_front()
	assert_eq(Hud.lines_in_front(wall, queue), ["Trophy one.", "Trophy two.", "New departments open: Bounty Office.", "Dolores pins up her first poster."])


func test_the_waiting_room_keeps_its_queue_when_the_wall_speaks() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	var rule := source.substr(source.find("func _show_lines"), 200)
	assert_true(rule.contains("Hud.lines_in_front(lines, _notices)"))
	assert_false(rule.contains("_notices.clear()"))

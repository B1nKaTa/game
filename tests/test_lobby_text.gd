extends TestCase

# The lobby is wider than the view and its camera scrolls, so its ticket line and DEV hint sit on the
# screen. These keep every line inside the 640x360 view and clear of the HUD's own text.

const LONGEST_HINT := DevStart.HINT + "   " + DevStart.WAITING_HINT
# A gap between the HUD's Pension and Condolences and the ticket line, at their widest.
const GAP := 16.0


# The widest lines the sign can show: four-digit numbers, counting on and in the served moment.
func _widest_lines() -> Array:
	return [
		[LobbyText.ticket_text(9999), LobbyText.serving_text(9998)],
		[LobbyText.ticket_text(9999), LobbyText.serving_text(9999, true)],
	]


func test_the_ticket_line_ends_inside_the_screen_on_the_top_row() -> void:
	for line: Array in _widest_lines():
		var left := LobbyText.ticket_left(line[0], line[1])
		var right := left + LobbyText.text_width(line[0] + line[1], LobbyText.TICKET_SIZE)
		assert_true(right <= LobbyText.VIEW.x, "ends at %.1f" % right)
	assert_true(LobbyText.TICKET_TOP + LobbyText.text_height(LobbyText.TICKET_SIZE) < Hud.NOTICE_TOP, "above the notices")


func test_the_ticket_line_clears_pension_and_condolences_at_their_widest() -> void:
	var status := Hud.status_text(99999, 99999, true)
	var status_right := 8.0 + LobbyText.text_width(status, 12)
	for line: Array in _widest_lines():
		assert_true(LobbyText.ticket_left(line[0], line[1]) >= status_right + GAP, "the status line ends at %.1f, the sign starts at %.1f" % [status_right, LobbyText.ticket_left(line[0], line[1])])


func test_the_dev_hint_and_profile_label_fit_the_bottom_of_the_screen() -> void:
	var hint_bottom := LobbyText.HINT_AT.y + LobbyText.text_height(LobbyText.HINT_SIZE)
	var profile_bottom := LobbyText.PROFILE_AT.y + LobbyText.text_height(LobbyText.PROFILE_SIZE)
	assert_true(hint_bottom <= LobbyText.VIEW.y - 4.0, "the hint ends at %.1f" % hint_bottom)
	assert_true(profile_bottom <= LobbyText.VIEW.y - 4.0, "the profile label ends at %.1f" % profile_bottom)
	var profile_right := LobbyText.PROFILE_AT.x + LobbyText.text_width(DevStart.PROFILE_LABEL, LobbyText.PROFILE_SIZE)
	assert_true(profile_right <= LobbyText.VIEW.x, "the profile label ends at %.1f" % profile_right)
	var hint_right := LobbyText.HINT_AT.x + LobbyText.text_width(LONGEST_HINT, LobbyText.HINT_SIZE)
	assert_true(hint_right + GAP <= LobbyText.PROFILE_AT.x, "the hint ends at %.1f" % hint_right)


func test_the_lines_read_as_the_lobby_sign() -> void:
	var text := LobbyText.new()
	text.show_text(14, LONGEST_HINT)
	assert_eq(text.ticket_line(), "YOUR TICKET: 015   NOW SERVING: 014")
	assert_eq(text.hint_line(), LONGEST_HINT)
	text.show_text(0, "")
	assert_eq(text.ticket_line(), "YOUR TICKET: 001   NOW SERVING: 000", "a fresh save counts from the start")
	assert_eq(text.hint_line(), "", "no hint outside debug builds")
	text.show_text(1000, "")
	assert_eq(text.ticket_line(), "YOUR TICKET: 1001   NOW SERVING: 1000")
	text.free()


# Harold is always next: the sign serves the number one short of his ticket, and never 999 or Called!.
func test_now_serving_is_always_one_short_of_the_ticket() -> void:
	for run_count in [0, 1, 41, 998]:
		var ticket := LobbyText.ticket_number(run_count)
		assert_eq(ticket, run_count + 1, "the ticket is the run about to start")
		assert_eq(LobbyText.serving_number(run_count), ticket - 1, "run_count %d" % run_count)
		var text := LobbyText.new()
		text.show_text(run_count, "")
		assert_eq(text.ticket_line(), "YOUR TICKET: %03d   NOW SERVING: %03d" % [ticket, ticket - 1])
		assert_false(text.ticket_line().contains("Called"))
		text.free()
	assert_eq(LobbyText.ticket_text(42) + LobbyText.serving_text(41), "YOUR TICKET: 042   NOW SERVING: 041", "three digits, as the title board")


# The served moment shows his finished run's own number on both sides, and only with a run behind him.
func test_the_served_line_serves_his_own_number() -> void:
	var text := LobbyText.new()
	text.show_text(7, "", true)
	assert_eq(text.ticket_line(), "YOUR TICKET: 007   NOW SERVING: 007" + LobbyText.SERVED_MARK)
	assert_eq(LobbyText.serving_number(7, true), LobbyText.ticket_number(7, true))
	text.show_text(0, "", true)
	assert_eq(text.ticket_line(), "YOUR TICKET: 001   NOW SERVING: 000", "a fresh save has nothing to serve")
	text.free()


# The scene names autoloads, so a test cannot load it. This pins that nothing in it draws text into the
# room, and that its lines go to the HUD's layer.
func test_the_waiting_room_draws_no_text_in_the_room() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	assert_false(source.contains("draw_string"))
	assert_false(source.contains("func _draw"))
	assert_true(source.contains("_hud.add_child(_lobby_text)"))

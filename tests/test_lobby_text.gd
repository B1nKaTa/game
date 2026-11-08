extends TestCase

# The lobby is wider than the view and its camera scrolls, so its ticket line and DEV hint sit on the
# screen. These keep every line inside the 640x360 view and clear of the HUD's own text.

const LONGEST_HINT := DevStart.HINT + "   " + DevStart.WAITING_HINT
# A gap between the HUD's Pension and Condolences and the ticket line, at their widest.
const GAP := 16.0


func test_the_ticket_line_ends_inside_the_screen_on_the_top_row() -> void:
	var ticket := LobbyText.ticket_text(999)
	var serving := LobbyText.serving_text(1000)
	var left := LobbyText.ticket_left(ticket, serving)
	var right := left + LobbyText.text_width(ticket + serving, LobbyText.TICKET_SIZE)
	assert_true(right <= LobbyText.VIEW.x, "ends at %.1f" % right)
	assert_true(LobbyText.TICKET_TOP + LobbyText.text_height(LobbyText.TICKET_SIZE) < Hud.NOTICE_TOP, "above the notices")


func test_the_ticket_line_clears_pension_and_condolences_at_their_widest() -> void:
	var status := Hud.status_text(99999, 99999, true)
	var status_right := 8.0 + LobbyText.text_width(status, 12)
	var ticket := LobbyText.ticket_text(9998)
	var serving := LobbyText.serving_text(9999)
	assert_true(LobbyText.ticket_left(ticket, serving) >= status_right + GAP, "the status line ends at %.1f" % status_right)


func test_the_dev_hint_and_profile_label_fit_the_bottom_of_the_screen() -> void:
	var hint_bottom := LobbyText.HINT_AT.y + LobbyText.text_height(LobbyText.HINT_SIZE)
	var profile_bottom := LobbyText.PROFILE_AT.y + LobbyText.text_height(LobbyText.PROFILE_SIZE)
	assert_true(hint_bottom <= LobbyText.VIEW.y - 4.0, "the hint ends at %.1f" % hint_bottom)
	assert_true(profile_bottom <= LobbyText.VIEW.y - 4.0, "the profile label ends at %.1f" % profile_bottom)
	var profile_right := LobbyText.PROFILE_AT.x + LobbyText.text_width(DevStart.PROFILE_LABEL, LobbyText.PROFILE_SIZE)
	assert_true(profile_right <= LobbyText.VIEW.x, "the profile label ends at %.1f" % profile_right)
	var hint_right := LobbyText.HINT_AT.x + LobbyText.text_width(LONGEST_HINT, LobbyText.HINT_SIZE)
	assert_true(hint_right + GAP <= LobbyText.PROFILE_AT.x, "the hint ends at %.1f" % hint_right)


func test_the_lines_read_as_the_lobby_sign_did() -> void:
	var text := LobbyText.new()
	text.show_text(14, 15, LONGEST_HINT)
	assert_eq(text.ticket_line(), "YOUR TICKET: 15   NOW SERVING: 15  Called!")
	assert_eq(text.hint_line(), LONGEST_HINT)
	text.show_text(15, LobbyText.NOT_CALLED, "")
	assert_eq(text.ticket_line(), "YOUR TICKET: 16   NOW SERVING: 999")
	assert_eq(text.hint_line(), "", "no hint outside debug builds")
	text.free()


# The scene names autoloads, so a test cannot load it. This pins that nothing in it draws text into the
# room, and that its lines go to the HUD's layer.
func test_the_waiting_room_draws_no_text_in_the_room() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/waiting_room.gd")
	assert_false(source.contains("draw_string"))
	assert_false(source.contains("func _draw"))
	assert_true(source.contains("_hud.add_child(_lobby_text)"))

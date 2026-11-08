class_name TitleMenu
extends RefCounted

# The title screen's menu as paper tickets on the strip hanging out of the TAKE 1 machine: which items
# show (SaveSlots.menu_items), their labels, and where each ticket sits on the 640x360 view. The
# selected ticket slides out of the strip to the right; choosing one tears it off before its action runs.

const LABELS := {
	"continue": "Continue",
	"new": "New Game",
	"load": "Load Game",
	"options": "Options",
	"credits": "Credits",
	"quit": "Quit Game",
}
# The middle of the machine's slot mouth, in view pixels (TitleRoom.slot() in room pixels, through
# TitleRoom.to_view). Every ticket edge falls on the room's 3 px grid (view x = 3 n - 4, y = 3 n).
const SLOT := Vector2(275, 228)
const TICKET_SIZE := Vector2(78, 21)
# One ticket below the next, joined at its tear line.
const STEP := 21.0
# The selected ticket is pulled out this far, four of the room's pixels.
const STICK_OUT := 12.0
# How long the tear-off plays before the chosen action runs.
const TEAR_TIME := 0.42


static func ids(slots_with_progress: int) -> Array[String]:
	return SaveSlots.menu_items(slots_with_progress)


static func label(id: String) -> String:
	return LABELS.get(id, id)


# Where ticket index sits, of the strip's tickets, and where it sits when selected.
static func ticket_rect(index: int, selected := false) -> Rect2:
	var at := Vector2(SLOT.x - TICKET_SIZE.x / 2.0, SLOT.y + index * STEP)
	if selected:
		at.x += STICK_OUT
	return Rect2(at.round(), TICKET_SIZE)


# The ticket under a point of the view, or -1.
static func index_at(point: Vector2, count: int) -> int:
	for index in count:
		if ticket_rect(index).grow_individual(0, 0, STICK_OUT, 0).has_point(point):
			return index
	return -1


# The next index up (-1) or down (+1) the strip, wrapping at either end, as the keys and stick move.
static func step(index: int, direction: int, count: int) -> int:
	if count <= 0:
		return -1
	return posmod(index + direction, count)


# A ticket's tear-off at t seconds since it was chosen: how far it has dropped and turned (radians),
# and how opaque it still is. It jerks sideways off the perforation, then falls and fades.
static func tear(t: float) -> Dictionary:
	var k := clampf(t / TEAR_TIME, 0.0, 1.0)
	var jerk := minf(k / 0.25, 1.0)
	var fall := maxf(k - 0.25, 0.0) / 0.75
	return {
		"offset": Vector2(4.0 * jerk + 10.0 * fall, 40.0 * fall * fall),
		"angle": 0.35 * fall,
		"alpha": 1.0 - fall,
	}

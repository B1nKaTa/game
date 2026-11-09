class_name GhostChatter
extends RefCounted

# What the ghosts in the title screen's queue say to each other, and who says it. They take turns: the
# one spoken to usually answers next, nobody speaks twice in a row while another can, and a line is not
# heard again until RECENT others have been.

const LINES: Array[String] = [
	"Did they call 39 yet?",
	"I've been here since a Tuesday.",
	"They lost my form. Again.",
	"Is this the queue for the queue?",
	"I think I'm in the wrong line.",
	"My number's in the thousands.",
	"Form 7B. In triplicate.",
	"They said shortly. In 1974.",
	"Is the machine out of tickets?",
	"Anyone got a pen?",
	"Please hold. That's all they said.",
	"My ticket's gone see-through.",
	"Back of the queue, chum.",
	"Was that a number or a cough?",
	"I only popped in to ask.",
	"They're on their lunch. Still.",
	"Don't make eye contact with 41.",
	"Fill it in again, they said.",
	"I'm sure he pushed in.",
	"Window three is a painting.",
	"Still pending. Still dead.",
	"Is there a fast track? No?",
	"I was told to bring ID. What ID?",
	"Same chair as last century.",
]
# A line is not said again until this many others have been.
const RECENT := 10
# The longest line, in characters, so a bubble fits two short rows over a seat.
const MAX_CHARS := 34
# How often the one spoken to answers, when they still sit within reach.
const REPLY_CHANCE := 0.7

var _recent: Array[int] = []
var _last_speaker := -1
var _last_listener := -1
var _rng := RandomNumberGenerator.new()


func _init(seed_value := 0) -> void:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


# A line not said in the last RECENT turns.
func pick_line() -> String:
	var open: Array[int] = []
	for i in LINES.size():
		if not _recent.has(i):
			open.append(i)
	var index: int = open[_rng.randi() % open.size()]
	_recent.append(index)
	while _recent.size() > RECENT:
		_recent.pop_front()
	return LINES[index]


# Who speaks next, from the ghosts able to (seated, not busy): the last one spoken to, most of the time,
# and otherwise anyone but the last speaker. -1 when nobody can.
func pick_speaker(able: Array[int]) -> int:
	if able.is_empty():
		return -1
	if able.has(_last_listener) and _last_listener != _last_speaker and _rng.randf() < REPLY_CHANCE:
		return _last_listener
	var others: Array[int] = []
	for ghost in able:
		if ghost != _last_speaker:
			others.append(ghost)
	if others.is_empty():
		others = able
	return others[_rng.randi() % others.size()]


# Whom the speaker turns to: the nearest other ghost by seat position, or -1 when they are alone.
static func listener_for(speaker: int, positions: Dictionary) -> int:
	var best := -1
	var best_distance := INF
	for ghost: int in positions:
		if ghost == speaker:
			continue
		var distance := absf(float(positions[ghost]) - float(positions[speaker]))
		if distance < best_distance:
			best_distance = distance
			best = ghost
	return best


# Records a turn, so the next pick knows who spoke and who was spoken to.
func note_turn(speaker: int, listener: int) -> void:
	_last_speaker = speaker
	_last_listener = listener

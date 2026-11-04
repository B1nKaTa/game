class_name ShipRoll
extends RefCounted

# When the ship rolls. Each period the deck lies quiet, then the horn sounds and an arrow shows the side
# for `horn` seconds, and for the last `slide` seconds of the period everyone on the deck slides that
# way. The deck only ever tips to port or to starboard, left or right. An offset moves the whole cycle
# later, so neighbouring rooms never roll in step. The roll never hurts anyone.
enum { QUIET, HORN, SLIDE }

const PERIOD := 9.0
const HORN := 1.5
const SLIDE := 2.0
# How fast the roll carries whoever stands on the deck, on top of their own walk. Grandpa walks at
# 120, so he can still walk against it, slowly.
const SPEED := 70.0
const SIDES: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT]

var period := PERIOD
var horn := HORN
var slide := SLIDE
var offset := 0.0


func _init(period_seconds := PERIOD, horn_seconds := HORN, slide_seconds := SLIDE, offset_seconds := 0.0) -> void:
	period = maxf(period_seconds, 0.01)
	slide = clampf(slide_seconds, 0.0, period)
	horn = clampf(horn_seconds, 0.0, period - slide)
	offset = offset_seconds


# How far into its period the deck is, from 0 up to the period.
func phase_at(time: float) -> float:
	return fposmod(time - offset, period)


func state_at(time: float) -> int:
	var phase := phase_at(time)
	if phase >= period - slide:
		return SLIDE
	if phase >= period - slide - horn:
		return HORN
	return QUIET


# Which roll a moment belongs to, counting up from 0. The horn and the slide of one roll share it.
func roll_index(time: float) -> int:
	return floori((time - offset) / period)


# How far the horn's warning has filled, from 0 as it sounds to 1 as the slide starts.
func horn_progress(time: float) -> float:
	if state_at(time) != HORN or horn <= 0.0:
		return 0.0
	return clampf((phase_at(time) - (period - slide - horn)) / horn, 0.0, 1.0)


# How many horns sound after `from` and no later than `to`, so each roll is announced exactly once
# however the frames fall.
func horns_between(from: float, to: float) -> int:
	if to <= from:
		return 0
	var first := period - slide - horn
	return floori((to - offset - first) / period) - floori((from - offset - first) / period)


# Which way roll number `index` tips, fixed by the room's seed, so it reads the same every time.
static func side_for(index: int, seed_value: int) -> Vector2:
	return SIDES[0] if RoomDecor.noise(Vector2i(index, 17), seed_value) < 0.5 else SIDES[1]


# What the deck adds to a walk in a state: the side at its speed while sliding, and nothing otherwise.
static func slide_velocity(state: int, side: Vector2, speed: float) -> Vector2:
	if state != SLIDE or side.is_zero_approx():
		return Vector2.ZERO
	return side.normalized() * speed

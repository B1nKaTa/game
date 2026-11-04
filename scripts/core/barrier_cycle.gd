class_name BarrierCycle
extends RefCounted

# When a room's queue barriers are down, chiming and up. Each period ends with the rope up for its last
# `up_time` seconds, and the chime with its flash takes the `chime` seconds just before it rises, so a
# barrier never rises unwarned. Dropping needs no warning, since a dropped rope blocks nothing.
var period := 10.0
var up_time := 3.0
var chime := 1.0


func _init(period_seconds := 10.0, up_seconds := 3.0, chime_seconds := 1.0) -> void:
	period = maxf(period_seconds, 0.01)
	up_time = clampf(up_seconds, 0.0, period)
	chime = clampf(chime_seconds, 0.0, period - up_time)


# The same rope twice as fast: half the period and half the time up, but the same whole chime, so
# the warning never shortens.
static func faster(cycle: BarrierCycle, times: float) -> BarrierCycle:
	var scale := maxf(times, 1.0)
	return BarrierCycle.new(cycle.period / scale, cycle.up_time / scale, cycle.chime)


func phase_at(time: float) -> float:
	return fposmod(time, period)


func rise_at() -> float:
	return period - up_time


func is_up_at(time: float) -> bool:
	return up_time > 0.0 and phase_at(time) >= rise_at()


func is_chiming(time: float) -> bool:
	var phase := phase_at(time)
	return phase >= rise_at() - chime and phase < rise_at()


# How many times the rope rises after from and up to to, whatever the frame times.
func rises_between(from: float, to: float) -> int:
	if to <= from or up_time <= 0.0:
		return 0
	return floori((to - rise_at()) / period) - floori((from - rise_at()) / period)


# How far feet must move to clear a rope that has just risen under them, or zero when they do not touch
# it. The rope runs across (horizontal) or up and down. A side that is not open, such as a wall or a
# seat beyond it, is used only when neither side is; otherwise the nearer open side wins.
static func push_out(feet: Rect2, rope: Rect2, horizontal: bool, before_open := true, after_open := true, gap := 1.0) -> Vector2:
	if not feet.intersects(rope):
		return Vector2.ZERO
	var before := (rope.position.y - feet.end.y - gap) if horizontal else (rope.position.x - feet.end.x - gap)
	var after := (rope.end.y - feet.position.y + gap) if horizontal else (rope.end.x - feet.position.x + gap)
	var shift := before if absf(before) <= absf(after) else after
	if before_open and not after_open:
		shift = before
	elif after_open and not before_open:
		shift = after
	return Vector2(0.0, shift) if horizontal else Vector2(shift, 0.0)

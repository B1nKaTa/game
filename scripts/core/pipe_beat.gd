class_name PipeBeat
extends RefCounted

# When an organ pipe rests, glows and plays its chord. Each period ends with the chord, a short
# moment right at its end, and the glow takes the `glow` seconds just before it. An offset moves
# the whole beat later, so neighbouring pipes can take turns.
enum { QUIET, GLOW, CHORD }

# How long the chord itself shows. The ring leaves on its first instant.
const CHORD_TIME := 0.1

var period := 3.2
var glow := 0.8
var offset := 0.0


func _init(period_seconds := 3.2, glow_seconds := 0.8, offset_seconds := 0.0) -> void:
	period = period_seconds
	glow = glow_seconds
	offset = offset_seconds


# How far into its period a pipe is, from 0 up to the period.
func phase_at(time: float) -> float:
	return fposmod(time - offset, period)


func state_at(time: float) -> int:
	var phase := phase_at(time)
	if phase >= period - CHORD_TIME:
		return CHORD
	if phase >= period - CHORD_TIME - glow:
		return GLOW
	return QUIET


# How far the glow has filled, from 0 as it starts to 1 as the chord comes.
func glow_progress(time: float) -> float:
	if state_at(time) != GLOW or glow <= 0.0:
		return 0.0
	return clampf((phase_at(time) - (period - CHORD_TIME - glow)) / glow, 0.0, 1.0)


# How many chords start after `from` and no later than `to`, so a pipe sends each ring exactly once
# however its frames fall.
func chords_between(from: float, to: float) -> int:
	if to <= from:
		return 0
	var first := period - CHORD_TIME
	return floori((to - offset - first) / period) - floori((from - offset - first) / period)

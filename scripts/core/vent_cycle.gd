class_name VentCycle
extends RefCounted

# When a floor vent rests, glows and flares. Each period ends with the flare, which takes its last
# `flare` seconds, and the glow takes the `warn` seconds just before it. An offset moves the whole
# cycle later, so neighbouring vents can take turns.
enum { IDLE, WARN, FLARE }

var period := 3.0
var warn := 0.8
var flare := 0.5
var offset := 0.0


func _init(period_seconds := 3.0, warn_seconds := 0.8, flare_seconds := 0.5, offset_seconds := 0.0) -> void:
	period = period_seconds
	warn = warn_seconds
	flare = flare_seconds
	offset = offset_seconds


# How far into its period a vent is, from 0 up to the period.
func phase_at(time: float) -> float:
	return fposmod(time - offset, period)


func state_at(time: float) -> int:
	var phase := phase_at(time)
	if phase >= period - flare:
		return FLARE
	if phase >= period - flare - warn:
		return WARN
	return IDLE


# How far the glow has filled, from 0 as it starts to 1 as the flare comes.
func warn_progress(time: float) -> float:
	if state_at(time) != WARN or warn <= 0.0:
		return 0.0
	return clampf((phase_at(time) - (period - flare - warn)) / warn, 0.0, 1.0)

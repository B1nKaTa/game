class_name LightFlicker
extends Node

# Wobbles its parent light's strength a little, unevenly, as an open fire does. Two waves of
# different speed, started at a different place for every light, keep neighbours out of step.
var amount := 0.08
var _base := -1.0
var _phase := 0.0


static func factor(amount_share: float, time: float, phase: float) -> float:
	return 1.0 + amount_share * (0.6 * sin(time * 7.3 + phase) + 0.4 * sin(time * 17.9 + phase * 2.3))


func _ready() -> void:
	_phase = randf() * TAU


func _process(_delta: float) -> void:
	var light := get_parent() as PointLight2D
	if light == null:
		return
	if _base < 0.0:
		_base = light.energy
	light.energy = _base * factor(amount, Time.get_ticks_msec() / 1000.0, _phase)

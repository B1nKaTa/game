extends ItemEffect

# A test effect that notes every event, lets a few rule breaks off, and may side with him.

@export var excuses := 0
@export var sides := false
var events: Array[String] = []


func on_event(_ctx: EffectContext, event_name: String) -> void:
	events.append(event_name)


func excuses_rule_break(_ctx: EffectContext) -> bool:
	if excuses > 0:
		excuses -= 1
		return true
	return false


func sides_with_you(_ctx: EffectContext) -> bool:
	return sides

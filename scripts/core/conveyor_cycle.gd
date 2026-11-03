class_name ConveyorCycle
extends RefCounted

# When a room's strips run each way. They run their own way for a period, then the other way for the
# next, and a chime with flashing arrows takes the last `chime` seconds before every reversal.
var period := 6.0
var chime := 1.0


func _init(period_seconds := 6.0, chime_seconds := 1.0) -> void:
	period = maxf(period_seconds, 0.01)
	chime = clampf(chime_seconds, 0.0, period)


# 1 while the strips run their own way, -1 while they run back.
func direction_sign_at(time: float) -> int:
	return 1 if posmod(floori(time / period), 2) == 0 else -1


func is_chiming(time: float) -> bool:
	return fposmod(time, period) >= period - chime

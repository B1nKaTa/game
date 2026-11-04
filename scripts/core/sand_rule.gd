class_name SandRule
extends RefCounted

# The golf course's sand bunkers. Anyone walking in sand wades along slower, and Grandpa cannot dodge
# while his feet are sunk in it, though a dodge he started before stepping in carries on. Sand never
# hurts anyone. A floor boss can spread sand over warned patches of the course for a while.
const SPEED_FACTOR := 0.6
# Bunkers laid in a layout keep this many cells off every door cell, so nobody wades into a doorway.
const DOOR_CLEARANCE := 2


# How fast anyone walks, as a share of the usual, in sand or out of it.
static func speed_factor(in_sand: bool) -> float:
	return SPEED_FACTOR if in_sand else 1.0


static func can_dodge(in_sand: bool) -> bool:
	return not in_sand


# Grandpa's walk under a slow and in sand together. However slow, he keeps the least speed a
# sedative leaves him, so he can always wade out of trouble.
static func slowed(slow_factor: float, in_sand: bool) -> float:
	if not in_sand:
		return slow_factor
	return maxf(slow_factor * SPEED_FACTOR, SlowEffect.MIN_FACTOR)

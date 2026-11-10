class_name ShotGuard
extends Node2D

# One shot guard: a shot within radius is stopped when check says it may be, and spend is told it was.
# With no check it never blocks, so a pet that guards nothing is a plain body. It is an item's look in
# the room (ItemFx.GROUP), so leaving the room clears it.

var radius := 8.0
var check := Callable()
var spend := Callable()
# What it stands on, if anything (Loose Paperwork's sheets stand on Harold). Pet moves on its own.
var follow: Node2D


func _init() -> void:
	add_to_group(ShotGuards.GROUP)
	add_to_group(ItemFx.GROUP)
	z_index = ItemFx.Z


func _process(_delta: float) -> void:
	if is_instance_valid(follow):
		global_position = follow.global_position
	queue_redraw()


func blocks_shot(at: Vector2) -> bool:
	if not check.is_valid():
		return false
	if global_position.distance_to(at) > radius or not bool(check.call()):
		return false
	if spend.is_valid():
		spend.call()
	return true

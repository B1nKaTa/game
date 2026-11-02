class_name RoomPalette
extends Resource

# The one place room colors live. The defaults are the look of the office floor,
# and a FloorDef can carry its own palette to override them.
@export var floor_a := Color("6a6677")
@export var floor_b := Color("625e6f")
@export var wall := Color("3a3547")
@export var darkness := Color(0.04, 0.03, 0.05)
@export var ambient := Color(0.32, 0.32, 0.48)
@export var torch := Color(1.0, 0.62, 0.3)

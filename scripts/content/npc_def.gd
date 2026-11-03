class_name NpcDef
extends Resource

# Someone Grandpa can talk to. Drawn in code, like the other placeholders, from these.
@export var id: String = ""
@export var display_name: String = ""
@export var color := Color("8a6a4a")
@export var body_size := Vector2(20, 28)
# Said one at a time, in order, starting over after the last.
@export var lines: Array[String] = []

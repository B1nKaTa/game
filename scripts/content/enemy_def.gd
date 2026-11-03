class_name EnemyDef
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: float = 30.0
@export var speed: float = 60.0
@export var damage: int = 1
@export var pension_drop: int = 4
@export var ignores_walls: bool = false
@export var is_boss: bool = false
@export var body_size: Vector2 = Vector2(20, 24)
@export var color: Color = Color.WHITE
@export var frame_width: int = 32
@export var behavior_script: Script
@export var summon: EnemyDef
# How many spawn together at one enemy cell. Only the first of a group pays.
@export var group_size: int = 1
# A room holds at most this many of the type. Zero means no limit.
@export var max_per_room: int = 0
# Half the width in degrees of a shield facing its target. Zero means no shield.
@export var shield_half_angle: float = 0.0
# A placeholder sign drawn on the body, so a type reads without art. See EnemyMarks.
@export var mark: String = ""
# Bolted to a wall: it starts on a cell beside one and never moves, not even when hit.
@export var wall_mounted: bool = false
# What shows of it while it hides underground or in smoke: "mound" or "smoke".
@export var hidden_look: String = "mound"

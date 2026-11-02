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

class_name FloorDef
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var rooms_dir: String = ""
@export var enemies: Array = []
@export var mini_boss: EnemyDef
@export var floor_boss: EnemyDef
@export var clear_pension: int = 8
@export var treasure_pension: int = 25
@export var palette: RoomPalette
@export_group("Layout")
@export var grid_size := Vector2i(9, 7)
@export var main_path_rooms: int = 7
@export var min_rooms: int = 12
@export var max_rooms: int = 15
@export var item_rooms: int = 2
@export var healing_rooms: int = 1
@export var side_room_chance: float = 0.2
@export var path_reward_chance: float = 0.25


func room_palette() -> RoomPalette:
	return palette if palette != null else RoomPalette.new()

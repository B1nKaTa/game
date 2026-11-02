class_name FloorDef
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var rooms_dir: String = ""
@export var enemies: Array = []
# How often each entry of enemies is chosen. A missing weight counts as one.
@export var enemy_weights: PackedInt32Array = []
# Each fraction of the way along the main path that a combat room has passed adds one enemy.
@export var extra_enemy_steps: PackedFloat32Array = []
@export var mini_boss: EnemyDef
@export var floor_boss: EnemyDef
@export var clear_pension: int = 8
@export var treasure_pension: int = 25
# What a coin found in a barrel, a rock, a crate or a pile of bones is worth.
@export var prop_pension: int = 2
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


func enemy_weight(index: int) -> int:
	return enemy_weights[index] if index < enemy_weights.size() else 1


func extra_enemies_at(step: int, path_length: int) -> int:
	if path_length <= 1:
		return 0
	var along := float(step) / float(path_length - 1)
	var extra := 0
	for fraction in extra_enemy_steps:
		if along >= fraction:
			extra += 1
	return extra

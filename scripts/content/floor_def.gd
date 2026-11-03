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
@export_group("Path")
# How many floor bosses at open_after_depth must have fallen, on any path there, before this path
# opens. Zero means always open.
@export var clears_to_open: int = 0
# 1 for a floor reached from the first Crossroads, 2 for one from the second, and so on down.
@export var depth: int = 1
# Which depth's clears clears_to_open counts, on any path at that depth.
@export var open_after_depth: int = 1
# Skulls on the path's sign at the Crossroads.
@export var danger: int = 1
# What the chained sign says while the path is closed.
@export var closed_hint: String = ""
@export_group("Layout")
@export var grid_size := Vector2i(9, 7)
@export var main_path_rooms: int = 7
@export var min_rooms: int = 12
@export var max_rooms: int = 15
@export var item_rooms: int = 2
@export var healing_rooms: int = 1
@export var side_room_chance: float = 0.2
@export var path_reward_chance: float = 0.25
@export_group("Vaults")
# Vault rooms this floor hangs off its combat rooms, each behind a reinforced stone. A floor
# without vault layouts, or with none free cells, simply has fewer.
@export var vault_count: int = 1
# The Thermos upgrade level that breaks this floor's reinforced stones. A later floor can ask for less.
@export var vault_stone_level: int = 3
@export_group("Arcade")
# The chance that this floor hangs an Arcade Room off one of its combat rooms. Its layouts are shared
# by every floor.
@export var arcade_chance: float = 0.25
@export_group("Chests")
# How often a layout's C cell becomes each kind of chest, as weights by ChestRules kind. The rare
# kinds get likelier deeper down, and a first floor never rolls a mimic whatever this says.
@export var chest_weights: Dictionary = {"lunchbox": 50, "locked": 30, "safe": 12, "urn": 8, "mimic": 0}
# What a mimic chest wakes into here. A floor that names none never rolls a mimic.
@export var mimic: EnemyDef
@export_group("Difficulty")
# Every enemy spawned on this floor, bosses included, starts with its EnemyDef's max_hp times this.
# A boss made for one floor holds its final health divided by that floor's health_mult in its .tres.
@export var health_mult: float = 1.0
# Every enemy's Pension drop on this floor is multiplied by this and rounded up. Summons still pay nothing.
@export var pension_mult: float = 1.0
# How many enemy cells a combat room of each size holds on this floor.
@export var enemies_by_size: Dictionary = {"small": 4, "medium": 6, "large": 11}


func is_open(floors_cleared: int) -> bool:
	return floors_cleared >= clears_to_open


func is_open_for(data: ProgressData) -> bool:
	return is_open(data.clears_at(open_after_depth))


# What is wrong with a layout's enemy cells for this floor's room sizes. Only combat rooms are counted.
func room_size_errors(layout: RoomLayout) -> PackedStringArray:
	return layout.enemy_count_errors(enemies_by_size)


func chest_odds() -> Dictionary:
	var odds := ChestRules.odds_for_depth(chest_weights, depth)
	if mimic == null:
		odds[ChestRules.MIMIC] = 0.0
	return odds


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

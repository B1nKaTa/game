extends Node2D

const ROWS := [
	"####################",
	"#..................#",
	"#..................#",
	"#....##......##....#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#....##......##....#",
	"#..................#",
	"#..................#",
	"####################",
]

var player: Player


func _ready() -> void:
	InputSetup.ensure()
	var backdrop := RoomBackdrop.new()
	backdrop.setup(PackedStringArray(ROWS))
	add_child(backdrop)
	_spawn_player()


func _spawn_player() -> void:
	var upgrades: Array[UpgradeDef] = []
	player = Player.new()
	player.setup(RunState.new(upgrades, {}))
	player.position = RoomBackdrop.cell_center(Vector2i(10, 5))
	player.died.connect(_on_player_died)
	add_child(player)


func _on_player_died() -> void:
	player.queue_free()
	_spawn_player.call_deferred()

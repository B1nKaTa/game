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
const SPAWN_KEYS := {
	KEY_1: "intern_reaper",
	KEY_2: "filing_clerk",
	KEY_3: "debt_ghost",
	KEY_4: "senior_adjuster",
	KEY_5: "regional_reaper",
}

var player: Player
var _feedback: CombatFeedback


func _ready() -> void:
	InputSetup.ensure()
	var backdrop := RoomBackdrop.new()
	backdrop.setup(PackedStringArray(ROWS))
	add_child(backdrop)
	var camera := Camera2D.new()
	camera.position = Vector2(320, 180)
	add_child(camera)
	_feedback = CombatFeedback.new()
	_feedback.setup(camera)
	add_child(_feedback)
	_spawn_player()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var key: Key = event.physical_keycode
	if SPAWN_KEYS.has(key):
		var def: EnemyDef = load("res://data/enemies/%s.tres" % SPAWN_KEYS[key])
		_spawn_enemy(def, RoomBackdrop.cell_center(Vector2i(16, 5)))


func _spawn_enemy(def: EnemyDef, at: Vector2) -> void:
	var enemy := Enemy.new()
	enemy.setup(def, player, player.run.stats.warning_fraction)
	enemy.position = at
	enemy.summon_requested.connect(_spawn_enemy)
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)


func _spawn_player() -> void:
	var upgrades: Array[UpgradeDef] = []
	player = Player.new()
	player.setup(RunState.new(upgrades, {}))
	player.position = RoomBackdrop.cell_center(Vector2i(3, 5))
	player.died.connect(_on_player_died)
	add_child(player)
	_feedback.watch_player(player)


func _on_enemy_defeated(enemy: Enemy) -> void:
	DeathBurst.spawn(self, enemy.position, enemy.def.color, enemy.def.is_boss)
	_feedback.on_enemy_died(enemy.position, enemy.def.is_boss)


func _on_player_died() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	player.queue_free()
	_spawn_player.call_deferred()

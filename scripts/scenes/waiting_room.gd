extends Node2D

const ROWS := [
	"####################",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"####################",
]
const MERCHANT_CELL := Vector2i(5, 3)
const DOOR_CELL := Vector2i(18, 5)
const INTERACT_RANGE := 48.0

var player: Player
var _hud: Hud
var _merchant_position := Vector2.ZERO
var _panel: MerchantPanel


func _ready() -> void:
	var backdrop := RoomBackdrop.new()
	backdrop.setup(PackedStringArray(ROWS))
	add_child(backdrop)
	Lighting.add_room_mood(self)
	_merchant_position = RoomBackdrop.cell_center(MERCHANT_CELL)
	var merchant := SpriteVisual.new()
	merchant.position = _merchant_position
	add_child(merchant)
	merchant.setup("merchant", Vector2(22, 30), Color("8a4fbf"), 32)
	player = Player.new()
	player.setup(Progress.make_run())
	player.position = RoomBackdrop.cell_center(Vector2i(3, 5))
	add_child(player)
	var door := Door.new()
	door.setup(0, ">", player)
	door.locked = false
	door.position = RoomBackdrop.cell_center(DOOR_CELL)
	door.entered.connect(func(_id: int): Game.begin_run())
	add_child(door)
	_hud = Hud.new()
	_hud.setup(null)
	add_child(_hud)
	_hud.set_pension(Progress.data.pension)
	Progress.pension_changed.connect(_hud.set_pension)
	_hud.show_message(Progress.notice)
	Progress.notice = ""


func _process(_delta: float) -> void:
	queue_redraw()
	if _panel == null and Input.is_action_just_pressed("interact") and player.global_position.distance_to(_merchant_position) <= INTERACT_RANGE:
		_open_panel()


func _open_panel() -> void:
	_panel = MerchantPanel.new()
	_panel.closed.connect(_close_panel)
	add_child(_panel)
	player.cancel_charge()
	player.set_physics_process(false)
	_hud.show_message("")


func _close_panel() -> void:
	_panel.queue_free()
	_panel = null
	player.set_physics_process(true)


func _draw() -> void:
	if _panel == null and player != null and player.global_position.distance_to(_merchant_position) <= INTERACT_RANGE:
		draw_string(ThemeDB.fallback_font, _merchant_position + Vector2(-30, -24), "E: Trade", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(240, 24), "NOW SERVING: 666", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e4524f"))

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
# "clears" is how many floors must be cleared before a merchant appears, and a missing one means
# always there. "kind" picks the panel: upgrades by default, or "potions" for brews. Later floors
# will move the clears here, in one place.
const MERCHANTS := [
	{"id": "black_market", "title": "Black Market. You didn't see me.", "cell": Vector2i(5, 3), "color": Color("8a4fbf"), "art": "merchant"},
	{"id": "optometrist", "title": "Dr. Squint, Unlicensed Optometrist", "cell": Vector2i(5, 7), "color": Color("4fbfa8"), "art": "optometrist"},
	{"id": "potion_merchant", "kind": "potions", "clears": 1, "title": "Madame Murk, Discount Apothecary", "cell": Vector2i(8, 3), "color": Color("c0508f"), "art": "apothecary"},
	{"id": "bomb_merchant", "clears": 3, "title": "Boom Bernard, Fuel Dealer", "cell": Vector2i(14, 7), "color": Color("d9822b"), "art": "fuel_dealer"},
]
const DOOR_CELL := Vector2i(18, 5)
const INTERACT_RANGE := 48.0
const KEY_BOARD_CELL := Vector2i(14, 3)
const KEY_BOARD_COLOR := Color("6b4a2a")
const CRAFTER_CELL := Vector2i(10, 7)
const CRAFTER_COLOR := Color("c98a3c")
const CRAFTER_ART := "crafter"
const CRAFTER_TITLE := "Agnes, Afterlife Arts and Crafts"

var player: Player
var _hud: Hud
var _open_merchants: Array = []
var _panel: CanvasLayer
var _keys_panel: KeysPanel
var _craft_panel: CraftPanel


func _ready() -> void:
	var backdrop := RoomBackdrop.new()
	backdrop.setup(PackedStringArray(ROWS))
	add_child(backdrop)
	_open_merchants = MerchantRules.open_ones(MERCHANTS, Progress.data.floors_cleared)
	for entry in _open_merchants:
		var merchant := SpriteVisual.new()
		merchant.position = RoomBackdrop.cell_center(entry["cell"])
		add_child(merchant)
		merchant.setup(entry["art"], Vector2(22, 30), entry["color"], 32)
	var crafter := SpriteVisual.new()
	crafter.position = RoomBackdrop.cell_center(CRAFTER_CELL)
	add_child(crafter)
	crafter.setup(CRAFTER_ART, Vector2(22, 30), CRAFTER_COLOR, 32)
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
	if not _any_panel_open() and Input.is_action_just_pressed("interact"):
		var entry := _merchant_in_range()
		if not entry.is_empty():
			_open_panel(entry)
		elif _near_key_board():
			_open_keys_panel()
		elif _near_crafter():
			_open_craft_panel()


func _any_panel_open() -> bool:
	return _panel != null or _keys_panel != null or _craft_panel != null


func _near_key_board() -> bool:
	return player.global_position.distance_to(RoomBackdrop.cell_center(KEY_BOARD_CELL)) <= INTERACT_RANGE


func _near_crafter() -> bool:
	return player.global_position.distance_to(RoomBackdrop.cell_center(CRAFTER_CELL)) <= INTERACT_RANGE


func _open_craft_panel() -> void:
	_craft_panel = CraftPanel.new()
	_craft_panel.setup(CRAFTER_TITLE)
	_craft_panel.closed.connect(_close_craft_panel)
	add_child(_craft_panel)
	player.cancel_charge()
	player.set_physics_process(false)
	_hud.show_message("")


func _close_craft_panel() -> void:
	_craft_panel.queue_free()
	_craft_panel = null
	player.set_physics_process(true)


func _open_keys_panel() -> void:
	_keys_panel = KeysPanel.new()
	_keys_panel.closed.connect(_close_keys_panel)
	add_child(_keys_panel)
	player.cancel_charge()
	player.set_physics_process(false)
	_hud.show_message("")


func _close_keys_panel() -> void:
	_keys_panel.queue_free()
	_keys_panel = null
	player.set_physics_process(true)


func open_merchant_ids() -> Array:
	return _open_merchants.map(func(entry: Dictionary): return entry["id"])


func _merchant_in_range() -> Dictionary:
	var best := {}
	var best_distance := INTERACT_RANGE
	for entry in _open_merchants:
		var distance := player.global_position.distance_to(RoomBackdrop.cell_center(entry["cell"]))
		if distance <= best_distance:
			best = entry
			best_distance = distance
	return best


func _open_panel(entry: Dictionary) -> void:
	if entry.get("kind", "") == "potions":
		_panel = PotionPanel.new()
		_panel.setup(entry["title"])
	else:
		_panel = MerchantPanel.new()
		_panel.setup(entry["title"], entry["id"])
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
	var board_at := RoomBackdrop.cell_center(KEY_BOARD_CELL)
	draw_rect(Rect2(board_at - Vector2(14, 18), Vector2(28, 36)), KEY_BOARD_COLOR)
	draw_rect(Rect2(board_at - Vector2(14, 18), Vector2(28, 36)), Color.BLACK, false, 2.0)
	draw_string(ThemeDB.fallback_font, board_at + Vector2(-7, 5), "Keys", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	if not _any_panel_open() and player != null:
		var entry := _merchant_in_range()
		if not entry.is_empty():
			var at: Vector2 = RoomBackdrop.cell_center(entry["cell"])
			draw_string(ThemeDB.fallback_font, at + Vector2(-30, -24), KeyBindings.with_key("interact", "Trade"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		elif _near_key_board():
			draw_string(ThemeDB.fallback_font, board_at + Vector2(-30, -24), KeyBindings.with_key("interact", "Key Settings"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		elif _near_crafter():
			draw_string(ThemeDB.fallback_font, RoomBackdrop.cell_center(CRAFTER_CELL) + Vector2(-30, -24), KeyBindings.with_key("interact", "Craft"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(240, 24), "NOW SERVING: 666", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e4524f"))

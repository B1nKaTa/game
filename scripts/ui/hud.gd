class_name Hud
extends CanvasLayer

const BOSS_BAR_SIZE := Vector2(480, 10)
const BOSS_BAR_TOP := 336.0
const BOSS_NAME_TOP := 314.0
# Where the Slip and Thermos counters start; they follow the pills and Pension along the left panel's
# top row (_layout_top_row).
const SLIP_COUNTER_AT := Vector2(160, 3)
const THERMOS_COUNTER_AT := Vector2(196, 3)
const POTION_SLOT_AT := Vector2(412, 5)
const COUNTER_TEXT_OFFSET := Vector2(15, 2)
# The HUD sits in two framed panels (HudStyle) that leave the top middle clear, where the north door's
# opening and its sign show: pills, Pension, Slips, Thermoses and the item row on the left; the potion
# slot (and the run timer) right of the middle; then the small map.
const LEFT_PANEL_AT := Vector2(2, 1)
const LEFT_PANEL_MIN_WIDTH := 276.0
const RIGHT_PANEL := Rect2(404, 1, 118, 34)
# Behind the small map and the floor name over it (FloorMapView.MINI_RECT).
const MAP_PANEL := Rect2(524, 0, 116, 75)
const PILLS_AT := Vector2(8, 5)
const COUNTER_GAP := 10.0
const COUNTER_STEP := 36.0
const NOTICE_TOP := 40.0
const NOTICE_TIME := 3.5
# A faint band behind the top row, so full pills never read as empty over a pale floor.
const TOP_BAND_SIZE := Vector2(640, 22)
const TOP_BAND := Color(0.0, 0.0, 0.0, 0.4)
# The bottom of the HUD's top rows on screen: the band and the item row under it. Speech stays below it.
const BAND_BOTTOM := 36.0
# The item row under the band: the count and the newest few names, cut short with an ellipsis, and the
# case file's key on its right. It ends before the small map (FloorMapView.MINI_RECT) and never wraps.
const ITEM_ROW_AT := Vector2(8, 22)
const ITEM_ROW_END := 272.0
const ITEM_ROW_FONT := 8
const ITEMS_SHOWN := 3
const CASE_FILE_HINT := "Case file"
const HINT_GAP := 10.0
# The Game tab's run timer, on the top row in the gap before the Slip counter, right-aligned to it,
# since the small map's floor name holds the row's right end.
const TIMER_AT := Vector2(474, 22)
const TIMER_WIDTH := 44.0
const TIMER_FONT := 8
# The banner a combo shows as it forms, under the notice line.
const BANNER_TOP := 60.0
const BANNER_TIME := 2.5
const BANNER_TEXT := "COMBO: %s"
const BANNER_COLOR := Color("ffd24a")

var _run: RunState
var _status: Label
var _items: Label
var _item_row: ItemRow
var _case_hint: Label
var _case_label := ""
var _slips: Label
var _thermoses: Label
var _potion_slot: PotionSlot
var _potion_label := ""
# The film reel he holds, on the right panel's second row (ReelSlot.AT), and the key it names.
var _reel_slot: ReelSlot
var _reel_key := ""
var _active_slot: ActiveSlot
var _active_key := ""
var _message: Label
var _notice: Label
var _notice_left := 0.0
var _banner: Label
var _banner_left := 0.0
var _boss_name: Label
var _boss_back: ColorRect
var _boss_fill: ColorRect
var _boss_max_hp := 1.0
var _map_back: MapBack
var _rule_icon: RuleIcon
var _rule_stamp: RuleStamp
var _pension := 0
var _condolences := 0
# The Waiting Room shows Condolences beside Pension. A run shows Pension only, plus a pop-up when
# Condolences are earned.
var show_condolences := false
# Set from the Game tab's Show run timer. Only a run's HUD has the timer.
var show_timer := false
var _timer: Label
var _frame: HudFrame
var _slip_icon: ConsumableIcon
var _thermos_icon: ConsumableIcon


static func status_text(pension: int, condolences: int, with_condolences: bool) -> String:
	if with_condolences:
		return "Pension: %d   Condolences: %d" % [pension, condolences]
	return "Pension: %d" % pension


static func bar_fraction(hp: float, max_hp: float) -> float:
	if max_hp <= 0.0:
		return 0.0
	return clampf(hp / max_hp, 0.0, 1.0)


# The run timer's text: minutes and seconds, with hours once a run passes one.
static func timer_text(seconds: float) -> String:
	var whole := maxi(int(seconds), 0)
	if whole >= 3600:
		return "%d:%02d:%02d" % [whole / 3600, (whole / 60) % 60, whole % 60]
	return "%d:%02d" % [whole / 60, whole % 60]


# "Items: 12   Kettle, Rolling Pin, Wreath of Thorns": the count, then the newest names first.
static func items_text(names: PackedStringArray) -> String:
	if names.is_empty():
		return "Items: 0"
	var newest: PackedStringArray = []
	for i in mini(ITEMS_SHOWN, names.size()):
		newest.append(names[names.size() - 1 - i])
	return "Items: %d   %s" % [names.size(), ", ".join(newest)]


# The newest few items, newest first, with each one's icon or null.
static func item_row_entries(items: Array[ItemDef]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for i in mini(ITEMS_SHOWN, items.size()):
		var item := items[items.size() - 1 - i]
		entries.append({"name": item.display_name, "icon": ItemIcons.texture(item.id)})
	return entries


func item_row_uses_icons() -> bool:
	return _item_row != null and _item_row.visible


static func case_hint_text(key_label: String) -> String:
	return "%s: %s" % [key_label, CASE_FILE_HINT]


# Where the item row's two labels sit: the hint right-aligned to the row's end, and the names in what
# is left, so neither runs into the other or into the small map.
static func item_row_rects(hint_width: float) -> Array[Rect2]:
	var hint := Rect2(ITEM_ROW_END - hint_width, ITEM_ROW_AT.y, hint_width, 12.0)
	var names := Rect2(ITEM_ROW_AT, Vector2(maxf(hint.position.x - HINT_GAP - ITEM_ROW_AT.x, 0.0), 12.0))
	return [names, hint]


static func banner_text(combo_name: String) -> String:
	return BANNER_TEXT % combo_name


static func counter_text(amount: int) -> String:
	return "x%d" % amount


# Notices asked for now go in front of those already waiting, so news queued earlier still shows after
# them. Lines asked for again replace their earlier copies instead of waiting twice.
static func lines_in_front(lines: PackedStringArray, waiting: Array[String]) -> Array[String]:
	var queue: Array[String] = []
	for line in lines:
		queue.append(line)
	for line in waiting:
		if not lines.has(line):
			queue.append(line)
	return queue


func setup(run: RunState) -> void:
	_run = run


func _ready() -> void:
	_frame = HudFrame.new()
	_frame.hud = self
	add_child(_frame)
	# The small map's panel on a node of its own, so it fades with the map (MapFade).
	_map_back = MapBack.new()
	_map_back.hud = self
	add_child(_map_back)
	_status = _add_label(Vector2(8, 5), HudStyle.SMALL)
	_items = _add_label(ITEM_ROW_AT, ITEM_ROW_FONT)
	_items.clip_text = true
	_items.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_items.autowrap_mode = TextServer.AUTOWRAP_OFF
	_item_row = ItemRow.new()
	_item_row.visible = false
	add_child(_item_row)
	_case_hint = _add_label(ITEM_ROW_AT, ITEM_ROW_FONT)
	_case_hint.add_theme_color_override("font_color", HudStyle.DIM_TEXT)
	_case_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_message = _add_label(Vector2(0, 150), HudStyle.LARGE)
	_message.size = Vector2(640, 40)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice = _add_label(Vector2(0, NOTICE_TOP), HudStyle.SMALL)
	_notice.size = Vector2(640, 20)
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner = _add_label(Vector2(0, BANNER_TOP), HudStyle.LARGE)
	_banner.size = Vector2(640, 24)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_color", BANNER_COLOR)
	_banner.add_theme_constant_override("outline_size", 5)
	_boss_name = _add_label(Vector2(0, BOSS_NAME_TOP), HudStyle.LARGE)
	_boss_name.size = Vector2(640, 20)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var left := (640.0 - BOSS_BAR_SIZE.x) / 2.0
	_boss_back = _add_rect(Vector2(left, BOSS_BAR_TOP), BOSS_BAR_SIZE, Color("1a1214"))
	_boss_fill = _add_rect(Vector2(left, BOSS_BAR_TOP), BOSS_BAR_SIZE, Color("e4524f"))
	hide_boss_bar()
	if _run != null:
		_slip_icon = _add_icon(SLIP_COUNTER_AT, ConsumableIcon.Kind.SLIP)
		_slips = _add_label(SLIP_COUNTER_AT + COUNTER_TEXT_OFFSET, HudStyle.SMALL)
		_thermos_icon = _add_icon(THERMOS_COUNTER_AT, ConsumableIcon.Kind.THERMOS)
		_thermoses = _add_label(THERMOS_COUNTER_AT + COUNTER_TEXT_OFFSET, HudStyle.SMALL)
		_potion_slot = PotionSlot.new()
		_potion_slot.position = POTION_SLOT_AT
		add_child(_potion_slot)
		_reel_slot = ReelSlot.new()
		_reel_slot.position = ReelSlot.AT
		add_child(_reel_slot)
		_active_slot = ActiveSlot.new()
		add_child(_active_slot)
		_run.changed.connect(_refresh)
		_timer = _add_label(TIMER_AT, TIMER_FONT)
		_timer.size = Vector2(TIMER_WIDTH, 12)
		_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_timer.visible = show_timer
		# The Hearing Aid's arrows, drawn only while his stats ask for them.
		var arrows := ItemFx.OffscreenArrows.new()
		arrows.setup(_run)
		add_child(arrows)
	# The room rule's icon under the minimap, and its announcement card and stamps, drawn last so they sit on top.
	_rule_icon = RuleIcon.new()
	add_child(_rule_icon)
	_rule_stamp = RuleStamp.new()
	_rule_stamp.announce_done.connect(_rule_icon.show_rule)
	add_child(_rule_stamp)
	_refresh()


# The small map, its floor name and its panel together at this alpha (MapFade), so a warning under them shows.
func set_map_alpha(alpha: float, mini_map: CanvasItem) -> void:
	if _map_back != null:
		_map_back.modulate.a = alpha
	if _rule_icon != null:
		_rule_icon.modulate.a = alpha
	if mini_map != null:
		mini_map.modulate.a = alpha


func show_rule(rule: String) -> void:
	_rule_icon.show_rule(rule)


func announce_rule(rule: String) -> void:
	_rule_icon.clear()
	_rule_stamp.announce(rule)


func stamp_rule(kind: String) -> void:
	_rule_stamp.stamp(kind)


func pulse_rule(on: bool) -> void:
	_rule_icon.set_pulse(on)


func break_rule() -> void:
	_rule_icon.set_broken()


func clear_rule() -> void:
	_rule_icon.clear()


func rule_announcing() -> bool:
	return _rule_stamp.is_showing()


# What the reel slot shows: the flashback key while he holds a reel, "" while he holds none.
func reel_label() -> String:
	return _reel_slot.label_text() if _reel_slot != null else ""


# What the active slot says: its key and the active's name, "" while none is held.
func active_label() -> String:
	return _active_slot.label_text_shown() if _active_slot != null else ""


func map_alpha() -> float:
	return _map_back.modulate.a if _map_back != null else 1.0


func set_pension(amount: int) -> void:
	_pension = amount
	if _status != null:
		_refresh()


func set_condolences(amount: int) -> void:
	_condolences = amount
	if _status != null:
		_refresh()


func set_run_time(seconds: float) -> void:
	if _timer == null:
		return
	_timer.visible = show_timer
	if show_timer:
		_timer.text = timer_text(seconds)


func show_message(text: String) -> void:
	_message.text = text


func show_notice(text: String) -> void:
	if not text.is_empty():
		Sfx.play("notice_pop")
	_notice.text = text
	_notice_left = NOTICE_TIME


# "COMBO: <name>" for a moment, as a combo forms.
func show_combo(combo_name: String) -> void:
	_banner.text = banner_text(combo_name)
	_banner_left = BANNER_TIME


func banner() -> String:
	return _banner.text if _banner != null else ""


func _process(delta: float) -> void:
	# The potion slot names the active device's button, so it follows a switch of device.
	if _run != null and _potion_slot != null and (KeyBindings.prompt_label("potion") != _potion_label or KeyBindings.prompt_label("case_file") != _case_label or KeyBindings.prompt_label("flashback") != _reel_key or KeyBindings.prompt_label("use_item") != _active_key):
		_refresh()
	if _potion_slot != null:
		_potion_slot.show_buff(_run.buff, _run.buff_left)
	if _banner_left > 0.0:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_banner.text = ""

	if _notice_left <= 0.0:
		return
	_notice_left -= delta
	if _notice_left <= 0.0:
		_notice.text = ""


func show_boss_bar(display_name: String, max_hp: float) -> void:
	_boss_max_hp = max_hp
	_boss_name.text = display_name
	_boss_name.visible = true
	_boss_back.visible = true
	_boss_fill.visible = true
	set_boss_health(max_hp)
	_frame.queue_redraw()


func set_boss_health(hp: float) -> void:
	_boss_fill.size.x = BOSS_BAR_SIZE.x * bar_fraction(hp, _boss_max_hp)


func hide_boss_bar() -> void:
	_boss_name.visible = false
	_boss_back.visible = false
	_boss_fill.visible = false
	if _frame != null:
		_frame.queue_redraw()


func is_boss_bar_visible() -> bool:
	return _boss_back != null and _boss_back.visible


func _add_icon(at: Vector2, kind: ConsumableIcon.Kind) -> ConsumableIcon:
	var icon := ConsumableIcon.new()
	icon.setup(kind)
	icon.position = at
	add_child(icon)
	return icon


func _add_rect(at: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = at
	rect.size = size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect


func _add_label(at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudStyle.style_label(label, font_size)
	add_child(label)
	return label


func _refresh() -> void:
	var text := status_text(_pension, _condolences, show_condolences)
	if _run != null:
		_slips.text = counter_text(_run.keys)
		_thermoses.text = counter_text(_run.bombs)
		_potion_label = KeyBindings.prompt_label("potion")
		_potion_slot.show_potion(_run.potion, _potion_label)
		_reel_key = KeyBindings.prompt_label("flashback")
		_reel_slot.show_reel(_run.held_reel, _reel_key)
		var names: PackedStringArray = []
		for item in _run.items:
			names.append(item.display_name)
		_items.text = items_text(names)
		var entries := item_row_entries(_run.items)
		var with_icons := entries.any(func(entry): return entry["icon"] != null)
		_item_row.visible = with_icons
		_items.visible = not with_icons
		if with_icons:
			_item_row.show_pieces(ItemRow.pieces(_run.items.size(), entries))
		_case_label = KeyBindings.prompt_label("case_file")
		_case_hint.text = case_hint_text(_case_label)
		var font := HudStyle.font()
		var rects := item_row_rects(font.get_string_size(_case_hint.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ITEM_ROW_FONT).x + 6.0)
		_items.position = rects[0].position
		_items.size = rects[0].size
		_item_row.position = rects[0].position
		_item_row.size = rects[0].size
		_case_hint.position = rects[1].position
		_case_hint.size = rects[1].size
	_status.text = text
	_layout_top_row()
	if _run != null and _active_slot != null:
		_active_key = KeyBindings.prompt_label("use_item")
		var slot := ActiveSlot.slot_rect(left_panel_rect().end.x)
		_active_slot.position = slot.position
		_active_slot.size = slot.size
		_active_slot.show_active(_run.active, _run.active_charge, _run.active_needed(), _active_key)
	_frame.queue_redraw()


# The left panel's top row: the pills as icons, then the coin and Pension, then the Slip and Thermos
# counters, each placed after the last so nothing overlaps however many pills he has.
func _layout_top_row() -> void:
	var x := ITEM_ROW_AT.x
	if _run != null:
		x = PILLS_AT.x + _run.health.max_pills * HudStyle.PILL_STEP + COUNTER_GAP
	_status.position = Vector2(x + 12.0, 5)
	if _run == null:
		return
	var status_width := HudStyle.font().get_string_size(_status.text, HORIZONTAL_ALIGNMENT_LEFT, -1, HudStyle.SMALL).x
	x = _status.position.x + status_width + COUNTER_GAP
	_slip_icon.position = Vector2(x, 3)
	_slips.position = _slip_icon.position + COUNTER_TEXT_OFFSET
	_thermos_icon.position = Vector2(x + COUNTER_STEP, 3)
	_thermoses.position = _thermos_icon.position + COUNTER_TEXT_OFFSET


func left_panel_rect() -> Rect2:
	var end := LEFT_PANEL_MIN_WIDTH
	if _thermoses != null:
		end = maxf(end, _thermoses.position.x + 22.0)
	elif _status != null:
		end = maxf(end, _status.position.x + HudStyle.font().get_string_size(_status.text, HORIZONTAL_ALIGNMENT_LEFT, -1, HudStyle.SMALL).x + 8.0)
	return Rect2(LEFT_PANEL_AT, Vector2(end, 34))


# Draws the panels and the icons that are not nodes of their own: the pills and the Pension coin.
class HudFrame extends Control:
	var hud: Hud

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(640, 360)

	func _draw() -> void:
		if hud == null or hud._status == null:
			return
		HudStyle.draw_panel(self, hud.left_panel_rect())
		if hud._run != null:
			HudStyle.draw_panel(self, RIGHT_PANEL)
			var health := hud._run.health
			for i in health.max_pills:
				HudStyle.draw_pill(self, PILLS_AT + Vector2(i * HudStyle.PILL_STEP, 0), i < health.pills)
		HudStyle.draw_coin(self, hud._status.position + Vector2(-12, 0))
		if hud._boss_back != null and hud._boss_back.visible:
			HudStyle.draw_panel(self, Rect2(hud._boss_back.position - Vector2(4, 4), BOSS_BAR_SIZE + Vector2(8, 8)))


# The small map's panel, on its own so it fades with the map.
class MapBack extends Control:
	var hud: Hud

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(640, 360)

	func _draw() -> void:
		if hud != null and hud._run != null:
			HudStyle.draw_panel(self, MAP_PANEL)

class_name Hud
extends CanvasLayer

const BOSS_BAR_SIZE := Vector2(480, 10)
const BOSS_BAR_TOP := 336.0
const BOSS_NAME_TOP := 314.0
const SLIP_COUNTER_AT := Vector2(300, 5)
const THERMOS_COUNTER_AT := Vector2(360, 5)
const POTION_SLOT_AT := Vector2(414, 5)
const COUNTER_TEXT_OFFSET := Vector2(15, -2)
const NOTICE_TOP := 40.0
const NOTICE_TIME := 3.5
# A faint band behind the top row, so full pills never read as empty over a pale floor.
const TOP_BAND_SIZE := Vector2(640, 22)
const TOP_BAND := Color(0.0, 0.0, 0.0, 0.4)
# The Game tab's run timer, on the top row in the gap before the Slip counter, right-aligned to it,
# since the small map's floor name holds the row's right end.
const TIMER_AT := Vector2(250, 5)
const TIMER_WIDTH := 44.0
const TIMER_FONT := 10

var _run: RunState
var _status: Label
var _items: Label
var _slips: Label
var _thermoses: Label
var _potion_slot: PotionSlot
var _potion_label := ""
var _message: Label
var _notice: Label
var _notice_left := 0.0
var _boss_name: Label
var _boss_back: ColorRect
var _boss_fill: ColorRect
var _boss_max_hp := 1.0
var _pension := 0
var _condolences := 0
# The Waiting Room shows Condolences beside Pension. A run shows Pension only, plus a pop-up when
# Condolences are earned.
var show_condolences := false
# Set from the Game tab's Show run timer. Only a run's HUD has the timer.
var show_timer := false
var _timer: Label


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
	_add_rect(Vector2.ZERO, TOP_BAND_SIZE, TOP_BAND)
	_status = _add_label(Vector2(8, 4), 12)
	_items = _add_label(Vector2(8, 22), 9)
	_message = _add_label(Vector2(0, 150), 20)
	_message.size = Vector2(640, 40)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice = _add_label(Vector2(0, NOTICE_TOP), 12)
	_notice.size = Vector2(640, 20)
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name = _add_label(Vector2(0, BOSS_NAME_TOP), 16)
	_boss_name.size = Vector2(640, 20)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var left := (640.0 - BOSS_BAR_SIZE.x) / 2.0
	_boss_back = _add_rect(Vector2(left, BOSS_BAR_TOP), BOSS_BAR_SIZE, Color("1a1214"))
	_boss_fill = _add_rect(Vector2(left, BOSS_BAR_TOP), BOSS_BAR_SIZE, Color("e4524f"))
	hide_boss_bar()
	if _run != null:
		_slips = _add_counter(SLIP_COUNTER_AT, ConsumableIcon.Kind.SLIP)
		_thermoses = _add_counter(THERMOS_COUNTER_AT, ConsumableIcon.Kind.THERMOS)
		_potion_slot = PotionSlot.new()
		_potion_slot.position = POTION_SLOT_AT
		add_child(_potion_slot)
		_run.changed.connect(_refresh)
		_timer = _add_label(TIMER_AT, TIMER_FONT)
		_timer.size = Vector2(TIMER_WIDTH, 12)
		_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_timer.visible = show_timer
	_refresh()


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
	_notice.text = text
	_notice_left = NOTICE_TIME


func _process(delta: float) -> void:
	# The potion slot names the active device's button, so it follows a switch of device.
	if _run != null and _potion_slot != null and KeyBindings.prompt_label("potion") != _potion_label:
		_refresh()
	if _potion_slot != null:
		_potion_slot.show_buff(_run.buff, _run.buff_left)
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


func set_boss_health(hp: float) -> void:
	_boss_fill.size.x = BOSS_BAR_SIZE.x * bar_fraction(hp, _boss_max_hp)


func hide_boss_bar() -> void:
	_boss_name.visible = false
	_boss_back.visible = false
	_boss_fill.visible = false


func is_boss_bar_visible() -> bool:
	return _boss_back != null and _boss_back.visible


func _add_counter(at: Vector2, kind: ConsumableIcon.Kind) -> Label:
	var icon := ConsumableIcon.new()
	icon.setup(kind)
	icon.position = at
	add_child(icon)
	return _add_label(at + COUNTER_TEXT_OFFSET, 12)


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
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	return label


func _refresh() -> void:
	var text := status_text(_pension, _condolences, show_condolences)
	if _run != null:
		var pills := "■".repeat(_run.health.pills) + "□".repeat(_run.health.max_pills - _run.health.pills)
		text = "Pills: %s   %s" % [pills, text]
		_slips.text = counter_text(_run.keys)
		_thermoses.text = counter_text(_run.bombs)
		_potion_label = KeyBindings.prompt_label("potion")
		_potion_slot.show_potion(_run.potion, _potion_label)
		var names: PackedStringArray = []
		for item in _run.items:
			names.append(item.display_name)
		_items.text = ", ".join(names)
	_status.text = text

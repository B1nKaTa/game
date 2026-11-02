class_name RetirementStation
extends BreakableBlock

signal deposit_wanted(amount: int)
signal blasted

const DEPOSIT_STEP := 10
const REPEAT_TIME := 0.1
const USE_RADIUS := 48.0
const FILL_COLOR := Color("5d4a8c")
const TEXT_COLOR := Color("ece9e0")
const PROMPT_COLOR := Color("ffd24a")
const PROMPT := "Pay in 10 (hold)"

var _bank: Node
var _feet: Node2D
var _repeat_left := 0.0
var _near := false


static func status_lines(balance: int, next_tier: int, can_release: bool) -> PackedStringArray:
	var next_line := "All rewards earned" if next_tier == -1 else "Next reward at %d" % next_tier
	var state_line := "Empty"
	if can_release:
		state_line = "Bomb it to cash out"
	elif balance > 0:
		state_line = "Locked until your next run"
	return PackedStringArray(["Retirement Plan: %d / %d" % [balance, ProgressData.RETIREMENT_CAP], next_line, state_line])


func setup(bank: Node, feet: Node2D) -> void:
	_bank = bank
	_feet = feet


func can_break_by(_source: String) -> bool:
	return false


# Blasts do not destroy the plan. They crack it open if it is ready to pay out.
func take_blast() -> void:
	blasted.emit()


func _process(delta: float) -> void:
	queue_redraw()
	_repeat_left = maxf(_repeat_left - delta, 0.0)
	if not is_instance_valid(_feet):
		return
	_near = global_position.distance_to(_feet.global_position) <= USE_RADIUS
	if _near and Input.is_action_pressed("interact") and _repeat_left <= 0.0:
		_repeat_left = REPEAT_TIME
		deposit_wanted.emit(DEPOSIT_STEP)


func _draw() -> void:
	var half := RoomBackdrop.TILE / 2.0
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), FILL_COLOR)
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), Color.BLACK, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-6, 7), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, TEXT_COLOR)
	if _bank == null:
		return
	var data: ProgressData = _bank.data
	var lines := status_lines(data.retirement_balance, data.next_retirement_tier(), data.can_release_retirement())
	for i in lines.size():
		draw_string(ThemeDB.fallback_font, Vector2(-60, -48.0 + i * 11.0), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, TEXT_COLOR)
	if _near:
		draw_string(ThemeDB.fallback_font, Vector2(-60, 28), KeyBindings.with_key("interact", PROMPT), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PROMPT_COLOR)

class_name PadFocus
extends Node

# Controller focus for one panel. Every panel adds one as its last child, and it treats its parent as
# the panel. While a pad plays, or once a focus key is pressed, a control in the panel always has
# focus: the first enabled one when the panel opens, and the one in the same place after the panel
# rebuilds its list. The D-pad and left stick move between the panel's own controls only, along
# neighbours worked out here from where they are drawn, so focus never wanders to a panel behind.
# Plain buttons get a gold edge while focused; menu buttons keep their gold bar. Shoulder buttons (and
# Q / E where the panel says) call tabs, where a panel has tabs.

# Called with -1 or +1 when LB or RB is pressed, where the panel has tabs.
var tabs := Callable()
# Buttons take focus only while a pad plays, as on the card tables, where a mouse click must never
# leave a bet button focused for Space to press again.
var pad_only := false

var _index := 0
var _had_focus := false
var _count := -1


static func focusables(root: Node) -> Array[Control]:
	var list: Array[Control] = []
	_collect(root, list)
	return list


static func _collect(node: Node, list: Array[Control]) -> void:
	for child in node.get_children():
		# A box asked over the panel (a CanvasLayer such as ConfirmBox) has focus of its own.
		if child is CanvasLayer or child.is_queued_for_deletion():
			continue
		if child is Control:
			var control := child as Control
			if not control.visible:
				continue
			if control.focus_mode != Control.FOCUS_NONE:
				list.append(control)
		_collect(child, list)


static func first_of(list: Array[Control]) -> Control:
	for control in list:
		if not (control is BaseButton and (control as BaseButton).disabled):
			return control
	return list[0] if not list.is_empty() else null


static func refocus_index(index: int, count: int) -> int:
	if count <= 0:
		return -1
	return clampi(index, 0, count - 1)


# The control the D-pad reaches from rects[from] going dir, or -1. Up and down reach any row the way
# they point, the nearest in line first, so a Leave button far to the left still sits under a list.
# Left and right only reach controls on about the same line.
static func neighbour(rects: Array[Rect2], from: int, dir: Vector2) -> int:
	var a := rects[from]
	var best := -1
	var best_score := INF
	for i in rects.size():
		if i == from:
			continue
		var b := rects[i]
		var forward := (b.get_center() - a.get_center()).dot(dir)
		if forward <= 1.0:
			continue
		var side_gap := 0.0
		if dir.x == 0.0:
			side_gap = maxf(0.0, maxf(a.position.x, b.position.x) - minf(a.end.x, b.end.x))
		else:
			side_gap = maxf(0.0, maxf(a.position.y, b.position.y) - minf(a.end.y, b.end.y))
			if side_gap > 8.0:
				continue
		var score := forward + side_gap * 3.0
		if score < best_score:
			best_score = score
			best = i
	return best


static func focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = MenuStyle.GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.expand_margin_left = 1
	style.expand_margin_right = 1
	style.expand_margin_top = 1
	style.expand_margin_bottom = 1
	return style


# Gives every plain button the gold edge. A button styled with its own focus look keeps it.
static func style_all(list: Array[Control]) -> void:
	for control in list:
		if control is Button and not control.has_theme_stylebox_override("focus"):
			control.add_theme_stylebox_override("focus", focus_style())


func _process(_delta: float) -> void:
	var panel := get_parent()
	if panel == null:
		return
	if pad_only:
		_set_modes(panel, Control.FOCUS_ALL if ActiveDevice.using_pad else Control.FOCUS_NONE)
	var list := focusables(panel)
	if list.size() != _count:
		_count = list.size()
		_follow_scrolls(panel)
	style_all(list)
	_link(list)
	_keep_focus(panel, list)
	if tabs.is_valid():
		if Input.is_action_just_pressed(PadInput.TAB_PREV_ACTION):
			tabs.call(-1)
		elif Input.is_action_just_pressed(PadInput.TAB_NEXT_ACTION):
			tabs.call(1)


func _keep_focus(panel: Node, list: Array[Control]) -> void:
	if list.is_empty():
		return
	var owner := get_viewport().gui_get_focus_owner()
	if owner != null and is_instance_valid(owner) and owner.is_visible_in_tree() and not owner.is_queued_for_deletion():
		var at := list.find(owner)
		if at >= 0:
			_index = at
			_had_focus = true
		# Focus anywhere else that is shown belongs to whatever holds it: a box over this panel, or a
		# panel over this one.
		return
	var asked := ActiveDevice.using_pad
	for action in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		asked = asked or Input.is_action_just_pressed(action)
	if not asked:
		return
	var target := list[refocus_index(_index, list.size())] if _had_focus else first_of(list)
	if panel.is_inside_tree() and target.is_inside_tree():
		target.grab_focus()
		_had_focus = true


# Sets each control's neighbours to the panel's own controls, and to itself where there is none, so
# the D-pad stops at the panel's edge.
func _link(list: Array[Control]) -> void:
	var rects: Array[Rect2] = []
	for control in list:
		rects.append(control.get_global_rect())
	var count := list.size()
	for i in count:
		var control := list[i]
		_set_neighbour(control, SIDE_TOP, list, neighbour(rects, i, Vector2.UP))
		_set_neighbour(control, SIDE_BOTTOM, list, neighbour(rects, i, Vector2.DOWN))
		_set_neighbour(control, SIDE_LEFT, list, neighbour(rects, i, Vector2.LEFT))
		_set_neighbour(control, SIDE_RIGHT, list, neighbour(rects, i, Vector2.RIGHT))
		var next := control.get_path_to(list[(i + 1) % count])
		var previous := control.get_path_to(list[(i - 1 + count) % count])
		if control.focus_next != next:
			control.focus_next = next
		if control.focus_previous != previous:
			control.focus_previous = previous


func _set_neighbour(control: Control, side: Side, list: Array[Control], index: int) -> void:
	var path := control.get_path_to(list[index] if index >= 0 else control)
	if control.get_focus_neighbor(side) != path:
		control.set_focus_neighbor(side, path)


static func _set_modes(node: Node, mode: Control.FocusMode) -> void:
	for child in node.get_children():
		if child is CanvasLayer:
			continue
		if child is BaseButton and child.focus_mode != mode:
			child.focus_mode = mode
		_set_modes(child, mode)


static func _follow_scrolls(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasLayer:
			continue
		if child is ScrollContainer:
			child.follow_focus = true
		_follow_scrolls(child)

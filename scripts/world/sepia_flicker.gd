class_name SepiaFlicker
extends CanvasLayer

# The cinema screen's film look over the room for a moment, as a memory starts or ends. It sits on
# layer 0, after the room's own canvas (a CanvasLayer stacks by layer, then by its index in its parent,
# and the room's canvas is layer 0, index 0) and under the HUD's layer 1, so the HUD stays in colour.

const SHADER := preload("res://scripts/world/sepia_flicker.gdshader")
const TIME := 0.6
const LAYER := 0

var _rect: ColorRect
var _left := TIME


static func play(parent: Node) -> void:
	if parent == null or not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	parent.add_child(SepiaFlicker.new())


func _ready() -> void:
	if _rect != null:
		return
	layer = LAYER
	# A pause mid-flicker never leaves the screen in sepia under the pause menu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	_rect.material = mat
	add_child(_rect)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	var t := 1.0 - _left / TIME
	var mat := _rect.material as ShaderMaterial
	mat.set_shader_parameter("strength", sin(t * PI))
	mat.set_shader_parameter("flicker", 0.12 * sin(t * 70.0))

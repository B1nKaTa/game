class_name Vignette
extends Node2D

# The depth look's vignette: the view darkens toward its edges, so the light falls off toward the room's
# walls. It follows the view each frame by moving, never by redrawing. It sits over the floor and under
# every body, prop, shot and warning (DepthLook.VIGNETTE_Z), and draws unshaded so the room's light never
# lifts it.
const SIZE := Vector2i(160, 90)
const VIEW := Vector2(640, 360)

static var _texture: ImageTexture


static func shade() -> ImageTexture:
	if _texture == null:
		var image := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
		for y in SIZE.y:
			for x in SIZE.x:
				var d := Vector2((x + 0.5) / SIZE.x - 0.5, (y + 0.5) / SIZE.y - 0.5) * 2.0
				var r := d.length()
				var a := clampf((r - 0.55) / 0.75, 0.0, 1.0)
				image.set_pixel(x, y, Color(0.02, 0.01, 0.03, a * a * DepthLook.VIGNETTE_STRENGTH))
		_texture = ImageTexture.create_from_image(image)
	return _texture


func _ready() -> void:
	z_index = DepthLook.VIGNETTE_Z
	z_as_relative = false
	material = DepthLook.unshaded()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_follow()


func _process(_delta: float) -> void:
	_follow()


func _follow() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var view := viewport.get_visible_rect().size
	global_position = viewport.get_canvas_transform().affine_inverse() * (view / 2.0)


func _draw() -> void:
	draw_texture_rect(shade(), Rect2(-VIEW / 2.0 - Vector2(8, 8), VIEW + Vector2(16, 16)), false)

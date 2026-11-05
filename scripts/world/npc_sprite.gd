class_name NpcSprite
extends Node2D

# Someone's own art, from res://art/npcs/<art id>/: idle.png, a strip of 48 px frames of him standing
# facing south, and rotations.png, the eight ways he can face, from south round through east to
# south-west. His feet stand on this node's origin. Without both strips setup says no, and Npc draws
# its placeholder instead.

const FRAME := 48
# 125 ms a frame.
const IDLE_FPS := 8.0
const DIRECTIONS := 8
const SOUTH := 0
const FOLDER := "res://art/npcs/%s/"

# How far the top of his head rises above his feet, so a name can sit over it.
var height := float(FRAME)
var facing := SOUTH
var _sprite: Sprite2D
var _idle: Texture2D
var _turns: Texture2D
var _idle_feet := FRAME
var _turn_feet := FRAME
var _time := 0.0


static func idle_path(art_id: String) -> String:
	return (FOLDER % art_id) + "idle.png"


static func rotations_path(art_id: String) -> String:
	return (FOLDER % art_id) + "rotations.png"


static func has_art(art_id: String) -> bool:
	if art_id.is_empty():
		return false
	return ResourceLoader.exists(idle_path(art_id)) and ResourceLoader.exists(rotations_path(art_id))


# Which of the eight rotations looks along to (0 south, 2 east, 4 north, 6 west). Nothing to look at
# faces south.
static func direction(to: Vector2) -> int:
	if to.length_squared() < 0.001:
		return SOUTH
	var step := int(roundf(rad_to_deg(to.angle()) / 45.0))
	return posmod(2 - step, DIRECTIONS)


static func idle_frame(time: float, count: int) -> int:
	return int(time * IDLE_FPS) % maxi(count, 1)


# The rows a strip's art takes up, end exclusive: the lowest is where the feet are. The whole frame
# when the pixels can't be read.
static func used_rows(texture: Texture2D) -> Vector2i:
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		return Vector2i(0, FRAME)
	if image.is_compressed():
		image.decompress()
	var used := image.get_used_rect()
	if used.size.y <= 0:
		return Vector2i(0, FRAME)
	return Vector2i(used.position.y, used.end.y)


func setup(art_id: String) -> bool:
	if not has_art(art_id):
		return false
	_idle = load(idle_path(art_id))
	_turns = load(rotations_path(art_id))
	if _idle == null or _turns == null:
		return false
	var idle_rows := used_rows(_idle)
	var turn_rows := used_rows(_turns)
	_idle_feet = idle_rows.y
	_turn_feet = turn_rows.y
	height = float(maxi(idle_rows.y - idle_rows.x, turn_rows.y - turn_rows.x))
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_show()
	return true


func idle_frames() -> int:
	return frames_in(_idle)


func rotation_frames() -> int:
	return frames_in(_turns)


static func frames_in(texture: Texture2D) -> int:
	return maxi(texture.get_width() / FRAME, 1) if texture != null else 0


func texture() -> Texture2D:
	return _sprite.texture if _sprite != null else null


func frame() -> int:
	return _sprite.frame if _sprite != null else -1


# Turns him toward to (a spot relative to him). South plays his idle loop, the rest hold a rotation.
func face(to: Vector2) -> void:
	set_facing(direction(to))


func set_facing(way: int) -> void:
	if way == facing:
		return
	facing = way
	_show()


func _process(delta: float) -> void:
	_time += delta
	if _sprite != null and facing == SOUTH:
		_sprite.frame = idle_frame(_time, _sprite.hframes)


func _show() -> void:
	if _sprite == null:
		return
	var idle := facing == SOUTH
	_sprite.texture = _idle if idle else _turns
	_sprite.hframes = frames_in(_sprite.texture)
	_sprite.frame = idle_frame(_time, _sprite.hframes) if idle else facing
	_sprite.offset = Vector2(-FRAME / 2.0, -float(_idle_feet if idle else _turn_feet))

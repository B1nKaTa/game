class_name SpriteVisual
extends Node2D

const FPS := 10.0

var _art_id := ""
var _size := Vector2(20, 24)
var _color := Color.WHITE
var _frame_width := 32
var _anim := ""
var _sprite: Sprite2D
var _time := 0.0


static func frame_count(texture_width: int, frame_width: int) -> int:
	if frame_width <= 0:
		return 1
	return maxi(texture_width / frame_width, 1)


func setup(art_id: String, body_size: Vector2, color: Color, frame_width: int) -> void:
	_art_id = art_id
	_size = body_size
	_color = color
	_frame_width = frame_width
	play("idle")


func play(anim: String) -> void:
	if anim == _anim:
		return
	_anim = anim
	_time = 0.0
	var path := "res://art/sprites/%s/%s.png" % [_art_id, anim]
	if not ResourceLoader.exists(path):
		if _sprite != null:
			_sprite.visible = false
		queue_redraw()
		return
	if _sprite == null:
		_sprite = Sprite2D.new()
		add_child(_sprite)
	var texture: Texture2D = load(path)
	_sprite.texture = texture
	_sprite.hframes = frame_count(texture.get_width(), _frame_width)
	_sprite.frame = 0
	_sprite.visible = true
	queue_redraw()


func set_facing_left(left: bool) -> void:
	if _sprite != null:
		_sprite.flip_h = left


func _process(delta: float) -> void:
	if _sprite == null or not _sprite.visible:
		return
	_time += delta
	_sprite.frame = int(_time * FPS) % _sprite.hframes


func _draw() -> void:
	if _sprite != null and _sprite.visible:
		return
	draw_rect(Rect2(-_size / 2.0, _size), _color)
	draw_rect(Rect2(-_size / 2.0, _size), Color.BLACK, false, 1.0)

class_name DeathBurst
extends Node2D

const DURATION := 0.35
const SMALL_COUNT := 8
const BOSS_COUNT := 20
const SMALL_RADIUS := 22.0
const BOSS_RADIUS := 56.0
const PARTICLE_SIZE := 3.0

var _color := Color.WHITE
var _big := false
var _time := 0.0


static func progress_radius(time: float, max_radius: float) -> float:
	var t := clampf(time / DURATION, 0.0, 1.0)
	return max_radius * (1.0 - (1.0 - t) * (1.0 - t))


static func progress_alpha(time: float) -> float:
	return 1.0 - clampf(time / DURATION, 0.0, 1.0)


static func particle_count(big: bool) -> int:
	return BOSS_COUNT if big else SMALL_COUNT


static func max_radius(big: bool) -> float:
	return BOSS_RADIUS if big else SMALL_RADIUS


static func spawn(parent: Node, at: Vector2, color: Color, big: bool) -> void:
	var burst := DeathBurst.new()
	burst.setup(color, big)
	parent.add_child(burst)
	burst.position = at


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(color: Color, big: bool) -> void:
	_color = color
	_big = big


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var count := particle_count(_big)
	var radius := progress_radius(_time, max_radius(_big))
	var color := _color
	color.a = progress_alpha(_time)
	var size := PARTICLE_SIZE * (2.0 if _big else 1.0)
	for i in count:
		var angle := TAU * i / float(count) + (0.4 if i % 2 == 0 else 0.0)
		var reach := radius * (1.0 if i % 2 == 0 else 0.65)
		draw_rect(Rect2(Vector2.from_angle(angle) * reach - Vector2(size, size) / 2.0, Vector2(size, size)), color)

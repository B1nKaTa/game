class_name ReelChange
extends Node2D

# The reel the Projectionist has just laced up, and the room hazard it brings for TIME seconds: a rain
# reel (the floor wet all over, slippery by the wet floor's own rules, with rain streaking down the
# picture of the room), a silent comedy (custard pies thrown down warned lanes) or a western
# (tumbleweeds rolling along warned rows). The pies and tumbleweeds are ReelLanes he throws in while the
# reel runs; this node only keeps the reel's time and draws its rain. It never repeats the reel before.
# It goes when its time is up or he falls.
enum Genre { RAIN, COMEDY, WESTERN }

const TIME := 8.0
const RAIN_Z := 50
const RAIN := Color(0.78, 0.86, 1.0, 0.22)
const RAIN_DROPS := 70
const RAIN_SPEED := 340.0
const RAIN_LENGTH := 10.0

var genre := Genre.RAIN
var _source: Enemy
var _left := TIME
var _area := Rect2()
var _clock := 0.0


# Any reel but the one before; the first is any of the three.
static func next_genre(last: int, roll: float) -> int:
	var options: Array[int] = []
	for kind in [Genre.RAIN, Genre.COMEDY, Genre.WESTERN]:
		if kind != last:
			options.append(kind)
	return options[mini(int(roll * options.size()), options.size() - 1)]


static func title(kind: int) -> String:
	match kind:
		Genre.RAIN:
			return "Rain reel!"
		Genre.COMEDY:
			return "A silent comedy!"
	return "A western!"


# area is the room's floor in room space, where the rain falls.
func setup(source: Enemy, kind: int, area: Rect2, seconds := TIME) -> void:
	_source = source
	genre = kind
	_area = area
	_left = seconds
	z_index = RAIN_Z
	z_as_relative = false


func time_left() -> float:
	return maxf(_left, 0.0)


func is_running() -> bool:
	return _left > 0.0


# Moves its clock on. True once, as it ends.
func advance(delta: float) -> bool:
	if _left <= 0.0:
		return false
	_left -= delta
	_clock += delta
	return _left <= 0.0


# A reel itself hurts no one: its pies and tumbleweeds answer for themselves.
func threat_at(_p: Vector2, _strict: bool) -> int:
	return 0


func threat_imminent(_p: Vector2) -> bool:
	return false


func _process(delta: float) -> void:
	queue_redraw()
	if not is_instance_valid(_source) or _source.is_dead():
		queue_free()
		return
	if advance(delta):
		queue_free()


func _draw() -> void:
	if genre != Genre.RAIN or not _area.has_area():
		return
	var fade := clampf(minf(_left, TIME - _left + 0.3) / 0.6, 0.0, 1.0)
	var origin := _area.position - global_position
	for i in RAIN_DROPS:
		var x := fposmod(i * 73.0 + i * i * 0.37, _area.size.x)
		var y := fposmod(i * 41.0 + _clock * RAIN_SPEED * (0.8 + 0.4 * float(i % 3) / 2.0), _area.size.y)
		var at := origin + Vector2(x, y)
		draw_line(at, at + Vector2(-2.0, RAIN_LENGTH), Color(RAIN, RAIN.a * fade), 1.0)

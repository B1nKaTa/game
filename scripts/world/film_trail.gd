class_name FilmTrail
extends Node2D

# The strip of film a Runaway Film Reel unspools behind it as it rolls: dark film with sprocket holes
# along both edges, laid on the floor piece by piece. It never hurts, but while Grandpa's feet are on it
# he is slowed, as on the Paper Shredder's trail, and each piece fades away LINGER seconds after it was
# laid. It lies at the room's origin, with each piece where it fell.
const LINGER := 4.0
const FADE := 0.6
# Each piece is this long along the way the reel rolled and this wide across it.
const PIECE := 12.0
const WIDTH := 12.0
const MOST_PIECES := 64
const SLOW := 0.35
const SLOW_TIME := 0.4
# How often a slow is laid on him while he stands on it, so a long stand never piles slows up.
const SLOW_EVERY := 0.2
const FILM := Color(0.07, 0.06, 0.05)
const FILM_EDGE := Color(0.32, 0.28, 0.2)
const SPROCKET := Color(0.78, 0.74, 0.62)
const Z := -8
# Each piece's picture (art/props/film_piece.png): a strip of PIECE_TURNS pre-drawn turns over half a
# turn, the one nearest the way it rolled drawn upright; the drawing stays for when it is missing.
const ART := "film_piece"
const PIECE_TURNS := 4

# Each piece is [where, the way it runs, its age].
var _pieces: Array = []
var _target: Node2D
var _slow_wait := 0.0
# What unspools it. Once that is gone and the last piece fades, the trail goes too.
var _source: Node


# Whether a point lies on a piece laid at at, running along way.
static func covers_piece(at: Vector2, way: Vector2, point: Vector2) -> bool:
	var offset := point - at
	return absf(offset.dot(way)) <= PIECE / 2.0 and absf(offset.dot(way.orthogonal())) <= WIDTH / 2.0


func setup(target: Node2D, source: Node = null) -> void:
	_target = target
	_source = source
	z_index = Z


func add_piece(at: Vector2, way: Vector2) -> void:
	_pieces.append([at, way.normalized(), 0.0])
	while _pieces.size() > MOST_PIECES:
		_pieces.remove_at(0)
	queue_redraw()


func piece_count() -> int:
	return _pieces.size()


func covers(point: Vector2, margin := 0.0) -> bool:
	for piece: Array in _pieces:
		if piece[2] < LINGER and covers_piece(piece[0], piece[1], point if margin <= 0.0 else _toward(piece[0], point, margin)):
			return true
	return false


# A point pulled toward a piece by margin, so covers can ask with some room to spare.
static func _toward(at: Vector2, point: Vector2, margin: float) -> Vector2:
	var offset := point - at
	return at + offset.limit_length(maxf(offset.length() - margin, 0.0))


# Ages every piece, drops the faded ones, and says whether a slow is due on someone standing at point.
func advance(delta: float, point: Vector2) -> bool:
	for piece: Array in _pieces:
		piece[2] += delta
	while not _pieces.is_empty() and _pieces[0][2] >= LINGER:
		_pieces.remove_at(0)
	_slow_wait = maxf(_slow_wait - delta, 0.0)
	if _slow_wait > 0.0 or not covers(point):
		return false
	_slow_wait = SLOW_EVERY
	return true


# What it means for a point, for a simulated player: 1 on the film, which slows, else 0.
func threat_at(p: Vector2, strict: bool) -> int:
	return 1 if covers(p, 6.0 if strict else 0.0) else 0


func threat_imminent(_p: Vector2) -> bool:
	return false


func is_fed() -> bool:
	return is_instance_valid(_source) and not (_source.has_method("is_dead") and _source.is_dead())


func _process(delta: float) -> void:
	queue_redraw()
	var feet := Vector2.INF
	if is_instance_valid(_target):
		feet = _target.feet().global_position if _target.has_method("feet") else _target.global_position
	if advance(delta, feet) and is_instance_valid(_target) and _target.has_method("slow"):
		_target.slow(SLOW, SLOW_TIME)
	if _pieces.is_empty() and not is_fed():
		queue_free()


func _draw() -> void:
	for piece: Array in _pieces:
		var at: Vector2 = piece[0] - global_position
		var way: Vector2 = piece[1]
		var fade := clampf((LINGER - float(piece[2])) / FADE, 0.0, 1.0)
		var art := PropArt.texture(ART)
		if art != null:
			PropArt.draw_frame(self, art, PropArt.turn_frame(way.angle(), PIECE_TURNS, PI), at, Color(1, 1, 1, fade))
			continue
		draw_set_transform(at, way.angle())
		draw_rect(Rect2(-PIECE / 2.0 - 0.5, -WIDTH / 2.0, PIECE + 1.0, WIDTH), Color(FILM, 0.92 * fade))
		draw_line(Vector2(-PIECE / 2.0, -WIDTH / 2.0), Vector2(PIECE / 2.0, -WIDTH / 2.0), Color(FILM_EDGE, fade), 1.0)
		draw_line(Vector2(-PIECE / 2.0, WIDTH / 2.0), Vector2(PIECE / 2.0, WIDTH / 2.0), Color(FILM_EDGE, fade), 1.0)
		for x in [-3.5, 2.5]:
			draw_rect(Rect2(x, -WIDTH / 2.0 + 1.5, 2.0, 2.0), Color(SPROCKET, fade))
			draw_rect(Rect2(x, WIDTH / 2.0 - 3.5, 2.0, 2.0), Color(SPROCKET, fade))
		# A faint frame line across the middle of every piece.
		draw_line(Vector2(0.0, -WIDTH / 2.0 + 4.0), Vector2(0.0, WIDTH / 2.0 - 4.0), Color(FILM_EDGE, 0.6 * fade), 1.0)
	draw_set_transform(Vector2.ZERO)

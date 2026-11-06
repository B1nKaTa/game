class_name EctoplasmTrail
extends Node2D

# The sticky trail an Ectoplasm leaves as it oozes: round blobs of deep dark green goo laid behind it, a
# short trail of at most MOST_PIECES. It never hurts, but while Grandpa's feet are on it he is slowed,
# as on a Film Reel's film, and each blob fades LINGER seconds after it was laid. Its green is the
# palette's ectoplasm, far darker than the safe-spot mint. It lies at the room's origin.
const LINGER := 2.5
const FADE := 0.5
const RADIUS := 7.0
const MOST_PIECES := 10
const SLOW := 0.35
const SLOW_TIME := 0.4
const SLOW_EVERY := 0.2
# RoomPalette.ectoplasm's own value, so the goo matches the hotline wherever it oozes.
const GOO := Color("1f6b45")
const GOO_SHINE := Color(0.45, 0.75, 0.55, 0.5)
const GOO_EDGE := Color(0.04, 0.16, 0.1)
# Each blob's picture (art/props/ectoplasm.png, 16 px), drawn 1:1 and fading; the drawing stays for when
# it is missing.
const ART := "ectoplasm"
const Z := -8

# Each piece is [where, its age].
var _pieces: Array = []
var _target: Node2D
var _slow_wait := 0.0
var _source: Node


func setup(target: Node2D, source: Node = null) -> void:
	_target = target
	_source = source
	z_index = Z


func add_piece(at: Vector2) -> void:
	_pieces.append([at, 0.0])
	while _pieces.size() > MOST_PIECES:
		_pieces.remove_at(0)
	queue_redraw()


func piece_count() -> int:
	return _pieces.size()


func covers(point: Vector2, margin := 0.0) -> bool:
	for piece: Array in _pieces:
		if piece[1] < LINGER and (piece[0] as Vector2).distance_to(point) <= RADIUS + margin:
			return true
	return false


# Ages every piece, drops the faded ones, and says whether a slow is due on someone standing at point.
func advance(delta: float, point: Vector2) -> bool:
	for piece: Array in _pieces:
		piece[1] += delta
	while not _pieces.is_empty() and _pieces[0][1] >= LINGER:
		_pieces.remove_at(0)
	_slow_wait = maxf(_slow_wait - delta, 0.0)
	if _slow_wait > 0.0 or not covers(point):
		return false
	_slow_wait = SLOW_EVERY
	return true


# What it means for a point, for a simulated player: 1 on the goo, which slows, else 0.
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
		var fade := clampf((LINGER - float(piece[1])) / FADE, 0.0, 1.0)
		var art := PropArt.texture(ART)
		if art != null:
			draw_texture(art, PropArt.centred(art, at), Color(1, 1, 1, fade))
			continue
		draw_circle(at, RADIUS + 1.0, Color(GOO_EDGE, 0.8 * fade))
		draw_circle(at, RADIUS, Color(GOO, 0.9 * fade))
		draw_circle(at + Vector2(-2.0, -2.0), 2.0, Color(GOO_SHINE, GOO_SHINE.a * fade))

extends EnemyBehavior

const START_RANGE := 46.0
const FUSE := 0.9
const FUSE_CRAWL := 0.25
# Stuck behind something, it gives up and goes off where it stands, so a room can always end.
const RUSH_LIMIT := 12.0
const BLAST_RADIUS := 56.0
const ENEMY_DAMAGE := 30.0
const PUSH := 140.0

var _telegraph := Telegraph.new()
var _rushed := 0.0
var _lit := false
var _gone := false


static func blows_when_killed(lit: bool) -> bool:
	return lit


func tick(enemy: Enemy, delta: float) -> void:
	if _lit:
		enemy.desired_velocity = enemy.direction_to_target() * enemy.def.speed * FUSE_CRAWL
		enemy.blink()
		if _telegraph.tick(delta):
			enemy.clear_warning()
			enemy.self_destruct()
			enemy.take_damage(INF, Vector2.ZERO)
		return
	_rushed += delta
	enemy.desired_velocity = enemy.direction_to_target() * enemy.def.speed
	if enemy.distance_to_target() <= START_RANGE or _rushed >= RUSH_LIMIT:
		_lit = true
		_telegraph.start(FUSE)
		enemy.set_warning(_telegraph, BLAST_RADIUS)


func on_killed(enemy: Enemy) -> void:
	if _gone or not blows_when_killed(_lit):
		return
	_gone = true
	enemy.clear_warning()
	enemy.blast(BLAST_RADIUS, ENEMY_DAMAGE, PUSH)

class_name EraMoves
extends RefCounted

# A younger Harold's moves, on the same buttons. Old Harold has none: for_era("") is null.
# Player builds a fresh one at every set_era, so a football left in a room never holds back the next throw.

const TICKET_ROLL_COOLDOWN := 2.5
const DISC_COOLDOWN := 1.5
const MARROW_COOLDOWN := 2.0

var era := ""
var combo_damage: Array[float] = []
var reach := 0.0
var angle := 0.0
var push := 0.0
var lock_time := 0.2
var dodge_hit_damage := 0.0
var dodge_push := 0.0
var dodge_stun := 0.0
var dodge_length := 1.0
var throw_cooldown := TICKET_ROLL_COOLDOWN
var _ball: EraBall
var _roll_left := 0.0


static func for_era(id: String) -> EraMoves:
	var moves := EraMoves.new()
	moves.era = id
	match id:
		Eras.FOOTBALL:
			# Quick, light kicks: 6 + 6 + 12 over three 0.12 s locks = 67/s, a little over the cane's 63/s.
			moves.combo_damage = [6.0, 6.0, 12.0]
			moves.reach = 34.0
			moves.angle = 70.0
			moves.push = 50.0
			moves.lock_time = 0.12
			# The spin turn hits whoever he passes through.
			moves.dodge_hit_damage = 5.0
			moves.dodge_push = 40.0
		Eras.BUS:
			# One heavy ticket-punch: 25 over a 0.42 s lock = 60/s on paper, under the cane's 63/s, since in
			# play every self swings about once a second between approaches and dodges, so weight per
			# swing, not the lock, sets his pace (bot v12, tuned to about 15% above old Harold in play).
			moves.combo_damage = [25.0]
			moves.reach = 46.0
			moves.angle = 50.0
			moves.push = 150.0
			moves.lock_time = 0.42
			# The shoulder barge knocks them down.
			moves.dodge_hit_damage = 8.0
			moves.dodge_push = 160.0
			moves.dodge_stun = 0.2
			moves.throw_cooldown = TICKET_ROLL_COOLDOWN
		Eras.DANCE:
			# One spin, all round and close: 12 over a 0.14 s lock = 86/s on paper, well over the cane's 63/s,
			# since in play its quick lock is lost to approaches. Bot, 2026-11-11 ("max good 40 0 1 eras"):
			# at 9 damage it read 16% under old Harold (1 batch, 34 rooms); at 12, +16% pooled over 12
			# batches (411 rooms; single batches +8% to +30%).
			moves.combo_damage = [12.0]
			moves.reach = 30.0
			moves.angle = 180.0
			moves.push = 40.0
			moves.lock_time = 0.14
			# The slide runs long and nudges whoever he slides into.
			moves.dodge_hit_damage = 3.0
			moves.dodge_push = 30.0
			moves.dodge_length = 1.3
			moves.throw_cooldown = DISC_COOLDOWN
		Eras.ALLOTMENT:
			# A slow, strong spade thrust well past the cane: 30 over a 0.5 s lock = 60/s on paper. Bot,
			# 2026-11-11 ("max good 40 0 1 eras"): +32% to +36% over old Harold in play at every setting
			# tried (damage 30, 26, 22 at lock 0.5; 26 at lock 0.8 and 1.0), so damage and lock do not move
			# it; its reach probably sets its pace. Left as designed; pulling it to +15% needs a shorter reach.
			moves.combo_damage = [30.0]
			moves.reach = 64.0
			moves.angle = 15.0
			moves.push = 110.0
			moves.lock_time = 0.5
			# A shove with the spade's handle.
			moves.dodge_hit_damage = 6.0
			moves.dodge_push = 120.0
			moves.throw_cooldown = MARROW_COOLDOWN
		_:
			return null
	return moves


# The football waits to be picked up (walked over); the ticket roll waits its cooldown.
func throw_ready() -> bool:
	if era == Eras.FOOTBALL:
		return _ball == null or not is_instance_valid(_ball)
	return _roll_left <= 0.0


func tick(delta: float) -> void:
	_roll_left = maxf(_roll_left - delta, 0.0)


func make_throw(aim: Vector2) -> Node2D:
	if era == Eras.FOOTBALL:
		_ball = EraBall.new()
		_ball.direction = aim
		return _ball
	_roll_left = throw_cooldown
	if era == Eras.DANCE or era == Eras.ALLOTMENT:
		var shot: EraShot = EraShot.for_disc() if era == Eras.DANCE else EraShot.for_marrow()
		shot.direction = aim
		return shot
	var line := TicketLine.new()
	line.direction = aim
	return line

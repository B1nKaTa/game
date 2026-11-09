class_name EraMoves
extends RefCounted

# A younger Harold's moves, on the same buttons. Old Harold has none: for_era("") is null.
# Player builds a fresh one at every set_era, so a football left in a room never holds back the next throw.

const TICKET_ROLL_COOLDOWN := 2.5

var era := ""
var combo_damage: Array[float] = []
var reach := 0.0
var angle := 0.0
var push := 0.0
var lock_time := 0.2
var dodge_hit_damage := 0.0
var dodge_push := 0.0
var dodge_stun := 0.0
var _ball: EraBall
var _roll_left := 0.0


static func for_era(id: String) -> EraMoves:
	var moves := EraMoves.new()
	moves.era = id
	match id:
		Eras.FOOTBALL:
			# Quick, light kicks: 5 + 5 + 10 over three 0.12 s locks = 56/s on paper; his pace (1.45) makes
			# up the rest in play (bot v11).
			moves.combo_damage = [5.0, 5.0, 10.0]
			moves.reach = 34.0
			moves.angle = 70.0
			moves.push = 50.0
			moves.lock_time = 0.12
			# The spin turn hits whoever he passes through.
			moves.dodge_hit_damage = 4.0
			moves.dodge_push = 40.0
		Eras.BUS:
			# One heavy ticket-punch: 24 over a 0.42 s lock = 57/s on paper; its reach and the barge's
			# knockdown make up the rest in play (bot v11).
			moves.combo_damage = [24.0]
			moves.reach = 48.0
			moves.angle = 50.0
			moves.push = 150.0
			moves.lock_time = 0.42
			# The shoulder barge knocks them down.
			moves.dodge_hit_damage = 6.0
			moves.dodge_push = 160.0
			moves.dodge_stun = 0.3
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
	_roll_left = TICKET_ROLL_COOLDOWN
	var line := TicketLine.new()
	line.direction = aim
	return line

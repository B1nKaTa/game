class_name PadRumble
extends RefCounted

# Controller rumble through Input.start_joy_vibration: short and weak for a hit taken, stronger for a
# heavy hit landed, strongest for a boss slam. Only the pad being played with rumbles, and nothing does
# while the Vibration option is off (Settings sets enabled).

const HIT_TAKEN := "hit_taken"
const HEAVY_LANDED := "heavy_landed"
const BOSS_SLAM := "boss_slam"
# Each as (weak motor, strong motor, seconds).
const STRENGTHS := {
	HIT_TAKEN: Vector3(0.35, 0.15, 0.15),
	HEAVY_LANDED: Vector3(0.45, 0.55, 0.18),
	BOSS_SLAM: Vector3(0.6, 0.9, 0.3),
}

static var enabled := true
# The last rumble that played, for the full-loop check.
static var last := ""
# The strength of the rumble playing and when it stops, so a lighter one never cuts it short.
static var _playing := 0.0
static var _until_msec := 0


static func reset() -> void:
	last = ""
	_playing = 0.0
	_until_msec = 0


static func strength(kind: String) -> Vector3:
	return STRENGTHS.get(kind, Vector3.ZERO)


# Returns true when it rumbled.
static func play(kind: String) -> bool:
	var power := strength(kind)
	if not enabled or not ActiveDevice.using_pad or power == Vector3.ZERO:
		return false
	var now := Time.get_ticks_msec()
	if now < _until_msec and power.y < _playing:
		return false
	Input.start_joy_vibration(ActiveDevice.pad_id, power.x, power.y, power.z)
	last = kind
	_playing = power.y
	_until_msec = now + int(power.z * 1000.0)
	return true

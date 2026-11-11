extends ItemEffect

# Civil Servant (set): every fight room cleared has a CHANCE of a Slip where the last enemy fell.
# The full loop counts Slips exactly, so there it drops none.

const CHANCE := 1.0 / 3.0
var rng := RandomNumberGenerator.new()


func on_gain(_ctx: EffectContext) -> void:
	rng.randomize()


func load_state(_state: Dictionary) -> void:
	rng.randomize()


func on_room_clear(ctx: EffectContext, _room: Node, _damage_taken_here: int) -> void:
	if ctx.counting_exact or rng.randf() >= CHANCE:
		return
	var at := ctx.room.last_death_spot() if ctx.has_room() else ctx.feet()
	ctx.drop(RoomRules.DROP_KEY, at)

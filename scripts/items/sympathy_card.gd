extends ItemEffect

# Sympathy Card: clearing a fight room leaves a one-pill heal where its last enemy fell, one time in four.

const CHANCE := 0.25
const PILLS := 1
const COLOR := Color("f2a7c3")

var rng := RandomNumberGenerator.new()
var sent := 0


func on_gain(_ctx: EffectContext) -> void:
	rng.randomize()


func on_room_clear(ctx: EffectContext, room: Node, _damage_taken_here: int) -> void:
	if rng.randf() < CHANCE:
		send(ctx, room)


func send(ctx: EffectContext, room: Node) -> void:
	sent += 1
	var at := ctx.feet()
	if room != null and room.has_method("last_death_spot"):
		at = room.last_death_spot()
	ctx.drop(RoomRules.DROP_HEAL, at, PILLS)
	ctx.add_fx(ItemFx.make_pop("Get well soon", COLOR), at)


# How many cards were sent. A resumed run never hears on_gain, so the dice are shuffled here instead.
func save_state() -> Dictionary:
	return state_of(["sent"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["sent"])
	rng.randomize()

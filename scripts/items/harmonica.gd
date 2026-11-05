extends ItemEffect

# Harmonica: each combo finisher that lands plays a note over his head, and three notes within CHORD_TIME
# make a chord that heals half a pill, once a room.

const CHORD_TIME := 3.0
const NOTES := 3
const COLOR := Color("b7f29a")
const TEXT := "CHORD! +1/2"

var _time := 0.0
var _played: Array[float] = []
var healed := false


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_played.clear()
	healed = false


func tick(_ctx: EffectContext, delta: float) -> void:
	_time += delta


func on_swing_end(ctx: EffectContext, swing: SwingAttack) -> void:
	if swing.finisher and swing.landed_count() > 0:
		play(ctx)


# Plays one note. Returns whether it made the chord that heals.
func play(ctx: EffectContext) -> bool:
	_played = _played.filter(func(at: float) -> bool: return _time - at <= CHORD_TIME)
	_played.append(_time)
	var pitch := mini(_played.size(), NOTES) - 1
	var player_at := ctx.player.global_position if ctx.has_player() else ctx.feet()
	var note := ItemFx.make_note(pitch)
	if ctx.has_player():
		note.ride(ctx.player)
	ctx.add_fx(note, player_at)
	if _played.size() < NOTES or healed:
		return false
	healed = true
	_played.clear()
	ctx.heal_half()
	ctx.add_fx(ItemFx.make_pop(TEXT, COLOR), ctx.feet())
	return true

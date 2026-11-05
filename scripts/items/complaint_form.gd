extends ItemEffect

# Complaint Form: his hits on a boss fill a form over its head, full once they have dealt FILL_SHARE of
# its health, and a full form stuns the boss for STUN. Nothing fills it while the boss is held or for
# REST after, and then it starts empty, so one stun can never run into the next. The full loop fights
# bosses by its own timings, so there nothing fills.

const FILL_SHARE := 0.2
const STUN := 2.0
const REST := 3.0
const COLOR := Color("e0262f")

var _time := 0.0
# Boss instance id -> {"dealt": damage toward the form, "rest_until": time it fills again, "meter": WeakRef}.
var _forms := {}


func tick(_ctx: EffectContext, delta: float) -> void:
	_time += delta
	for key in _forms:
		var form: Dictionary = _forms[key]
		var meter := _meter_of(form)
		if meter == null:
			continue
		meter.filed = _time < float(form["rest_until"]) - REST
		meter.fill = fill_of(form["dealt"], form.get("max", 1.0))


# A form belongs to one room's fight, and leaving the room takes its meter away.
func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_forms.clear()


func on_hit(ctx: EffectContext, enemy: Enemy, amount: float, _source: String) -> void:
	if ctx.counting_exact or enemy.def == null or not enemy.def.is_boss or enemy.is_summon:
		return
	file(ctx, enemy, amount)


# Adds a hit's damage to this boss's form, and stuns it when the form fills. Returns whether it stunned.
func file(ctx: EffectContext, boss: Enemy, amount: float) -> bool:
	var key := boss.get_instance_id()
	if not _forms.has(key):
		_forms[key] = {"dealt": 0.0, "rest_until": -1.0, "max": boss.max_hp(), "meter": null}
		var meter := ItemFx.make_meter(boss, boss.def.body_size.y / 2.0 + 6.0)
		if ctx.add_fx(meter, boss.global_position) != null:
			_forms[key]["meter"] = weakref(meter)
	var form: Dictionary = _forms[key]
	if _time < float(form["rest_until"]):
		return false
	form["dealt"] = float(form["dealt"]) + amount
	if fill_of(form["dealt"], form["max"]) < 1.0:
		return false
	form["dealt"] = 0.0
	form["rest_until"] = _time + STUN + REST
	ctx.stun(boss, STUN)
	ctx.add_fx(ItemFx.make_stamp("COMPLAINT FILED"), boss.global_position)
	ctx.play_sound("ticket_ding")
	return true


# How full a form is, from 0 to 1, for so much damage toward a boss of so much health.
static func fill_of(dealt: float, max_hp: float) -> float:
	return clampf(dealt / maxf(max_hp * FILL_SHARE, 1.0), 0.0, 1.0)


# Whether the form on this boss is resting and fills with nothing.
func is_resting(boss: Enemy) -> bool:
	var form: Dictionary = _forms.get(boss.get_instance_id(), {})
	return not form.is_empty() and _time < float(form["rest_until"])


func _meter_of(form: Dictionary) -> ItemFx.FxMeter:
	var ref: WeakRef = form["meter"]
	if ref == null:
		return null
	var meter := ref.get_ref() as ItemFx.FxMeter
	return meter if meter != null and is_instance_valid(meter) else null

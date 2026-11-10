extends ItemEffect

# A test effect that scales pets' hits.

@export var scale := 2.0


func pet_damage_scale(_ctx: EffectContext) -> float:
	return scale

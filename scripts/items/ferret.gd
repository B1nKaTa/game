extends PetEffect

# Trouser Ferret: every dodge, he leaps out and bites the enemy nearest Harold within REACH for DAMAGE.

const REACH := 120.0
const DAMAGE := 15.0


func on_dodge(ctx: EffectContext, _direction: Vector2) -> void:
	strike(ctx, nearest(ctx, REACH), DAMAGE)

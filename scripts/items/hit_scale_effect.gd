class_name HitScaleEffect
extends ItemEffect

# What the "+N% to all your hits" items share: his own hits (RunEffects.HIS_HITS) are multiplied by
# 1 + bonus(ctx). A pet's bite and the turned Auditor's clipboard are not his hits. The full loop measures
# damage exactly, so there they add nothing.


func bonus(_ctx: EffectContext) -> float:
	return 0.0


func hit_damage(ctx: EffectContext, _enemy: Enemy, amount: float, source: String) -> float:
	if ctx.counting_exact or not RunEffects.is_his_hit(source):
		return amount
	return amount * (1.0 + maxf(bonus(ctx), 0.0))

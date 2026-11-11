extends HitScaleEffect

# Repeat Offender: every rule broken this run makes his hits PER harder, and every Auditor's hit costs
# EXTRA more pills.

const PER := 0.06
const EXTRA := 1


func bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return PER * run.rules_broken if run != null else 0.0


# The full loop counts every pill a hit costs, so there he hits as usual.
func on_auditor(ctx: EffectContext, auditor: Enemy) -> void:
	if ctx.counting_pills:
		return
	auditor.extra_damage += EXTRA

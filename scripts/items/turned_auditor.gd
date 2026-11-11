extends ItemEffect

# Clipboard of Your Own: a broken rule's Auditor fights for Harold instead (AllyAuditor). Fine Print asks
# first, so a let-off break sends nobody.


# The full loop checks a hostile Auditor walks in, so there he stays hostile.
func sides_with_you(ctx: EffectContext) -> bool:
	return not ctx.counting_exact

extends ItemEffect

# Tea Cosy: his own Thermos blasts never cost him a pill. Every other hurt is left as it is.


func on_hurt(_ctx: EffectContext, pills: int, source: String) -> int:
	return 0 if source == RunEffects.HURT_OWN_BLAST else pills

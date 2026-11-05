extends ItemEffect

# Tax Refund: walking out of a shop without buying anything pays a little, once per shop.

const PAY := 15
const NOTICE := "Tax Refund: +%d Pension for buying nothing."

var _last_shop: WeakRef
var _refunded := {}


func on_room_enter(ctx: EffectContext, room: Node) -> void:
	var left: Node = _last_shop.get_ref() if _last_shop != null else null
	_last_shop = null
	if left != null and left != room and is_instance_valid(left):
		leave_shop(ctx, left.get_instance_id(), int(left.get("shop_purchases")))
	if room is RoomView and room.room_type() == RoomLayout.TYPE_SHOP:
		_last_shop = weakref(room)


# Pays for leaving the shop with this key, once, when nothing was bought there. Returns whether it paid.
func leave_shop(ctx: EffectContext, shop_key: int, purchases: int) -> bool:
	if purchases > 0 or _refunded.has(shop_key):
		return false
	_refunded[shop_key] = true
	ctx.pay(PAY)
	ctx.notice(NOTICE % PAY)
	return true

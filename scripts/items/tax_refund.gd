extends ItemEffect

# Tax Refund: walking out of a shop without buying anything pays a little, once per shop.

const PAY := 15
const NOTICE := "Tax Refund: +%d Pension for buying nothing."

var _last_shop: WeakRef
var _refunded := {}


# Shops are known by their room on this floor, so the record starts again with each floor.
func on_floor_start(_ctx: EffectContext) -> void:
	_refunded.clear()


func on_room_enter(ctx: EffectContext, room: Node) -> void:
	var left: Node = _last_shop.get_ref() if _last_shop != null else null
	_last_shop = null
	if left != null and left != room and is_instance_valid(left):
		var key: int = left.room_id() if left.has_method("room_id") else left.get_instance_id()
		leave_shop(ctx, key, int(left.get("shop_purchases")))
	if room is RoomView and room.room_type() == RoomLayout.TYPE_SHOP:
		_last_shop = weakref(room)


# Pays for leaving the shop with this key, once, when nothing was bought there. Returns whether it paid.
func leave_shop(ctx: EffectContext, shop_key: int, purchases: int) -> bool:
	if purchases > 0 or _refunded.has(shop_key):
		return false
	_refunded[shop_key] = true
	ctx.pay(PAY)
	ctx.notice(NOTICE % PAY)
	ctx.play_sound("coin")
	return true


# The shops on this floor that already paid, by room.
func save_state() -> Dictionary:
	return {"refunded": _refunded.keys()}


func load_state(state: Dictionary) -> void:
	var keys: Variant = state.get("refunded", [])
	if keys is Array:
		for key in keys:
			_refunded[int(key)] = true

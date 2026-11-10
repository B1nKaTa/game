extends ItemEffect

# Loose Paperwork: on entering a room he gets a sheet per Slip carried, at most MOST. The sheets circle him
# and each stops one shot (a shot guard round him), and are gone until the next room. The full loop counts
# every pill a shot costs, so there no sheet blocks.

const MOST := 5
const REACH := 20.0
const PAPER := Color("f2ecd8")
var sheets := 0
var _guard: WeakRef
# Kept for has_sheet, which the guard calls with no context. Safe: the run owns this effect, and the
# context holds the run weakly.
var _ctx: EffectContext


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	_ctx = ctx
	var run := ctx.run()
	sheets = mini(run.keys, MOST) if run != null else 0
	var guard := PaperSheets.new()
	guard.radius = REACH
	guard.check = has_sheet
	guard.spend = use_sheet
	guard.owner_effect = weakref(self)
	guard.follow = ctx.player if ctx.has_player() else null
	var placed := ctx.add_fx(guard, ctx.feet())
	_guard = weakref(placed) if placed != null else null


func has_sheet() -> bool:
	return sheets > 0 and not (_ctx != null and _ctx.counting_pills)


func use_sheet() -> void:
	sheets = maxi(sheets - 1, 0)


# The sheets round him, drawn as small pale rectangles turning slowly.
class PaperSheets extends ShotGuard:
	var owner_effect: WeakRef
	var _turn := 0.0

	func _process(delta: float) -> void:
		super(delta)
		_turn += delta * 2.0

	func _draw() -> void:
		var effect = owner_effect.get_ref() if owner_effect != null else null
		var count: int = effect.sheets if effect != null else 0
		for i in count:
			var at := Vector2.from_angle(_turn + TAU * i / maxf(count, 1)) * radius
			draw_set_transform(at, _turn + i, Vector2.ONE)
			draw_rect(Rect2(-3, -2, 6, 4), Color("f2ecd8"))
			draw_rect(Rect2(-3, -2, 6, 4), Color(0.3, 0.27, 0.2), false, 1.0)
		draw_set_transform(Vector2.ZERO)

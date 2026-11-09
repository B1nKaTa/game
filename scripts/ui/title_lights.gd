class_name TitleLights
extends Node2D

# The title screen's lamplight, in room pixels, drawn additively in hard bands on the room's grid (no
# soft glow): a pool on the wall behind each lamp (the back layer) and, in front, each lamp's cone of
# light down to the floor with dust drifting in it, and the bulbs themselves. TitleRoom sets each lamp's
# level every frame (the left lamp flickers); a lamp at 0 is out.

const WARM := Color(1.0, 0.78, 0.46)
const BULB := Color(1.0, 0.93, 0.7)
const CONE_BANDS: Array[float] = [0.11, 0.07, 0.04]
const POOL_BANDS: Array[float] = [0.16, 0.10, 0.06]
const DUST_COUNT := 16
const DUST_COLOR := Color(1.0, 0.9, 0.7)

# Each lamp: the bulb's centre, how far its cone spreads at the floor, and the floor's row.
var lamps: Array[Dictionary] = []
var levels: Array[float] = []
var front := true
var _dust: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	_rng.randomize()
	if front:
		for i in DUST_COUNT:
			_dust.append(_new_mote(i % maxi(lamps.size(), 1), true))


func set_levels(values: Array[float]) -> void:
	levels = values
	queue_redraw()


func _process(delta: float) -> void:
	if not front:
		return
	for mote in _dust:
		mote["at"] += mote["velocity"] * delta
		mote["age"] += delta
		var lamp: Dictionary = lamps[mote["lamp"]]
		if mote["age"] > mote["life"] or mote["at"].y > lamp["floor"] or mote["at"].y < lamp["bulb"].y + 2.0:
			var fresh := _new_mote(mote["lamp"], false)
			mote.merge(fresh, true)
	queue_redraw()


func _new_mote(lamp_index: int, anywhere: bool) -> Dictionary:
	var lamp: Dictionary = lamps[lamp_index] if not lamps.is_empty() else {"bulb": Vector2.ZERO, "spread": 1.0, "floor": 1.0}
	var depth := _rng.randf_range(0.1, 1.0) if anywhere else _rng.randf_range(0.1, 0.9)
	var y: float = lerpf(lamp["bulb"].y + 4.0, lamp["floor"], depth)
	var half := _half_width(lamp, y)
	return {
		"lamp": lamp_index,
		"at": Vector2(lamp["bulb"].x + _rng.randf_range(-half, half) * 0.8, y),
		"velocity": Vector2(_rng.randf_range(-1.2, 1.2), _rng.randf_range(-0.6, 1.4)),
		"age": 0.0 if not anywhere else _rng.randf_range(0.0, 4.0),
		"life": _rng.randf_range(4.0, 9.0),
	}


# Half the cone's width at row y.
static func _half_width(lamp: Dictionary, y: float) -> float:
	var depth := clampf((y - lamp["bulb"].y) / maxf(lamp["floor"] - lamp["bulb"].y, 1.0), 0.0, 1.0)
	return lerpf(3.0, lamp["spread"], depth)


func _draw() -> void:
	for i in lamps.size():
		var level: float = levels[i] if i < levels.size() else 1.0
		if level <= 0.01:
			continue
		var lamp: Dictionary = lamps[i]
		var bulb: Vector2 = lamp["bulb"]
		if not front:
			# A banded pool on the wall round and below the shade.
			for band in POOL_BANDS.size():
				var radius := 10.0 + band * 7.0
				var color := WARM
				color.a = POOL_BANDS[band] * level
				for dy in range(-int(radius * 0.6), int(radius)):
					var half := floorf(sqrt(maxf(radius * radius - float(dy * dy) * 1.6, 0.0)))
					draw_rect(Rect2(bulb.x - half, bulb.y + 4 + dy, half * 2.0, 1), color)
			continue
		# The cone: one rect per row, so its edges step on the room's pixel grid.
		for band in CONE_BANDS.size():
			var color := WARM
			color.a = CONE_BANDS[band] * level
			var y := bulb.y + 2.0
			while y < float(lamp["floor"]):
				var half := floorf(_half_width(lamp, y) * (1.0 - band * 0.28))
				draw_rect(Rect2(bulb.x - half, y, half * 2.0, 1), color)
				y += 1.0
		var glow := BULB
		glow.a = 0.55 * level
		draw_rect(Rect2(bulb + Vector2(-2, 0), Vector2(4, 2)), glow)
		glow.a = 0.9 * level
		draw_rect(Rect2(bulb + Vector2(-1, 0), Vector2(2, 1)), glow)
	if not front:
		return
	for mote in _dust:
		var lamp_index: int = mote["lamp"]
		var level: float = levels[lamp_index] if lamp_index < levels.size() else 1.0
		var life: float = mote["life"]
		var fade := clampf(minf(mote["age"], life - mote["age"]) / 1.2, 0.0, 1.0)
		var color := DUST_COLOR
		color.a = 0.32 * fade * level
		# A mote is one view pixel, a third of a room pixel, so it reads as dust and not as a block.
		draw_rect(Rect2((mote["at"] * 3.0).floor() / 3.0, Vector2(1, 1) / 3.0), color)

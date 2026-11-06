class_name EnemyDef
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: float = 30.0
@export var speed: float = 60.0
@export var damage: int = 1
# What walking into its body costs Grandpa, in pills. Zero makes its body harmless to touch, as the
# Training Yard's dummy's. See ContactRule.
@export var contact_damage: int = 1
# A ghost passes through him harmlessly, whatever contact_damage says, unless this is set.
@export var ghost_contact: bool = false
@export var pension_drop: int = 4
@export var ignores_walls: bool = false
@export var is_boss: bool = false
@export var body_size: Vector2 = Vector2(20, 24)
@export var color: Color = Color.WHITE
# How wide one frame of its art is. Zero means square frames, as tall as each strip (SpriteVisual.frame_size).
@export var frame_width: int = 0
# Whose art it wears, from res://art/sprites/<art_id>/, so a floor variant can share its base's. Empty
# means its own id. See art().
@export var art_id: String = ""
# A recolour of that art for a floor variant: hues within art_hue_width degrees of art_hue_from turn
# to art_hue_to, on coloured pixels only, so skin, greys and whites stay. Zero width keeps the art's own.
@export var art_hue_from: float = 0.0
@export var art_hue_to: float = 0.0
@export var art_hue_width: float = 0.0
# Multiplies the value of those same hues, to lift a dark robe a floor's light would swallow.
@export var art_value: float = 1.0
@export var behavior_script: Script
@export var summon: EnemyDef
# How many spawn together at one enemy cell. Only the first of a group pays.
@export var group_size: int = 1
# A room holds at most this many of the type. Zero means no limit.
@export var max_per_room: int = 0
# Half the width in degrees of a shield facing its target. Zero means no shield.
@export var shield_half_angle: float = 0.0
# A placeholder sign drawn on the body, so a type reads without art. See EnemyMarks.
@export var mark: String = ""
# Bolted to a wall: it starts on a cell beside one and never moves, not even when hit.
@export var wall_mounted: bool = false
# What shows of it while it hides underground or in smoke: "mound" or "smoke".
@export var hidden_look: String = "mound"
# Whether its art turns to face the way it goes, mirrored from the east-drawn strips. An object drawn
# from one side only, a single south-facing look such as the Ectoplasm's blob, never mirrors.
@export var flips: bool = true
# Drops a Permission Slip when it falls, as a mimic does. Summons never drop one.
@export var drops_key: bool = false


# The art folder it uses: art_id, or its own id.
func art() -> String:
	return art_id if not art_id.is_empty() else id

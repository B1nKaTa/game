class_name ContactShadow
extends Sprite2D

# A soft dark ellipse on the ground under something that stands on it, so nothing floats: Harold,
# enemies, NPCs, props, chests and pickups each add one with ContactShadow.add_to. It is a child, so it
# moves with its owner for free and never redraws; it draws at Z, above the floor and its flat marks
# and below every body, whatever the owner's own z. Every floor gets them.
const Z := -7
const ALPHA := 0.42
# An ellipse this much as tall as it is wide.
const FLAT := 0.36

static var _textures := {}


# One baked ellipse per width, drawn in three hard bands so it reads as pixel art and not a blur.
static func ellipse(width: int) -> ImageTexture:
	width = clampi(width, 6, 96)
	if _textures.has(width):
		return _textures[width]
	var height := maxi(4, roundi(width * FLAT))
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var d := Vector2((x + 0.5) / width - 0.5, (y + 0.5) / height - 0.5) * 2.0
			var r := d.length()
			var a := 0.0
			if r < 0.55:
				a = 1.0
			elif r < 0.8:
				a = 0.65
			elif r < 1.0:
				a = 0.3
			image.set_pixel(x, y, Color(0.02, 0.01, 0.03, a * ALPHA))
	var made := ImageTexture.create_from_image(image)
	_textures[width] = made
	return made


# Adds a shadow width px across with its middle at `feet` in the owner's space. Returns it, so an owner
# that hides (a submerged enemy) can hide it too.
static func add_to(owner_node: Node2D, width: float, feet: Vector2) -> ContactShadow:
	var shadow := ContactShadow.new()
	shadow.texture = ellipse(roundi(width))
	shadow.centered = true
	shadow.position = feet.round()
	shadow.z_as_relative = false
	shadow.z_index = Z
	shadow.name = "ContactShadow"
	owner_node.add_child(shadow)
	return shadow

class_name PixelCleanup
extends RefCounted

const ALPHA_CUTOFF := 0.5


static func process(source: Image, width: int, height: int, palette: PackedColorArray) -> Image:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	image.resize(width, height, Image.INTERPOLATE_NEAREST)
	for y in height:
		for x in width:
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_CUTOFF:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				image.set_pixel(x, y, _nearest(color, palette))
	return image


static func parse_palette(text: String) -> PackedColorArray:
	var colors := PackedColorArray()
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		colors.append(Color.html(line))
	return colors


static func _nearest(color: Color, palette: PackedColorArray) -> Color:
	var best := palette[0]
	var best_distance := INF
	for candidate in palette:
		var dr := color.r - candidate.r
		var dg := color.g - candidate.g
		var db := color.b - candidate.b
		var distance := dr * dr + dg * dg + db * db
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return Color(best.r, best.g, best.b, 1.0)

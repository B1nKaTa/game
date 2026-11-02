class_name RoomCatalog
extends RefCounted


static func load_valid(dir: String) -> Array[RoomLayout]:
	var valid: Array[RoomLayout] = []
	for resource in Content.load_dir(dir):
		if not resource is RoomLayout:
			push_error("Not a room layout: %s" % resource.resource_path)
			continue
		var errors: PackedStringArray = resource.validate()
		if not errors.is_empty():
			push_error("Skipping broken room %s: %s" % [resource.resource_path, ", ".join(errors)])
			continue
		valid.append(resource)
	return valid

class_name ChoiceGroup
extends RefCounted

# Items laid out as a choice. Taking one clears the rest away, once.
var _members: Array[Node] = []
var _settled := false


func add(pickup: Node) -> void:
	_members.append(pickup)


func take(pickup: Node) -> void:
	if _settled:
		return
	_settled = true
	for other in _members:
		if other != pickup and is_instance_valid(other) and not other.is_queued_for_deletion():
			other.queue_free()


func is_settled() -> bool:
	return _settled

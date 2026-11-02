extends Node


func _ready() -> void:
	Game.start.call_deferred()

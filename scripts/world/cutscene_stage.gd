class_name CutsceneStage
extends Node2D

# The set behind an ending scene, drawn in code in stage units (CutsceneSteps.VIEW). Filled in with
# the scenes.

var stage_name := ""


func set_stage(new_name: String) -> void:
	stage_name = new_name
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CutsceneSteps.VIEW), Color("2a2430"))

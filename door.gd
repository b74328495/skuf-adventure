extends Node2D

@export_file("*.tscn") var next_scene: String

func _on_door_open_animate_body_entered(body):
	if not body.is_in_group("player"):
		return
	$OpenDoor.show()

func _on_door_open_animate_body_exited(body):
	if not body.is_in_group("player"):
		return
	$OpenDoor.hide()

func _on_go_to_next_scene_body_entered(body):
	if not body.is_in_group("player"):
		return
	get_tree().change_scene_to_file(next_scene)


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_body_exited(body: Node2D) -> void:
	pass # Replace with function body.

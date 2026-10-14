extends Area2D

@onready var destination: Marker2D = $destination

func _on_body_entered(body: Node2D) -> void:
	print("enterd portal")
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/levels/level_2.tscn")
		

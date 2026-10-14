extends Area2D



func _on_try_againbutton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_4.tscn")
	
	


func _on_returntostartbutton_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/game.tscn")
	
	

func _on_quitbutton_3_pressed() -> void:
	get_tree().quit()

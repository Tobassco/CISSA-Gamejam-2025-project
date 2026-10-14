extends CanvasLayer


func _on_try_again_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_2.tscn")
	
	

func _on_returntolvl1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/game.tscn")
	
	

func _on_quit_button_3_pressed() -> void:
	get_tree().quit()

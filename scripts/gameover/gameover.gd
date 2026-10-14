extends CanvasLayer




func _on_try_again_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/game.tscn")

func _on_returnto_level1_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/game.tscn")

func _on_quit_utton_3_pressed() -> void:
		get_tree().quit()

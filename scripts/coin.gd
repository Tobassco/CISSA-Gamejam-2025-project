extends Area2D


@onready var game_manager: Node = %"game manager"

func _on_body_entered(body):
	game_manager.add_point()
	print ("+1 coin") 
	
	queue_free()

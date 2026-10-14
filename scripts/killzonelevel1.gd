extends Area2D

@onready var timer = $Timer
@onready var slime_length: Timer = $slime_length

func _on_body_entered(body):
	if body.has_method("player"):
		print("player entered")
		if $"../attack_cooldown".is_stopped():
			global.golem_take_damage = true
			print("golem take damage, ", global.golem_take_damage)
		else:
			$"../attack_cooldown".start()
			
	# Engine.time_scale = 0.5
	# body.get_node("CollisionShape2D").queue_free()
	slime_length.start()
	# timer.start()

func _on_timer_timeout():
	pass
	# Engine.time_scale = 1.0
	# get_tree().change_scene_to_file("res://scenes/levels/gameover.tscn")


func _on_slime_length_timeout() -> void:
	print("yo")
	global.golem_take_damage = false

extends CharacterBody2D

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var golem: CharacterBody2D = get_parent()
var speed = 50
var hover_amplitude = 20 
var hover_speed = 2  
var time_passed = 0.0
var last_facing_left = false  # Track the last facing direction

var sound_effects = [
	preload("res://sfx/LEBRONNN/LEBRON Sound Effect.mp3"),
	preload("res://sfx/LEBRONNN/That one Lebron meme.mp3"),
	preload("res://sfx/LEBRONNN/[Edit] BO BO BO BOOM #lebron #lebronjames #edit #nba.mp3"),
	preload("res://sfx/LEBRONNN/Evil Lebron meme (you are my sunshine).mp3")
]

func _ready() -> void:
	$Timer.wait_time = randf_range(10, 20)
	$Timer.start()
	$AnimatedSprite2D.play("default")

func _physics_process(delta: float) -> void:
	if not golem:
		return
	
	time_passed += delta 
	
	var direction = (golem.global_position - global_position).normalized()
	velocity = direction * speed
	
	var distance = global_position.distance_to(golem.global_position)
	if distance < 100:
		velocity = -direction
	
	velocity.y += sin(time_passed * hover_speed) * hover_amplitude

	move_and_slide()

	# Check if the parent sprite flipped
	var parent_flipped = $"../AnimatedSprite2D".flip_h

	if parent_flipped != last_facing_left:
		# Only flip position when the direction actually changes
		position.x = -position.x
		last_facing_left = parent_flipped
		rotation_degrees = 345 if parent_flipped else 15  
	
		

	# Ensure sprite flips correctly
	$AnimatedSprite2D.flip_h = parent_flipped

func play_random_sound():
	if audio_player.playing:
		audio_player.stop()
	
	var random_sound = sound_effects.pick_random()
	audio_player.stream = random_sound
	audio_player.play()

func _on_timer_timeout() -> void:
	print("LEBRONNN")
	play_random_sound()
	$Timer.wait_time = randf_range(35, 50)
	$Timer.start()

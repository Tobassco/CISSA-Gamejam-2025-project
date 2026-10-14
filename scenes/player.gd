extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -200.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Portal variables
var last_portal: Area2D = null  # Stores the last portal entered

# Physics processing
func _physics_process(delta: float) -> void:
	# Apply gravity
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	velocity.y += gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get movement direction (-1 left, 1 right)
	var direction := Input.get_axis("move_left", "move_right")

	# Flip sprite based on direction
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Move and animate
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Play animation based on movement
	if is_on_floor():
		animated_sprite.play("idle" if direction == 0 else "run")
	else:
		animated_sprite.play("jump")

	move_and_slide()
	

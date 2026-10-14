extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var maxHealth = 200 # changhe back to normal value
@onready var currentHealth: int = maxHealth

var enemy_inattack_range = false
var enemy_attack_cooldown = true
var attack_ip = false
var player_alive = true
var cant_move = false

signal healthChanged
signal enemyAttacked

var main_sm: LimboHSM

func _ready():
	healthChanged.emit()
	initiate_state_machine()

func _physics_process(delta: float) -> void:
	# var testMode = str(main_sm.get_active_state())
	# var index = testMode.find(":")
	# var golemState = testMode.substr(0, index)
	# $debug.text = golemState
	
	slime_touched()
	enemy_attack()
	
	if cant_move:
		velocity = Vector2.ZERO
		# it seems that the attack frame occurs for 10 frames
		# ! this may vary for fps
		if animated_sprite.frame == 2:
			global.player_current_attack = true
		return
		
	
	# print(velocity)
	
	if (currentHealth <= 0):
		print("dead")
		main_sm.dispatch(&"to_death")
	
	# ! COULD MAYBE ADD A SCREEN SHAKE EFFECT IF GOLEM FALLS SUPER HIGH DOWN
	if not is_on_floor():
		velocity += get_gravity() * delta
		if (velocity.y > 0):
			main_sm.dispatch(&"to_fall")


	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	flip_sprite(direction)
	move_and_slide()

func flip_sprite(direction):
	if direction >= 1:
		animated_sprite.flip_h = false
	elif direction <= -1:
		animated_sprite.flip_h = true

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("jump"):
		main_sm.dispatch(&"to_jump")
	elif event.is_action_pressed("attack"):
		main_sm.dispatch(&"to_attack")

func initiate_state_machine():
	main_sm = LimboHSM.new()
	add_child(main_sm)
	
	var idle_state = LimboState.new().named("idle").call_on_enter(idle_start).call_on_update(idle_update)
	var walk_state = LimboState.new().named("walk").call_on_enter(walk_start).call_on_update(walk_update)
	var jump_state = LimboState.new().named("jump").call_on_enter(jump_start).call_on_update(jump_update)
	var attack_state = LimboState.new().named("attack").call_on_enter(attack_start).call_on_update(attack_update)
	var fall_state = LimboState.new().named("fall").call_on_enter(fall_start).call_on_update(fall_update)
	var death_state = LimboState.new().named("death").call_on_enter(death_start).call_on_update(death_update)
	
	main_sm.add_child(idle_state)
	main_sm.add_child(walk_state)
	main_sm.add_child(jump_state)
	main_sm.add_child(attack_state)
	main_sm.add_child(fall_state)
	main_sm.add_child(death_state)
	
	main_sm.initial_state = idle_state
	
	# how this works in order
	# current state -> next state - by calling the signal
	# walk and idle states
	main_sm.add_transition(idle_state, walk_state, &"to_walk")
	main_sm.add_transition(main_sm.ANYSTATE, idle_state, &"state_ended")
	
	# jumping states
	main_sm.add_transition(idle_state, jump_state, &"to_jump")
	main_sm.add_transition(walk_state, jump_state, &"to_jump")
	
	# fighting states
	# with current logic dont make punch mid air
	#main_sm.add_transition(main_sm.ANYSTATE, attack_state, &"to_attack")
	main_sm.add_transition(idle_state, attack_state, &"to_attack")
	main_sm.add_transition(walk_state, attack_state, &"to_attack")
	
	# falling states
	main_sm.add_transition(idle_state, fall_state, &"to_fall")
	main_sm.add_transition(jump_state, fall_state, &"to_fall")
	main_sm.add_transition(walk_state, fall_state, &"to_fall")
	
	main_sm.add_transition(main_sm.ANYSTATE, death_state, &"to_death")
	
	main_sm.initialize(self)
	main_sm.set_active(true)
	
func idle_start():
	animated_sprite.play("idle")
func idle_update(delta: float):
	if velocity.x != 0:
		main_sm.dispatch(&"to_walk")

func death_start():
	player_alive = false
	cant_move = true
	animated_sprite.play("death")
	$golem_death.play()
	$death_timer.start()
func death_update():
	get_tree().change_scene_to_file("res://scenes/levels/gameover.tscn")
	
	print("reset")
	currentHealth = maxHealth
	player_alive = true
	cant_move = false
	main_sm.dispatch(&"state_ended")
	
func walk_start():
	animated_sprite.play("walk")
func walk_update(delta: float):
	if velocity.x == 0:
		$golem_walk.stop()
		main_sm.dispatch(&"state_ended")
	else:
		if not $golem_walk.playing:
			$golem_walk.play()

func jump_start():
	animated_sprite.play("jump")
	$golem_jump.play()
	velocity.y = JUMP_VELOCITY
func jump_update(delta: float):
	if not is_on_floor() and velocity.y > 0:
		main_sm.dispatch(&"to_fall")
	if is_on_floor():
		main_sm.dispatch(&"state_ended")

func fall_start():
	animated_sprite.play("fall")
func fall_update(delta: float):
	if is_on_floor():
		$golem_landing.play()
		main_sm.dispatch(&"state_ended")

func attack_start():
	animated_sprite.play("attack")
	$golem_punch.play()
	cant_move = true
	attack_ip = true
func attack_update(delta: float):
	if animated_sprite.frame == animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation) - 1:
		print("attack done")
		global.player_current_attack = false
		cant_move = false
		main_sm.dispatch(&"state_ended")

func player():
	pass

func slime_touched():
	if global.golem_take_damage == true:
		currentHealth = currentHealth - 0.2
		if not $golem_damage.playing:
			$golem_damage.play()
			animated_sprite.play("hit")
		healthChanged.emit()
		print("slime touched: ", currentHealth)

func _on_players_hitbox_body_entered(body: Node2D) -> void:
	print("body entered golem: ", body)
	if body.has_method("enemy"):
		print("enemy in range")
		enemy_inattack_range = true

func _on_players_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("enemy"):
		enemy_inattack_range = false

func enemy_attack():
	#print("Enemey in range: ", enemy_inattack_range, ", current in cooldown ", enemy_attack_cooldown)
	if enemy_inattack_range and enemy_attack_cooldown == true:
		if global.boss_current_attack == true:
			currentHealth = currentHealth - global.boss_damage
			$golem_damage.play()
			animated_sprite.play("hit")
			healthChanged.emit()
			enemy_attack_cooldown = false
			$attack_cooldown.start()
			print(currentHealth)

func _on_attack_cooldown_timeout() -> void:
	enemy_attack_cooldown = true


func _on_death_timer_timeout() -> void:
	global.golem_take_damage == false
	$".".queue_free()
	get_tree().change_scene_to_file("res://scenes/levels/gameover.tscn")
	

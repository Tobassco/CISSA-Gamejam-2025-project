extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var player = get_parent().find_child("Golem")
@onready var health_bar = owner.find_child("ProgressBar")
@onready var boss_health: ProgressBar = $UI/Boss_Health

signal healthSignal

var speed = 50
var direction : Vector2
var main_sm: LimboHSM
var player_detected = false
var player_in_attackrange = false
var maxHealth = 300 # changhe back to normal value
var currentHealth: int = maxHealth
var cant_move = false

func enemy():
	pass

func _ready():
	initiate_state_machine()
	
func _process(_delta):
	direction = player.position - position
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func _physics_process(delta: float) -> void:
	# TESTING: these lines just show the current state of the boss
	# var testMode = str(main_sm.get_active_state())
	# var index = testMode.find(":")
	# $debug.text = testMode.substr(0, index)
	
	if cant_move:
		velocity = Vector2.ZERO
	
	process_damage()
	if currentHealth <= 0:
		print("boss killed")
		main_sm.dispatch(&"to_death")
		$death_timer.start()
		return
	
	var distance = global_position.distance_to(player.global_position)
	#print("Cooldown remaining: ", $melee_cooldown.time_left)
	if $melee_cooldown.time_left <= 0.3:
		$melee_cooldown.stop()
		# have to manually stop cuz stuck on loop
	
	# deciding move set
	if distance < 100:
		if $melee_cooldown.is_stopped():
			# print("melee attack")
			main_sm.dispatch(&"to_melee")
			$melee_cooldown.start()
	
	move_and_slide()

func initiate_state_machine():
	main_sm = LimboHSM.new()
	add_child(main_sm)
	
	var idle_state = LimboState.new().named("idle").call_on_enter(idle_start).call_on_update(idle_update)
	var follow_state = LimboState.new().named("follow").call_on_enter(follow_start).call_on_update(follow_update)
	var dash_state = LimboState.new().named("dash").call_on_enter(dash_start).call_on_update(dash_update)
	var death_state = LimboState.new().named("death").call_on_enter(death_start).call_on_update(death_update)
	var melee_state = LimboState.new().named("melee").call_on_enter(melee_start).call_on_update(melee_update)
	var ranged_one_state = LimboState.new().named("ranged_one").call_on_enter(ranged_one_start).call_on_update(ranged_one_update)
	var ranged_two_state = LimboState.new().named("ranged_two").call_on_enter(ranged_two_start).call_on_update(ranged_two_update)
	
	main_sm.add_child(idle_state)
	main_sm.add_child(follow_state)
	main_sm.add_child(dash_state)
	main_sm.add_child(death_state)
	main_sm.add_child(melee_state)
	main_sm.add_child(ranged_one_state)
	main_sm.add_child(ranged_two_state)
	
	main_sm.initial_state = idle_state
	
	# how this works in order - basically what state can transition into which state
	# current state -> next state - by calling the signal
	# idle state
	main_sm.add_transition(main_sm.ANYSTATE, idle_state, &"state_ended")
	
	#f follow state
	main_sm.add_transition(main_sm.ANYSTATE, follow_state, &"to_follow")
	
	# dash state
	main_sm.add_transition(melee_state, dash_state, &"to_dash")
	
	# fighting states
	# melee
	main_sm.add_transition(follow_state, melee_state, &"to_melee")
	main_sm.add_transition(idle_state, melee_state, &"to_melee")
	
	# ranged 1 (medium distance)
	
	# ranged 2 (long distance)
	
	# death state
	main_sm.add_transition(main_sm.ANYSTATE, death_state, &"to_death")
	
	main_sm.initialize(self)
	main_sm.set_active(true)
	
func idle_start():
	sprite.play("idle")
func idle_update(delta: float):
	if player_detected:
		main_sm.dispatch(&"to_follow")
		health_bar.set_deferred("visible", true)

func follow_start():
	sprite.play("run")
func follow_update(delta: float):
	if not player_detected:
		main_sm.dispatch(&"to_idle")
		return
	
	
	if cant_move == false and velocity.x == 0 and is_on_wall():
		print("stuck on wall")
		position.x += 5 if get_last_slide_collision().get_normal().x < 0 else -5
		return
	
	# move towards player
	var direction = (player.global_position - global_position).normalized()
	
	var direction_vector = player.global_position - global_position
	var horizontal_direction = Vector2(sign(direction_vector.x), 0)
	velocity = horizontal_direction * speed
	# velocity = direction * speed ! FREE FLOAT
	
	# however keep distance as witches are long ranged typically
	var distance = global_position.distance_to(player.global_position)
	if distance < 300:
		velocity = -horizontal_direction * 30
		# velocity = -direction * 20 ! FREE FLOAT

func dash_start():
	var direction_vector = player.global_position - global_position
	var horizontal_direction = Vector2(sign(direction_vector.x), 0)
	velocity = -horizontal_direction * 200
func dash_update():
	main_sm.dispatch(&"to_follow")
	return
	
func death_start():
	# player_alive = false
	# cant_move = true
	sprite.play("death")
	$AnimationPlayer.play("boss_killed")
	$witch_death.play()
func death_update():
	print("reset")
	currentHealth = maxHealth
	# player_alive = true
	# cant_move = false
	main_sm.dispatch(&"state_ended")
	

func melee_start():
	print("melee attack")
	global.boss_current_attack = true
	global.boss_damage = 40
	cant_move = true
	sprite.play("attack")
func melee_update(delta: float):
	if sprite.frame == sprite.sprite_frames.get_frame_count(sprite.animation) - 1:
		global.boss_current_attack = false
		global.boss_damage = 0
		cant_move = false
		main_sm.dispatch(&"to_follow") # dash dont work
		
func ranged_one_start():
	pass
func ranged_one_update():
	pass

func ranged_two_start():
	pass
func ranged_two_update():
	pass

func process_damage():
	if player_in_attackrange and global.player_current_attack == true:
		currentHealth = currentHealth - 3
		if not $witch_hurt.playing:
			$witch_hurt.play()
		sprite.play("hit")
		healthSignal.emit()

func _on_player_detection_body_entered(body: Node2D) -> void:
	print("EnemyPOV - Body Detected: ", body)
	if body.has_method("player"):
		print("Player Detected")
		player_detected = true
		boss_health.set_deferred("visible", true)

func _on_player_detection_body_exited(body: Node2D) -> void:
	print("EnemyPOV - Body Detected EXIT: ", body)
	if body.has_method("player"):
		player_detected = false

func _on_enemy_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		print("EnemyPOV - Player within Hitbox Range")
		player_in_attackrange = true

func _on_enemy_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		print("EnemyPOV - Player EXITED Hitbox Range")
		player_in_attackrange = false


func _on_death_timer_timeout() -> void:
	print("boss dead reset")

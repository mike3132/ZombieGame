extends CharacterBody3D

@export var mouse_sensitivity = 0.2

@onready var playerAnimations = $PlayerAnimations
@onready var camera = $Camera3D
@onready var weaponAnimation = $Camera3D/glock/GlockAnimations
@onready var firstPersonAnimation = $Camera3D/FpAnimations
@onready var firstPersonHands = $Camera3D/FpHands
@onready var gunRayCast = $Camera3D/GunRaycast

# Debug hud
@onready var debughud = $PlayerHud/DebugMenu
@onready var playerVelocity = $PlayerHud/DebugMenu/DebugHud/PlayerVelocity
@onready var projectVelocity = $PlayerHud/DebugMenu/DebugHud/ProjectVelocity
@onready var playerLocation = $PlayerHud/DebugMenu/DebugHud/PlayerLocation

var bullet = load("res://Scenes/bullet.tscn")
var instance

const walk_speed = 5.0
const jump_velocity = 4.5
const max_speed = 6.0
const max_speed_air = 5.5
const ground_acceleration = 35
const air_acceleration = 26
const ground_friction = 3.5

var syncPosition = Vector3(0,0,0)
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Multiplayer code for later use
#func _enter_tree():
#	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())


func _ready():
	# Multiplayer code for later use
	#if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	


func _unhandled_input(event):
	# Multiplayer code for later use
	#if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
	# Change this to an pause / options menu at a later date
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
	if Input.is_action_just_pressed("shoot"):
		play_shoot_effects.rpc()
	
	if Input.is_action_just_pressed("debughud"):
		if debughud.visible:
			debughud.hide()
		else:
			debughud.show()


func _physics_process(delta):
	# Multiplayer code for later use
	#if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():

	syncPosition = global_position

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		velocity = accelerate(direction, delta, ground_acceleration, max_speed)
		var speed = velocity.length()
		if speed != 0:
			var drop = speed * ground_friction * delta
			velocity *= max(speed - drop, 0) / speed
		# Handle jump.
		if Input.is_action_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity
	else:
		velocity = accelerate(direction, delta, air_acceleration, max_speed_air)
		velocity.y -= gravity * delta
	
	playerAnimations.set("parameters/conditions/idle", input_dir == Vector2.ZERO)
	playerAnimations.set("parameters/conditions/walk", input_dir != Vector2.ZERO)

	if weaponAnimation.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		firstPersonAnimation.play("walk")
	else:
		weaponAnimation.play("idle")
		firstPersonAnimation.play("idle")
	
	playerLocation.text = "Player Location: " + str(global_position)
	
	move_and_slide()
	#else:
	#	global_position = global_position.lerp(syncPosition, .5)
		


func accelerate(direction, delta, acceleration_type, max_velocity):
	var project_velocity = velocity.dot(direction)
	var acceleration_velocity = acceleration_type * delta
	
	if (project_velocity + acceleration_velocity > max_velocity):
		acceleration_velocity = max_velocity - project_velocity
	
	playerVelocity.text = "Player Velocity: " + str(velocity.length())
	projectVelocity.text = "Project Velocity: " + str(project_velocity)
	
	return velocity + (direction * acceleration_velocity)



@rpc("any_peer", "call_local")
func play_shoot_effects():
	weaponAnimation.stop()
	weaponAnimation.play("shoot")
	firstPersonAnimation.play("shoot")

	instance = bullet.instantiate()
	instance.position = gunRayCast.global_position
	instance.transform.basis = gunRayCast.global_transform.basis
	get_parent().add_child(instance)

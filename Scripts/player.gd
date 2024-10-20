extends CharacterBody3D

@onready var playerAnimations = $PlayerAnimations
@onready var camera = $Camera3D
@onready var weaponAnimation = $Camera3D/glock/GlockAnimations
@onready var firstPersonAnimation = $Camera3D/FpAnimations
@onready var firstPersonHands = $Camera3D/FpHands
@onready var gunRayCast = $Camera3D/GunRaycast
#@onready var muzzleFlash = $Camera3D/Pistol/MuzzleFlash

var bullet = load("res://Scenes/bullet.tscn")
var instance


const WALK_SPEED = 5.0
const RUN_SPEED = 10.0
const JUMP_VELOCITY = 4.5

var syncPosition = Vector3(0,0,0)
var running = false

# Multiplayer code for later use
#func _enter_tree():
#	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())

func _ready():
	# Multiplayer code for later use
	#if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true


func _input(event):
	running = true if Input.is_action_pressed("run") else false


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


func _physics_process(delta):
	# Multiplayer code for later use
	#if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	syncPosition = global_position

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed = RUN_SPEED if running else WALK_SPEED
		
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	playerAnimations.set("parameters/conditions/idle", input_dir == Vector2.ZERO)
	playerAnimations.set("parameters/conditions/walk", input_dir != Vector2.ZERO and not running)
	playerAnimations.set("parameters/conditions/run", input_dir != Vector2.ZERO and running)

	if weaponAnimation.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		firstPersonAnimation.play("walk")
	else:
		weaponAnimation.play("idle")
		firstPersonAnimation.play("idle")
	
	move_and_slide()
	#else:
	#	global_position = global_position.lerp(syncPosition, .5)
		

@rpc("any_peer", "call_local")
func play_shoot_effects():
	weaponAnimation.stop()
	weaponAnimation.play("shoot")
	firstPersonAnimation.play("shoot")

	instance = bullet.instantiate()
	instance.position = gunRayCast.global_position
	instance.transform.basis = gunRayCast.global_transform.basis
	get_parent().add_child(instance)
	
	#muzzleFlash.restart()
	#muzzleFlash.emitting = true
# Blue's Message

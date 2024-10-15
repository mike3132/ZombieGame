extends CharacterBody3D

@onready var camera = $Camera3D
@onready var animationPlayer = $AnimationPlayer
@onready var muzzleFlash = $Camera3D/Pistol/MuzzleFlash

const SPEED = 10.0
const JUMP_VELOCITY = 4.5

var syncPosition = Vector3(0,0,0)

func _enter_tree():
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())

func _ready():
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		camera.current = true


func _unhandled_input(event):
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * .005)
			camera.rotate_x(-event.relative.y * .005)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
		# Change this to an pause / options menu at a later date
		if Input.is_action_just_pressed("quit"):
			get_tree().quit()
		
		if Input.is_action_just_pressed("shoot") and animationPlayer.current_animation != "shoot":
			play_shoot_effects.rpc()


func _physics_process(delta):
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
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
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

		if animationPlayer.current_animation == "shoot":
			pass
		elif input_dir != Vector2.ZERO and is_on_floor():
			animationPlayer.play("move")
		else:
			animationPlayer.play("idle")

		move_and_slide()
	else:
		global_position = global_position.lerp(syncPosition, .5)
		

@rpc("any_peer", "call_local")
func play_shoot_effects():
	animationPlayer.stop()
	animationPlayer.play("shoot")
	muzzleFlash.restart()
	muzzleFlash.emitting = true
	

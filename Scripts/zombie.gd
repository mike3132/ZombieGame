extends CharacterBody3D

@export var PlayerPath : NodePath
@export var aggroRange : = 5.0

@onready var navigation = $NavigationAgent3D
@onready var sight = $Sight
@onready var engageTimer = $Engaged

const Player = preload("res://Scenes/player.tscn")


var zombie_health = 3
var speed = 5.0
var jump_velocity : = 4.5

var startingPosition
var engaged = false


func _physics_process(delta):
	var current_location = global_transform.origin
	var next_location  = navigation.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	
	#var player = Player.instantiate()
	#var playerposition = player.get_position_delta()
	#navigation.target_position(playerposition)
	
	
	velocity = new_velocity
	
	move_and_slide()

func takeDamage(dmg):
	zombie_health -= dmg
	engaged = true
	engageTimer.start()
	print("Zombie took damage")
	if zombie_health < 1:
		queue_free()
		print("Zombie dead")
	


func _on_engaged_timeout():
	engaged = false

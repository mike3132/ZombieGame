extends Node3D

@export var PlayerScene : PackedScene
const Zombie = preload("res://Scenes/zombie.tscn")

func _ready():
	_on_timer_timeout()

func _on_timer_timeout():
	print("Timer stopped")
	var zombie = Zombie.instantiate()
	zombie.position = Vector3(1, 2, 1)
	add_child(zombie)


# Multiplayer Code for later use
# Sets the player name to an id and spawns them at a position
#func _ready():
#	_on_timer_timeout()
#	var index = 0
#	for i in GameManager.Players:
#		var currentPlayer = PlayerScene.instantiate()
#		currentPlayer.name = str(GameManager.Players[i].id)
#		add_child(currentPlayer)
#		for spawn in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
#			if spawn.name == str(index):
#				currentPlayer.global_position = spawn.global_position
#		index += 1

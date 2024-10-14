extends Control

@onready var Adress = $Menu/VBoxContainer/MultiplayerIP
@onready var PlayerName = $Menu/VBoxContainer/PlayerName
@onready var PlayerNameError = $PlayerNameError
@onready var MainMenu_Sound = $MainMenu_Sound
@onready var StartGameSound = $StartGame_Sound

const Player = preload("res://Scenes/player.tscn")
const PORT = 20110
var enet_peer = ENetMultiplayerPeer.new()

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

# Gets called on the server and clients
func peer_connected(id):
	print("Player Connected " + str(id))

# Gets called on the server and clients
func peer_disconnected(id):
	print("Player Disconnected " + str(id))

# Gets called only on clients
func connected_to_server():
	print("Connected To Server")
	SendPlayerInformation.rpc_id(1, $Menu/VBoxContainer/PlayerName.text, multiplayer.get_unique_id())

# Gets called only on clients
func connection_failed():
	print("Connection Failed")


func _on_single_player_button_pressed():
	if PlayerName.text != "":
		
		var error = enet_peer.create_server(PORT)
		
		if error != OK:
			print("Cannot host " + error)
			return
		
		enet_peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
		
		multiplayer.set_multiplayer_peer(enet_peer)
		print("Single Player Game Started, Loading level and player / mob models and textures")
		SendPlayerInformation($Menu/VBoxContainer/PlayerName.text, multiplayer.get_unique_id())
		
		enet_peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(enet_peer)
		start_game.rpc()
		
		StartGameSound.play()
		MainMenu_Sound.stop()
	else:
		PlayerNameError.show()


func _on_host_multiplayer_button_pressed():
	var error = enet_peer.create_server(PORT, 32)
	
	if error != OK:
		print("Cannot host " + error)
		return
	
	enet_peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(enet_peer)
	print("Waiting for players")
	SendPlayerInformation($Menu/VBoxContainer/PlayerName.text, multiplayer.get_unique_id())
	


func _on_join_multiplayer_button_pressed():
	enet_peer.create_client(Adress.text, PORT)
	enet_peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(enet_peer)


func _on_start_multiplayer_pressed():
	start_game.rpc()


func _on_quit_button_pressed():
	get_tree().quit()


@rpc("any_peer", "call_local")
func start_game():
	var world = load("res://Scenes/world.tscn").instantiate()
	get_tree().root.add_child(world)
	self.hide()


@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name,
			"id": id,
			"score": 0
		}
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)


func _on_name_error_button_pressed():
	PlayerNameError.hide()

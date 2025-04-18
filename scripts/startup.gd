extends Node

const PORT = 8080
const SERVER_IP = "127.0.0.1"

const gameplay_level = "res://scenes/level.tscn"
const lobby_scene = "res://scenes/lobby.tscn"

const IS_SERVER = false;

func _ready() -> void:
	if IS_SERVER:
		_on_host_pressed()

func change_level(scene: PackedScene):
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	
	level.add_child(scene.instantiate())

func start_game():
	$UI.hide()
	
	if multiplayer.is_server():
		print("Server Loading Level")
		change_level.call_deferred(load(gameplay_level))

func _on_host_pressed():
	print("host pressed")
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	
	start_game()

func _on_client_pressed(ip = SERVER_IP, port = PORT):
	print("client pressed")
	
	var peer = ENetMultiplayerPeer.new()
	if $UI/TextEdit.text:
		peer.create_client($UI/TextEdit.text, PORT)
	else:
		peer.create_client(SERVER_IP, PORT)
	multiplayer.multiplayer_peer = peer
	
	start_game()

func start_client(ip, port):
	print("start_client %s, %s" % [ip, port])
	_on_client_pressed(ip, port)
	$LobbyPlaceholder.get_child(0).hide()

func _on_find_match_pressed():
	print("Find")
	$UI.hide()
	
	var mock_id = str(randi() % 1000)
	var mock_user = {
		"playerId": mock_id,
		"username": "User" + mock_id,
		"rank": "311"
	}
	print(mock_user)
	var lobby = preload(lobby_scene).instantiate()
	lobby.mock_user = mock_user
	
	lobby.start_client.connect(start_client)
	$LobbyPlaceholder.add_child(lobby)

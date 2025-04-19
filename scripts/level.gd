extends Node3D

const SPAWN_RADIUS := 25.0

const LOCAL_HOST_MODE = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("level ready")
	
	if not multiplayer.is_server():
		return
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	
	for id in multiplayer.get_peers():
		add_player(id)
	
	if LOCAL_HOST_MODE && not OS.has_feature("dedicated_server"):
		add_player(1)

func add_player(id: int):
	print("add player:", id)
	var character = preload("res://scenes/items/player.tscn").instantiate()
	character.player = id
	
	var pos := Vector2.from_angle(randf() * 2 * PI)
	character.position = Vector3(pos.x * SPAWN_RADIUS, 0, pos.y * SPAWN_RADIUS)
	character.name = str(id)
	$Players.add_child(character, true)

func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()

func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)

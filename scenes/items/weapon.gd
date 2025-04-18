extends Node3D

var _has_fired = false

@onready var player_input = $"../PlayerInput"
@onready var camera: Camera3D = $"../CameraContainer/CameraRot/Camera3D"

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	if not _has_fired and player_input.mbdown:
		_has_fired = true
		_fire_weapon()
	elif _has_fired and !player_input.mbdown:
		_has_fired = false

func _fire_weapon():
	var center = get_viewport().get_size()/2
	
	var ray_origin = camera.project_ray_origin(center)
	var ray_end = ray_origin + camera.project_ray_normal(center)*1000
	
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	
	if not intersection.is_empty():
		print(intersection.collider.name)
		if intersection.collider is Player:
			intersection.collider.respawn.rpc()
	else:
		print("Nothing")

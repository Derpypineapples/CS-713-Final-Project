class_name Player extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const DIRECTION_INTERPOLATE_SPEED = 1
const MOTION_INTERPOLATE_SPEED = 10
const ROTATION_INTERPOLATE_SPEED = 10

var health = 100

var motion = Vector2()
var root_motion = Transform3D()
var orientation = Transform3D()

@onready var player_model = $PlayerModel
@onready var player_input = $PlayerInput

@export var player := 1:
	set(id):
		player = id
		$PlayerInput.set_multiplayer_authority(id)

func _ready():
	orientation = player_model.global_transform
	orientation.origin = Vector3()
	if not multiplayer.is_server():
		set_process(false)

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_apply_input(delta)

@rpc("any_peer")
func respawn():
	print("Respawning %s" % player)
	var pos := Vector2.from_angle(randf() * 2 * PI)
	position = Vector3(pos.x * 5, 0, pos.y * 5)

@rpc ("any_peer")
func take_damage(damage: int):
	if not is_multiplayer_authority():
		return
	health -= damage

func _apply_input(delta: float):
	motion = motion.lerp(player_input.input_motion, MOTION_INTERPOLATE_SPEED * delta)
	#print(motion)
	
	var camera_basis : Basis = player_input.get_camera_rotation_basis()
	var camera_z := camera_basis.z
	var camera_x := camera_basis.x
	
	camera_z.y = 0
	camera_z = camera_z.normalized()
	camera_x.y = 0
	camera_x = camera_z.normalized()
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if not player_input.jumping && player_input.do_jump and is_on_floor():
		player_input.do_jump = false
		player_input.jumping = true
	elif player_input.jumping and is_on_floor():
		velocity.y = JUMP_VELOCITY
		player_input.jumping = false
	elif is_on_floor():
		var target = camera_x * motion.x + camera_z * motion.y
		if target.length() > 0.001:
			var q_from = orientation.basis.get_rotation_quaternion()
			var q_to = Transform3D().looking_at(target, Vector3.UP).basis.get_rotation_quaternion()
			orientation.basis = Basis(q_from.slerp(q_to, delta * ROTATION_INTERPOLATE_SPEED))
	
	var rotmotion = camera_basis * Vector3(motion.x, 0, motion.y)	
	velocity.x = rotmotion.x * SPEED
	velocity.z = rotmotion.z * SPEED
	
	# Apply Movement
	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()
	
	# Cleanup
	orientation.origin = Vector3()
	orientation = orientation.orthonormalized()
	player_model.global_transform.basis = orientation.basis

extends MultiplayerSynchronizer

@export var jumping := false
@export var input_motion := Vector2()
@export var do_jump := false
@export var mbdown := false

@export var camera_base : Node3D
@export var camera_rot : Node3D
@export var camera_3D : Camera3D

const CAMERA_CONTROLLER_ROTATION_SPEED := 3.0
const CAMERA_MOUSE_ROTATION_SPEED := 0.01
const CAMERA_X_ROT_MIN := deg_to_rad(-89.9)
const CAMERA_X_ROT_MAX := deg_to_rad(89.9)
const CAMERA_UP_DOWN_MOVEMENT = -1

func _ready() -> void:
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		camera_3D.make_current()
	else:
		set_process(false)
		set_process_input(false)

func _process(delta: float) -> void:
	input_motion = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if Input.is_action_just_pressed("ui_accept"):
		jump.rpc()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_camera(event.relative * CAMERA_MOUSE_ROTATION_SPEED)
	if event is InputEventMouseButton and event.get_button_index() == MOUSE_BUTTON_LEFT:
		mbdown = event.pressed

func rotate_camera(move):
	camera_base.rotate_y(-move.x)
	camera_base.orthonormalize()
	camera_rot.rotation.x = clamp(camera_rot.rotation.x + (CAMERA_UP_DOWN_MOVEMENT * move.y), CAMERA_X_ROT_MIN, CAMERA_X_ROT_MAX)

func get_camera_rotation_basis() -> Basis:
	return camera_rot.global_transform.basis

func get_camera() -> Camera3D:
	return camera_3D

@rpc("call_local")
func jump():
	do_jump = true

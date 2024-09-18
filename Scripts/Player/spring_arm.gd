extends SpringArm3D

# Settings for how fast the spring arm will rotate the camera and its range of motion.
@export var _rotation_speed : float = 2
@export var _min_x_rotation : float = -1
@export var _max_x_rotation : float = 1
@export var _reset_x_rotation : float = -0.5
@export var _duration : float = 0.25
@onready var _character : CharacterBody3D = get_parent()
var _target_direction : Vector3
var _target_rotation : Vector3 = Vector3(_reset_x_rotation, 0, 0)
var _tween : Tween
var _target : Node3D

# Rotate the spring arm based on player input.
func look(direction : Vector2):
	# vertical y rotation
	rotation.x += direction.y * _rotation_speed * get_process_delta_time() * (1 if File.settings.camera_invert_y else -1)
	rotation.x = clampf(rotation.x, _min_x_rotation, _max_x_rotation)
	# horizontal x rotation
	rotation.y += direction.x * _rotation_speed * get_process_delta_time() * (1 if File.settings.camera_invert_x else -1)

func position_camera_behind_character(duration : float = _duration):
	_tween_rotation(_character.get_rig_rotation().y + PI, duration)

func _process(_delta : float):
	if _target and (not _tween or not _tween.is_running()):
		_target_direction = global_position - _target.global_position
		rotation.y = atan2(_target_direction.x, _target_direction.z)

func _tween_rotation(target_y_rotation : float, duration : float = _duration):
	_target_rotation.y = wrapf(target_y_rotation, rotation.y - PI, rotation.y + PI)
	if _tween && _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "rotation", _target_rotation, duration)

func _on_player_targeted(new_target : Node3D):
	_target = new_target
	if _target:
		_target_direction = global_position - _target.global_position
		_tween_rotation(atan2(_target_direction.x, _target_direction.z))

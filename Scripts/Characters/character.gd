extends CharacterBody3D

# Components required to draw and animate the character.
@onready var _rig : Node3D = $Rig
@onready var _animation : AnimationTree = $AnimationTree
@onready var _state : AnimationNodeStateMachinePlayback = _animation["parameters/playback"]

# Variables for controlling how a character walks, runs, and rotates.
@export_category("Locomotion")
@export var _walking_speed : float = 2
@export var _running_speed : float = 4
@export var _acceleration : float = 8
@export var _deceleration : float = 16
@export var _rotation_speed : float = PI * 2
@onready var _movement_speed : float = _walking_speed
var _input_direction : Vector3
var _angle_difference : float
var _xz_velocity : Vector3
var _can_move : bool = true:
	set(new_value):
		_can_move = new_value
		if not _can_move:
			_input_direction = Vector3.ZERO

# Variables for controlling how a character jumps and falls.
@export_category("Jumping")
@export var _jump_height : float = 1
@export var _air_control : float = 0.5
@export var _air_brakes : float = 0.5
var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var _jump_velocity : float

# Equipment sockets; Main Hand, Off Hand, Head, Back
@export_category("Equipment")
@export var _sockets : Array[BoneAttachment3D]

# Calculate the amount of force required to reach the desired jump height.
func _ready():
	_jump_velocity = sqrt(_jump_height * _gravity * 2)

# Which direction is the character rig facing in global space?
func get_rig_rotation() -> Vector3:
	return _rig.global_rotation

#region Equip

# Put on a piece of equipment using the item's designated socket.
func don(item : Equipment):
	var instance : Node3D = load(item.scene).instantiate()
	_sockets[item.type].add_child(instance)
	instance.freeze = true

# Remove any piece of equipment in the designated socket.
func doff(socket : int):
	if _sockets[socket].get_child_count() > 0:
		_sockets[socket].get_child(0).queue_free()

#endregion

#region Movement

# Tell this character to move in a direction, if they can.
func move(direction : Vector3):
	if not _can_move:
		return
	_input_direction = direction

# Change this character's movement speed to walking or running speed.
func walk():
	_movement_speed = _walking_speed
func run():
	_movement_speed = _running_speed

# Tell this character to jump if they can.
func jump():
	# Characters can only jump if they are able to move and are on the floor.
	if not _can_move or not is_on_floor():
		return
	# Tell the animation tree to transition to Jump Start state.
	_state.travel("Jump_Start")

# Jump animation calls this function once the character's feet leave the ground.
func _apply_jump_velocity():
	if is_on_floor():
		velocity.y = _jump_velocity

#endregion

#region Physics

# Every physics frame...
func _physics_process(delta : float):
	# If the player is giving movement input
	if _input_direction:
		# Face direction of input
		_rotate_towards_direction(_input_direction, delta)
	# Copy the character's x and z velocity to isolate from y.
	_xz_velocity = Vector3(velocity.x, 0, velocity.z)
	# Do ground or air physics
	if is_on_floor():
		_ground_physics(delta)
	else:
		_air_physics(delta)
	# Apply adjusted xz velocity to the character
	velocity.x = _xz_velocity.x
	velocity.z = _xz_velocity.z

	# Apply forces to the character for this frame
	move_and_slide()

# Rotate the character rig to turn towards the direction they want to face.
func _rotate_towards_direction(direction : Vector3, delta : float):
	_angle_difference = wrapf(atan2(direction.x, direction.z) - _rig.rotation.y, -PI, PI)
	_rig.rotation.y += clamp(_rotation_speed * delta, 0, abs(_angle_difference)) * sign(_angle_difference)

func _ground_physics(delta : float):
	# Apply movement input to the xz velocity
	if _input_direction:
		# Accelerate
		if _input_direction.dot(velocity) >= 0:
			_xz_velocity = _xz_velocity.move_toward(_input_direction * _movement_speed, _acceleration * delta)
		# Turn around
		else:
			_xz_velocity = _xz_velocity.move_toward(_input_direction * _movement_speed, _deceleration * delta)
	# Decelerate
	else:
		_xz_velocity = _xz_velocity.move_toward(Vector3.ZERO, _deceleration * delta)
	# Tell the animation tree how to blend the locomotion animations
	_animation.set("parameters/Locomotion/blend_position", _xz_velocity.length() / _running_speed)

func _air_physics(delta : float):
	# Add the gravity.
	velocity.y -= _gravity * delta
	# Apply movement input to the xz velocity
	if _input_direction:
		# Accelerate
		_xz_velocity = _xz_velocity.move_toward(_input_direction * _movement_speed, _acceleration * _air_control * delta)
	else:
		# Decelerate
		_xz_velocity = _xz_velocity.move_toward(Vector3.ZERO, _deceleration * _air_brakes * delta)

#endregion

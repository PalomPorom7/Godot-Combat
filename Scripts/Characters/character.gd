extends CharacterBody3D

# Components required to draw and animate the character.
@onready var _rig : Node3D = $Rig
@onready var _animation : AnimationTree = $AnimationTree

# Variables for controlling how a character walks, runs, and rotates.
@export_category("Locomotion")
@export var _walking_speed : float = 2
@export var _running_speed : float = 4
@export var _acceleration : float = 8
@export var _deceleration : float = 16
@export var _rotation_speed : float = PI * 2
@onready var _movement_speed : float = _walking_speed
var _input_direction : Vector3
var _wants_to_face_direction : Vector3
var _angle_difference : float
var _xz_velocity : Vector3
var _relative_velocity : Vector3
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
var _attack_animation : Enums.WeaponType
var _main_hand : Node3D
var _off_hand : Node3D

# Combat variables
@export_category("Combat")
@export var _max_health : int = 5
@onready var _current_health : int = _max_health
@onready var _unarmed_hit_box : Area3D = get_node_or_null("Rig/Hit Box")
@export_flags_3d_physics var _enemy_hurt_layer : int
@onready var _hurt_box : Area3D = $"Hurt Box"
var _is_dead : bool
var _from_behind : bool
var _target : Node3D
var _locked_on_blend : Vector2

# Buffered Inputs
var _wants_to_jump : bool
var _wants_to_attack : bool

signal health_changed(percentage : float)
signal died

# Calculate the amount of force required to reach the desired jump height.
func _ready():
	_jump_velocity = sqrt(_jump_height * _gravity * 2)
	if _unarmed_hit_box:
		_unarmed_hit_box.collision_mask = _enemy_hurt_layer

# Which direction is the character rig facing in global space?
func get_rig_rotation() -> Vector3:
	return _rig.global_rotation

#region Equip

# Put on a piece of equipment using the item's designated socket.
func don(item : Equipment):
	var instance : Node3D = load(item.scene).instantiate()
	_sockets[item.type].add_child(instance)
	instance.freeze = true
	if item is Weapon:
		_main_hand = instance
		_main_hand.damage = item.damage
		_main_hand.set_hit_box_collision_mask(_enemy_hurt_layer)
		_attack_animation = item.weapon_type
		if item.weapon_type == Enums.WeaponType.DUAL_WIELD:
			instance = load(item.scene).instantiate()
			_sockets[Enums.EquipmentType.OFF_HAND].add_child(instance)
			instance.freeze = true
			_off_hand = instance
			_off_hand.damage = item.damage
			_off_hand.set_hit_box_collision_mask(_enemy_hurt_layer)

# Remove any piece of equipment in the designated socket.
func doff(socket : int):
	if socket == Enums.EquipmentType.MAIN_HAND:
		_main_hand = null
		if _attack_animation == Enums.WeaponType.DUAL_WIELD:
			doff(Enums.EquipmentType.OFF_HAND)
		_attack_animation = Enums.WeaponType.UNARMED
	elif socket == Enums.EquipmentType.OFF_HAND:
		_off_hand = null
	if _sockets[socket].get_child_count() > 0:
		_sockets[socket].get_child(0).queue_free()

#endregion

#region Movement

func restrict_movement(can_not_move : bool):
	_can_move = not can_not_move

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
	_wants_to_jump = true
	_wants_to_attack = false

func cancel_jump():
	_wants_to_jump = false

# Jump animation calls this function once the character's feet leave the ground.
func _apply_jump_velocity():
	if is_on_floor():
		velocity.y = _jump_velocity

#endregion

#region Combat

func _on_player_targeted(new_target : Node3D):
	_target = new_target

func attack():
	_wants_to_attack = true
	_wants_to_jump = false

func cancel_attack():
	_wants_to_attack = false

func activate_hit_box(active : bool, which_hand : int = 1):
	match which_hand:
		0:
			_unarmed_hit_box.monitoring = active
		1:
			_main_hand.activate_hit_box(active)
		2:
			_off_hand.activate_hit_box(active)

func _on_hit_box_area_entered(hurt_box : Area3D):
	hurt_box.get_parent().take_damage(1, (global_position - hurt_box.global_position).normalized())

func take_damage(amount : int, direction : Vector3 = Vector3.ZERO):
	_current_health = max(_current_health - amount, 0)
	_interrupt_actions()
	health_changed.emit(float(_current_health) / _max_health)
	_from_behind = direction.dot(_rig.global_basis.z) < 0
	if _current_health == 0:
		_is_dead = true
		died.emit()
		collision_layer = 0
		collision_mask = 1
		_hurt_box.set_deferred("monitorable", false)
	else:
		_animation.get_hit(amount < 2)

func _interrupt_actions():
	deactivate_all_hit_boxes()

func deactivate_all_hit_boxes():
	if _unarmed_hit_box:
		_unarmed_hit_box.monitoring = false
	if _main_hand:
		_main_hand.activate_hit_box(false)
	if _off_hand:
		_off_hand.activate_hit_box(false)

#endregion

#region Physics

# Every physics frame...
func _physics_process(delta : float):
	# If the player is giving movement input
	if _input_direction:
		# Face direction of input or towards target
		if _target:
			_wants_to_face_direction = _target.global_position - global_position
		else:
			_wants_to_face_direction = _input_direction
		_rotate_towards_direction(_wants_to_face_direction, delta)
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
	_animation.character_is_moving(velocity != Vector3.ZERO)

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
	_relative_velocity = _xz_velocity / _running_speed
	if _target:
		_locked_on_blend.x = _rig.global_basis.x.dot(_relative_velocity) * -1
		_locked_on_blend.y = _rig.global_basis.z.dot(_relative_velocity)
		_animation.set_locked_on_blend(_locked_on_blend)
	else:
		_animation.set_not_locked_on_blend(_relative_velocity.length())

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

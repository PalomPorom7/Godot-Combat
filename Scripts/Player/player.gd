extends Node

# Various things that player input might need to be forwarded to.
@onready var _gm : Node3D = $/root/Game
@onready var _character : CharacterBody3D = %Character
@onready var _spring_arm : SpringArm3D = %SpringArm
@onready var _camera : Camera3D = %Camera
@onready var _target_indicator : Sprite3D = $"Target Indicator"
var _target : Node3D:
	set(new_target):
		_target = new_target
		targeted.emit(_target)

signal targeted(new_target : Node3D)

# The direction of WASD or left analog stick input.
var _input_direction : Vector2
# The input direction in global space relative to the rotation of the camera.
var _move_direction : Vector3
# If player input is disabled for any reason, immediately stop the character from moving.
var enabled : bool = true:
	set(new_value):
		enabled = new_value
		# Stop character from moving after player control is disabled
		if not enabled:
			_character.move(Vector3.ZERO)

# Called any time input is given.
func _input(event : InputEvent):
	# Tell the game manager to toggle game pause.
	if event.is_action_pressed("pause"):
		_gm.toggle_pause()
	# If the game is paused, all other input is ignored.
	if get_tree().paused:
		return
	# Tell the game manager to toggle the inventory menu.
	if event.is_action_pressed("inventory"):
		_gm.toggle_inventory()
	# Ignore any other inputs if the player controls are not enabled
	if enabled:
		_camera_inputs(event)
		_character_inputs(event)

# Input events that control the camera.
func _camera_inputs(event : InputEvent):
	# Free movement of camera with the mouse
	if not _target and event is InputEventMouseMotion:
		_spring_arm.look(event.relative * get_process_delta_time())
	if event.is_action_pressed("toggle_lock"):
		if _target:
			# if pressing down, force lock off
			if _input_direction.dot(Vector2.DOWN) > 0.75:
				toggle_lock(true)
			else:
				toggle_lock()
		else:
			toggle_lock()
			if not _target:
				_spring_arm.position_camera_behind_character()

func toggle_lock(force_off : bool = false):
	_target = null if force_off else _camera.get_nearest_visible_target(_target)
	if _target:
		_target_indicator.reparent(_target)
		_target_indicator.position = Vector3.UP * 3
		_target_indicator.visible = true
	else:
		_target_indicator.reparent(self)
		_target_indicator.visible = false

# Input events that control the character.
func _character_inputs(event : InputEvent):
	# Toggle run or walk
	if event.is_action_pressed("run"):
		_character.run()
	elif event.is_action_released("run"):
		_character.walk()
	# Jump
	if event.is_action_pressed("jump"):
		_character.jump()

# Every frame, ignoring delta time
func _process(_delta : float):
	# If paused or player controls are disabled, do nothing
	if get_tree().paused || not enabled:
		return

	# Free movement of the camera with the right analog stick on controller
	if not _target:
		_spring_arm.look(Input.get_vector("look_left", "look_right", "look_up", "look_down"))

	# Character movement with left analog stick or WASD keys, from the perspective of the camera
	_input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	_move_direction = (_camera.global_basis.x * Vector3(1, 0, 1)).normalized() * _input_direction.x
	_move_direction += (_camera.global_basis.z * Vector3(1, 0, 1)).normalized() * _input_direction.y
	_character.move(_move_direction)

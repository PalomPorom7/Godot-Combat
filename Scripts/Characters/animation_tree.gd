extends AnimationTree

@export var _blend_speed : float = 4
var _action_state : AnimationNodeStateMachinePlayback
var _blend_node : AnimationNodeBlend2
var _blend_amount : float = 0.01

func _ready():
	tree_root = tree_root.duplicate(true)
	_action_state = self["parameters/Action/playback"]
	_blend_node = tree_root.get_node("Lower+Upper")

func character_is_moving(is_moving : bool):
	_blend_node.filter_enabled = is_moving

func set_locked_on_blend(blend_amount : Vector2):
	set("parameters/Movement/Locomotion/Locked On/blend_position", blend_amount)

func set_not_locked_on_blend(blend_amount : float):
	set("parameters/Movement/Locomotion/Not Locked On/blend_position", blend_amount)

func _process(delta : float):
	if _action_state.get_current_node() == "Idle":
		_blend_amount = move_toward(_blend_amount, 0.01, _blend_speed * delta)
	else:
		_blend_amount = move_toward(_blend_amount, 0.99, _blend_speed * delta)
	set("parameters/Lower+Upper/blend_amount", _blend_amount)

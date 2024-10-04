extends AnimationTree

@export var _blend_speed : float = 4
var _hit_state : AnimationNodeStateMachinePlayback
var _action_state : AnimationNodeStateMachinePlayback
var _blend_node : AnimationNodeBlend2
var _blend_amount : float = 0.01

func _ready():
	tree_root = tree_root.duplicate(true)
	_hit_state = self["parameters/Hit/playback"]
	_action_state = self["parameters/Hit/BlendTree/Action/playback"]
	_blend_node = tree_root.get_node("Hit").get_node("BlendTree").get_node("Lower+Upper")

func character_is_moving(is_moving : bool):
	_blend_node.filter_enabled = is_moving

func set_locked_on_blend(blend_amount : Vector2):
	set("parameters/Hit/BlendTree/Movement/Locomotion/Locked On/blend_position", blend_amount)

func set_not_locked_on_blend(blend_amount : float):
	set("parameters/Hit/BlendTree/Movement/Locomotion/Not Locked On/blend_position", blend_amount)

func set_dodge_blend(blend_amount : Vector2):
	set("parameters/Hit/BlendTree/Movement/Dodge/blend_position", blend_amount)

func is_blocking() -> bool:
	var current_action : String = _action_state.get_current_node()
	return current_action == "Blocking" or current_action == "Block_Hit"

func block_hit():
	_action_state.travel("Block_Hit")

func get_hit(lightly : bool):
	_hit_state.travel("Hit_A" if lightly else "Hit_B")

func _process(delta : float):
	if _action_state.get_current_node() == "Idle":
		_blend_amount = move_toward(_blend_amount, 0.01, _blend_speed * delta)
	else:
		_blend_amount = move_toward(_blend_amount, 0.99, _blend_speed * delta)
	set("parameters/Hit/BlendTree/Lower+Upper/blend_amount", _blend_amount)

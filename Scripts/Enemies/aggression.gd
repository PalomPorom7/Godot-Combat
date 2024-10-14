extends Node3D

@onready var _character : CharacterBody3D = get_parent()
@onready var _field_of_vision : Area3D = $"Field of Vision"
@onready var _line_of_sight : RayCast3D = $"Field of Vision/Line of Sight"
var _target : CharacterBody3D
var _has_seen_target : bool

func _ready():
	_character.died.connect(stop)

func _process(_delta : float):
	rotation.y = _character.get_rig_rotation().y
	if not _target:
		return
	if not _has_seen_target:
		_line_of_sight.target_position = _target.global_position + Vector3.UP - global_position
		_line_of_sight.force_raycast_update()
		if _line_of_sight.is_colliding() and _line_of_sight.get_collider() == _target:
			_has_seen_target = true
			_target.died.connect(stop)
	else:
		_character.navigate_to(_target.global_position)

func stop():
	_target = null
	_has_seen_target = false
	_character.move(Vector3.ZERO)
	_field_of_vision.monitoring = false

func _on_attack_range_area_entered(_hurt_box : Area3D):
	_character.attack()

func _on_attack_range_area_exited(_hurt_box : Area3D):
	_character.cancel_attack()

func _on_field_of_vision_body_entered(body : Node3D):
	_target = body

func _on_field_of_vision_body_exited(body : Node3D):
	if body == _target and not _has_seen_target:
		_target = null

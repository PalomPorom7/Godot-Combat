extends Item

@onready var _hit_box : Area3D = $"Hit Box"
var damage : int

func set_hit_box_collision_mask(mask : int):
	_hit_box.collision_mask = mask

func activate_hit_box(active : bool):
	_hit_box.monitoring = active

func _on_hit_box_area_entered(hurt_box : Area3D):
	hurt_box.get_parent().take_damage(damage, (global_position - hurt_box.global_position).normalized())

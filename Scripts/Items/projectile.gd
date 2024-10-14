extends RigidBody3D

@export var _damage : int = 1
@onready var _hit_box : Area3D = $"Hit Box"
@onready var _timer : Timer = $Timer

func on_load(damage : int, enemy_collision_layer : int):
	_damage += damage
	_hit_box.collision_mask = enemy_collision_layer
	freeze = true

func shoot(impulse_force : Vector3):
	freeze = false
	reparent($/root/Game)
	look_at(global_position - impulse_force)
	apply_central_impulse(impulse_force)
	_timer.start()
	_hit_box.monitoring = true

func _on_body_entered(_body : Node):
	set_deferred("freeze", true)
	_hit_box.set_deferred("monitoring", false)

func _on_timer_timeout():
	queue_free()

func _on_hit_box_area_entered(hurt_box : Area3D):
	hurt_box.get_parent().take_damage(_damage, (global_position - hurt_box.global_position).normalized())
	queue_free()

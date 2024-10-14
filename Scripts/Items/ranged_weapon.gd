extends Item

@export var _ammo_prefab : PackedScene
@onready var _ammo_socket : Node3D = $"Ammo Socket"
var loaded_ammo : RigidBody3D
var damage : int
var force : float = 10
var enemy_collision_layer : int

func set_hit_box_collision_mask(mask : int):
	enemy_collision_layer = mask

func activate_hit_box(_active : bool):
	return

func shoot(direction : Vector3):
	loaded_ammo.shoot(direction * force)
	loaded_ammo = null

func shoot_at_target(target : Node3D):
	loaded_ammo.shoot((target.global_position + Vector3.UP - global_position).normalized() * force)
	loaded_ammo = null

func reload():
	loaded_ammo = _ammo_prefab.instantiate()
	_ammo_socket.add_child(loaded_ammo)
	loaded_ammo.on_load(damage, enemy_collision_layer)

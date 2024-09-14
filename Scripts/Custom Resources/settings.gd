class_name Settings extends Resource

@export var camera_invert_x : bool
@export var camera_invert_y : bool
@export var master_volume : float
@export var music_volume : float
@export var sfx_volume : float
@export var typing_speed : int

func _init():
	camera_invert_x = false
	camera_invert_y = true
	master_volume = 1
	music_volume = 0.5
	sfx_volume = 0.5
	typing_speed = 90

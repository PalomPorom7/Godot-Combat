extends Node

@export var _weapon : Weapon
@onready var _character : CharacterBody3D = get_parent()

func _ready():
	_character.don(_weapon)

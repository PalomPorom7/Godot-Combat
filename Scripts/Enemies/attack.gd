extends Node

@onready var _character : CharacterBody3D = get_parent()

func _ready():
	_character.attack()

extends Node3D

# All the things this manager needs to manage.
@onready var _character : CharacterBody3D = %Character
@onready var _pause_menu : Control = %"Pause Menu"
@onready var _current_level : Node3D = $Graveyard
@onready var _inventory = $UI/Inventory
@onready var _fade : ColorRect = $UI/Fade

func _ready():
	# Hide cursor and use mouse inputs for camera controls
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Position the character at the start position
	_character.position = _current_level.get_player_start_position()
	# Fade in
	_fade.to_clear()

# Pause and unpause the game, display pause menu
func toggle_pause():
	get_tree().paused = !get_tree().paused
	if get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_pause_menu.open()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_pause_menu.close()

# Open or close the inventory menu.
func toggle_inventory():
	if _inventory.is_open:
		_inventory.close()
	else:
		_inventory.open()

# Return to the title scene
func _on_exit_pressed():
	await _fade.to_black()
	get_tree().quit()

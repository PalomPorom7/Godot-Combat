extends Menu

# Prefab button to represent an item in the player's inventory.
const PREFAB : PackedScene = preload("res://Scenes/UI/item.tscn")

# So the player controls can be disabled while the inventory menu is open.
@onready var _player : Node = %Player
# The player character can equip or unequip items from the inventory.
@onready var _character : CharacterBody3D = %Character
# The container which holds the buttons representing the player's inventory.
@onready var _container : Container = $ScrollContainer/GridContainer
# Text labels to display the currently selected item's information.
@onready var _item_name : Label = $"Info/Item Name"
@onready var _item_description : Label = $"Info/Item Description"
# A button to equip or unequip the selected item.
@onready var _button : Button = $Info/HBoxContainer/Button
# Which item and button is currently selected, and previously selected.
var _selected_item : ItemInfo
var _selected_button : Button
var _previously_selected_button : Button

func _ready():
	# Populate with the player's starting inventory
	for item in File.progress.inventory:
		_add_item_button(load("res://Scripts/Custom Resources/Items/" + item.name + ".tres"))
	# Equip player character with their starting equipment
	for equipped in File.progress.equipment:
		if equipped != -1:
			_container.get_child(equipped).grab_focus()
			_equip_selected_item()

# Open the inventory menu
func open(breadcrumb : Menu = null):
	_player.enabled = false
	super.open(breadcrumb)
	# If there is at least 1 item, tell the first item to grab focus.
	if _container.get_child_count() > 0:
		_container.get_child(0).grab_focus()
	# Otherwise display no item information.
	else:
		_display_item_information(null)

# Add 1 item to the player's inventory
func add_item(item : ItemInfo):
	File.progress.inventory.push_back({"name" : item.name})
	_add_item_button(item)

# Create a new button to represent the item.
func _add_item_button(item : ItemInfo, container : Container = _container):
	var new_item_button : Button = PREFAB.instantiate()
	new_item_button.get_node("Icon").texture = item.icon
	container.add_child(new_item_button)
	new_item_button.focus_entered.connect(_display_item_information.bind(item, new_item_button))
	new_item_button.focus_exited.connect(_display_item_information)

# Display the name and description of the selected item on the right side of the inventory menu.
func _display_item_information(item : ItemInfo = null, button : Button = null):
	_item_name.text = item.name if item else ""
	_item_description.text = item.description if item else ""
	_selected_item = item
	_previously_selected_button = _selected_button
	_selected_button = button
	# Disable button if no item is selected
	_button.disabled = not item
	# Change the text on the button.
	if _selected_item_is_equipped():
		_button.text = "X Unequip"
	else:
		_button.text = "X Equip"

# Check whether the item button which has focus represents something the player character has equipped.
func _selected_item_is_equipped() -> bool:
	return (
		_selected_item &&
		_selected_item is Equipment &&
		File.progress.equipment[_selected_item.type] == _container.get_children().find(_selected_button)
		)

# Hotkey controller inputs to activate equip/unequip button
func _input(event : InputEvent):
	if not is_open:
		return
	if event.is_action_pressed("equip_item"):
		_button.pressed.emit()

# If action button is clicked, immediately return focus back to the previously selected item button.
func _on_action_button_focus_entered():
	if _previously_selected_button:
		_previously_selected_button.grab_focus()

# Equip or unequip the selected item when the button is pressed.
func _on_auxiliary_pressed():
	if _selected_item:
		if _selected_item is Equipment:
			if _selected_item_is_equipped():
				_unequip_selected_item()
			else:
				_equip_selected_item()

# Equip the selected item.
func _equip_selected_item():
	# Unequip currently equipped item in the slot.
	if File.progress.equipment[_selected_item.type] != -1:
		_character.doff(_selected_item.type)
		_container.get_child(File.progress.equipment[_selected_item.type]).get_node("Label").visible = false
	# Set the data in the player's progress resource.
	File.progress.equipment[_selected_item.type] = _container.get_children().find(_selected_button)
	# Tell the character to put on the equipment.
	_character.don(_selected_item)
	# Put an "E" on the item button.
	_selected_button.get_node("Label").visible = true
	# Change the text on the auxiliary button.
	_button.text = "X Unequip"

# Unequip the selected item.
func _unequip_selected_item():
	# Set the data in the player's progress resource.
	File.progress.equipment[_selected_item.type] = -1
	# Tell the character to remove the equipment.
	_character.doff(_selected_item.type)
	# Remove the "E" from the item button.
	_selected_button.get_node("Label").visible = false
	# Change the text on the auxiliary button.
	_button.text = "X Equip"

# Re-enable player controls when the inventory menu is closed.
func close():
	if not _breadcrumb:
		_player.enabled = true
	super.close()

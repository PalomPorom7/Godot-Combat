class_name Progress extends Resource

@export var inventory : Array
@export var equipment : Array

# Initialize the player's inventory.
func _init():
	inventory = [
		{"name" : "Axe"},
		{"name" : "Barbarian Round Shield"},
		{"name" : "Barbarian Hat"},
		{"name" : "Barbarian Cape"},
		{"name" : "Crossbow"},
		{"name" : "Greataxe"},
		{"name" : "Greatsword"},
		{"name" : "Heavy Crossbow"},
		{"name" : "Knife"},
		{"name" : "Sword"}
	]
	equipment = [-1, -1, 2, 3]

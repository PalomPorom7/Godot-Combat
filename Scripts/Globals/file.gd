extends Node

# Where to save settings and progress data for user
const SETTINGS_PATH : String = "user://settings.tres"
const SAVE_PATH : String = "user://save.res"

# Public variables accessible through autoload
var settings : Settings
var progress : Progress

func _ready():
	# So I can skip the title scene...
	new_game()
	# Check if settings exist, load or create them
	if ResourceLoader.exists(SETTINGS_PATH):
		settings = ResourceLoader.load(SETTINGS_PATH)
	else:
		settings = Settings.new()
		ResourceSaver.save(settings, SETTINGS_PATH)

# Save the game settings for this user
func save_settings():
	ResourceSaver.save(settings, SETTINGS_PATH)

# Return whether or not the user has a save file
func save_file_exists() -> bool:
	return ResourceLoader.exists(SAVE_PATH)

# Start a new game
func new_game():
	progress = Progress.new()

# Save the player's progress
func save_game():
	ResourceSaver.save(progress, SAVE_PATH)

# Load the player's progress
func load_game():
	progress = ResourceLoader.load(SAVE_PATH)

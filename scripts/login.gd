# *************************************************
# godot3-spacegame by Yanick Bourbeau
# Released under MIT License
# *************************************************
# CLIENT-SIDE CODE
#
# Populate the login form and handle callbacks
# on buttons.
#
# *************************************************
extends CanvasLayer

onready var input_color = $ui/grid/input_color
onready var input_player =$ui/grid/text_player
onready var input_hostname = $ui/grid/text_hostname

func _ready():
	# Adding four spaceship colors
	input_color.add_item("Blue")
	input_color.add_item("Red")
	input_color.add_item("Green")
	input_color.add_item("Yellow")
	
	# Set default hostname
	input_hostname.text = global.DEFAULT_HOSTNAME
	pass

# Callback function for "Start!" button
func _on_button_login_pressed():
	
	# Store information about spaceship color and player name
	global.cfg_color = input_color.text
	global.cfg_player_name = input_player.text
	
	# Lookup hostname and store resolved IP
	global.cfg_server_ip = IP.resolve_hostname(input_hostname.text)
	
	# Change to client scene
	if get_tree().change_scene("res://scenes/client.tscn") != OK:
		print("Unable to load client scene!")

# Callback function for "Start Server" button
func _on_button_start_server_pressed():
	# Change to server scene
	if get_tree().change_scene("res://scenes/server.tscn") != OK:
		print("Unable to load server scene!")



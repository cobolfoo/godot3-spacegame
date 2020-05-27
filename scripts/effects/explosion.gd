# *************************************************
# godot3-spacegame by Yanick Bourbeau
# Released under MIT License
# *************************************************
# CLIENT-SIDE CODE
#
# Display spaceship explosion
#
# *************************************************
extends Node2D


var total_delta = 0

func _process(delta):
	total_delta += delta
	# Destroy after 10 seconds
	if total_delta > 10:
		queue_free()

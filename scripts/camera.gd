# *************************************************
# godot3-spacegame by Yanick Bourbeau
# Released under MIT License
# *************************************************
# CLIENT AND SERVER-SIDE CODE
#
# Handle camera and zoom level (mouse input)
#
# *************************************************
extends Camera2D

var correction_speed = 2.0
var zoom_speed = 5.0
var zoom_interval = 5
var target_translation_y = 8
var ignore_mousewheel = false
var current_zoom = Vector2(8,8)

func _ready():
	set_process_input(true)


func _physics_process(delta):
	update_position(delta)
	


func _input(_event):
	
	# Handle mouse input (mousewheel and middle button)
	
	if Input.is_action_just_pressed("zoom_reset"):
		target_translation_y = 8
		ignore_mousewheel = false
		return
	
	if ignore_mousewheel:
		return
	
	if Input.is_action_just_pressed("zoom_up"):
		ignore_mousewheel = true
		target_translation_y -= zoom_interval
		if (target_translation_y < 4):
			target_translation_y = 4
		return
		
	if Input.is_action_just_pressed("zoom_down"):
		ignore_mousewheel = true
		target_translation_y += zoom_interval
		if (target_translation_y > 12):
			target_translation_y = 12
		return
	
	
# We use linear interpolation to smooth zooming movement
func update_position(delta):

	current_zoom.x = lerp(current_zoom.x, target_translation_y, zoom_speed * delta)
	current_zoom.y = lerp(current_zoom.y, target_translation_y, zoom_speed * delta)
	if abs(current_zoom.x - target_translation_y) < 1.0:
		ignore_mousewheel = false
		
	set_zoom(current_zoom)
	


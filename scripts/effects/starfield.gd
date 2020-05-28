# *************************************************
# godot3-spacegame by Yanick Bourbeau
# Released under MIT License
# *************************************************
# CLIENT-SIDE CODE
#
# Add a beautiful starfield to the game.
#
# We create 2000 stars (1 pixel) at random positions
# inside a -2000,2000 range for both axis.
#
# *************************************************
extends Control

onready var texture_star = preload("res://images/star.png")
onready var node_camera = get_node("/root/world/camera")

var sprites = []
var points = []
var colors = []
var previous_position = null

func _ready():
	var sprite = Sprite.new()
	sprite.texture = texture_star
	for _i in range(2000):
		var x = rand_range(-2000, 2000)
		var y = rand_range(-2000, 2000)
		# Using VisualServer to prevent performance issues
		var ci_rid = VisualServer.canvas_item_create()
		VisualServer.canvas_item_set_parent(ci_rid, get_canvas_item())
		VisualServer.canvas_item_add_texture_rect(ci_rid, Rect2(-0.1,-0.5,1, 1), sprite)
		var xform = Transform2D().translated(Vector2(x,y))
		VisualServer.canvas_item_set_transform(ci_rid, xform)
		var c = rand_range(0.25, 1.0)
		VisualServer.canvas_item_set_modulate (ci_rid, Color(c,c,c))
		colors.append(c)
		points.append(Vector2(x,y))
		sprites.append(ci_rid)
		

func _process(_delta):

	if previous_position == null:
		previous_position = node_camera.offset

	var diff = previous_position - node_camera.offset
	previous_position = node_camera.offset
	
	# Adjust starfield speed
	diff *= 0.2
	
	for i in len(sprites):
		points[i].x += diff.x * colors[i]
		points[i].y += diff.y * colors[i]
		
		# If a point is outside of range, teleport it.
		if points[i].x > 2000:
			points[i].x -= 4000
		if points[i].y > 2000:
			points[i].y -= 4000
		if points[i].x < -2000:
			points[i].x += 4000
		if points[i].y < -2000:
			points[i].y += 4000
			
		var xform = Transform2D().translated(points[i])
		VisualServer.canvas_item_set_transform(sprites[i], xform)
			

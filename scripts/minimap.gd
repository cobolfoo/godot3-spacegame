# *************************************************
# godot3-spacegame by Yanick Bourbeau
# Released under MIT License
# *************************************************
# CLIENT-SIDE CODE
#
# Display current player and other objects (players)
# on a 128x128 minimap (bottom-right)
#
# *************************************************
extends TextureRect

onready var texture_object = preload("res://images/minimap/object.png")
onready var texture_player = preload("res://images/minimap/player.png")
onready var label_position = $label_position
onready var node_root = get_node("/root/world")
var total_delta = 0

# Redraw the minimap once per 1/2 second
func _process(delta):
	total_delta += delta
	if (total_delta > 0.5):
		total_delta -= 0.5
		update()

# Draw the players on the minimap
func _draw():

	var peer_id = get_tree().get_network_unique_id()
	var pos = Vector2(0,0)
	if node_root.player_info.has(peer_id):
		pos.x += node_root.player_info[peer_id].position.x
		pos.y += node_root.player_info[peer_id].position.y
		label_position.text = str(round(pos.x))+","+str(round(pos.y))
		
	for peer_id in node_root.player_info:
		
		var object = node_root.player_info[peer_id]
		if object.destroyed:
			continue
			
		# Convert world size to texture rectangle size
		var world_radius = global.WORLD_SIZE / 2
		var x = (object.node.position.x - pos.x) / (world_radius / rect_size.x / 2)
		var y = (object.node.position.y - pos.y) / (world_radius / rect_size.y / 2)
		
		# out of bound, dont render
		if x < -63 or y < -63 or x > 63 or y > 63: continue
		draw_texture(texture_object, Vector2(63 + x,63 + y))
		
	draw_texture(texture_player, Vector2(62,62))
 

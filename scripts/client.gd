# *************************************************
# godot3-spacegame by Yanick Bourbeau
# Released under MIT License
# *************************************************
# CLIENT-SIDE CODE
#
# All the client logics in one file!
# *************************************************
extends Node

var my_info = { name = "Player" }
var preload_player = preload("res://scenes/player.tscn")
var preload_projectile = preload("res://scenes/projectile.tscn")
var preload_damage  = preload("res://scenes/effects/damage.tscn")
var preload_explosion = preload("res://scenes/effects/explosion.tscn")

# Player info, associate ID to data
var player_info = {}
var projectiles = []
var my_peer = null
var last_update = -1
onready var node_players = $camera/players
onready var node_projectiles = $camera/projectiles
onready var camera = $camera
onready var progress_health = $UI/progress_health
onready var chat = $UI/item_chat

func _ready():
	
	print("Server IP       : " + global.cfg_server_ip)
	print("Player Name     : " + global.cfg_player_name)
	print("Spaceship Color : " + global.cfg_color)
	
	print("Connecting to server ...")
	
	var peer = NetworkedMultiplayerENet.new()
	
	# Create a client using specified server ip
	peer.create_client(global.cfg_server_ip, global.SERVER_PORT)
	
	# Associate the current network peer to the tree
	get_tree().set_network_peer(peer)
	
	# Keep the current peer somewhere to differenciate between you and other players
	my_peer = peer
	
	# Connect signals
	if get_tree().connect("connected_to_server", self, "client_connected_ok") != OK:
		print("Unable to connect signal (connected_to_server) !")
		
	if get_tree().connect("connection_failed", self, "client_connected_fail") != OK:
		print("Unable to connect signal (connection_failed) !")
		
	if get_tree().connect("server_disconnected", self, "server_disconnected") != OK:
		print("Unable to connect signal (server_disconnected) !")
	
	# Add a message to the chat box
	add_chat("Welcome to this network test!")
	add_chat("Connecting to server ....")
	
func _process(_delta):
	
	# To mitigate latency issues we use interpolation. The idea is simple, we receive
	# position updates every TICK_DURATION (50 ms, 20 per seconds). We interpolate between
	# the last two previous updates, this way we always have smooth movements. The
	# main drawback is added latency (100 ms).
	var pos = Vector2(0,0)
	var target_timestamp = OS.get_ticks_msec() - (global.TICK_DURATION*2)
	
	for peer_id in player_info:
		# Update position using lerp with 2 prior states
		var keys = player_info[peer_id].updates.keys()
		for i in range(0, keys.size()):
			if keys[i] > target_timestamp:
				if not player_info[peer_id].destroyed:
					var percent = float(target_timestamp - keys[i-1]) / global.TICK_DURATION
					player_info[peer_id].position.x = lerp(player_info[peer_id].updates[keys[i-1]].position.x, player_info[peer_id].updates[keys[i]].position.x, percent)
					player_info[peer_id].position.y = lerp(player_info[peer_id].updates[keys[i-1]].position.y, player_info[peer_id].updates[keys[i]].position.y, percent)
					player_info[peer_id].node.set_position(player_info[peer_id].position)
					player_info[peer_id].velocity = lerp(player_info[peer_id].updates[keys[i-1]].velocity, player_info[peer_id].updates[keys[i]].velocity, percent)
					player_info[peer_id].rotation = global.lerp_angle(player_info[peer_id].updates[keys[i-1]].rotation, player_info[peer_id].updates[keys[i]].rotation, percent)
					player_info[peer_id].node.set_rotation(player_info[peer_id].rotation)
				break
			
	# We spawn projectiles based on required timestamp (received from server)
	target_timestamp = OS.get_ticks_msec() 
	for projectile in projectiles:
		if projectile.timestamp <= target_timestamp:
			var node_projectile = preload_projectile.instance()
			var info = player_info[projectile.id]
			var projectile_os = Vector2(projectile.position.x,projectile.position.y)
			node_projectile.name = "projectile_" + info.name
			node_projectiles.add_child(node_projectile)
			var trustp = Vector2(0,global.PROJECTILE_OFFSET).rotated(projectile.current_angle)
			node_projectile.contacts_reported = 1
			node_projectile.set_position(projectile_os - trustp)
			node_projectile.set_linear_velocity(-trustp * global.PROJECTILE_SPEED)
			projectiles.erase(projectile)
	
	# Adjust camera on position
	var peer_id = get_tree().get_network_unique_id()
	if player_info.has(peer_id):
		pos.x += player_info[peer_id].position.x
		pos.y += player_info[peer_id].position.y
	
	camera.set_offset(pos)

	# Handle input (keyboard)
	handle_input()
		

func handle_input():
	
	# If not connected, don't handle input.
	if not my_peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED:
		return
		
	# if not currently playing, don't handle input too.
	if my_info == null:
		return
		
	# Send input events over network to the server
	
	# Rotating left
	if Input.is_action_just_pressed("player_left"):
		rpc_id(1,"player_input",get_tree().get_network_unique_id(),"left",true)
	if Input.is_action_just_released("player_left"):
		rpc_id(1,"player_input",get_tree().get_network_unique_id(),"left",false)
		
	# Rotating right
	if Input.is_action_just_pressed("player_right"):
		rpc_id(1,"player_input",get_tree().get_network_unique_id(),"right",true)
	if Input.is_action_just_released("player_right"):
		rpc_id(1,"player_input",get_tree().get_network_unique_id(),"right",false)
		
	# Handle flying forward
	if Input.is_action_just_pressed("player_up"):
		rpc_id(1,"player_input",get_tree().get_network_unique_id(),"up",true)
	if Input.is_action_just_released("player_up"):
		rpc_id(1,"player_input",get_tree().get_network_unique_id(),"up",false)
		
	# Handle flying backward
	if Input.is_action_just_pressed("player_down"):
		rpc_id(1,"player_input",get_tree().get_network_unique_id(),"down",true)
	if Input.is_action_just_released("player_down"):
		rpc_id(1,"player_input",get_tree().get_network_unique_id(),"down",false)
		
	# Handle player firing a projectile
	if Input.is_action_just_pressed("player_fire"):
		rpc_id(1,"player_input",get_tree().get_network_unique_id(),"fire",true)
	if Input.is_action_just_released("player_fire"):
		rpc_id(1,"player_input",get_tree().get_network_unique_id(),"fire",false)

		
func client_connected_ok():
	print("Callback: client_connected_ok")
	add_chat("Connected. Enjoy!")
	# Only called on clients, not server. Send my ID and info to all the other peers
	my_info.name = global.cfg_player_name
	my_info.color = global.cfg_color
	rpc_id(1,"register_player", get_tree().get_network_unique_id(), my_info)
	OS.set_window_title("Connected as " + my_info.name)

func  server_disconnected():
	print("Callback: server_disconnected")
	OS.alert('You have been disconnected!', 'Connection Closed')	
	# Change to login scene
	if get_tree().change_scene("res://scenes/login.tscn") != OK:
		print("Unable to load login scene!")

func client_connected_fail():
	print("Callback: client_connected_fail")
	OS.alert('Unable to connect to server!', 'Connection Failed')
	# Change to login scene
	if get_tree().change_scene("res://scenes/login.tscn") != OK:
		print("Unable to load login scene!")
	
remote func player_joined(id, info):
	print("Callback: player_joined(" + str(id)+"," + str(info) + ")")
	player_info[id] = info
	add_chat("Player joined: " + player_info[id].name)
	
	var node_player = preload_player.instance()
	var color = info.color.to_lower()
	
	node_player.get_node("texture_player").texture = load("res://images/player_" + color + ".png")
	
	info.node = node_player
	info.updates = {}
	
	var pos = Vector2(info.position.x,info.position.y)
	node_player.mode = RigidBody2D.MODE_KINEMATIC
	node_player.set_position(pos)
	node_player.name = info.name
		
	node_players.add_child(node_player)
	

remote func player_respawned(id, info):
	print("Callback: player_respawned (" + str(id)+"," + str(info) + ")")
	player_info[id] = info
	add_chat("Player respawned: " + player_info[id].name)
	
	var node_player = preload_player.instance()
	var color = info.color.to_lower()
	
	node_player.get_node("texture_player").texture = load("res://images/player_" + color + ".png")
	
	info.node = node_player
	info.updates = {}
	
	var pos = Vector2(info.position.x,info.position.y)
	node_player.mode = RigidBody2D.MODE_KINEMATIC
	node_player.set_position(pos)
	node_player.name = info.name
		
	node_players.add_child(node_player)
	
remote func player_leaving(id):
	print("Callback: player_leaving(" + str(id)+")")
	add_chat("Player leaving: " + player_info[id].name)
	player_info[id].node.queue_free()
	player_info.erase(id)


remote func player_health(id, health):
	print("Callback: player_health(" + str(id) +","+str(health)+")")
	if health == 0:
		player_info[id].destroyed = true
		add_chat(player_info[id].name +" destroyed!")
		player_info[id].node.queue_free()
		var node_explosion = preload_explosion.instance()
		node_explosion.get_node("particles").emitting = true
		node_explosion.get_node("particles").one_shot = true
		node_explosion.position = player_info[id].node.position
		node_projectiles.add_child(node_explosion)
		
	var peer_id = get_tree().get_network_unique_id()
	if id == peer_id:
		progress_health.value = health
	
# Player update function
# This function is named "pu" to lower the network bandwidth usage, sending something
# like "player_update" will use an extra 220 bytes / second for each connected player. 
remote func pu(id, update_id, pos, velocity, rotation):
	
	# Unreliable packets can be sent in wrong order, we only work with the latest
	# data available.
	if update_id < last_update:
		print("Received update in wrong order. Discarding!")
		return
		
	last_update = update_id
	player_info[id].updates[OS.get_ticks_msec()] = { position = pos, velocity = velocity, rotation = rotation }
	while len(player_info[id].updates) > 10:
		player_info[id].updates.erase(player_info[id].updates.keys()[0])
	
	if player_info[id].destroyed:
		return
		
	if player_info[id].node.has_node("particles"):
		player_info[id].node.get_node("particles").set_emitting(velocity != 0)

	if player_info[id].node.has_node("audio_thruster"):
		player_info[id].node.get_node("audio_thruster").stream_paused = velocity == 0

	
remote func fire_weapon(id, position, current_angle):
	projectiles.append({ timestamp = OS.get_ticks_msec() + (global.TICK_DURATION * 2), id = id, position = position, current_angle = current_angle })
	
func add_chat(text):
	
	chat.add_item(text)
	if chat.get_item_count() == 7:
		chat.remove_item(0)

	for i in range(0,chat.get_item_count()):
		chat.set_item_selectable(i,false)
	
func display_damage(body):
	for peer_id in player_info:
		if player_info[peer_id].node == body:
			var node_damage = preload_damage.instance()
			node_damage.name = "damage"
			node_damage.get_node("particles").emitting = true
			node_damage.get_node("particles").one_shot = true
			player_info[peer_id].node.add_child(node_damage)
			break
	
	

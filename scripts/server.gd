# *************************************************
# godot3-spacegame by Yanick Bourbeau
# Released under MIT License
# *************************************************
# SERVER-SIDE CODE
#
# All the server logics in one file!
#
# *************************************************
extends Node


# Player info, associate ID to data
var player_info = {}

var delta_update = 0
var delta_interval = float(global.TICK_DURATION) * 0.001
onready var camera = $camera
onready var node_players = $camera/players
onready var node_projectiles = $camera/projectiles
onready var node_asteroids = $camera/asteroids

var preload_player = preload("res://scenes/player.tscn")
var preload_projectile = preload("res://scenes/projectile.tscn")
var velocity_speed = 500
var trust_origin = Vector2(0,0)
var rotate_origin1 = Vector2(0,64)
var rotate_origin2 = Vector2(0,-64)
var rotation_power = 10.0
var current_zoom = Vector2(20,20)
var update_id = 0

func _ready():
	print("Starting the server ...")
	print("Server port: " + str(global.SERVER_PORT))
	print("Max players: " + str(global.MAX_PLAYERS))
	var peer = NetworkedMultiplayerENet.new()
	print("Listening on port: " + str(global.SERVER_PORT))
	if peer.create_server(global.SERVER_PORT, global.MAX_PLAYERS) != OK:
		print("Unable to create server")
		return
		
	if get_tree().set_network_peer(peer) != OK:
		print("Unable to set network peer!")
	
	# Connect the signals
	if get_tree().connect("network_peer_connected", self, "player_connected") != OK:
		print("Unable to connect signal (network_peer_connected) !")
		
	if get_tree().connect("network_peer_disconnected", self, "player_disconnected") != OK:
		print("Unable to connect signal (network_peer_disconnected) !")
	
	
func _process(delta):
	
	camera.set_zoom(current_zoom)
	
	for peer_id in player_info:
		if player_info[peer_id].respawn_time != -999:
			player_info[peer_id].respawn_time -= delta
			if player_info[peer_id].respawn_time <= 0:
				
				player_info[peer_id].position = get_spawn_position()
				player_info[peer_id].velocity = 0
				player_info[peer_id].rotation = 0
				player_info[peer_id].firing = 0
				player_info[peer_id].firing_delta = 0
				player_info[peer_id].current_angle = 0
				player_info[peer_id].health = 100
				player_info[peer_id].respawn_time = -999
				player_info[peer_id].destroyed = false
				
				var node_player = preload_player.instance()
				player_info[peer_id].node = node_player
			
				var pos = Vector2(player_info[peer_id].position.x,player_info[peer_id].position.y)
				
				node_player.set_position(pos)
				node_player.show()
				node_player.set_process(true)
				
				node_player.name = player_info[peer_id].name
				
				node_players.add_child(node_player)
				
				
				# Broadcast the new player to everyone
				for peer_id2 in player_info:
					rpc_id(peer_id2, "player_respawned", peer_id, player_info[peer_id])

	
func _physics_process(delta):
	
	for peer_id in player_info:
#		print(str(player_info[peer_id].node.rotation) + " / " + str(player_info[peer_id].node.position) + " / " + str(player_info[peer_id].velocity))
#		print("Player:" + str(peer_id) + " = " + str(player_info[peer_id].position) + " = " + str(player_info[peer_id].velocity))
		if player_info[peer_id].destroyed:
			continue
		
		var v = Vector2(0,0)
		if player_info[peer_id].velocity != 0:
			var trustp = Vector2(0,player_info[peer_id].velocity * velocity_speed).rotated(player_info[peer_id].node.rotation)
			player_info[peer_id].node.apply_impulse(trust_origin, trustp * delta)
			
		if player_info[peer_id].rotation != 0:
			if player_info[peer_id].rotation < 0:
				player_info[peer_id].node.apply_impulse(rotate_origin1, Vector2(320,0) * delta)
				player_info[peer_id].node.apply_impulse(rotate_origin2, Vector2(-320,0) * delta)
			else:
				player_info[peer_id].node.apply_impulse(rotate_origin1, Vector2(-320,0) * delta)
				player_info[peer_id].node.apply_impulse(rotate_origin2, Vector2(320,0) * delta)
				
		v = player_info[peer_id].node.get_position()
		
		# Keep the player within boundaries
		var world_radius = global.WORLD_SIZE / 2
		if v.x > world_radius:
			v.x = world_radius
			player_info[peer_id].node.set_position(v)
		if v.x < -world_radius:
			v.x = -world_radius
			player_info[peer_id].node.set_position(v)
		if v.y > world_radius:
			v.y = world_radius
			player_info[peer_id].node.set_position(v)
		if v.y < -world_radius:
			v.y = -world_radius
			player_info[peer_id].node.set_position(v)
		
		player_info[peer_id].position = player_info[peer_id].node.get_position()
		player_info[peer_id].current_angle = player_info[peer_id].node.rotation
		
		if player_info[peer_id].firing == 1:
			player_info[peer_id].firing_delta += delta
			if player_info[peer_id].firing_delta > global.PROJECTILE_DELAY:
				player_info[peer_id].firing_delta -= global.PROJECTILE_DELAY
				fire_weapon(peer_id)
	
	delta_update += delta
	while delta_update >= delta_interval:
		delta_update -= delta_interval
		broadcast_world_positions()
	
func broadcast_world_positions():
	
	for peer_id in player_info:
		for peer_id_2 in player_info:
			rpc_unreliable_id(peer_id, "pu", peer_id_2, update_id, player_info[peer_id_2].position, player_info[peer_id_2].velocity, player_info[peer_id_2].current_angle)
			
	update_id += 1
	
	
func player_connected(id):
	print("Callback: server_player_connected: " + str(id))

func player_disconnected(id):
	print("Callback: server_player_disconnected: " + str(id))
	
	# Broadcast the "player_left" message to every other players
	for peer_id in player_info:
		rpc_id(peer_id, "player_leaving", id)

	# Erase player from player information array
	player_info[id].node.queue_free()
	player_info.erase(id) 
	


func get_spawn_position():
	
	var pos = Vector2(0,0)
	pos.x = rand_range(-950,950)
	pos.y = rand_range(-950,950)
	return pos


# Register a new player
remote func register_player(id, info):
	print("Remote: register_player(" + str(id) +","+str(info)+")")

	info.position = get_spawn_position()
	info.velocity = 0
	info.rotation = 0
	info.firing = 0
	info.firing_delta = 0
	info.current_angle = 0
	info.health = 100
	info.respawn_time = -999
	info.destroyed = false
	
	# send list of previous players to the new one
	for peer_id in player_info:
		rpc_id(id, "player_joined", peer_id, player_info[peer_id])
	
	
	var node_player = preload_player.instance()
	info.node = node_player

	var pos = Vector2(info.position.x,info.position.y)
	
	node_player.set_position(pos)
	node_player.show()
	node_player.set_process(true)
	
	node_player.name = info.name
	
	node_players.add_child(node_player)
	
	# Store the information
	player_info[id] = info
	
	# Broadcast the new player to everyone
	for peer_id in player_info:
		rpc_id(peer_id, "player_joined", id, player_info[id])



remote func player_input(id, key, pressed):
	print("Remote: player_input(" + str(id)+","+key+","+str(pressed)+")")

	if key == "left":
		player_info[id].rotation = -1 if pressed else 0
	elif key == "right":
		player_info[id].rotation = 1 if pressed else 0
	elif key == "up":
		player_info[id].velocity = -1 if pressed else 0
	elif key == "down":
		player_info[id].velocity = 1 if pressed else 0
	elif key == "fire":
		player_info[id].firing = 1 if pressed else 0
		
		
func fire_weapon(id):
	print("Fire weapon!")
		
	var info = player_info[id]
	var node_projectile = preload_projectile.instance()
	var pos = Vector2(info.position.x,info.position.y)
	
	node_projectile.name = info.name
	node_projectile.contacts_reported = 1
	node_projectiles.add_child(node_projectile)

	var weapon_angle = info.node.rotation + rand_range(-global.PROJECTILE_RANDOM/2, global.PROJECTILE_RANDOM/2)
	var trustp = Vector2(0,global.PROJECTILE_OFFSET).rotated(weapon_angle)
	node_projectile.set_position(pos - trustp)
	node_projectile.set_linear_velocity(-trustp * global.PROJECTILE_SPEED)
	
	for peer_id in player_info:
		rpc_id(peer_id, "fire_weapon", id, player_info[id].position, weapon_angle)
	
func player_got_shot(body):
	print("player got shot!")
	for peer_id in player_info:
		if player_info[peer_id].node == body:
			if not player_info[peer_id].health == 0:
				player_info[peer_id].health -= 10
				if player_info[peer_id].health < 0:
					player_info[peer_id].health = 0
					
				# broadcast!
				print("Broadcast health: " + str(player_info[peer_id].health))
				for peer_id2 in player_info:
						rpc_id(peer_id2, "player_health", peer_id, player_info[peer_id].health)
						
				if player_info[peer_id].health == 0:
					player_info[peer_id].destroyed = true
					player_info[peer_id].respawn_time = 5.0
					player_info[peer_id].node.queue_free()
					

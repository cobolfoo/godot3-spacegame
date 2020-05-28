# *************************************************
# godot3-spacegame by Yanick Bourbeau
# Released under MIT License
# *************************************************
#
# This is a auto-included singleton containing
# information used by client and server codes.
#
# *************************************************
extends Node

const SERVER_PORT = 5225
const MAX_PLAYERS = 16
const WORLD_SIZE = 40000.0
const TICK_DURATION = 50 # In milliseconds, it means 20 network updates/second

# Spawn the projectile 120 pixels from the center of the spaceship
const PROJECTILE_OFFSET = 120.0 

# Add some loss in projectile precision 
const PROJECTILE_RANDOM = 0.2

# The projectile speed
const PROJECTILE_SPEED = 20.0

# Delay inbetween projectiles, playing with this value will change the amount
# of data exchanged over network.
const PROJECTILE_DELAY = 0.1

# Default hostname used by the login form
const DEFAULT_HOSTNAME = "127.0.0.1"

# Store information about connected players
var player_info = {}

# Those variables are only used by the client-side application
var cfg_server_ip = ""
var cfg_color = "Green"
var cfg_player_name = "Robot!"


# Helper functions (Static)

# Linear interpolation between 2 angles using the shortest direction
static func lerp_angle(a, b, t):
	if abs(a-b) >= PI:
		if a > b:
			a = normalize_angle(a) - 2.0 * PI
		else:
			b = normalize_angle(b) - 2.0 * PI
	return lerp(a, b, t)


# Used for angle normalization
static func normalize_angle(x):
	return fposmod(x + PI, 2.0*PI) - PI
		

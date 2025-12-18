extends Area2D

# Player Settings
@export var speed_damping: float = 10.0
@export var sway_amount: float = 5.0

# State
var target_x: float = 0.0
var screen_size: Vector2

func _ready():
	screen_size = get_viewport_rect().size
	target_x = screen_size.x / 2.0
	position = Vector2(target_x, screen_size.y - 200)

func _input(event):
	# Handle Touch and Mouse input for smooth following
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		target_x = event.position.x
	
	if event is InputEventScreenTouch and event.pressed:
		target_x = event.position.x

func _physics_process(delta):
	# Smoothly interpolate to the target X position (Follow Finger mechanic)
	position.x = lerp(position.x, target_x, speed_damping * delta)
	
	# Clamp to screen to prevent going out of bounds
	position.x = clamp(position.x, 50, screen_size.x - 50)
	
	# Add slight vertical sway for "floating" feel (Bioluminescent forest vibe)
	position.y = (screen_size.y - 200) + sin(Time.get_ticks_msec() * 0.002) * sway_amount

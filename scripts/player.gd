extends Area3D

# Player Settings
@export var speed_damping: float = 10.0
@export var sway_amount: float = 0.2 # Reduced for 3D
@export var max_x: float = 4.0 # World units for road width

# State
var target_x: float = 0.0
var screen_size: Vector2

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	target_x = 0.0 # Center
	position = Vector3(0, 0, 0)

func _input(event):
	# Handle Touch and Mouse input for smooth following
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		_update_target_from_input(event.position.x)
	
	if event is InputEventScreenTouch and event.pressed:
		_update_target_from_input(event.position.x)

func _update_target_from_input(screen_x: float):
	# Map screen X (0 to width) to world X (-max_x to max_x)
	var normalized_x = (screen_x / screen_size.x) - 0.5 # -0.5 to 0.5
	target_x = normalized_x * 2.0 * max_x

func _physics_process(delta):
	# Resize update in case window changes
	screen_size = get_viewport().get_visible_rect().size
	
	# Smoothly interpolate to the target X position
	position.x = lerp(position.x, target_x, speed_damping * delta)
	
	# Clamp is implicit by mapping logic, but good safety
	position.x = clamp(position.x, -max_x, max_x)
	
	# Add slight vertical sway for "floating" feel (Bioluminescent forest vibe)
	position.y = 0.5 + sin(Time.get_ticks_msec() * 0.002) * sway_amount

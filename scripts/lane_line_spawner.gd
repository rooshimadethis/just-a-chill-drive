extends Node3D

@export var spawn_interval: float = 1.0  # 60 BPM: 1 beat = 1 second (visual rhythm)
@export var scroll_speed: float = 17.0  # Reduced 10% (was 18.8)
@export var lane_width: float = 2.0  # Distance from center
@export var line_length: float = 3.0  # Length of each dash
@export var line_width: float = 0.15  # Width of the line

var spawn_timer: float = 0.0
var lane_lines = []
var lane_material: ShaderMaterial
var game_manager: Node

# Object pooling for performance
var lane_line_pool = []
var pool_size = 100  # Pre-allocate 100 lane lines

func _ready():
	game_manager = get_node("/root/Game/GameManager")
	_initialize_material()
	_initialize_pool()

func _initialize_pool():
	# Pre-create lane lines to avoid runtime allocation
	for i in range(pool_size):
		var line = _create_lane_line()
		line.visible = false
		add_child(line)
		lane_line_pool.append(line)

func _get_pooled_line() -> MeshInstance3D:
	if lane_line_pool.size() > 0:
		var line = lane_line_pool.pop_back()
		line.visible = true
		return line
	else:
		# Pool exhausted, create new (shouldn't happen with proper sizing)
		return _create_lane_line()

func _return_to_pool(line: MeshInstance3D):
	line.visible = false
	lane_line_pool.append(line)

func _initialize_material():
	# Create shared material once
	lane_material = ShaderMaterial.new()
	if game_manager and game_manager.has_method("get_winding_shader"):
		lane_material.shader = game_manager.get_winding_shader()
	
	# Initial params
	lane_material.set_shader_parameter("albedo", Color(0.9, 0.9, 0.95))
	lane_material.set_shader_parameter("emission", Color(0.7, 0.8, 0.9))
	lane_material.set_shader_parameter("emission_energy", 0.0)  # No glow on lane lines

var current_mode_gold: bool = false

func _process(delta):
	# Update Shared Material based on Harmony (ONCE per frame)
	var harmony = 0
	if game_manager:
		harmony = game_manager.harmony_score
	
	var should_be_gold = (harmony >= 10)
	
	if should_be_gold != current_mode_gold:
		current_mode_gold = should_be_gold
		
		# Update only on state change
		if current_mode_gold:
			# Gold
			lane_material.set_shader_parameter("albedo", Color(1.0, 0.85, 0.3))
			lane_material.set_shader_parameter("emission", Color(1.0, 0.8, 0.1))
		else:
			# Default White/Blue
			lane_material.set_shader_parameter("albedo", Color(0.9, 0.9, 0.95))
			lane_material.set_shader_parameter("emission", Color(0.7, 0.8, 0.9))

	# Move existing lane lines (iterate backwards to safely remove)
	for i in range(lane_lines.size() - 1, -1, -1):
		var line = lane_lines[i]
		line.position.z += scroll_speed * delta
		
		# Delete only when well behind camera
		if line.position.z > 10:
			_return_to_pool(line)
			lane_lines.remove_at(i)
	
	# Spawn new lane lines
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_lane_line_set()

func spawn_lane_line_set():
	# Spawn Left Lane Line
	var line_left = _get_pooled_line()
	line_left.position = Vector3(-lane_width, 0.05, -120)  # Slightly above road
	lane_lines.append(line_left)
	
	# Spawn Right Lane Line
	var line_right = _get_pooled_line()
	line_right.position = Vector3(lane_width, 0.05, -120)
	lane_lines.append(line_right)

func _create_lane_line() -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(line_width, 0.02, line_length)  # Thin, flat dash
	mesh.subdivide_depth = 8 # Increased subdivision to allow mesh to bend with the curve shader
	mesh.subdivide_width = 2 # Also subdivide width for side-to-side curvature
	mesh_inst.mesh = mesh
	
	# Use shared material
	if lane_material:
		mesh_inst.set_surface_override_material(0, lane_material)
	
	return mesh_inst

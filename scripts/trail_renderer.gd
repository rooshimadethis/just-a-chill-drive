extends CPUParticles3D

# Settings
@export var scroll_speed: float = 17.0 
@export var vertical_offset: float = 0.05

var game_manager: Node

func _ready():
	game_manager = get_node_or_null("/root/Game/GameManager")
	
	_setup_system()
	_setup_material()

func _setup_system():
	# System Settings
	amount = 100 # Increased slightly for smoother dense cloud
	lifetime = 5.0 # Longer lifetime since they move slower
	preprocess = 0.0
	speed_scale = 2.0
	explosiveness = 0.0
	randomness = 1.0
	fixed_fps = 60
	fract_delta = true
	local_coords = false 
	
	# Emission - Wide stripe at back of car
	emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	emission_box_extents = Vector3(0.5, 0.05, 0.05) 
	
	# Movement
	# "Even slower" -> almost stationary relative to car release, just gently drifting
	direction = Vector3(0, 0, 1) # +Z is backwards
	spread = 20.0 
	gravity = Vector3(0, 0.1, 0) # Very subtle float up
	initial_velocity_min = 0.2
	initial_velocity_max = 1.5
	
	# Size variation
	scale_amount_min = 0.1
	scale_amount_max = 0.5
	
	# Visuals - Tiny Sphere
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.012 
	s_mesh.height = 0.024
	s_mesh.radial_segments = 4
	s_mesh.rings = 2
	mesh = s_mesh
	
	# Initial position
	position.y = vertical_offset
	position.z = 1.3 

func _setup_material():
	var mat = ShaderMaterial.new()
	
	# Use the world winding shader
	if game_manager and game_manager.has_method("get_winding_shader"):
		mat.shader = game_manager.get_winding_shader()
	
	# Sparkle Colors (Rich Gold)
	var firefly_color = Color(1.0, 0.75, 0.2, 0.6) # More Orange/Gold, Lower Alpha
	
	mat.set_shader_parameter("albedo", firefly_color)
	mat.set_shader_parameter("emission", firefly_color)
	mat.set_shader_parameter("emission_energy", 1.0) # Dimmer (was 3.0)
	mat.set_shader_parameter("roughness", 1.0)
	
	material_override = mat

func _process(delta):
	pass

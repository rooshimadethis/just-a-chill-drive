extends Area3D

# Player Settings
@export var speed_damping: float = 10.0
@export var sway_amount: float = 0.2 # Reduced for 3D
@export var max_x: float = 4.0 # World units for road width

# State
var target_x: float = 0.0
var screen_size: Vector2
var car_visuals: Node3D
var mesh_instance: MeshInstance3D
var fireflies: CPUParticles3D
var game_manager: Node

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	target_x = 0.0 # Center
	position = Vector3(0, 0, 0)
	
	game_manager = get_node_or_null("/root/Game/GameManager")
	
	setup_visuals()

func setup_visuals():
	# 1. Structure: Player -> CarVisuals -> MeshInstance
	# This allows us to tilt CarVisuals (Z-axis) while MeshInstance is rotated (X-axis) for the Capsule
	car_visuals = Node3D.new()
	car_visuals.name = "CarVisuals"
	add_child(car_visuals)
	
	# Move existing MeshInstance to CarVisuals
	mesh_instance = $MeshInstance3D
	remove_child(mesh_instance)
	car_visuals.add_child(mesh_instance)
	
	# 2. Soften Geometry (Capsule Mesh)
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.45 # Reduced 10% (was 0.5)
	capsule.height = 1.8 # Reduced 10% (was 2.0)
	mesh_instance.mesh = capsule
	# Lay it flat (rotate 90 degrees on X to align with Z-axis/forward)
	mesh_instance.rotation_degrees.x = -90 
	
	# Soft Plastic Material
	var mat
	if game_manager and game_manager.has_method("get_winding_shader"):
		var shader = game_manager.get_winding_shader()
		mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("albedo", Color(0.8, 0.2, 0.4)) # Nice car color - "Soft Plastic"
		mat.set_shader_parameter("roughness", 0.8) # High roughness
	else:
		mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.2, 0.4) # Nice car color - "Soft Plastic"
		mat.roughness = 0.8 # High roughness
		mat.metallic = 0.0
	
	mesh_instance.set_surface_override_material(0, mat)
	
	# Prevent culling when shader displaces mesh outside original AABB
	mesh_instance.extra_cull_margin = 16384.0
	
	# 3. Fireflies (Particle System)
	fireflies = CPUParticles3D.new()
	car_visuals.add_child(fireflies)
	fireflies.amount = 20
	fireflies.lifetime = 2.0
	fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fireflies.emission_sphere_radius = 2.0
	fireflies.gravity = Vector3(0, 0.5, 0) # Float up
	fireflies.scale_amount_min = 0.05
	fireflies.scale_amount_max = 0.1
	
	var p_mesh = SphereMesh.new()
	p_mesh.radius = 0.05
	p_mesh.height = 0.1
	p_mesh.radial_segments = 4
	p_mesh.rings = 2
	fireflies.mesh = p_mesh
	
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(1.0, 1.0, 0.5) 
	p_mat.emission_enabled = true
	p_mat.emission = Color(1.0, 1.0, 0.5)
	p_mat.emission_energy_multiplier = 2.0
	fireflies.material_override = p_mat
	fireflies.emitting = false

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

func _process(delta):
	# Floaty Movement (Tilt)
	var target_rot_z = -Input.get_axis("ui_left", "ui_right") * 0.1
	if car_visuals:
		car_visuals.rotation.z = lerp_angle(car_visuals.rotation.z, target_rot_z, delta * 5.0)
	
	# Check Harmony for Fireflies
	if game_manager and game_manager.harmony_score >= 20:
		if not fireflies.emitting:
			fireflies.emitting = true

func _physics_process(delta):
	# Resize update in case window changes
	screen_size = get_viewport().get_visible_rect().size
	
	# Smoothly interpolate to the target X position
	position.x = lerp(position.x, target_x, speed_damping * delta)
	
	# Clamp is implicit by mapping logic, but good safety
	position.x = clamp(position.x, -max_x, max_x)
	
	# Add slight vertical sway for "floating" feel (Bioluminescent forest vibe)
	position.y = 0.5 + sin(Time.get_ticks_msec() * 0.002) * sway_amount


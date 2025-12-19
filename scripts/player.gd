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
	
	# 2. Car Body (Imported GLB)
	if has_node("MeshInstance3D"):
		get_node("MeshInstance3D").queue_free()
		
	var car_scene = load("res://assets/car/sedan-sports.glb")
	if car_scene:
		var car_node = car_scene.instantiate()
		car_visuals.add_child(car_node)
		
		# Adjust orientation (GLB often faces +Z, we look -Z)
		car_node.rotation_degrees.y = 180
		# Adjust position to center it
		car_node.position.y = -0.3 # Lower it slightly if wheels float
		
		# Create Winding Shader Material
		var mat
		if game_manager and game_manager.has_method("get_rigid_winding_shader"):
			var shader = game_manager.get_rigid_winding_shader()
			mat = ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter("albedo", Color(0.8, 0.2, 0.4)) # Keep signature pink/red color
			mat.set_shader_parameter("roughness", 0.4) # Shinier car
		
		if mat:
			_apply_material_recursive(car_node, mat)
	else:
		print("Failed to load car model, fallback to box not implemented.")

func _apply_material_recursive(node: Node, material: Material):
	if node is MeshInstance3D:
		# Apply to all surfaces
		for i in range(node.mesh.get_surface_count()):
			node.set_surface_override_material(i, material)
			# Important: Expand cull margin so the car doesn't disappear when curving off-screen
			node.extra_cull_margin = 16384.0
			
	for child in node.get_children():
		_apply_material_recursive(child, material)
	
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
	# Doubled sensitivity (was 2.0). Now 4.0 so we reach edges with 25% screen movement from center.
	target_x = normalized_x * 4.0 * max_x

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
	
	# Vertical float synchronized to 60 BPM (4-beat cycle = 4 seconds)
	# At 60 BPM: 1 beat = 1 second, so 4 beats = 4 seconds per complete float cycle
	# This creates a breathing-like rhythm for attention restoration
	var bpm = 60.0
	var beats_per_cycle = 4.0 # Complete up-down motion over 4 beats
	var seconds_per_cycle = beats_per_cycle * (60.0 / bpm) # = 4 seconds
	var float_frequency = TAU / seconds_per_cycle # Radians per second
	var time_in_seconds = Time.get_ticks_msec() / 1000.0
	
	position.y = 0.5 + sin(time_in_seconds * float_frequency) * sway_amount


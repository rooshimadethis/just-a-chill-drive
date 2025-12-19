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
		
		# Create Winding Shader Materials with calming colors
		if game_manager and game_manager.has_method("get_rigid_winding_shader"):
			var shader = game_manager.get_rigid_winding_shader()
			_apply_multi_color_materials(car_node, shader)
	else:
		print("Failed to load car model, fallback to box not implemented.")

func _apply_multi_color_materials(node: Node, shader: Shader):
	"""Apply different calming colors to different car components"""
	if node is MeshInstance3D:
		var mesh_name = node.name.to_lower()
		var mat = ShaderMaterial.new()
		mat.shader = shader
		
		# Assign colors based on component type - all soft, restorative colors
		if "body" in mesh_name or "chassis" in mesh_name or "hood" in mesh_name or "door" in mesh_name:
			# Main body: Soft sage green (calming, natural)
			mat.set_shader_parameter("albedo", Color(0.6, 0.75, 0.65))  # Sage green
			mat.set_shader_parameter("roughness", 0.3)
		elif "window" in mesh_name or "glass" in mesh_name or "windshield" in mesh_name:
			# Windows: Soft blue-grey (sky-like, peaceful)
			mat.set_shader_parameter("albedo", Color(0.65, 0.7, 0.8, 0.6))  # Translucent blue-grey
			mat.set_shader_parameter("roughness", 0.1)  # Glossy
		elif "wheel" in mesh_name or "tire" in mesh_name or "rim" in mesh_name:
			# Wheels: Warm grey (grounded, stable)
			mat.set_shader_parameter("albedo", Color(0.5, 0.48, 0.45))  # Warm grey
			mat.set_shader_parameter("roughness", 0.6)
		elif "light" in mesh_name or "headlight" in mesh_name:
			# Lights: Soft warm white
			mat.set_shader_parameter("albedo", Color(0.95, 0.92, 0.85))  # Warm white
			mat.set_shader_parameter("roughness", 0.2)
		else:
			# Default for other parts: Soft teal (calming water-like color)
			mat.set_shader_parameter("albedo", Color(0.55, 0.7, 0.7))  # Soft teal
			mat.set_shader_parameter("roughness", 0.4)
		
		# Apply to all surfaces
		for i in range(node.mesh.get_surface_count()):
			node.set_surface_override_material(i, mat)
			# Important: Expand cull margin so the car doesn't disappear when curving off-screen
			node.extra_cull_margin = 16384.0
			
	for child in node.get_children():
		_apply_multi_color_materials(child, shader)
	
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
	
	# 4. Headlights (Two SpotLights) - need to be added after car is loaded
	# Store reference to car node for headlights
	if car_visuals.get_child_count() > 0:
		var car_node = car_visuals.get_child(0)
		_add_headlights(car_node)

func _add_headlights(car_node: Node3D):
	# Left headlight - attached to car node so it moves with the car
	var left_light = SpotLight3D.new()
	left_light.name = "LeftHeadlight"
	car_node.add_child(left_light)
	left_light.position = Vector3(-0.4, 0.5, 1.0)  # Front left of car (adjusted for car's local space)
	left_light.rotation_degrees = Vector3(0, 180, 0)  # Point forward in car's local space
	left_light.light_color = Color(1.0, 0.95, 0.85)  # Warm white
	left_light.light_energy = 1.5
	left_light.spot_range = 20.0
	left_light.spot_angle = 45.0
	left_light.spot_attenuation = 2.0
	left_light.shadow_enabled = true
	
	# Right headlight
	var right_light = SpotLight3D.new()
	right_light.name = "RightHeadlight"
	car_node.add_child(right_light)
	right_light.position = Vector3(0.4, 0.5, 1.0)  # Front right of car (adjusted for car's local space)
	right_light.rotation_degrees = Vector3(0, 180, 0)  # Point forward in car's local space
	right_light.light_color = Color(1.0, 0.95, 0.85)  # Warm white
	right_light.light_energy = 1.5
	right_light.spot_range = 20.0
	right_light.spot_angle = 45.0
	right_light.spot_attenuation = 2.0
	right_light.shadow_enabled = true


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
	
	# Vertical float synchronized to 60 BPM metronome (4-beat cycle = 4 seconds)
	# Use the metronome's bar_phase for perfect synchronization
	if game_manager:
		var bar_phase = game_manager.get_bar_phase()
		# Convert phase (0.0 to 1.0) to full sine wave cycle (0 to TAU)
		position.y = 0.5 + sin(bar_phase * TAU) * sway_amount
	else:
		# Fallback to time-based if GameManager not available
		var bpm = 60.0
		var beats_per_cycle = 4.0
		var seconds_per_cycle = beats_per_cycle * (60.0 / bpm)
		var float_frequency = TAU / seconds_per_cycle
		var time_in_seconds = Time.get_ticks_msec() / 1000.0
		position.y = 0.5 + sin(time_in_seconds * float_frequency) * sway_amount


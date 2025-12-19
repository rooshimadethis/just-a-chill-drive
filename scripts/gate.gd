extends Area3D

@export var speed: float = 18.0
var collected: bool = false
var game_manager: Node

func _ready():
	# Find GameManager in the scene tree
	game_manager = get_node("/root/Game/GameManager")
	
	# 1. Widen the Gap 
	# User Request: "Make gates width of lane" (Gap 4.0)
	var half_width = 2.0
	
	# Create shared CylinderMesh
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.height = 2.8 # 30% shorter (was 4.0)
	cyl_mesh.top_radius = 0.3
	cyl_mesh.bottom_radius = 0.3
	cyl_mesh.radial_segments = 16
	cyl_mesh.rings = 12 # Add vertical subdivision for curved world effect
	
	if has_node("LeftPillar"):
		$LeftPillar.mesh = cyl_mesh
		$LeftPillar.position.x = -half_width
		$LeftPillar.position.y = -0.6  # Lower to ground (half of height reduction: 1.2 / 2)
		$LeftPillar.scale = Vector3(0.8, 0.8, 0.8) # 20% smaller pillars
	if has_node("RightPillar"):
		$RightPillar.mesh = cyl_mesh
		$RightPillar.position.x = half_width
		$RightPillar.position.y = -0.6  # Lower to ground
		$RightPillar.scale = Vector3(0.8, 0.8, 0.8)
	
	# Adjust Trigger Size to match new width and height
	if has_node("CollisionShape3D"):
		var shape = $CollisionShape3D.shape
		if shape is BoxShape3D:
			# Make unique to avoid affecting other gates if it was shared
			$CollisionShape3D.shape = shape.duplicate()
			$CollisionShape3D.shape.size.x = half_width * 2.0  # 4.0 units wide
			$CollisionShape3D.shape.size.y = 2.8  # Match pillar height
		# Position at origin since gate is now spawned at correct height
		$CollisionShape3D.position.y = 0.0
	
	# 2. Add Top Bar (Make it a Gate) --> REMOVED
	# var top_bar = MeshInstance3D.new() ...
	
	# Assign material (Ghostly)
	# Use shader if available
	var shader = null
	if game_manager and game_manager.has_method("get_winding_shader"):
		shader = game_manager.get_winding_shader()
	
	var create_gate_mat = func(color: Color):
		if shader:
			var m = ShaderMaterial.new()
			m.shader = shader
			m.set_shader_parameter("albedo", color)
			m.set_shader_parameter("emission", color)
			m.set_shader_parameter("emission_energy", 2.0)
			return m
		else:
			var m = StandardMaterial3D.new()
			m.albedo_color = color
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = 2.0
			return m
	
	var default_color = Color(0.2, 0.8, 1.0, 0.0) # Start invisible
	
	# Apply to all parts
	if has_node("LeftPillar"):
		$LeftPillar.set_surface_override_material(0, create_gate_mat.call(default_color))
	if has_node("RightPillar"):
		$RightPillar.set_surface_override_material(0, create_gate_mat.call(default_color))
		$RightPillar.set_surface_override_material(0, create_gate_mat.call(default_color))

func set_speed(new_speed):
	speed = new_speed

func set_special_color(color: Color):
	# Create a new material for the special color
	var shader = null
	if game_manager and game_manager.has_method("get_winding_shader"):
		shader = game_manager.get_winding_shader()
		
	var mat
	if shader:
		mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("albedo", Color(color.r, color.g, color.b, 0.0))
		mat.set_shader_parameter("emission", color)
		mat.set_shader_parameter("emission_energy", 3.0)
	else:
		mat = StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, 0.0)  # Start invisible
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 3.0
	
	# Apply to pillars
	if has_node("LeftPillar"):
		$LeftPillar.set_surface_override_material(0, mat)
	if has_node("RightPillar"):
		$RightPillar.set_surface_override_material(0, mat)
		$RightPillar.set_surface_override_material(0, mat)

func _process(delta):
	position.z += speed * delta
	_update_transparency()
	
	if position.z > 10:
		queue_free()

func _update_transparency():
	# Map Z from -120 (start) to -90 (end of fade)
	# At -120: should be 1.0 (invisible)
	# At -90: should be 0.0 (opaque)
	
	var start_z = -120.0
	var end_z = -90.0
	
	# Linear interpolation factor (0.0 at start, 1.0 at end)
	var t = clamp((position.z - start_z) / (end_z - start_z), 0.0, 1.0)
	var alpha = 1.0 - t # Invert for transparency
	
	_set_transparency(alpha)

func _set_transparency(alpha: float):
	# Apply transparency to children meshes via material
	var targets = ["LeftPillar", "RightPillar"]
	for target_name in targets:
		if has_node(target_name):
			var node = get_node(target_name)
			var mat = node.get_surface_override_material(0)
			if mat:
				# Target alpha is 0.25 (Very transparent Ghostly) when fully visible
				var target_opacity = (1.0 - alpha) * 0.25
				
				if mat is ShaderMaterial:
					var col = mat.get_shader_parameter("albedo")
					if col:
						col.a = target_opacity
						mat.set_shader_parameter("albedo", col)
				elif mat is StandardMaterial3D:
					mat.albedo_color.a = target_opacity




func _on_area_entered(area):
	if area.name == "Player" and not collected:
		collected = true
		if game_manager:
			game_manager.add_harmony(1)
		
		# Haptic Feedback
		if OS.get_name() == "Android" or OS.get_name() == "iOS":
			Input.vibrate_handheld(75)
		
		# Visual Feedback: Fade out and scale up
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.2)
		# tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2) # Transparency requires material access
		tween.tween_callback(queue_free)

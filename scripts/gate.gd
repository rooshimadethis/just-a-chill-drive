extends Area3D

@export var speed: float = 18.0
var collected: bool = false
var game_manager: Node
var coin_pivot: Node3D
var coin_mesh: MeshInstance3D

func _ready():
	# Find GameManager in the scene tree
	game_manager = get_node("/root/Game/GameManager")
	
	# Remove old pillars if they exist (handling the .tscn children)
	if has_node("LeftPillar"):
		$LeftPillar.queue_free()
	if has_node("RightPillar"):
		$RightPillar.queue_free()
	
	# Create a pivot for rotation
	coin_pivot = Node3D.new()
	coin_pivot.name = "CoinPivot"
	coin_pivot.position.y = 0.0 # Center of coin relative to parent (World Y=1.4)
	add_child(coin_pivot)
	
	# Create Coin Mesh
	var mesh_data = CylinderMesh.new()
	mesh_data.top_radius = 0.6
	mesh_data.bottom_radius = 0.6
	mesh_data.height = 0.1
	mesh_data.radial_segments = 32
	
	coin_mesh = MeshInstance3D.new()
	coin_mesh.mesh = mesh_data
	coin_mesh.name = "CoinMesh"
	# Rotate 90 degrees on X to stand up like a coin
	coin_mesh.rotation.x = deg_to_rad(90)
	
	coin_pivot.add_child(coin_mesh)
	
	# Create Gold Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.84, 0.0) # Gold
	mat.metallic = 1.0
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.0)
	mat.emission_energy_multiplier = 0.5
	
	coin_mesh.material_override = mat
	
	# Apply Rigid Winding Shader so the coin follows the road curve
	if game_manager and game_manager.has_method("get_rigid_winding_shader"):
		var shader = game_manager.get_rigid_winding_shader()
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = shader
		
		# Copy properties from current material to shader material
		shader_mat.set_shader_parameter("albedo", mat.albedo_color)
		shader_mat.set_shader_parameter("emission", mat.emission)
		shader_mat.set_shader_parameter("emission_energy", mat.emission_energy_multiplier)
		shader_mat.set_shader_parameter("roughness", mat.roughness)
		
		coin_mesh.material_override = shader_mat

	# Adjust Trigger Size
	if has_node("CollisionShape3D"):
		var shape = $CollisionShape3D.shape
		if shape is BoxShape3D:
			# Make unique and resize
			$CollisionShape3D.shape = shape.duplicate()
			$CollisionShape3D.shape.size = Vector3(2.0, 2.0, 0.5)
		# Position at coin height
		$CollisionShape3D.position.y = 0.0
		
	# Store cached alpha for fade-in logic
	_update_transparency()

func reset_gate():
	# Reset gate state for pooling
	collected = false
	visible = true
	if coin_pivot:
		coin_pivot.scale = Vector3.ONE
	if coin_mesh:
		coin_mesh.transparency = 0.0

func set_speed(new_speed):
	speed = new_speed

func set_special_color(color: Color):
	if coin_mesh and coin_mesh.material_override:
		var mat = coin_mesh.material_override
		if mat is StandardMaterial3D:
			mat.set_shader_parameter("albedo", color)
			mat.set_shader_parameter("emission", color)
			# Reduce metallic for colored coins? Or keep it metallic colored?
			# Let's keep it metallic for now.

func _process(delta):
	position.z += speed * delta
	
	# Rotate the coin
	if coin_pivot:
		coin_pivot.rotation.y += 3.0 * delta
	
	_update_transparency()
	
	if position.z > 10:
		queue_free()

func _update_transparency():
	# Simple fade-in from distance
	# Start fading in at -120, fully visible at -90
	var start_z = -120.0
	var end_z = -90.0
	
	var t = clamp((position.z - start_z) / (end_z - start_z), 0.0, 1.0)
	
	# Invert logic: t=0 (at start_z) -> invisible? 
	# User likely wants it to fade IN clearly. 
	# Let's map visibility: 0.0 at -120, 1.0 at -90
	
	if coin_mesh and coin_mesh.material_override:
		var alpha = t
		if alpha < 0.99:
			# Shader material parameter update
			var mat = coin_mesh.material_override
			if mat is ShaderMaterial:
				var current_color = mat.get_shader_parameter("albedo")
				mat.set_shader_parameter("albedo", Color(current_color.r, current_color.g, current_color.b, alpha))
		else:
			var mat = coin_mesh.material_override
			if mat is ShaderMaterial:
				var current_color = mat.get_shader_parameter("albedo")
				mat.set_shader_parameter("albedo", Color(current_color.r, current_color.g, current_color.b, 1.0))

func _on_area_entered(area):
	if area.name == "Player" and not collected:
		collected = true
		if game_manager:
			game_manager.add_harmony(1)
		
		# Haptic Feedback
		if OS.get_name() == "Android" or OS.get_name() == "iOS":
			Input.vibrate_handheld(75)
		
		# Visual Feedback: Pop and disappear
		var tween = get_tree().create_tween()
		tween.tween_property(coin_pivot, "scale", Vector3(1.5, 1.5, 1.5), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(coin_mesh, "transparency", 1.0, 0.1)
		tween.tween_callback(queue_free)

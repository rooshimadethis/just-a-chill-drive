extends Node3D

@export var spawn_interval: float = 0.8
@export var scroll_speed: float = 17.0  # Reduced 10% (was 18.8)

var spawn_timer: float = 0.0
var trees = []
var tree_templates = []
var game_manager: Node

# Increase template count for better variety without runtime cost
const TEMPLATE_COUNT = 12

func _ready():
	game_manager = get_node("/root/Game/GameManager")
	
	# Pre-calculate tree templates for performance
	_generate_tree_templates()

func _generate_tree_templates():
	print("Generating ", TEMPLATE_COUNT, " tree templates...")
	for i in range(TEMPLATE_COUNT):
		var tree = _create_tree_mesh()
		tree_templates.append(tree)

func _process(delta):
	# Move existing trees (iterate backwards to safely remove)
	for i in range(trees.size() - 1, -1, -1):
		var tree = trees[i]
		tree.position.z += scroll_speed * delta
		
		# Delete only when well behind camera
		if tree.position.z > 10:
			tree.queue_free()
			trees.remove_at(i)
	
	# Spawn new trees
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_forest_row()

func spawn_forest_row():
	if tree_templates.size() == 0:
		return

	# Spawn multiple layers of trees to create depth (Forest effect)
	var layers = [12.0, 22.0, 34.0]
	
	for base_dist in layers:
		# Inner layer always spawns, outer layers have a chance to skip for organic density
		if base_dist == 12.0 or randf() > 0.3:
			_spawn_single_tree(-base_dist)
			_spawn_single_tree(base_dist)

func _spawn_single_tree(x_base: float):
	var tree = _instantiate_tree(tree_templates.pick_random())
	
	# Position with wide variance
	var x_pos = x_base + randf_range(-4, 4)
	var z_pos = -120 + randf_range(-5, 5) # Z variance to break the grid
	tree.position = Vector3(x_pos, 0, z_pos)
	
	# Random Rotation
	tree.rotation.y = randf() * TAU
	
	# Random Scale (0.8 to 1.5)
	var s = randf_range(0.8, 1.5)
	tree.scale = Vector3(s, s, s)
	
	add_child(tree)
	trees.append(tree)

func _instantiate_tree(template: Node3D) -> Node3D:
	return template.duplicate()

func _create_tree_mesh() -> Node3D:
	# Create a temporary container for the fractal tree structure
	var temp_container = Node3D.new()
	
	# Generate L-System sentence for fractal structure
	var l_sys = LSystem.new()
	l_sys.axiom = "F"
	l_sys.rules = {
		"F": "F[+F][-F][++F][--F]"  # Organic branching pattern
	}
	l_sys.iterations = 3
	var sentence = l_sys.generate_sentence()
	
	# Prepare Material (Shared)
	var mat
	var shader = null
	if game_manager and game_manager.has_method("get_winding_shader"):
		shader = game_manager.get_winding_shader()
	
	if shader:
		mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("albedo", Color(0.2, 0.5, 0.3))
		mat.set_shader_parameter("emission", Color(0.3, 0.6, 0.4))
		mat.set_shader_parameter("emission_energy", 0.0)  # No glow on trees
	else:
		mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.5, 0.3)
		mat.emission_enabled = false  # No glow on trees
		mat.emission = Color(0.3, 0.6, 0.4)
		mat.emission_energy_multiplier = 0.0
	
	# Draw the tree structure into temp_container (creates many MeshInstance3D children)
	_draw_3d_tree(temp_container, sentence, mat)
	
	# --- OPTIMIZATION START ---
	# Merge all branch meshes into a single MeshInstance3D to reduce draw calls
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for child in temp_container.get_children():
		if child is MeshInstance3D:
			st.append_from(child.mesh, 0, child.transform)
			child.queue_free() # Mark for deletion
	
	temp_container.queue_free() # We don't need the container anymore
	
	# Final merged mesh
	var merged_mesh = st.commit()
	var final_instance = MeshInstance3D.new()
	final_instance.mesh = merged_mesh
	final_instance.set_surface_override_material(0, mat)
	# --- OPTIMIZATION END ---
	
	return final_instance

func _draw_3d_tree(container: Node3D, sentence: String, material: Material):
	# Turtle state
	var transform_stack = []
	var current_pos = Vector3.ZERO
	var current_dir = Vector3.UP  # Start pointing up
	var step_length = 1.2
	var branch_angle = 25.0
	var branch_thickness = 0.15
	
	for char in sentence:
		match char:
			"F":
				# Draw a branch segment
				var next_pos = current_pos + current_dir * step_length
				var branch = _create_branch_segment(current_pos, next_pos, branch_thickness, material)
				container.add_child(branch)
				current_pos = next_pos
				# Reduce thickness and length for natural taper
				step_length *= 0.85
				branch_thickness *= 0.75
			"+":
				# Rotate around Z axis (right) with organic variation
				var angle = deg_to_rad(branch_angle + randf_range(-8, 8))
				current_dir = current_dir.rotated(Vector3(0, 0, 1), angle)
			"-":
				# Rotate around Z axis (left) with organic variation
				var angle = deg_to_rad(branch_angle + randf_range(-8, 8))
				current_dir = current_dir.rotated(Vector3(0, 0, 1), -angle)
			"[":
				# Save state
				transform_stack.push_back([current_pos, current_dir, step_length, branch_thickness])
			"]":
				# Restore state
				if transform_stack.size() > 0:
					var state = transform_stack.pop_back()
					current_pos = state[0]
					current_dir = state[1]
					step_length = state[2]
					branch_thickness = state[3]

func _create_branch_segment(start: Vector3, end: Vector3, thickness: float, material: Material) -> MeshInstance3D:
	# Create a cylinder for the branch
	var mesh_inst = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	
	# Calculate length and orientation
	var length = start.distance_to(end)
	cylinder.height = length
	cylinder.top_radius = thickness
	cylinder.bottom_radius = thickness * 1.2  # Slight taper
	cylinder.radial_segments = 4  # Reduced from 6 for better performance
	cylinder.rings = 1  # Reduced from default for performance
	
	mesh_inst.mesh = cylinder
	# Reuse the same material resource for the template to save memory/draw calls if batched
	# We will duplicate it when instantiating the tree row
	mesh_inst.set_surface_override_material(0, material)
	
	# Position at midpoint
	var midpoint = (start + end) / 2.0
	mesh_inst.position = midpoint
	
	# Orient the cylinder to point from start to end
	var direction = (end - start).normalized()
	if direction.length() > 0.001:  # Avoid zero-length branches
		# Align Y-axis (cylinder's default up) with the direction vector
		var up = Vector3.UP
		if abs(direction.dot(up)) > 0.99:  # Nearly parallel
			up = Vector3.RIGHT
		var right = direction.cross(up).normalized()
		var forward = right.cross(direction).normalized()
		
		# Create basis from direction vectors
		var basis = Basis(right, direction, forward)
		mesh_inst.basis = basis
	
	return mesh_inst

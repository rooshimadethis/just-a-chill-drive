extends Node3D

@export var spawn_interval: float = 0.8
@export var scroll_speed: float = 22.0  # 10% faster

var spawn_timer: float = 0.0
var trees = []

func _ready():
	pass

func _process(delta):
	# Move existing trees (iterate backwards to safely remove)
	for i in range(trees.size() - 1, -1, -1):
		var tree = trees[i]
		tree.position.z += scroll_speed * delta
		
		# Fade In Logic (Z: -120 -> -90)
		var start_z = -120.0
		var end_z = -90.0
		var t = clamp((tree.position.z - start_z) / (end_z - start_z), 0.0, 1.0)
		
		# Set alpha via material (iterate through all branch segments)
		for child in tree.get_children():
			if child is MeshInstance3D:
				var mat = child.get_surface_override_material(0)
				if mat:
					mat.albedo_color.a = t  # t goes from 0.0 (invisible) to 1.0 (opaque)
		
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
	# Spawn Left Tree
	var tree_left = _create_tree_mesh()
	tree_left.position = Vector3(-8 + randf_range(-2, 2), 0, -120)
	add_child(tree_left)
	trees.append(tree_left)
	
	# Spawn Right Tree
	var tree_right = _create_tree_mesh()
	tree_right.position = Vector3(8 + randf_range(-2, 2), 0, -120)
	add_child(tree_right)
	trees.append(tree_right)

func _create_tree_mesh() -> Node3D:
	# Create a container for the fractal tree
	var tree_container = Node3D.new()
	
	# Generate L-System sentence for fractal structure
	var l_sys = LSystem.new()
	l_sys.axiom = "F"
	l_sys.rules = {
		"F": "F[+F][-F][++F][--F]"  # Organic branching pattern
	}
	l_sys.iterations = 3  # Keep it simple for performance
	var sentence = l_sys.generate_sentence()
	
	# Draw the tree using turtle graphics in 3D
	_draw_3d_tree(tree_container, sentence)
	
	return tree_container

func _draw_3d_tree(container: Node3D, sentence: String):
	# Turtle state
	var transform_stack = []
	var current_pos = Vector3.ZERO
	var current_dir = Vector3.UP  # Start pointing up
	var step_length = 1.2
	var branch_angle = 25.0
	var branch_thickness = 0.15
	
	# Create material with transparency for fade-in effect
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.3, 0.0)  # Soft green, start invisible
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.6, 0.4)  # Subtle bioluminescent glow
	mat.emission_energy_multiplier = 0.5
	
	for char in sentence:
		match char:
			"F":
				# Draw a branch segment
				var next_pos = current_pos + current_dir * step_length
				var branch = _create_branch_segment(current_pos, next_pos, branch_thickness, mat)
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

func _create_branch_segment(start: Vector3, end: Vector3, thickness: float, material: StandardMaterial3D) -> MeshInstance3D:
	# Create a cylinder for the branch
	var mesh_inst = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	
	# Calculate length and orientation
	var length = start.distance_to(end)
	cylinder.height = length
	cylinder.top_radius = thickness
	cylinder.bottom_radius = thickness * 1.2  # Slight taper
	
	mesh_inst.mesh = cylinder
	mesh_inst.set_surface_override_material(0, material.duplicate())  # Duplicate for independent alpha
	
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

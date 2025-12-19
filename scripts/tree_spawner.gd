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
	# Removed closest layer (12.0) to keep road clear
	var layers = [22.0, 34.0]
	
	for base_dist in layers:
		# Outer layers have a chance to skip for organic density
		if randf() > 0.3:
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
	# Create a container for the tree
	var tree_root = Node3D.new()
	
	# Get the winding shader
	var shader = null
	if game_manager and game_manager.has_method("get_winding_shader"):
		shader = game_manager.get_winding_shader()
	
	# 1. TRUNK MATERIAL
	var trunk_mat
	if shader:
		trunk_mat = ShaderMaterial.new()
		trunk_mat.shader = shader
		trunk_mat.set_shader_parameter("albedo", Color(0.35, 0.25, 0.15)) # Dark Brown
		trunk_mat.set_shader_parameter("emission_energy", 0.0)
	else:
		trunk_mat = StandardMaterial3D.new()
		trunk_mat.albedo_color = Color(0.35, 0.25, 0.15)
	
	# 2. FOLIAGE MATERIAL
	var foliage_mat
	if shader:
		foliage_mat = ShaderMaterial.new()
		foliage_mat.shader = shader
		# Randomize green slightly for specific tree template
		var green_var = randf_range(0.0, 0.15)
		foliage_mat.set_shader_parameter("albedo", Color(0.1 + green_var, 0.4 + green_var, 0.2 + green_var))
		foliage_mat.set_shader_parameter("emission_energy", 0.0)
	else:
		foliage_mat = StandardMaterial3D.new()
		foliage_mat.albedo_color = Color(0.1, 0.4, 0.2)
	
	# --- BUILD TRUNK ---
	var trunk = MeshInstance3D.new()
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.4
	trunk_mesh.bottom_radius = 0.5
	trunk_mesh.height = 2.0
	trunk_mesh.radial_segments = 6 # Low poly
	trunk_mesh.rings = 1
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.0
	trunk.material_override = trunk_mat
	tree_root.add_child(trunk)
	
	# --- BUILD FOLIAGE (Stacked Cones) ---
	var tiers = randi_range(3, 4)
	var current_y = 1.5
	var current_radius = 2.5
	var height_step = 1.8
	
	for i in range(tiers):
		var cone = MeshInstance3D.new()
		var cone_mesh = CylinderMesh.new()
		cone_mesh.bottom_radius = current_radius
		cone_mesh.top_radius = 0.0 # Cone
		cone_mesh.height = 2.5
		cone_mesh.radial_segments = 7 # Low poly, odd number looks deeper
		cone_mesh.rings = 1
		
		cone.mesh = cone_mesh
		cone.position.y = current_y + (cone_mesh.height / 2.0) - 0.5 # Overlap
		cone.material_override = foliage_mat
		
		tree_root.add_child(cone)
		
		# Move up and shrink for next tier
		current_y += 1.2
		current_radius *= 0.65
	
	return tree_root

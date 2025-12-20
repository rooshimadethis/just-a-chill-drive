extends Node3D

@export var spawn_interval: float = 2.0  # Spawn more frequently since we have more types
@export var scroll_speed: float = 22.0
@export var star_spread_x: float = 80.0
@export var star_height_min: float = 15.0
@export var star_height_max: float = 60.0
@export var constellation_height_min: float = 40.0  # Constellations higher up
@export var constellation_height_max: float = 80.0
@export var max_depth: int = 3

var spawn_timer: float = 0.0
var sky_objects = [] # Stores [node, parallax_factor]

# Storm Mode Settings
var is_storm_mode: bool = false
@export var storm_spawn_interval: float = 0.3 # Fast spawn during storm
@export var normal_spawn_interval: float = 2.0 # Default spawn interval

# Cache materials
var star_mat: StandardMaterial3D
var cloud_mat: StandardMaterial3D

func _ready():
	_init_materials()
	
	for i in range(10):
		var z_pos = -250.0 + (i * 30.0)
		_spawn_sky_element_at(z_pos)

func set_storm_mode(enabled: bool):
	if is_storm_mode == enabled:
		return
		
	is_storm_mode = enabled
	print("SkySpawner: Storm Mode ", "ON" if enabled else "OFF")
	
	if is_storm_mode:
		spawn_interval = storm_spawn_interval
	else:
		spawn_interval = normal_spawn_interval

func _init_materials():
	# Background Star Material (White, crisp)
	star_mat = StandardMaterial3D.new()
	star_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	star_mat.emission_enabled = true
	star_mat.emission = Color(1.0, 1.0, 1.0)
	star_mat.emission_energy_multiplier = 1.5
	
	# Cloud Material (Soft, transparent, white/grey)
	cloud_mat = StandardMaterial3D.new()
	cloud_mat.albedo_color = Color(0.9, 0.9, 0.95, 0.1) # Very transparent
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD # Additive blending for "glowy" clouds
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _process(delta):
	# Move objects
	for i in range(sky_objects.size() - 1, -1, -1):
		var data = sky_objects[i]
		var node = data[0]
		var parallax = data[1]
		
		# Move based on parallax speed
		node.position.z += scroll_speed * delta * parallax
		
		# Fade Logic
		var z = node.position.z
		var alpha = 1.0
		
		# Fade in (far away)
		if z < -200:
			alpha = clamp((z - -300) / 100.0, 0.0, 1.0)
		# Fade out (overhead)
		elif z > 20: 
			alpha = 0.0 # Force kill
			
		_update_alpha(node, alpha)
		
		if z > 50:
			node.queue_free()
			sky_objects.remove_at(i)
			
	# Spawn loop
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_sky_element_at(-300)

func _spawn_sky_element_at(z_pos: float):
	var rng = randf()
	

	
	if is_storm_mode:
		# Storm Mode: 90% Clouds, 10% Other
		if rng < 0.9:
			_spawn_cloud(z_pos)
		elif rng < 0.95:
			_spawn_star_cluster(z_pos)
		else:
			_spawn_constellation(z_pos)
			
	else:
		# Normal Mode: 40% Stars, 30% Clouds, 30% Constellations
		if rng < 0.4:
			_spawn_star_cluster(z_pos)
		elif rng < 0.7:
			_spawn_cloud(z_pos)
		else:
			_spawn_constellation(z_pos)

func _spawn_star_cluster(z_pos: float):
	var stars = _create_star_cluster()
	stars.position = Vector3(
		randf_range(-star_spread_x, star_spread_x),
		randf_range(star_height_min, star_height_max),
		z_pos
	)
	add_child(stars)
	sky_objects.append([stars, 0.1]) # 0.1 parallax (Very slow/far)

func _spawn_cloud(z_pos: float):
	var cloud = _create_cloud()
	cloud.position = Vector3(
		randf_range(-star_spread_x, star_spread_x),
		randf_range(star_height_min, star_height_max),
		z_pos
	)
	add_child(cloud)
	sky_objects.append([cloud, 0.3]) # 0.3 parallax (Slow drifting)

func _spawn_constellation(z_pos: float):
	var constellation = _create_constellation()
	constellation.position = Vector3(
		randf_range(-star_spread_x, star_spread_x),
		randf_range(constellation_height_min, constellation_height_max),  # Higher up
		z_pos
	)
	add_child(constellation)
	sky_objects.append([constellation, 0.5]) # 0.5 parallax (Mid distance)

# --- Creators ---

func _create_star_cluster() -> Node3D:
	var container = Node3D.new()
	var count = randi_range(5, 10)
	# Duplicate material once for this cluster so they fade together
	var local_mat = star_mat.duplicate()
	
	for i in range(count):
		var mesh_inst = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = randf_range(0.15, 0.35)  # Bigger background stars
		sphere.height = sphere.radius * 2
		sphere.radial_segments = 4  # Reduced from 6 for performance
		sphere.rings = 2  # Reduced from 3 for performance
		mesh_inst.mesh = sphere
		# Spread stars across the whole sky instead of clustering
		mesh_inst.position = Vector3(
			randf_range(-star_spread_x * 2, star_spread_x * 2),
			randf_range(star_height_min, star_height_max),
			randf_range(-100, 100)
		)
		container.add_child(mesh_inst)
		
	return _merge_meshes_in_container(container, local_mat)

func _create_cloud() -> Node3D:
	var container = Node3D.new()
	# Duplicate material for this cloud
	var local_mat = cloud_mat.duplicate()
	
	var puffs = randi_range(4, 8)
	for i in range(puffs):
		var mesh_inst = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		var size = randf_range(2.0, 5.0)
		sphere.radius = size
		sphere.height = size * 1.8 # Slightly flattened
		sphere.radial_segments = 8  # Reduced from 12 for performance
		sphere.rings = 4  # Reduced from 6 for performance
		mesh_inst.mesh = sphere
		
		# Clump spheres together
		mesh_inst.position = Vector3(
			randf_range(-4, 4),
			randf_range(-2, 2),
			randf_range(-3, 3)
		)
		container.add_child(mesh_inst)
		
	return _merge_meshes_in_container(container, local_mat)

func _merge_meshes_in_container(container: Node3D, material: Material) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for child in container.get_children():
		if child is MeshInstance3D:
			st.append_from(child.mesh, 0, child.transform)
			child.queue_free()
	
	container.queue_free()
	
	var merged_mesh = st.commit()
	var final_instance = MeshInstance3D.new()
	final_instance.mesh = merged_mesh
	final_instance.set_surface_override_material(0, material)
	return final_instance

func _update_alpha(node: Node, alpha: float):
	if node is MeshInstance3D:
		var mat = node.get_surface_override_material(0)
		if mat:
			# Check if it's a cloud material (based on properties) to apply generic factor
			# Clouds are very transparent by default (0.1), so max alpha is 0.15
			if mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and mat.blend_mode == BaseMaterial3D.BLEND_MODE_ADD and mat.emission_enabled == false:
				mat.albedo_color.a = alpha * 0.15 
			else:
				mat.albedo_color.a = alpha

func _create_constellation() -> Node3D:
	var container = Node3D.new()
	
	# Unique color for this constellation
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	var hue = randf_range(0.5, 0.85) # Cyan -> Blue -> Purple
	mat.emission = Color.from_hsv(hue, 0.7, 1.0)
	mat.emission_energy_multiplier = 3.0  # Brighter for visibility
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	# Create dimmer material for lines (50% opacity)
	var line_mat = mat.duplicate()
	line_mat.emission_energy_multiplier = 1.5  # Half the brightness of stars
	
	_recursive_star(container, Vector3.ZERO, 1.2, max_depth, mat, line_mat)
	
	return _merge_meshes_in_container(container, mat)

func _recursive_star(container: Node3D, pos: Vector3, size: float, depth: int, mat: StandardMaterial3D, line_mat: StandardMaterial3D):
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = size * 0.3  # Bigger stars for visibility
	sphere.height = size * 0.6
	sphere.radial_segments = 6  # Reduced from 8 for performance
	sphere.rings = 3  # Reduced from 4 for performance
	mesh_inst.mesh = sphere
	mesh_inst.position = pos
	# Note: We don't need to set material here as we set it on the merged mesh
	# But append_from takes mesh geometry, not material.
	container.add_child(mesh_inst)
	
	if depth <= 0: return
		
	var branches = randi_range(2, 3)
	for i in range(branches):
		var dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-0.5, 0.5)).normalized()
		var len = size * randf_range(3.5, 5.0)  # Spread farther but still visible
		var next_pos = pos + (dir * len)
		
		var line = _create_line(pos, next_pos, size * 0.05, line_mat)
		container.add_child(line)
		
		_recursive_star(container, next_pos, size * 0.6, depth - 1, mat, line_mat)

func _create_line(p1: Vector3, p2: Vector3, thickness: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	var height = p1.distance_to(p2)
	cylinder.height = height
	cylinder.top_radius = thickness
	cylinder.bottom_radius = thickness
	cylinder.radial_segments = 4
	
	mesh_inst.mesh = cylinder
	# Reuse material not needed for merge, but consistent API
	mesh_inst.position = (p1 + p2) / 2.0
	
	if height > 0.001:
		var direction = (p2 - p1).normalized()
		var up = Vector3.UP
		if abs(direction.dot(up)) > 0.99: up = Vector3.RIGHT
		
		var right = direction.cross(up).normalized()
		var forward = right.cross(direction).normalized()
		mesh_inst.basis = Basis(right, direction, forward)
		
	return mesh_inst

extends Node3D

@export var spawn_interval: float = 1.0  # Twice as often as gates (2.0s)
@export var scroll_speed: float = 22.0  # Match game speed
@export var lane_width: float = 2.0  # Distance from center
@export var line_length: float = 3.0  # Length of each dash
@export var line_width: float = 0.15  # Width of the line

var spawn_timer: float = 0.0
var lane_lines = []

func _ready():
	pass

func _process(delta):
	# Move existing lane lines (iterate backwards to safely remove)
	for i in range(lane_lines.size() - 1, -1, -1):
		var line = lane_lines[i]
		line.position.z += scroll_speed * delta
		
		# Fade In Logic (Z: -120 -> -90)
		var start_z = -120.0
		var end_z = -90.0
		var t = clamp((line.position.z - start_z) / (end_z - start_z), 0.0, 1.0)
		
		# Set alpha via material
		var mat = line.get_surface_override_material(0)
		if mat:
			mat.albedo_color.a = t  # t goes from 0.0 (invisible) to 1.0 (opaque)
		
		# Delete only when well behind camera
		if line.position.z > 10:
			line.queue_free()
			lane_lines.remove_at(i)
	
	# Spawn new lane lines
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_lane_line_set()

func spawn_lane_line_set():
	# Spawn Left Lane Line
	var line_left = _create_lane_line()
	line_left.position = Vector3(-lane_width, 0.05, -120)  # Slightly above road
	add_child(line_left)
	lane_lines.append(line_left)
	
	# Spawn Right Lane Line
	var line_right = _create_lane_line()
	line_right.position = Vector3(lane_width, 0.05, -120)
	add_child(line_right)
	lane_lines.append(line_right)

func _create_lane_line() -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(line_width, 0.02, line_length)  # Thin, flat dash
	mesh_inst.mesh = mesh
	
	# Create material with transparency and subtle glow
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.95, 0.0)  # Soft white/blue, start invisible
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.8, 0.9)  # Soft blue-white glow
	mat.emission_energy_multiplier = 0.8
	mesh_inst.set_surface_override_material(0, mat)
	
	return mesh_inst

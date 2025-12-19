extends Node

signal score_updated(new_score)

var harmony_score: int = 0
var camera_x: float = 0.0  # Track camera's current X position for smooth lerp

func _ready():
	# Allow time for the scene to fully load
	await get_tree().process_frame
	setup_environment()

func _process(delta):
	# Camera Following Logic - follows both road curve and player position
	
	# Sync Time
	var road_time = Time.get_ticks_msec() / 1000.0
	RenderingServer.global_shader_parameter_set("road_time", road_time)
	
	# Calculate road curve
	var z = 0.0 # Player position
	var curve_adjust = sin(z * 0.02 - road_time * 0.5) * 1.25
	
	# Get player position
	var player = get_node_or_null("/root/Game/Player")
	var target_camera_x = 0.0
	
	if player:
		# Camera follows 50% of road curve + 20% of player's X position
		target_camera_x = (curve_adjust * 0.5) + (player.position.x * 0.2)
	else:
		# Fallback to 50% road curve if player not found
		target_camera_x = curve_adjust * 0.5
	
	# Smoothly lerp camera to target position (same damping as player: 10.0)
	camera_x = lerp(camera_x, target_camera_x, 10.0 * delta)
	
	var cam = get_viewport().get_camera_3d()
	if cam:
		cam.position.x = camera_x




func add_harmony(amount: int = 1):
	harmony_score += amount
	score_updated.emit(harmony_score)

func reset_score():
	harmony_score = 0
	score_updated.emit(harmony_score)

func setup_environment():
	var world_env = get_node_or_null("/root/Game/WorldEnvironment")
	if not world_env:
		print("WorldEnvironment not found, creating one...")
		world_env = WorldEnvironment.new()
		get_node("/root/Game").add_child(world_env)
	
	# Create and initialize DayNightCycle
	var day_night = DayNightCycle.new()
	day_night.name = "DayNightSystem"
	get_node("/root/Game").add_child(day_night)
	day_night.setup(world_env)
	
	# 4. Road Winding Shader
	setup_road()

var _winding_shader: Shader

func get_winding_shader() -> Shader:
	if _winding_shader:
		return _winding_shader
		
	var shader_code = """
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission : source_color = vec4(0.0);
uniform float emission_energy = 1.0;
uniform float roughness : hint_range(0,1) = 0.5;
uniform float alpha_scissor_threshold : hint_range(0,1) = 0.0;
uniform float curve_strength_forward : hint_range(0,1) = 0.003;
uniform float curve_strength_side : hint_range(0,1) = 0.001;

global uniform float road_time;
varying float v_world_z;

void vertex() {
   // Spherical Planet Curvature + Winding Road Effect
   // 1. Get World position
   vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
   float z = world_vertex.z;
   float x = world_vertex.x;
   v_world_z = z;
   
   // 2. Winding Road Effect (left-right sine wave)
   float winding_offset = sin(z * 0.02 - road_time * 0.5) * 1.25; 
   world_vertex.x += winding_offset;
   
   // 3. Spherical Planet Curvature
   // Forward/backward curve (drops down as distance increases)
   float dist_from_camera = abs(z);
   world_vertex.y -= dist_from_camera * dist_from_camera * curve_strength_forward;
   
   // Left/right curve (drops down based on distance from center)
   float dist_from_center = abs(world_vertex.x);
   world_vertex.y -= dist_from_center * dist_from_center * curve_strength_side;
   
   // 4. Transform back to Local Space
   VERTEX = (inverse(MODEL_MATRIX) * vec4(world_vertex, 1.0)).xyz;
}

void fragment() {
	vec4 albedo_tex = albedo;
	
	// Distance Fade Logic
	float fade_start = -120.0;
	float fade_end = -90.0;
	float fade = clamp((v_world_z - fade_start) / (fade_end - fade_start), 0.0, 1.0);
	
	ALBEDO = albedo_tex.rgb;
	ALPHA = albedo_tex.a * fade;
	ROUGHNESS = roughness;
	EMISSION = emission.rgb * emission_energy * fade;
}
"""
	_winding_shader = Shader.new()
	_winding_shader.code = shader_code
	return _winding_shader

var _opaque_winding_shader: Shader

func get_opaque_winding_shader() -> Shader:
	if _opaque_winding_shader:
		return _opaque_winding_shader
		
	var shader_code = """
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission : source_color = vec4(0.0);
uniform float emission_energy = 1.0;
uniform float roughness : hint_range(0,1) = 0.5;
uniform float curve_strength_forward : hint_range(0,1) = 0.003;
uniform float curve_strength_side : hint_range(0,1) = 0.001;

global uniform float road_time;

void vertex() {
   // Spherical Planet Curvature + Winding Road Effect
   vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
   float z = world_vertex.z;
   
   // Winding Road Effect (left-right sine wave)
   float winding_offset = sin(z * 0.02 - road_time * 0.5) * 1.25; 
   world_vertex.x += winding_offset;
   
   // Spherical Planet Curvature
   // Forward/backward curve (drops down as distance increases)
   float dist_from_camera = abs(z);
   world_vertex.y -= dist_from_camera * dist_from_camera * curve_strength_forward;
   
   // Left/right curve (drops down based on distance from center)
   float dist_from_center = abs(world_vertex.x);
   world_vertex.y -= dist_from_center * dist_from_center * curve_strength_side;
   
   VERTEX = (inverse(MODEL_MATRIX) * vec4(world_vertex, 1.0)).xyz;
}

void fragment() {
	vec4 albedo_tex = albedo;
	ALBEDO = albedo_tex.rgb;
	ROUGHNESS = roughness;
	EMISSION = emission.rgb * emission_energy;
}
"""
	_opaque_winding_shader = Shader.new()
	_opaque_winding_shader.code = shader_code
	return _opaque_winding_shader

var _rigid_winding_shader: Shader

func get_rigid_winding_shader() -> Shader:
	if _rigid_winding_shader:
		return _rigid_winding_shader
		
	var shader_code = """
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission : source_color = vec4(0.0);
uniform float emission_energy = 1.0;
uniform float roughness : hint_range(0,1) = 0.5;
uniform float curve_strength_forward : hint_range(0,1) = 0.003;
uniform float curve_strength_side : hint_range(0,1) = 0.001;

global uniform float road_time;

void vertex() {
   // Rigid Winding Road Effect with Spherical Curvature
   // Get World Origin of object for Z calculation
   vec3 world_origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
   float z = world_origin.z;
   float winding_offset = sin(z * 0.02 - road_time * 0.5) * 1.25; 
   
   // Apply offset to World Pos
   vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
   world_vertex.x += winding_offset;
   
   // Spherical Planet Curvature
   // Forward/backward curve (drops down as distance increases)
   float dist_from_camera = abs(z);
   world_vertex.y -= dist_from_camera * dist_from_camera * curve_strength_forward;
   
   // Left/right curve (drops down based on distance from center)
   float dist_from_center = abs(world_vertex.x);
   world_vertex.y -= dist_from_center * dist_from_center * curve_strength_side;
   
   // Transform back
   VERTEX = (inverse(MODEL_MATRIX) * vec4(world_vertex, 1.0)).xyz;
}

void fragment() {
	vec4 albedo_tex = albedo;
	ALBEDO = albedo_tex.rgb;
	ROUGHNESS = roughness;
	EMISSION = emission.rgb * emission_energy;
}
"""
	_rigid_winding_shader = Shader.new()
	_rigid_winding_shader.code = shader_code
	return _rigid_winding_shader

func setup_road():
	# Use OPAQUE shader for ground/road to ensure correct depth sorting
	var shader = get_opaque_winding_shader()
	
	var road_nodes = ["/root/Game/Road", "/root/Game/GroundLeft", "/root/Game/GroundRight"]
	for node_path in road_nodes:
		var node = get_node_or_null(node_path)
		if node and node is MeshInstance3D:
			# Create ShaderMaterial
			var mat = ShaderMaterial.new()
			mat.shader = shader
			
			# specific colors for contrast
			if "Road" in node.name:
				mat.set_shader_parameter("albedo", Color(0.02, 0.02, 0.04)) # Darker Road
				mat.set_shader_parameter("roughness", 0.8)
			elif "Ground" in node.name:
				mat.set_shader_parameter("albedo", Color(0.05, 0.25, 0.08)) # Greener Grass
				mat.set_shader_parameter("roughness", 1.0)
			else:
				mat.set_shader_parameter("albedo", Color(0.1, 0.1, 0.15))
				mat.set_shader_parameter("roughness", 0.9)
			
			node.set_surface_override_material(0, mat)
			
			# ENSURE SUBDIVISION:
			# The winding shader requires vertices to displace. A flat plane with 4 corners won't curve.
			var mesh = node.mesh
			if mesh:
				if mesh is PlaneMesh:
					mesh.subdivide_depth = 100
					mesh.subdivide_width = 10
				elif mesh is BoxMesh:
					mesh.subdivide_depth = 100
					mesh.subdivide_width = 10
				elif mesh is QuadMesh:
					# Quads don't have subdivision in the same way, usually need PlaneMesh
					pass
			
			# If the mesh is an ArrayMesh (imported), we can't easily subdivide it via script.
			# But if it's a built-in primitive (common for prototype), this fixes the "straight road on curved path" issue.

	# 5. Camera Setup (Fit Screen)
	var cam = get_viewport().get_camera_3d()
	if cam:
		cam.keep_aspect = Camera3D.KEEP_WIDTH
		# Optional: Adjust FOV if needed, but KEEP_WIDTH ensures lanes stay visible on tall phones.




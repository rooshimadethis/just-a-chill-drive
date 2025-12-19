extends Node

signal score_updated(new_score)

var harmony_score: int = 0

func _ready():
	# Allow time for the scene to fully load
	await get_tree().process_frame
	setup_environment()

func _process(delta):
	# Camera Following Logic for Winding Road
	# We want the camera to stay centered on the visual road, which is displaced by the shader.
	# The shader logic is: offset = sin(z * 0.02 - TIME * 0.5) * 1.25
	# The "Focal Point" is the Player at Z=0.
	# If we shift the camera by the offset at Z=0, the road at Z=0 (and the player) will appear centered.
	
	var t = Time.get_ticks_msec() / 1000.0
	# Note: TIME in shader ~ Time.get_ticks_msec()/1000. If scene loads instantly, they match.
	# If there is drift, it will be a constant offset.
	
	var z = 0.0 # Player position
	var curve_adjust = sin(z * 0.02 - t * 0.5) * 1.25
	
	var cam = get_viewport().get_camera_3d()
	if cam:
		# The camera's base X is 0. We add the curve offset.
		cam.position.x = curve_adjust

func add_harmony(amount: int = 1):
	harmony_score += amount
	score_updated.emit(harmony_score)
	# print("Harmony increased: ", harmony_score) # Removed console noise

func reset_score():
	harmony_score = 0
	score_updated.emit(harmony_score)

func setup_environment():
	var world_env = get_node_or_null("/root/Game/WorldEnvironment")
	if not world_env:
		print("WorldEnvironment not found, creating one...")
		world_env = WorldEnvironment.new()
		get_node("/root/Game").add_child(world_env)
	
	var env = Environment.new()
	world_env.environment = env
	
	# 1. Background (Dusk/Dream)
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	
	# Colors: Deep Purple to Soft Teal/Pink
	sky_mat.sky_top_color = Color(0.1, 0.05, 0.2) # Deep Purple
	sky_mat.sky_horizon_color = Color(0.0, 0.5, 0.5).lerp(Color(1.0, 0.4, 0.7), 0.5) # Teal/Pink Mix
	sky_mat.ground_bottom_color = Color(0.05, 0.05, 0.1)
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	
	sky.sky_material = sky_mat
	env.sky = sky
	
	# 2. Fog (Infinite Journey)
	env.fog_enabled = true
	env.fog_light_color = sky_mat.sky_horizon_color
	env.fog_density = 0.007 # 30% weaker (was 0.01)
	# Note: Volumetric fog is heavier, sticking to standard fog for compatibility/performance consistency
	env.fog_sky_affect = 1.0
	
	
	# 3. Glow (Bloom) - Pulsing light
	env.glow_enabled = true
	env.glow_intensity = 1.5
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 0.5 # Lower threshold to catch more light
	
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

void vertex() {
   // Winding Road Effect (Gentle Sine Wave)
   // Based on World Z position and Time
   // IMPORTANT: All objects must use this same logic to align visually!
   float z = (MODEL_MATRIX * vec4(VERTEX, 1.0)).z;
   float offset = sin(z * 0.02 - TIME * 0.5) * 1.25; 
   VERTEX.x += offset;
}

void fragment() {
	vec4 albedo_tex = albedo;
	ALBEDO = albedo_tex.rgb;
	ALPHA = albedo_tex.a;
	ROUGHNESS = roughness;
	EMISSION = emission.rgb * emission_energy;
}
"""
	_winding_shader = Shader.new()
	_winding_shader.code = shader_code
	return _winding_shader

func setup_road():
	var shader = get_winding_shader()
	
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




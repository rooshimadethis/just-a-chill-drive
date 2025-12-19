extends Node

signal score_updated(new_score)
signal beat_occurred(beat_number: int)  # Emitted on every beat
signal bar_occurred(bar_number: int)    # Emitted every 4 beats

var harmony_score: int = 0
var camera_x: float = 0.0  # Track camera's current X position for smooth lerp
var audio_system: Node

# Cache for optimization
var last_camera_update_x: float = 0.0
var camera_update_threshold: float = 0.01  # Only update if change > 0.01 units
var camera_tilt: float = 0.0 # Track camera roll


# ===== CURVE CONSTANTS =====
# Defined here to sync between GDScript and Shaders
const CURVE_STRENGTH_FORWARD: float = 0.003
const CURVE_STRENGTH_SIDE: float = 0.001
const WINDING_FREQUENCY: float = 0.02
const WINDING_TIME_SCALE: float = 0.5
const WINDING_AMPLITUDE: float = 1.25

# ===== CENTRALIZED 60 BPM METRONOME =====
# This is the single source of truth for all timing in the game
const BPM: float = 60.0
const BEAT_DURATION: float = 1.0  # 60 BPM = 1 second per beat
const BAR_DURATION: float = 4.0   # 4 beats per bar = 4 seconds

var metronome_time: float = 0.0        # Total elapsed time in seconds
var current_beat: int = 0              # Current beat number (0, 1, 2, 3, ...)
var current_bar: int = 0               # Current bar number (0, 1, 2, ...)
var beat_phase: float = 0.0            # Current position within beat (0.0 to 1.0)
var bar_phase: float = 0.0             # Current position within bar (0.0 to 1.0)
var last_beat: int = -1                # Track last beat to detect changes

func _ready():
	# Allow time for the scene to fully load
	await get_tree().process_frame
	setup_audio()
	setup_environment()

func _process(delta):
	# ===== UPDATE METRONOME =====
	# This runs first so all other systems can use updated timing
	metronome_time += delta
	
	# Calculate current beat and bar
	current_beat = int(metronome_time / BEAT_DURATION)
	current_bar = int(metronome_time / BAR_DURATION)
	
	# Calculate phase within current beat (0.0 to 1.0)
	beat_phase = fmod(metronome_time, BEAT_DURATION) / BEAT_DURATION
	
	# Calculate phase within current bar (0.0 to 1.0)
	bar_phase = fmod(metronome_time, BAR_DURATION) / BAR_DURATION
	
	# Emit signals when beat changes
	if current_beat != last_beat:
		last_beat = current_beat
		beat_occurred.emit(current_beat)
		
		# Emit bar signal every 4 beats
		if current_beat % 4 == 0:
			bar_occurred.emit(current_bar)
	
	# ===== CAMERA FOLLOWING LOGIC =====
	# Camera Following Logic - follows both road curve and player position
	
	# Sync Time (calculate once per frame)
	var road_time = Time.get_ticks_msec() / 1000.0
	RenderingServer.global_shader_parameter_set("road_time", road_time)
	
	# Calculate road curve
	var z = 0.0 # Player position
	var curve_adjust = sin(z * 0.02 - road_time * 0.5) * 1.25
	
	var player = get_node_or_null("/root/Game/Player")
	var target_camera_x = 0.0
	
	if player:
		# Camera follows 50% of road curve + 20% of player's X position
		target_camera_x = (curve_adjust * 0.5) + (player.position.x * 0.2)
	else:
		# Fallback to 50% road curve if player not found
		target_camera_x = curve_adjust * 0.5
	
	# Smoothly lerp camera to target position (same damping as player: 10.0)
	var previous_camera_x = camera_x
	# Clamp lerp weight ensures we never overshoot even if delta is huge (lag spike)
	camera_x = lerp(camera_x, target_camera_x, clamp(10.0 * delta, 0.0, 1.0))
	
	# Calculate Tilt (Roll)
	# Use VELOCITY (dist / time) instead of raw displacement to prevent huge snaps during hiccups
	var valid_delta = max(delta, 0.001)
	var velocity = (camera_x - previous_camera_x) / valid_delta
	
	# Target multiplier: 0.016 matches the previous "1.0 per frame at 60fps" feel
	var target_tilt = velocity * 0.016
	
	# Clamp tilt to prevent breaking neck during teleport/reset
	target_tilt = clamp(target_tilt, -0.3, 0.3) 
	
	# Smoothly lerp tilt
	camera_tilt = lerp(camera_tilt, target_tilt, 5.0 * delta)

	# Update Camera Position and Rotation
	var cam = get_viewport().get_camera_3d()
	if cam:
		if abs(camera_x - last_camera_update_x) > camera_update_threshold:
			last_camera_update_x = camera_x
			cam.position.x = camera_x
		
		# Apply tilt
		cam.rotation.z = camera_tilt


# ===== METRONOME HELPER FUNCTIONS =====
# These allow other systems to query the metronome state

func get_beat_phase() -> float:
	"""Returns current position within beat (0.0 to 1.0)"""
	return beat_phase

func get_bar_phase() -> float:
	"""Returns current position within bar (0.0 to 1.0)"""
	return bar_phase

func get_current_beat() -> int:
	"""Returns the current beat number"""
	return current_beat

func get_current_bar() -> int:
	"""Returns the current bar number"""
	return current_bar

func is_on_beat(tolerance: float = 0.1) -> bool:
	"""Returns true if we're close to a beat (within tolerance)"""
	return beat_phase < tolerance or beat_phase > (1.0 - tolerance)

func is_on_bar(tolerance: float = 0.1) -> bool:
	"""Returns true if we're close to a bar (within tolerance)"""
	return bar_phase < tolerance or bar_phase > (1.0 - tolerance)

func get_time_to_next_beat() -> float:
	"""Returns time in seconds until next beat"""
	return (1.0 - beat_phase) * BEAT_DURATION

func get_time_to_next_bar() -> float:
	"""Returns time in seconds until next bar"""
	return (1.0 - bar_phase) * BAR_DURATION

func get_metronome_time() -> float:
	"""Returns total elapsed metronome time"""
	return metronome_time



func setup_audio():
	# Load and instantiate the AudioSystem script
	var AudioSystemScript = load("res://scripts/audio_system.gd")
	audio_system = AudioSystemScript.new()
	audio_system.name = "AudioSystem"
	add_child(audio_system)
	print("AudioSystem initialized: Brown noise engine running")

func add_harmony(amount: int = 1):
	harmony_score += amount
	score_updated.emit(harmony_score)
	
	# Trigger relaxing chord progression
	if audio_system and audio_system.has_method("play_chord"):
		audio_system.play_chord()

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
	
	# Add Rain System (3D Particles) attached to Camera
	var cam = get_viewport().get_camera_3d()
	if cam:
		var rain_script = load("res://scripts/rain_system.gd")
		if rain_script:
			var rain_sys = rain_script.new()
			rain_sys.name = "RainSystem"
			cam.add_child(rain_sys)
			# Position slightly above and ahead of camera to fill view
			rain_sys.position = Vector3(0, 10, -10) 
			print("GameManager: RainSystem added to Camera")
	else:
		push_error("GameManager: Could not find Camera3D for RainSystem")
	
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

var _car_visual_shader: Shader

func get_car_visual_shader() -> Shader:
	"""Shader for the car that ONLY handles coloring, no vertex displacement.
	Transformation is handled via script in player.gd to ensure lights follow."""
	if _car_visual_shader:
		return _car_visual_shader
		
	var shader_code = """
shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission : source_color = vec4(0.0);
uniform float emission_energy = 1.0;
uniform float roughness : hint_range(0,1) = 0.5;

void vertex() {
	// No displacement - handled by script
}

void fragment() {
	vec4 albedo_tex = albedo;
	ALBEDO = albedo_tex.rgb;
	ROUGHNESS = roughness;
	EMISSION = emission.rgb * emission_energy;
}
"""
	_car_visual_shader = Shader.new()
	_car_visual_shader.code = shader_code
	return _car_visual_shader

func get_world_curve_offset(pos_z: float, pos_x: float = 0.0, time: float = 0.0) -> Vector3:
	"""Calculates the curve offset for a given position and time (CPU side).
	Returns Vector3(x_offset, y_drop, 0)"""
	
	# 1. Winding (X Offset)
	# sin(z * 0.02 - road_time * 0.5) * 1.25
	var x_offset = sin(pos_z * WINDING_FREQUENCY - time * WINDING_TIME_SCALE) * WINDING_AMPLITUDE
	
	# 2. Forward Curve (Y Drop)
	# dist * dist * strength
	var dist_forward = abs(pos_z)
	var y_drop_forward = dist_forward * dist_forward * CURVE_STRENGTH_FORWARD
	
	# 3. Side Curve (Y Drop)
	# Calc based on visual X (pos_x + x_offset)
	# The shader uses dist_from_center = abs(world_vertex.x)
	var final_x = pos_x + x_offset
	var dist_side = abs(final_x)
	var y_drop_side = dist_side * dist_side * CURVE_STRENGTH_SIDE
	
	return Vector3(x_offset, -(y_drop_forward + y_drop_side), 0.0)


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

			# DYNAMIC RESIZING: Make road bigger per user request
			# Goal: 3 even lanes of width 4.0
			# Middle Lane: -2 to +2 (Width 4) -> defined by lane_line_spawner (+/- 2.0)
			# Side Lanes: need to be width 4 also.
			# Left Lane: -6 to -2. Right Lane: +2 to +6.
			# Total Road Width needed: 12.0 (-6 to +6)
			
			if "Road" in node.name and mesh is PlaneMesh:
				mesh.size.x = 12.0 
			
			if "GroundLeft" in node.name:
				# Ground is 20 wide (extents +/- 10).
				# We want right edge at -6.0.
				# Center must be at -16.0 (-16 + 10 = -6).
				node.position.x = -16.0 
			
			if "GroundRight" in node.name:
				# We want left edge at +6.0.
				# Center must be at +16.0 (16 - 10 = 6).
				node.position.x = 16.0 

	# 5. Camera Setup (Fit Screen)
	var cam = get_viewport().get_camera_3d()
	if cam:
		cam.keep_aspect = Camera3D.KEEP_WIDTH
		# Optional: Adjust FOV if needed, but KEEP_WIDTH ensures lanes stay visible on tall phones.




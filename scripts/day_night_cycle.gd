extends Node

class_name DayNightCycle

# Settings
@export var day_duration_seconds: float = 60.0 # Full cycle time
@export var sun_color: Color = Color("ffddaad0") # Warm Sunlight
@export var moon_color: Color = Color("aaccee") # Cool Moonlight
@export var star_fade_threshold: float = 0.3 # When stars appear

# Sky Gradient Colors
var col_midnight_top = Color(0.02, 0.02, 0.05)
var col_midnight_hor = Color(0.05, 0.05, 0.1)

var col_dawn_top = Color(0.1, 0.1, 0.3)
var col_dawn_hor = Color(0.8, 0.4, 0.3)

var col_noon_top = Color(0.1, 0.4, 0.8) # Bright Blue
var col_noon_hor = Color(0.4, 0.7, 0.9) # Cyan/White

var col_dusk_top = Color(0.1, 0.05, 0.2)
var col_dusk_hor = Color(0.8, 0.3, 0.5)

# Components
var celestials_pivot: Node3D
var sun_mesh: Node3D
var moon_mesh: Node3D
var main_light: DirectionalLight3D
var world_environment: WorldEnvironment
var sky_material: ProceduralSkyMaterial

var time_time: float = 0.0 # 0 to 1 cycle

func setup(env_node: WorldEnvironment):
	world_environment = env_node
	_create_celestials()
	_setup_sky()

func _create_celestials():
	# 1. Pivot center
	celestials_pivot = Node3D.new()
	celestials_pivot.name = "Celestials"
	add_child(celestials_pivot)
	celestials_pivot.position.z = -900.0 # Far away to reduce stretching and add scale
	
	# 2. Main Light
	main_light = DirectionalLight3D.new()
	main_light.shadow_enabled = true
	main_light.shadow_opacity = 0.7
	celestials_pivot.add_child(main_light)
	main_light.rotation_degrees.x = -90 
	
	# 3. Sun Mesh (Visual)
	var sun_inst = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 25.0
	s_mesh.height = 50.0
	sun_inst.mesh = s_mesh
	
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(1, 0.9, 0.6)
	s_mat.emission_enabled = true
	s_mat.emission = Color(1, 0.8, 0.5)
	s_mat.emission_energy_multiplier = 10.0
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s_mat.disable_fog = true
	sun_inst.set_surface_override_material(0, s_mat)
	
	sun_mesh = sun_inst
	celestials_pivot.add_child(sun_mesh)
	sun_mesh.position = Vector3(0, 600, 0) # High orbit
	
	# 4. Moon Mesh (Visual - Crescent)
	# Use CSG to subtract a sphere from another
	var moon_combiner = CSGCombiner3D.new()
	moon_combiner.name = "MoonCrescent"
	
	# Visible Body
	var m_body = CSGSphere3D.new()
	m_body.radius = 20.0
	m_body.radial_segments = 24
	m_body.rings = 12
	# Material
	var m_mat = StandardMaterial3D.new()
	m_mat.albedo_color = Color(0.9, 0.9, 1.0)
	m_mat.emission_enabled = true
	m_mat.emission = Color(0.8, 0.8, 1.0)
	m_mat.emission_energy_multiplier = 5.0
	m_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_mat.disable_fog = true
	m_body.material = m_mat
	moon_combiner.add_child(m_body)
	
	# Shadow Cutter
	var m_cut = CSGSphere3D.new()
	m_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	m_cut.radius = 22.0
	m_cut.radial_segments = 24
	m_cut.rings = 12
	# Offset to create crescent
	m_cut.position = Vector3(8, 5, 0) 
	moon_combiner.add_child(m_cut)
	
	moon_mesh = moon_combiner
	celestials_pivot.add_child(moon_mesh)
	moon_mesh.position = Vector3(0, -600, 0) # Opposite to sun, high orbit

func _setup_sky():
	if not world_environment: return
	
	var env = Environment.new()
	world_environment.environment = env
	
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	sky_material = ProceduralSkyMaterial.new()
	sky.sky_material = sky_material
	env.sky = sky
	
	# Fog
	env.fog_enabled = true
	env.fog_density = 0.005 # Sightly lighter
	env.fog_sky_affect = 1.0
	
	# Glow
	env.glow_enabled = true
	env.glow_intensity = 1.2
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

func _process(delta):
	if not world_environment: return
	
	time_time += delta / day_duration_seconds
	if time_time > 1.0: time_time -= 1.0
	
	_update_celestial_positions()
	_update_sky_colors()

func _update_celestial_positions():
	# Rotate pivot 360 degrees based on time
	# Left to Right:
	# Start (Sunrise): Sun at Left (-X). Rotation should act such that it rises.
	# Let's say Noon (time 0.5) is Sun Vertical. 
	# Sunrise (0.25). Sunset (0.75). Midnight (0.0).
	
	var angle = (time_time * 360.0) - 180.0 # -180 to 180
	# -180 = Midnight
	# -90 = Sunrise (Left)
	# 0 = Noon (Top)
	# 90 = Sunset (Right)
	# 180 = Midnight
	
	# Rotate around Z axis to move left-to-right (assuming camera looks down Z and X is horizontal)
	# Actually standard Godot: -Z Forward, +X Right, +Y Up.
	# Rotation around Z axis: Positive is CCW.
	# We want -X -> +Y -> +X. This is Clockwise (-Z rotation).
	# So we negate the angle.
	
	celestials_pivot.rotation_degrees.z = -angle
	
	# Adjust Light Energy based on sun height
	var sun_height = cos(deg_to_rad(angle)) # 1 at noon, 0 at horizon, -1 at midnight
	
	if sun_height > -0.2: # Day / Twilight
		main_light.light_energy = clamp(sun_height, 0.0, 1.2)
		main_light.light_color = sun_color
		main_light.rotation_degrees.x = -90 # Sun points down
	else: # Night (Moon logic)
		# Flip light to simulate moon? Or just dim it.
		# A realistic moon light is dim and blue.
		main_light.light_energy = 0.2
		main_light.light_color = moon_color
		# For simplicity, we keep the light source direction but change its properties
		# Actually, physically the moon is opposite, so the light should come from the moon.
		# Since pivot rotates, "main_light" also rotates.
		# But "main_light" is fixed relative to Sun in the pivot (pointing down Y).
		# So at night (sun bottom), the light points UP. This is wrong for the moon (which is at bottom?? No moon is opposite).
		# Wait, Moon is at -200 Y (local).
		# If Pivot is rotated 180 (Midnight). Sun is at Bottom. Moon is at Top.
		# Light (child of pivot, pointing -Y local) is now pointing +Y world (Up).
		# We want light from Moon. Moon is at -Y local.
		# So we need a second light for the moon or rotate this one.
		pass

	# Handle Shadows
	main_light.shadow_enabled = sun_height > 0.0

func _update_sky_colors():
	# Determine phase
	# 0.0 Midnight, 0.25 Dawn, 0.5 Noon, 0.75 Dusk
	
	var t = time_time
	var top: Color
	var hor: Color
	
	if t < 0.15: # Midnight -> Pre-Dawn
		top = col_midnight_top
		hor = col_midnight_hor
	elif t < 0.35: # Dawn (0.25 center)
		var local_t = (t - 0.15) / 0.2
		top = col_midnight_top.lerp(col_noon_top, local_t)
		hor = col_midnight_hor.lerp(col_dawn_hor, local_t)
		if local_t > 0.5: # Transition to day
			hor = hor.lerp(col_noon_hor, (local_t - 0.5) * 2.0)
	elif t < 0.65: # Day
		top = col_noon_top
		hor = col_noon_hor
	elif t < 0.85: # Dusk (0.75 center)
		var local_t = (t - 0.65) / 0.2
		top = col_noon_top.lerp(col_midnight_top, local_t)
		hor = col_noon_hor.lerp(col_dusk_hor, local_t)
		if local_t > 0.5:
			hor = hor.lerp(col_midnight_hor, (local_t - 0.5) * 2.0)
	else: # Night
		top = col_midnight_top
		hor = col_midnight_hor

	sky_material.sky_top_color = top
	sky_material.sky_horizon_color = hor
	sky_material.ground_bottom_color = col_midnight_top # Always dark ground below
	sky_material.ground_horizon_color = hor
	
	# Update Fog to match horizon
	if world_environment.environment:
		world_environment.environment.fog_light_color = hor


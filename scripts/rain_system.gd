extends Node3D

class_name RainSystem

# Settings
@export var rain_color: Color = Color(0.6, 0.7, 1.0, 0.6)
@export var min_wait_time: float = 90.0
@export var max_wait_time: float = 150.0
@export var effect_duration: float = 45.0
@export var fade_duration: float = 5.0

# Components
var particles: GPUParticles3D
var timer: float = 0.0
var time_until_next: float = 0.0
var is_raining: bool = false
var is_fading_in: bool = false
var is_fading_out: bool = false
var current_alpha: float = 0.0

func _ready():
	_create_particles()
	_schedule_next()
	
	# Start invisible
	_update_alpha(0.0)
	print("RainSystem 3D initialized")

func _process(delta):
	if is_fading_in:
		current_alpha += delta / fade_duration
		if current_alpha >= 1.0:
			current_alpha = 1.0
			is_fading_in = false
			is_raining = true
			timer = effect_duration
		_update_alpha(current_alpha)
		
	elif is_raining:
		timer -= delta
		if timer <= 0.0:
			is_raining = false
			is_fading_out = true
	
	elif is_fading_out:
		current_alpha -= delta / fade_duration
		if current_alpha <= 0.0:
			current_alpha = 0.0
			is_fading_out = false
			particles.emitting = false
			_schedule_next()
		_update_alpha(current_alpha)
		
	else:
		time_until_next -= delta
		if time_until_next <= 0.0:
			_start_rain()

func _create_particles():
	particles = GPUParticles3D.new()
	add_child(particles)
	particles.name = "RainParticles"
	
	# 1. Process Material (Movement)
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(20, 1, 20) # Wide area coverage
	mat.direction = Vector3(0, -1, 0) # Down
	mat.spread = 5.0
	mat.gravity = Vector3(0, -20, 0) # Fast fall
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 15.0
	# Color gradient for fade
	mat.color = rain_color
	
	particles.process_material = mat
	
	# 2. Draw Pass (Visuals)
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.05, 1.0) # Long thin streaks
	
	var visual_mat = StandardMaterial3D.new()
	visual_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	visual_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	visual_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual_mat.vertex_color_use_as_albedo = true
	visual_mat.albedo_color = Color.WHITE # Color comes from particle
	visual_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	
	mesh.material = visual_mat
	particles.draw_pass_1 = mesh
	
	# Settings
	particles.amount = 2000
	particles.lifetime = 1.5
	particles.preprocess = 1.0 # Start fully raining if triggered instantly
	particles.visibility_aabb = AABB(Vector3(-20,-20,-20), Vector3(40,40,40))
	particles.emitting = false # Wait for trigger

func _start_rain():
	print("RainSystem: Starting rain")
	particles.emitting = true
	is_fading_in = true
	current_alpha = 0.0
	_update_alpha(0.0)

func _schedule_next():
	time_until_next = randf_range(min_wait_time, max_wait_time)
	print("RainSystem: Next rain in ", time_until_next)

func _update_alpha(alpha: float):
	if particles and particles.process_material:
		var col = rain_color
		col.a = alpha * rain_color.a
		particles.process_material.color = col

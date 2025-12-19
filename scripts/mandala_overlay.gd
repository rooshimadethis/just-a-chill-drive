extends ColorRect

@export var enable_mandala: bool = true
@export var mirror_segments: int = 8
@export var rotation_speed: float = 0.05
@export var zoom: float = 1.0
@export var sky_threshold: float = 0.4  # Y position below which effect is disabled
@export var blend_softness: float = 0.1  # Softness of the transition
@export var center_offset: Vector2 = Vector2(0.5, 0.325)  # Center point of kaleidoscope

# Random activation settings
@export var min_wait_time: float = 90.0  # Minimum time before next activation (1.5 minutes)
@export var max_wait_time: float = 150.0  # Maximum time before next activation (2.5 minutes)
@export var effect_duration: float = 30.0  # How long the effect lasts
@export var fade_duration: float = 2.0  # How long fade in/out takes

var mandala_material: ShaderMaterial
var back_buffer_copy: BackBufferCopy

# State tracking
var current_opacity: float = 0.0
var target_opacity: float = 0.0
var time_until_next_activation: float = 0.0
var effect_timer: float = 0.0
var is_active: bool = false
var is_fading_in: bool = false
var is_fading_out: bool = false

func _ready():
	# Make the ColorRect transparent initially
	color = Color(1, 1, 1, 0)
	
	# Create BackBufferCopy node as a sibling (not child)
	back_buffer_copy = BackBufferCopy.new()
	back_buffer_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	get_parent().add_child(back_buffer_copy)
	get_parent().move_child(back_buffer_copy, get_index())
	
	# Load and set up the mandala shader
	var shader = load("res://shaders/mandala_effect.gdshader")
	mandala_material = ShaderMaterial.new()
	mandala_material.shader = shader
	
	# Apply material to this ColorRect
	material = mandala_material
	
	# Make sure we cover the whole screen
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Ensure we're on top
	z_index = 100
	
	# Set initial wait time
	_schedule_next_activation()
	
	# Update parameters
	_update_shader_params()

func _process(delta):
	if not enable_mandala:
		return
	
	# Check if debug mode is enabled
	var debug_enabled = _is_debug_enabled()
	
	var opacity_changed = false
	
	if debug_enabled:
		# Force 50% opacity when debug is enabled
		if current_opacity != 0.5:
			current_opacity = 0.5
			opacity_changed = true
	else:
		# Normal behavior when debug is disabled
		# Handle activation timing
		if not is_active and not is_fading_in:
			time_until_next_activation -= delta
			if time_until_next_activation <= 0.0:
				_start_effect()
		
		# Handle fade in
		if is_fading_in:
			current_opacity += (delta / fade_duration)
			opacity_changed = true
			if current_opacity >= 1.0:
				current_opacity = 1.0
				is_fading_in = false
				is_active = true
				effect_timer = effect_duration
		
		# Handle active effect
		if is_active:
			effect_timer -= delta
			if effect_timer <= 0.0:
				_end_effect()
		
		# Handle fade out
		if is_fading_out:
			current_opacity -= (delta / fade_duration)
			opacity_changed = true
			if current_opacity <= 0.0:
				current_opacity = 0.0
				is_fading_out = false
				_schedule_next_activation()
	
	# Only update shader if opacity changed
	if opacity_changed and mandala_material:
		mandala_material.set_shader_parameter("opacity", current_opacity)

func _start_effect():
	is_fading_in = true
	target_opacity = 1.0

func _end_effect():
	is_active = false
	is_fading_out = true
	target_opacity = 0.0

func _schedule_next_activation():
	# Random time between min and max wait time
	time_until_next_activation = randf_range(min_wait_time, max_wait_time)
	print("Mandala effect scheduled in ", time_until_next_activation, " seconds")

func _update_shader_params():
	# Set static parameters once (only called from _ready)
	if mandala_material:
		mandala_material.set_shader_parameter("mirror_segments", mirror_segments)
		mandala_material.set_shader_parameter("rotation_speed", rotation_speed)
		mandala_material.set_shader_parameter("zoom", zoom)
		mandala_material.set_shader_parameter("sky_threshold", sky_threshold)
		mandala_material.set_shader_parameter("blend_softness", blend_softness)
		mandala_material.set_shader_parameter("center_offset", center_offset)
		mandala_material.set_shader_parameter("opacity", 0.0)

func _is_debug_enabled() -> bool:
	# Check if MandalaDebug node exists and has debug enabled
	var canvas_layer = get_parent()
	if canvas_layer:
		var debug_node = canvas_layer.get_node_or_null("MandalaDebug")
		if debug_node and "enable_debug" in debug_node:
			return debug_node.enable_debug
	return false

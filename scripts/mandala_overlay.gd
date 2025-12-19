extends ColorRect

@export var enable_mandala: bool = true
@export var mirror_segments: int = 8
@export var rotation_speed: float = 0.05
@export var zoom: float = 1.0
@export var sky_threshold: float = 0.4  # Y position below which effect is disabled
@export var blend_softness: float = 0.1  # Softness of the transition
@export var center_offset: Vector2 = Vector2(0.5, 0.25)  # Center point of kaleidoscope
@export var opacity: float = 0.2  # Overall opacity of the mandala effect

var mandala_material: ShaderMaterial
var back_buffer_copy: BackBufferCopy

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
	
	# Update parameters
	_update_shader_params()

func _process(_delta):
	if enable_mandala:
		_update_shader_params()

func _update_shader_params():
	if mandala_material:
		mandala_material.set_shader_parameter("mirror_segments", mirror_segments)
		mandala_material.set_shader_parameter("rotation_speed", rotation_speed)
		mandala_material.set_shader_parameter("zoom", zoom)
		mandala_material.set_shader_parameter("sky_threshold", sky_threshold)
		mandala_material.set_shader_parameter("blend_softness", blend_softness)
		mandala_material.set_shader_parameter("center_offset", center_offset)
		mandala_material.set_shader_parameter("opacity", opacity)


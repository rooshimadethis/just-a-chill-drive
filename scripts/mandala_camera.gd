extends Camera3D

@export var enable_mandala: bool = true
@export var mirror_segments: int = 8
@export var rotation_speed: float = 0.05
@export var zoom: float = 1.0

var mandala_material: ShaderMaterial
var viewport_texture: ViewportTexture

func _ready():
	# Create the mandala shader material
	mandala_material = ShaderMaterial.new()
	var shader = load("res://shaders/mandala_effect.gdshader")
	mandala_material.shader = shader
	
	# Set initial parameters
	_update_shader_params()

func _process(_delta):
	if enable_mandala:
		_update_shader_params()

func _update_shader_params():
	if mandala_material:
		mandala_material.set_shader_parameter("mirror_segments", mirror_segments)
		mandala_material.set_shader_parameter("rotation_speed", rotation_speed)
		mandala_material.set_shader_parameter("zoom", zoom)

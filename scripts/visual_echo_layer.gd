extends CanvasLayer

var color_rect: ColorRect
var shader_material: ShaderMaterial
var active: bool = false
var tween: Tween
var current_strength: float = 0.0

# Debug flag
var debug_always_on: bool = false

func _ready():
	layer = 128
	follow_viewport_enabled = false
	
	print("VisualEchoLayer: Initializing...")
	print("VisualEchoLayer: Layer value: ", layer)
	
	setup_visuals()
	
	# Connect to GameManager
	var gm = get_node_or_null("/root/Game/GameManager")
	if gm:
		if gm.has_signal("visual_echo_triggered"):
			gm.visual_echo_triggered.connect(trigger_effect)
			print("VisualEchoLayer: Connected to GameManager signal")
	else:
		print("VisualEchoLayer: WARNING - GameManager not found!")
	
	print("VisualEchoLayer: Ready! Debug mode: ", debug_always_on)

func setup_visuals():
	# Add BackBufferCopy to capture the screen
	var back_buffer = BackBufferCopy.new()
	back_buffer.name = "BackBufferCopy"
	back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	back_buffer.rect = Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	add_child(back_buffer)
	
	print("VisualEchoLayer: BackBufferCopy created")
	
	# Now add ColorRect on top
	color_rect = ColorRect.new()
	add_child(color_rect)
	
	# Full screen with explicit positioning
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.offset_left = 0
	color_rect.offset_top = 0
	color_rect.offset_right = 0
	color_rect.offset_bottom = 0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Don't block clicks
	color_rect.z_index = 100  # Ensure it's on top
	
	print("VisualEchoLayer: ColorRect created")
	print("VisualEchoLayer: ColorRect size: ", color_rect.size)
	print("VisualEchoLayer: ColorRect visible: ", color_rect.visible)
	print("VisualEchoLayer: ColorRect global position: ", color_rect.global_position)
	
	# Setup Material with shader
	var shader = load("res://shaders/visual_echo.gdshader")
	if shader:
		shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		color_rect.material = shader_material
		
		# No need to set texture manually, shader uses screen_texture
		# color_rect.texture = back_buffer.get_texture()
		
		_set_strength(0.0)  # Start invisible
		print("VisualEchoLayer: Shader loaded and applied with initial strength 2.0")
	else:
		print("VisualEchoLayer: ERROR - Failed to load shader!")

func _process(delta):
	# Handle debug toggle
	if debug_always_on:
		if current_strength < 1.0:
			_set_strength(lerp(current_strength, 2.0, delta * 2.0))
	elif active:
		# Managed by Tween
		pass
	else:
		# Ensure it stays off if not active
		if current_strength > 0.0:
			_set_strength(lerp(current_strength, 0.0, delta * 5.0))

func trigger_effect():
	if debug_always_on: return
	
	active = true
	
	if tween: tween.kill()
	tween = create_tween()
	
	# Fade in to strength 2.0 over 2 seconds
	tween.tween_method(_set_strength, 0.0, 2.0, 2.0).set_trans(Tween.TRANS_SINE)
	
	# Hold for 6 seconds
	tween.tween_interval(6.0)
	
	# Fade out over 2 seconds
	tween.tween_method(_set_strength, 2.0, 0.0, 2.0).set_trans(Tween.TRANS_SINE)
	
	# Cleanup
	tween.tween_callback(func(): active = false)

func _set_strength(val: float):
	current_strength = val
	if shader_material:
		shader_material.set_shader_parameter("strength", val)
		if debug_always_on and val > 0.1:
			print("VisualEchoLayer: Strength set to ", val)

func set_debug(enabled: bool):
	debug_always_on = enabled
	if not enabled:
		active = false # Let _process fade it out

extends Area3D

@export var speed: float = 20.0
var collected: bool = false
var game_manager: Node

func _ready():
	# Find GameManager in the scene tree (assuming it's at /root/Game/GameManager)
	game_manager = get_node("/root/Game/GameManager")
	
	# Duplicate materials so each gate has its own instance
	if has_node("LeftPillar"):
		var left_mat = $LeftPillar.get_surface_override_material(0)
		if left_mat:
			$LeftPillar.set_surface_override_material(0, left_mat.duplicate())
	
	if has_node("RightPillar"):
		var right_mat = $RightPillar.get_surface_override_material(0)
		if right_mat:
			$RightPillar.set_surface_override_material(0, right_mat.duplicate())
	
	# Initialize transparency immediately to avoid 1-frame pop-in
	_update_transparency()

func set_speed(new_speed):
	speed = new_speed

func set_special_color(color: Color):
	# Create a new material for the special color
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.0)  # Start invisible
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	
	# Apply to pillars
	$LeftPillar.set_surface_override_material(0, mat)
	$RightPillar.set_surface_override_material(0, mat)

func _process(delta):
	position.z += speed * delta
	_update_transparency()
	
	if position.z > 10:
		queue_free()

func _update_transparency():
	# Map Z from -120 (start) to -90 (end of fade)
	# At -120: should be 1.0 (invisible)
	# At -90: should be 0.0 (opaque)
	
	var start_z = -120.0
	var end_z = -90.0
	
	# Linear interpolation factor (0.0 at start, 1.0 at end)
	var t = clamp((position.z - start_z) / (end_z - start_z), 0.0, 1.0)
	var alpha = 1.0 - t # Invert for transparency
	
	_set_transparency(alpha)

func _set_transparency(alpha: float):
	# Apply transparency to children meshes via material
	if has_node("LeftPillar"):
		var pillar = $LeftPillar
		var mat = pillar.get_surface_override_material(0)
		if mat:
			mat.albedo_color.a = 1.0 - alpha  # alpha 1.0 = invisible, so we invert
	if has_node("RightPillar"):
		var pillar = $RightPillar
		var mat = pillar.get_surface_override_material(0)
		if mat:
			mat.albedo_color.a = 1.0 - alpha



func _on_area_entered(area):
	if area.name == "Player" and not collected:
		collected = true
		if game_manager:
			game_manager.add_harmony(1)
		
		# Haptic Feedback
		if OS.get_name() == "Android" or OS.get_name() == "iOS":
			Input.vibrate_handheld(75)
		
		# Visual Feedback: Fade out and scale up
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.2)
		# tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2) # Transparency requires material access
		tween.tween_callback(queue_free)

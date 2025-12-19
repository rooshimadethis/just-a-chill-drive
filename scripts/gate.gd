extends Area3D

@export var speed: float = 20.0
var collected: bool = false
var game_manager: Node

func _ready():
	# Find GameManager in the scene tree (assuming it's at /root/Game/GameManager)
	game_manager = get_node("/root/Game/GameManager")

func set_speed(new_speed):
	speed = new_speed

func set_special_color(color: Color):
	# Create a new material for the special color
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	
	# Apply to pillars
	$LeftPillar.set_surface_override_material(0, mat)
	$RightPillar.set_surface_override_material(0, mat)

func _process(delta):
	position.z += speed * delta
	
	# Fade In Logic (Z: -120 -> -90)
	# Transparency 1.0 is invisible, 0.0 is opaque
	var fade_alpha = smoothstep(-90, -120, position.z)
	_set_transparency(fade_alpha)
	
	if position.z > 10:
		queue_free()

func _set_transparency(alpha: float):
	# Apply transparency to children meshes
	if has_node("LeftPillar"):
		$LeftPillar.transparency = alpha
	if has_node("RightPillar"):
		$RightPillar.transparency = alpha


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

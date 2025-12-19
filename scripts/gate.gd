extends Node2D

@export var speed: float = 400.0
var collected: bool = false
var game_manager: Node

func _ready():
	# Find GameManager in the scene tree (assuming it's at /root/Game/GameManager)
	# Safest way for prototype:
	game_manager = get_node("/root/Game/GameManager")

func set_speed(new_speed):
	speed = new_speed

func _process(delta):
	position.y += speed * delta
	
	if position.y > get_viewport_rect().size.y + 100:
		queue_free()

func _on_area_entered(area):
	if area.name == "Player" and not collected:
		collected = true
		if game_manager:
			game_manager.add_harmony(1)
		
		# Haptic Feedback
		if OS.get_name() == "Android" or OS.get_name() == "iOS":
			# Increase duration slightly to ensure it's perceptible
			Input.vibrate_handheld(75)
		
		# Visual Feedback: Fade out and scale up
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)

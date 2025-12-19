extends Area2D

var speed: float = 400.0

func set_speed(new_speed):
	speed = new_speed

func _process(delta):
	position.y += speed * delta
	
	if position.y > get_viewport_rect().size.y + 100:
		queue_free()

func _on_area_entered(area):
	if area.name == "Player":
		# Gentle interaction:
		# 1. Visual feedback (e.g., slight transparency or color flash)
		# 2. Audio feedback (e.g., soft chime)
		# 3. No game over, just continued flow.
		
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
		print("Soft bump - gentle restoration")

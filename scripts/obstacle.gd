extends Area2D

var speed: float = 400.0

func set_speed(new_speed):
	speed = new_speed

func _process(delta):
	position.y += speed * delta
	
	if position.y > get_viewport_rect().size.y + 100:
		queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		print("Soft Collision - Flow Broken")
		# TODO: Implement soft fail state (slow down, music dim)

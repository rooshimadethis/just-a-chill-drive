extends Node2D

@export var scroll_speed: float = 300.0

# We will scroll the texture of children "Road" sprites
# Assuming we have 2 sprites for seamless looping, or a ParallaxBackground

func _process(delta):
	# Increase global scroll position
	# In a real infinite runner, we often move the world towards the player
	# But for a simple visual prototype, we can scroll offsets.
	
	# For now, let's just emit a signal or update a global shader variable
	# This is a placeholder for the actual Parallax system we will set up in the Scene
	pass

extends Node2D

@export var scroll_speed: float = 200.0
@export var background_layer: ParallaxBackground

func _process(delta):
	# Move the background scroll offset
	if background_layer:
		background_layer.scroll_offset.y += scroll_speed * delta


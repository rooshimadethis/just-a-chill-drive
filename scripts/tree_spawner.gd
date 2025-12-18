extends Node2D

@export var tree_script = preload("res://scripts/fractal_tree.gd")
@export var spawn_interval: float = 0.8
@export var scroll_speed: float = 300.0

var spawn_timer: float = 0.0
var trees = []
var screen_height: float

func _ready():
	screen_height = get_viewport_rect().size.y

func _process(delta):
	# Move existing trees (iterate backwards to safely remove)
	for i in range(trees.size() - 1, -1, -1):
		var tree = trees[i]
		tree.position.y += scroll_speed * delta
		
		# Fade out as they leave the screen
		if tree.position.y > screen_height:
			var dist = tree.position.y - screen_height
			var alpha = 1.0 - (dist / 400.0)
			tree.modulate.a = clamp(alpha, 0.0, 1.0)
		
		# Delete only when well off-screen
		if tree.position.y > screen_height + 500:
			tree.queue_free()
			trees.remove_at(i)
	
	# Spawn new trees
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_forest_row()

func spawn_forest_row():
	# Spawn Left Tree
	var tree_left = Node2D.new()
	tree_left.set_script(tree_script)
	tree_left.position = Vector2(50 + randf_range(-20, 20), -100)
	tree_left.set("branch_color", Color(0.1, randf_range(0.5, 0.9), 0.5, 0.6)) # Varied green/teal
	add_child(tree_left)
	trees.append(tree_left)
	
	# Spawn Right Tree
	var tree_right = Node2D.new()
	tree_right.set_script(tree_script)
	# Flip it visually if we want, or just position it
	tree_right.position = Vector2(get_viewport_rect().size.x - 50 + randf_range(-20, 20), -100)
	tree_right.scale.x = -1 # Mirror
	tree_right.set("branch_color", Color(0.1, randf_range(0.5, 0.9), 0.5, 0.6))
	add_child(tree_right)
	trees.append(tree_right)

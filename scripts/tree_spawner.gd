extends Node3D

@export var spawn_interval: float = 0.8
@export var scroll_speed: float = 20.0

var spawn_timer: float = 0.0
var trees = []

func _ready():
	pass

func _process(delta):
	# Move existing trees (iterate backwards to safely remove)
	for i in range(trees.size() - 1, -1, -1):
		var tree = trees[i]
		tree.position.z += scroll_speed * delta
		
		# Fade In Logic (Z: -120 -> -90)
		var fade_alpha = smoothstep(-90, -120, tree.position.z)
		tree.transparency = fade_alpha
		
		# Delete only when well behind camera
		if tree.position.z > 10:
			tree.queue_free()
			trees.remove_at(i)
	
	# Spawn new trees
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_forest_row()

func spawn_forest_row():
	# Spawn Left Tree
	var tree_left = _create_tree_mesh()
	tree_left.position = Vector3(-8 + randf_range(-2, 2), 0, -120)
	add_child(tree_left)
	trees.append(tree_left)
	
	# Spawn Right Tree
	var tree_right = _create_tree_mesh()
	tree_right.position = Vector3(8 + randf_range(-2, 2), 0, -120)
	add_child(tree_right)
	trees.append(tree_right)

func _create_tree_mesh() -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1, 5, 1) # Tall box
	mesh_inst.mesh = mesh
	# No material for now, will be white/gray default
	# Lift it up so it sits on ground (height/2)
	mesh_inst.position.y = 2.5
	return mesh_inst

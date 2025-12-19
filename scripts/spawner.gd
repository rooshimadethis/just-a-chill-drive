extends Node3D

@export var obstacle_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var speed: float = 20.0

var spawn_timer: float = 0.0
var spawn_count: int = 0

func _ready():
	pass

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		# Add organic variance (+/- 0.5s) to avoid robotic feeling
		spawn_timer = randf_range(-0.5, 0.5) 
		spawn_gate()

func spawn_gate():
	if not obstacle_scene:
		return
	
	spawn_count += 1
	var gate = obstacle_scene.instantiate()
	add_child(gate)
	
	# Random X, approximate road width -4 to 4
	var random_x = randf_range(-3.0, 3.0)
	# Spawn far away
	gate.position = Vector3(random_x, 0, -120)
	
	# Configure gate properties
	if gate.has_method("set_speed"):
		gate.set_speed(speed)
	
	# Every 5th gate is special (Orange)
	if spawn_count % 5 == 0:
		if gate.has_method("set_special_color"):
			gate.set_special_color(Color(1.0, 0.5, 0.0)) # Orange


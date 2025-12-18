extends Node2D

@export var obstacle_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var speed: float = 400.0

var spawn_timer: float = 0.0
var screen_size: Vector2

func _ready():
	screen_size = get_viewport_rect().size

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_gate()

func spawn_gate():
	if not obstacle_scene:
		return
		
	var gate = obstacle_scene.instantiate()
	add_child(gate)
	
	# Random X, keeping margins (100px for marker width + buffer)
	var random_x = randf_range(150, screen_size.x - 150)
	gate.position = Vector2(random_x, -50)
	
	if gate.has_method("set_speed"):
		gate.set_speed(speed)

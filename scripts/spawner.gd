extends Node3D

@export var obstacle_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var speed: float = 18.8  # Reduced 5% (was 19.8)

var spawn_timer: float = 0.0
var spawn_count: int = 0
var last_lane_index: int = -1  # Track last lane to avoid consecutive spawns

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
	
	# Choose one of three lanes: left (-4.0), center (0.0), or right (4.0)
	# Matching visual lane width of 4.0 (lines at +/- 2.0)
	var lanes = [-4.0, 0.0, 4.0]
	
	# Pick a different lane than last time
	var available_indices = []
	for i in range(lanes.size()):
		if i != last_lane_index:
			available_indices.append(i)
	
	# Select randomly from available lanes
	var chosen_index = available_indices[randi() % available_indices.size()]
	last_lane_index = chosen_index
	var lane_x = lanes[chosen_index]
	
	# Spawn far away in the chosen lane
	gate.position = Vector3(lane_x, 0, -120)
	
	# Configure gate properties
	if gate.has_method("set_speed"):
		gate.set_speed(speed)
	
	# Every 5th gate is special (Orange)
	if spawn_count % 5 == 0:
		if gate.has_method("set_special_color"):
			gate.set_special_color(Color(1.0, 0.5, 0.0)) # Orange



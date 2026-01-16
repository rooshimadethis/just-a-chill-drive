extends Node3D

@export var obstacle_scene: PackedScene
@export var speed: float = 17.0  # Reduced 10% (was 18.8)

var spawn_count: int = 0
var last_lane_index: int = -1  # Track last lane to avoid consecutive spawns
var game_manager: Node
var lane_line_spawner: Node3D

func _ready():
	# Connect to GameManager's metronome
	game_manager = get_node("/root/Game/GameManager")
	if game_manager:
		game_manager.bar_occurred.connect(_on_bar_occurred)
		print("Gate Spawner: Connected to metronome (spawning every 4 beats)")
	
	lane_line_spawner = get_node_or_null("/root/Game/LaneLineSpawner")

func _on_bar_occurred(bar_number: int):
	# Spawn a gate on every bar (every 4 beats = 4 seconds at 60 BPM)
	spawn_gate()

func spawn_gate():
	if not obstacle_scene:
		return
	
	spawn_count += 1
	var gate = obstacle_scene.instantiate()
	add_child(gate)
	
	# Choose one of three lanes: left, center, or right
	# Dynamically calculate lanes based on lane_width
	var l_width = 2.0 # Default fallback
	if lane_line_spawner:
		l_width = lane_line_spawner.lane_width
	
	# Middle lane is from -l_width to +l_width (Center 0)
	# Side lanes should be the same width (2*l_width)
	# So Side Centers are at +/- 2*l_width
	var lanes = [-2.0 * l_width, 0.0, 2.0 * l_width]
	
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
	# Y = 1.4 positions the base of the pillars at ground level
	# (pillar height is 2.8, half = 1.4, and pillar offset is -0.6, so 1.4 - 0.6 = 0.8 above origin)
	gate.position = Vector3(lane_x, 1.4, -120)
	
	# Configure gate properties
	if gate.has_method("set_speed"):
		gate.set_speed(speed)
	
	# Every 5th gate is special (Orange)
	if spawn_count % 5 == 0:
		if gate.has_method("set_special_color"):
			gate.set_special_color(Color(1.0, 0.5, 0.0)) # Orange



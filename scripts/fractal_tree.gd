extends Node2D

@export var depth: int = 3
@export var length: float = 20.0
@export var angle_deg: float = 25.0
@export var width: float = 2.0
@export var branch_color: Color = Color(0.1, 0.8, 0.4, 0.5) # Bioluminescent Green

func _ready():
	generate_tree()

func generate_tree():
	var l_sys = LSystem.new()
	l_sys.axiom = "X"
	# Simple fern-like rule
	l_sys.rules = {
		"X": "F+[[X]-X]-F[-FX]+X",
		"F": "FF"
	}
	l_sys.iterations = depth
	var sentence = l_sys.generate_sentence()
	draw_turtle(sentence)

func draw_turtle(sentence: String):
	# We will create Line2D nodes for branches to allow for glowing/width effects easily
	# Or just use _draw() for performance. Let's use _draw() for now as it's lighter for many trees.
	queue_redraw()
	self.set_meta("sentence", sentence) # Store for _draw

func _draw():
	if not has_meta("sentence"): return
	var sentence = get_meta("sentence")
	
	var transform_stack = []
	var current_pos = Vector2.ZERO
	var current_rot = -PI / 2 # Pointing UP
	var step_length = length
	
	for char in sentence:
		match char:
			"F":
				var next_pos = current_pos + Vector2(cos(current_rot), sin(current_rot)) * step_length
				draw_line(current_pos, next_pos, branch_color, width)
				current_pos = next_pos
			"+":
				current_rot += deg_to_rad(angle_deg + randf_range(-5, 5)) # Add organic randomness
			"-":
				current_rot -= deg_to_rad(angle_deg + randf_range(-5, 5))
			"[":
				transform_stack.push_back([current_pos, current_rot])
			"]":
				var state = transform_stack.pop_back()
				current_pos = state[0]
				current_rot = state[1]

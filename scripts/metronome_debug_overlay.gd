extends CanvasLayer

# Debug overlay to visualize the metronome synchronization
# Add this to your scene to see the metronome in action

var game_manager: Node
var label: Label

func _ready():
	game_manager = get_node("/root/Game/GameManager")
	
	# Create label for debug info
	label = Label.new()
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 20)
	add_child(label)
	
	# Connect to metronome signals
	if game_manager:
		game_manager.beat_occurred.connect(_on_beat)
		game_manager.bar_occurred.connect(_on_bar)

func _on_beat(beat_number: int):
	# Flash the label on each beat
	label.modulate = Color.YELLOW

func _on_bar(bar_number: int):
	# Flash brighter on each bar
	label.modulate = Color.ORANGE

func _process(delta):
	if not game_manager:
		label.text = "GameManager not found!"
		return
	
	# Update debug info
	var beat = game_manager.get_current_beat()
	var bar = game_manager.get_current_bar()
	var beat_phase = game_manager.get_beat_phase()
	var bar_phase = game_manager.get_bar_phase()
	var time = game_manager.get_metronome_time()
	
	label.text = "METRONOME DEBUG\n"
	label.text += "Time: %.2f s\n" % time
	label.text += "Beat: %d (%.1f%%)\n" % [beat, beat_phase * 100]
	label.text += "Bar: %d (%.1f%%)\n" % [bar, bar_phase * 100]
	label.text += "Beat in Bar: %d/4\n" % (beat % 4 + 1)
	
	# Visual beat indicator
	var beat_bar = ""
	for i in range(4):
		if i == (beat % 4):
			beat_bar += "█ "
		else:
			beat_bar += "▯ "
	label.text += beat_bar + "\n"
	
	# Phase bar (visual representation)
	var phase_bar_length = 20
	var filled = int(beat_phase * phase_bar_length)
	var phase_bar = "["
	for i in range(phase_bar_length):
		if i < filled:
			phase_bar += "="
		else:
			phase_bar += " "
	phase_bar += "]"
	label.text += phase_bar
	
	# Fade back to white
	label.modulate = label.modulate.lerp(Color.WHITE, delta * 5.0)

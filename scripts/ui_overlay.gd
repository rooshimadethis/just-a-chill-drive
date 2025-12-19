extends Label

func _ready():
	# Diegetic UI: Hide the text, rely on visual cues
	text = "" 
	
	# Keep listening technically if we ever want to debug, but for now silence it.
	# var game_manager = get_node("/root/Game/GameManager")
	# game_manager.score_updated.connect(_on_score_updated)

# func _on_score_updated(new_score):
# 	text = "Harmony: " + str(new_score)

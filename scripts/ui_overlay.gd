extends Label

func _ready():
	var game_manager = get_node("/root/Game/GameManager")
	game_manager.score_updated.connect(_on_score_updated)

func _on_score_updated(new_score):
	text = "Harmony: " + str(new_score)

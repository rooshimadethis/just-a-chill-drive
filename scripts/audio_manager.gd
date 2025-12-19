extends Node

class_name AudioManager

@export var music_bus: String = "Music"
@export var sfx_bus: String = "SFX"

var current_track: AudioStreamPlayer
var next_track: AudioStreamPlayer

func _ready():
	# Initialize players if needed
	pass

func play_music(stream: AudioStream, crossfade_duration: float = 2.0):
	# Placeholder for crossfading logic
	pass

func play_sfx(stream: AudioStream):
	# Placeholder for SFX
	pass

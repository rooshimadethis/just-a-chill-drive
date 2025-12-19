extends CanvasModulate

class_name DayNightCycle

@export var cycle_duration_minutes: float = 5.0
@export var day_color: Color = Color("ffffff") # White/Neutral
@export var night_color: Color = Color("1a1a40") # Deep Blue
@export var sunrise_color: Color = Color("ffcc66") # Warm Orange
@export var sunset_color: Color = Color("cc6699") # Purple/Pink

var time_elapsed: float = 0.0

func _process(delta: float) -> void:
	time_elapsed += delta
	var cycle_progress = fmod(time_elapsed / (cycle_duration_minutes * 60.0), 1.0)
	
	# Simple 4-stage gradient
	if cycle_progress < 0.25:
		# Sunrise -> Day
		color = sunrise_color.lerp(day_color, cycle_progress / 0.25)
	elif cycle_progress < 0.7:
		# Day -> Sunset (Longer day)
		color = day_color.lerp(sunset_color, (cycle_progress - 0.25) / 0.45)
	elif cycle_progress < 0.8:
		# Sunset -> Night
		color = sunset_color.lerp(night_color, (cycle_progress - 0.7) / 0.1)
	else:
		# Night -> Sunrise
		color = night_color.lerp(sunrise_color, (cycle_progress - 0.8) / 0.2)

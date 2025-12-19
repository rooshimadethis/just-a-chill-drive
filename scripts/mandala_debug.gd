extends Control

@export var enable_debug: bool = false
@export var mirror_segments: int = 8
@export var center_offset: Vector2 = Vector2(0.5, 0.325)
@export var sky_threshold: float = 0.4
@export var blend_softness: float = 0.1
@export var line_color: Color = Color(1.0, 0.5, 0.0, 0.8)  # Orange with transparency
@export var center_color: Color = Color(1.0, 0.0, 0.0, 1.0)  # Red for center point
@export var threshold_color: Color = Color(0.0, 1.0, 1.0, 0.6)  # Cyan for threshold line

var screen_size: Vector2

func _ready():
	# Make sure we cover the whole screen
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Ensure we're on top of everything
	z_index = 200
	
	# Make background transparent
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	if enable_debug:
		queue_redraw()

func _draw():
	if not enable_debug:
		return
	
	screen_size = get_viewport_rect().size
	
	# Calculate center point in screen coordinates
	var center_pos = Vector2(
		center_offset.x * screen_size.x,
		center_offset.y * screen_size.y
	)
	
	# Draw sky threshold line
	_draw_sky_threshold()
	
	# Draw mirror segment lines radiating from center
	_draw_mirror_segments(center_pos)
	
	# Draw center point
	_draw_center_point(center_pos)
	
	# Draw labels
	_draw_labels(center_pos)

func _draw_sky_threshold():
	# Draw the main threshold line
	var threshold_y = sky_threshold * screen_size.y
	draw_line(
		Vector2(0, threshold_y),
		Vector2(screen_size.x, threshold_y),
		threshold_color,
		2.0
	)
	
	# Draw blend softness range
	var blend_top = (sky_threshold - blend_softness) * screen_size.y
	var blend_bottom = (sky_threshold + blend_softness) * screen_size.y
	
	# Draw dashed lines for blend range
	_draw_dashed_line(
		Vector2(0, blend_top),
		Vector2(screen_size.x, blend_top),
		Color(threshold_color.r, threshold_color.g, threshold_color.b, 0.3),
		1.0,
		10.0
	)
	_draw_dashed_line(
		Vector2(0, blend_bottom),
		Vector2(screen_size.x, blend_bottom),
		Color(threshold_color.r, threshold_color.g, threshold_color.b, 0.3),
		1.0,
		10.0
	)

func _draw_mirror_segments(center_pos: Vector2):
	# Calculate the segment angle
	var segment_angle = TAU / float(mirror_segments)
	
	# First, draw the source segment highlight (the first half-segment)
	# This is the "master" segment that all others mirror
	_draw_source_segment_highlight(center_pos, segment_angle)
	
	# Draw lines for each mirror segment
	for i in range(mirror_segments):
		var angle = i * segment_angle
		
		# Calculate end point (extend to edge of screen)
		var max_radius = screen_size.length()  # Diagonal length to ensure we reach edges
		var end_pos = center_pos + Vector2(cos(angle), sin(angle)) * max_radius
		
		# Draw the segment boundary line
		draw_line(center_pos, end_pos, line_color, 2.0)
		
		# Draw the half-segment line (where mirroring happens) with dashed line
		var half_angle = angle + segment_angle * 0.5
		var half_end_pos = center_pos + Vector2(cos(half_angle), sin(half_angle)) * max_radius
		_draw_dashed_line(
			center_pos,
			half_end_pos,
			Color(line_color.r, line_color.g, line_color.b, 0.4),
			1.0,
			15.0
		)

func _draw_source_segment_highlight(center_pos: Vector2, segment_angle: float):
	# The source segment is rotated one segment counter-clockwise
	# This matches the shader's rotation offset
	var half_segment = segment_angle * 0.5
	
	# Rotate counter-clockwise by one full segment (subtract angle)
	var start_angle = -segment_angle
	var end_angle = start_angle + half_segment
	
	# Create a polygon to fill the source segment
	var max_radius = screen_size.length()
	var points = PackedVector2Array()
	
	# Start at center
	points.append(center_pos)
	
	# Create arc from start_angle to end_angle
	var arc_steps = 32
	for i in range(arc_steps + 1):
		var t = float(i) / float(arc_steps)
		var angle = lerp(start_angle, end_angle, t)
		var point = center_pos + Vector2(cos(angle), sin(angle)) * max_radius
		points.append(point)
	
	# Back to center to close the shape
	points.append(center_pos)
	
	# Draw filled polygon with semi-transparent green
	var source_color = Color(0.0, 1.0, 0.5, 0.15)  # Bright green with low opacity
	draw_colored_polygon(points, source_color)
	
	# Draw outline in brighter green
	var outline_color = Color(0.0, 1.0, 0.5, 0.6)
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], outline_color, 3.0)

func _draw_center_point(center_pos: Vector2):
	# Draw a crosshair at the center point
	var cross_size = 20.0
	
	# Horizontal line
	draw_line(
		Vector2(center_pos.x - cross_size, center_pos.y),
		Vector2(center_pos.x + cross_size, center_pos.y),
		center_color,
		3.0
	)
	
	# Vertical line
	draw_line(
		Vector2(center_pos.x, center_pos.y - cross_size),
		Vector2(center_pos.x, center_pos.y + cross_size),
		center_color,
		3.0
	)
	
	# Draw a circle at the center
	draw_arc(center_pos, 10.0, 0, TAU, 32, center_color, 2.0)

func _draw_labels(center_pos: Vector2):
	# Draw label for center point
	var font = ThemeDB.fallback_font
	var font_size = 16
	
	draw_string(
		font,
		center_pos + Vector2(25, -25),
		"Mandala Center",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(1, 1, 1, 1)
	)
	
	# Draw label for threshold
	var threshold_y = sky_threshold * screen_size.y
	draw_string(
		font,
		Vector2(10, threshold_y - 10),
		"Sky Threshold",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(1, 1, 1, 1)
	)
	
	# Draw segment count label
	draw_string(
		font,
		Vector2(10, 30),
		str(mirror_segments) + " Mirror Segments",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(1, 1, 1, 1)
	)
	
	# Draw source segment label
	var segment_angle = TAU / float(mirror_segments)
	var half_segment = segment_angle * 0.5
	# Rotate counter-clockwise by one segment
	var start_angle = -segment_angle
	var end_angle = start_angle + half_segment
	var label_angle = (start_angle + end_angle) * 0.5  # Middle of the source segment
	var label_distance = 150.0  # Distance from center
	var label_pos = center_pos + Vector2(cos(label_angle), sin(label_angle)) * label_distance
	
	draw_string(
		font,
		label_pos,
		"SOURCE SEGMENT",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		font_size,
		Color(0.0, 1.0, 0.5, 1.0)  # Bright green
	)

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash_length: float):
	var direction = (to - from).normalized()
	var distance = from.distance_to(to)
	var current_pos = from
	var traveled = 0.0
	var drawing = true
	
	while traveled < distance:
		var next_traveled = min(traveled + dash_length, distance)
		var next_pos = from + direction * next_traveled
		
		if drawing:
			draw_line(current_pos, next_pos, color, width)
		
		current_pos = next_pos
		traveled = next_traveled
		drawing = not drawing

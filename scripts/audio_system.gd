extends Node

# Brown Noise Engine
var engine_player: AudioStreamPlayer
var engine_playback: AudioStreamGeneratorPlayback
var sample_hz = 22050.0
var brown_noise_state = 0.0

# Chord Progression Players (polyphonic - multiple simultaneous chords)
var chord_players = []
var chord_playbacks = []
var num_chord_voices = 3  # Allow 3 simultaneous chords for rich layering

# Kick Drum Player (60 BPM heartbeat)
var kick_player: AudioStreamPlayer
var kick_playback: AudioStreamGeneratorPlayback
var is_generating_kick = false
var kick_frame_index = 0
var kick_total_frames = 0

# Reference to GameManager for metronome
var game_manager: Node

# Restorative chord progressions (60 BPM, slow harmonic rhythm)
# Using open voicings (spread across 2+ octaves) and maj7/sus chords
# Frequencies in Hz - each chord has 4-5 notes for rich, floating texture

var chord_progressions = [
	# Cmaj7 (C2-E3-G3-B3-D4) - Home, dreamy
	[65.41, 164.81, 196.00, 246.94, 293.66],
	
	# Fmaj7 (F2-A3-C4-E4) - Drifting, safe
	[87.31, 220.00, 261.63, 329.63],
	
	# Csus2 (C2-D3-G3-C4) - Floating, neutral
	[65.41, 146.83, 196.00, 261.63],
	
	# Gsus4 (G2-C3-D3-G3) - Suspended, peaceful
	[98.00, 130.81, 146.83, 196.00],
]

var current_chord_index = 0

# Chord generation state (one per voice)
var chord_states = []

func _ready():
	# Get reference to GameManager
	game_manager = get_node("/root/Game/GameManager")
	
	setup_engine_noise()
	setup_chord_players()
	setup_kick_drum()
	
	# Connect to metronome for kick drum timing
	if game_manager:
		game_manager.beat_occurred.connect(_on_beat_occurred)
		print("AudioSystem: Connected to metronome for kick drum")

func _on_beat_occurred(beat_number: int):
	# Trigger kick on every beat (60 BPM = 1 beat per second)
	trigger_kick()
	
func setup_engine_noise():
	# Create continuous brown noise player
	engine_player = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_hz
	stream.buffer_length = 0.1  # Small buffer for responsiveness
	
	engine_player.stream = stream
	engine_player.volume_db = -9.0  # Audible background hum (doubled volume)
	add_child(engine_player)
	engine_player.play()
	engine_playback = engine_player.get_stream_playback()
	
	# Start generating brown noise in _process

func setup_chord_players():
	# Create multiple chord players for polyphonic playback
	for i in range(num_chord_voices):
		var player = AudioStreamPlayer.new()
		var stream = AudioStreamGenerator.new()
		stream.mix_rate = sample_hz
		stream.buffer_length = 0.1
		
		player.stream = stream
		player.volume_db = -8.0  # Audible but not overwhelming
		add_child(player)
		player.play()
		
		chord_players.append(player)
		chord_playbacks.append(player.get_stream_playback())
		
		# Initialize state for this voice
		chord_states.append({
			"is_generating": false,
			"frame_index": 0,
			"total_frames": 0,
			"phases": [],
			"freqs": [],
			"attack_frames": 0,
			"decay_frames": 0,
			"sustain_level": 0.0,
			"release_frames": 0
		})

func setup_kick_drum():
	# Create kick drum player
	kick_player = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_hz
	stream.buffer_length = 0.1
	
	kick_player.stream = stream
	kick_player.volume_db = -6.0  # Punchy but not overpowering
	add_child(kick_player)
	kick_player.play()
	kick_playback = kick_player.get_stream_playback()

func _process(delta):
	# Generate brown noise continuously
	generate_brown_noise()
	
	# Generate chord frames for all active voices
	for i in range(num_chord_voices):
		if chord_states[i]["is_generating"]:
			generate_chord_frames(i)
	
	# Generate kick drum frames if active
	if is_generating_kick:
		generate_kick_frames()

func generate_brown_noise():
	if not engine_playback:
		return
		
	var frames_available = engine_playback.get_frames_available()
	
	for i in range(frames_available):
		# Brown noise algorithm (random walk with low-pass filter)
		var white = randf_range(-1.0, 1.0)
		brown_noise_state = (brown_noise_state + white * 0.02)
		
		# Clamp to prevent drift
		brown_noise_state = clamp(brown_noise_state, -1.0, 1.0)
		
		# Apply gentle low-pass filtering for "engine hum" character
		var sample = brown_noise_state * 0.3
		
		engine_playback.push_frame(Vector2(sample, sample))

func play_chord():
	# Find an available voice (not currently generating)
	var voice_index = -1
	for i in range(num_chord_voices):
		if not chord_states[i]["is_generating"]:
			voice_index = i
			break
	
	# If all voices are busy, use the oldest one (voice 0)
	if voice_index == -1:
		voice_index = 0
	
	# Get next chord in progression
	var chord = chord_progressions[current_chord_index]
	current_chord_index = (current_chord_index + 1) % chord_progressions.size()
	
	# Start async chord generation on this voice
	start_chord_generation(voice_index, chord)

func start_chord_generation(voice_index: int, chord: Array):
	var state = chord_states[voice_index]
	
	# Set up chord generation parameters
	state["freqs"] = chord
	state["frame_index"] = 0
	
	# Pre-calculate frequency increments to avoid division in the sample loop
	state["increments"] = []
	for freq in chord:
		state["increments"].append(freq / sample_hz)
	
	# 60 BPM = 1 beat per second
	# Hold each chord for 4 beats (4 seconds) for slow harmonic rhythm
	var duration = 4.0
	state["total_frames"] = int(sample_hz * duration)
	
	# ADSR parameters optimized for restorative music
	var attack = int(sample_hz * 0.8)    # 800ms - very slow swell
	var decay = int(sample_hz * 0.3)     # 300ms decay
	var sustain = 0.7                      # 70% sustain - present but gentle
	var release = int(sample_hz * 1.0)   # 1000ms - long, peaceful fade
	
	state["attack_frames"] = attack
	state["decay_frames"] = decay
	state["sustain_level"] = sustain
	state["release_frames"] = release
	
	# Pre-calculate reciprocals for envelope generation (Divisions are expensive in loops)
	state["inv_attack"] = 1.0 / float(attack) if attack > 0 else 0.0
	state["inv_decay"] = 1.0 / float(decay) if decay > 0 else 0.0
	state["inv_release"] = 1.0 / float(release) if release > 0 else 0.0
	state["release_start_frame"] = state["total_frames"] - release
	
	# Reset phases to zero to prevent discontinuity
	state["phases"] = []
	for i in range(chord.size()):
		state["phases"].append(0.0)
	
	state["is_generating"] = true

func generate_chord_frames(voice_index: int):
	var playback = chord_playbacks[voice_index]
	var state = chord_states[voice_index]
	
	if not playback:
		state["is_generating"] = false
		return
	
	var frames_available = playback.get_frames_available()
	
	# Generate frames in small batches to prevent buffer overflow
	var frames_to_generate = min(frames_available, 512)
	
	# Cache values locally for faster access in loop
	var frame_idx = state["frame_index"]
	var total = state["total_frames"]
	var attack = state["attack_frames"]
	var decay_end = attack + state["decay_frames"]
	var release_start = state["release_start_frame"]
	var sustain = state["sustain_level"]
	var inv_attack = state["inv_attack"]
	var inv_decay = state["inv_decay"]
	var inv_release = state["inv_release"]
	var increments = state["increments"]
	var phases = state["phases"]
	var num_notes_float_inv = 1.0 / float(state["freqs"].size()) # Multiplication is faster than division
	
	for i in range(frames_to_generate):
		if frame_idx >= total:
			state["is_generating"] = false
			state["frame_index"] = frame_idx # Save state before exit
			return
		
		# Inline Envelope Calculation for performance
		var envelope = 0.0
		if frame_idx < attack:
			envelope = float(frame_idx) * inv_attack
		elif frame_idx < decay_end:
			var decay_progress = float(frame_idx - attack) * inv_decay
			envelope = 1.0 - (1.0 - sustain) * decay_progress
		elif frame_idx < release_start:
			envelope = sustain
		else:
			var release_progress = float(frame_idx - release_start) * inv_release
			envelope = sustain * (1.0 - release_progress)
		
		# Mix all notes
		var mixed_sample = 0.0
		var note_count = increments.size()
		
		for note_idx in range(note_count):
			# Use sine wave for pure, pad-like tone
			var note_sample = sin(phases[note_idx] * TAU)
			mixed_sample += note_sample
			phases[note_idx] = fmod(phases[note_idx] + increments[note_idx], 1.0)
		
		# Apply weighting and envelope
		mixed_sample *= (num_notes_float_inv * envelope * 0.15)
		
		# Push stereo frame
		playback.push_frame(Vector2(mixed_sample, mixed_sample))
		
		frame_idx += 1
	
	# Save updated state
	state["frame_index"] = frame_idx

func trigger_kick():
	# Start kick drum generation
	kick_frame_index = 0
	kick_total_frames = int(sample_hz * 0.3)  # 300ms kick duration
	is_generating_kick = true

func generate_kick_frames():
	if not kick_playback:
		is_generating_kick = false
		return
	
	var frames_available = kick_playback.get_frames_available()
	var frames_to_generate = min(frames_available, 512)
	
	for i in range(frames_to_generate):
		if kick_frame_index >= kick_total_frames:
			is_generating_kick = false
			return
		
		# Kick drum synthesis:
		# - Frequency sweep from 150Hz to 50Hz (pitch drop)
		# - Exponential decay envelope
		# - Short duration (300ms)
		
		var progress = float(kick_frame_index) / float(kick_total_frames)
		
		# Frequency sweep (150Hz -> 50Hz)
		var start_freq = 150.0
		var end_freq = 50.0
		var freq = start_freq + (end_freq - start_freq) * progress
		
		# Exponential decay envelope
		var envelope = exp(-progress * 8.0)  # Fast decay
		
		# Generate sine wave at current frequency
		var phase = (freq / sample_hz) * float(kick_frame_index)
		var sample = sin(phase * TAU) * envelope * 0.5
		
		# Push stereo frame
		kick_playback.push_frame(Vector2(sample, sample))
		
		kick_frame_index += 1

# Centralized Metronome System

## Overview

The game now uses a **centralized 60 BPM metronome** in the `GameManager` to synchronize all timing-dependent systems. This prevents timer drift that can occur when multiple systems use independent timers, especially during lag spikes.

## Key Concepts

- **BPM**: 60 beats per minute (1 beat = 1 second)
- **Bar**: 4 beats (4 seconds)
- **Beat Phase**: Position within current beat (0.0 to 1.0)
- **Bar Phase**: Position within current bar (0.0 to 1.0)

## Benefits

1. **No Drift**: All systems reference the same clock, so they stay synchronized even during lag
2. **Predictable**: Timing is deterministic and based on actual elapsed time
3. **Flexible**: Systems can listen to beat/bar events OR poll the metronome state
4. **Restorative**: Maintains the 60 BPM rhythm essential for the game's calming effect

## How to Use

### Method 1: Listen to Signals (Recommended)

Connect to the metronome's signals in your `_ready()` function:

```gdscript
func _ready():
    var game_manager = get_node("/root/Game/GameManager")
    if game_manager:
        # Trigger on every beat (1 second intervals)
        game_manager.beat_occurred.connect(_on_beat)
        
        # Trigger on every bar (4 second intervals)
        game_manager.bar_occurred.connect(_on_bar)

func _on_beat(beat_number: int):
    print("Beat: ", beat_number)
    # Do something every beat

func _on_bar(bar_number: int):
    print("Bar: ", bar_number)
    # Do something every bar
```

### Method 2: Query Metronome State

Use the helper functions to check metronome state in your `_process()`:

```gdscript
func _process(delta):
    var game_manager = get_node("/root/Game/GameManager")
    
    # Get current phase (0.0 to 1.0)
    var beat_phase = game_manager.get_beat_phase()
    var bar_phase = game_manager.get_bar_phase()
    
    # Check if we're on a beat/bar
    if game_manager.is_on_beat(0.05):  # Within 5% of beat
        print("On beat!")
    
    # Get time until next event
    var time_to_beat = game_manager.get_time_to_next_beat()
    var time_to_bar = game_manager.get_time_to_next_bar()
    
    # Get current beat/bar numbers
    var current_beat = game_manager.get_current_beat()
    var current_bar = game_manager.get_current_bar()
```

## Currently Synchronized Systems

1. **Gate Spawner** (`spawner.gd`): Spawns gates every bar (4 beats)
2. **Lane Line Spawner** (`lane_line_spawner.gd`): Spawns lane lines every beat (1 second)
3. **Audio System** (`audio_system.gd`): Kick drum triggers on every beat

## Adding New Synchronized Systems

To synchronize a new system:

1. Remove any independent timers (e.g., `spawn_timer`)
2. Get a reference to GameManager in `_ready()`
3. Connect to `beat_occurred` or `bar_occurred` signals
4. Implement your callback function

Example:

```gdscript
extends Node3D

var game_manager: Node

func _ready():
    game_manager = get_node("/root/Game/GameManager")
    if game_manager:
        game_manager.beat_occurred.connect(_on_beat)

func _on_beat(beat_number: int):
    # Your synchronized logic here
    spawn_particle()
```

## Technical Details

- **Metronome Update**: Runs first in `GameManager._process()` before any other logic
- **Signal Emission**: Signals are emitted when beat/bar number changes
- **Time Source**: Uses `delta` accumulation for frame-rate independence
- **Phase Calculation**: Uses `fmod()` for smooth interpolation between beats/bars

## Future Enhancements

Potential additions to the metronome system:

- Tempo changes (currently fixed at 60 BPM)
- Swing/groove timing
- Time signature changes (currently 4/4)
- Metronome pause/resume
- Beat subdivision (eighth notes, sixteenth notes, etc.)

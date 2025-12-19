# Metronome Synchronization Implementation Summary

## Problem
Multiple game systems (spawners, audio, player movement) were using independent timers that could drift out of sync during lag spikes, breaking the 60 BPM rhythm essential for the game's restorative design.

## Solution
Implemented a centralized 60 BPM metronome in `GameManager` that serves as the single source of truth for all timing in the game.

## Changes Made

### 1. GameManager (`scripts/game_manager.gd`)

**Added:**
- Metronome state variables:
  - `metronome_time`: Total elapsed time
  - `current_beat`: Current beat number
  - `current_bar`: Current bar number (every 4 beats)
  - `beat_phase`: Position within current beat (0.0 to 1.0)
  - `bar_phase`: Position within current bar (0.0 to 1.0)

- Signals:
  - `beat_occurred(beat_number: int)`: Emitted every beat (1 second)
  - `bar_occurred(bar_number: int)`: Emitted every bar (4 seconds)

- Helper functions:
  - `get_beat_phase()`: Query current beat phase
  - `get_bar_phase()`: Query current bar phase
  - `get_current_beat()`: Get beat number
  - `get_current_bar()`: Get bar number
  - `is_on_beat(tolerance)`: Check if near a beat
  - `is_on_bar(tolerance)`: Check if near a bar
  - `get_time_to_next_beat()`: Time until next beat
  - `get_time_to_next_bar()`: Time until next bar
  - `get_metronome_time()`: Total elapsed time

**Modified:**
- `_process()`: Now updates metronome first, before any other logic

### 2. Gate Spawner (`scripts/spawner.gd`)

**Removed:**
- `spawn_interval` export variable
- `spawn_timer` variable
- Timer-based spawning in `_process()`

**Added:**
- `game_manager` reference
- Connection to `bar_occurred` signal
- `_on_bar_occurred()` callback

**Result:** Gates now spawn exactly every 4 beats (4 seconds), synchronized with chord changes.

### 3. Lane Line Spawner (`scripts/lane_line_spawner.gd`)

**Removed:**
- `spawn_interval` export variable
- `spawn_timer` variable
- Timer-based spawning in `_process()`

**Added:**
- Connection to `beat_occurred` signal
- `_on_beat_occurred()` callback

**Result:** Lane lines now spawn exactly every beat (1 second), creating perfect visual rhythm.

### 4. Audio System (`scripts/audio_system.gd`)

**Removed:**
- `kick_timer` variable
- `kick_interval` variable
- Timer-based kick triggering in `_process()`

**Added:**
- `game_manager` reference
- Connection to `beat_occurred` signal
- `_on_beat_occurred()` callback

**Result:** Kick drum now triggers exactly on every beat, perfectly synchronized with spawners.

### 5. Player (`scripts/player.gd`)

**Modified:**
- `_physics_process()`: Vertical floating motion now uses `game_manager.get_bar_phase()` instead of independent time calculation

**Result:** Car's breathing-like float is now perfectly synchronized with the 4-beat rhythm.

### 6. Documentation

**Created:**
- `docs/metronome_system.md`: Comprehensive guide on using the metronome system
- `docs/metronome_implementation_summary.md`: This file

## Benefits

1. **Perfect Synchronization**: All systems reference the same clock
2. **No Drift**: Even during lag spikes, timing relationships are preserved
3. **Predictable**: Deterministic timing based on actual elapsed time
4. **Maintainable**: Single source of truth makes debugging easier
5. **Extensible**: Easy to add new synchronized systems via signals
6. **Restorative**: Maintains the 60 BPM rhythm essential for attention restoration

## Testing Checklist

- [ ] Gates spawn every 4 seconds (every bar)
- [ ] Lane lines spawn every 1 second (every beat)
- [ ] Kick drum plays every 1 second (every beat)
- [ ] Car floats up and down over 4 seconds (every bar)
- [ ] All timing stays synchronized during lag (test by pausing debugger briefly)
- [ ] Chord progressions align with gate spawns (every 4 beats)

## Future Enhancements

Potential additions:
- Visual metronome indicator for debugging
- Tempo changes (currently fixed at 60 BPM)
- Swing/groove timing
- Beat subdivision (eighth notes, etc.)
- Metronome pause/resume functionality
- Time signature changes (currently 4/4)

## Migration Guide for New Systems

To synchronize a new system to the metronome:

1. Remove any `timer` variables
2. Get GameManager reference in `_ready()`
3. Connect to appropriate signal (`beat_occurred` or `bar_occurred`)
4. Implement callback function
5. (Optional) Use helper functions to query phase for smooth interpolation

Example:
```gdscript
var game_manager: Node

func _ready():
    game_manager = get_node("/root/Game/GameManager")
    if game_manager:
        game_manager.beat_occurred.connect(_on_beat)

func _on_beat(beat_number: int):
    # Your synchronized logic here
    pass
```

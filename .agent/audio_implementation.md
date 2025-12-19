# Audio System Implementation

## Overview
Implemented a procedural audio system for the relaxing driving game following Attention Restoration Theory principles.

## Components

### 1. Brown Noise Engine (Continuous Background)
- **Type**: Procedural brown noise generator
- **Purpose**: Provides steady "engine hum" to mask external distractions
- **Implementation**: 
  - Uses `AudioStreamGenerator` with random walk algorithm
  - Low-pass filtered for smooth, deep rumble
  - Volume: -15dB (subtle background layer)
  - Sample rate: 22,050 Hz

### 2. Chord Progression System (Gate Collection)
- **Type**: Procedural harmonic chords
- **Purpose**: Relaxing audio reward when passing through gates
- **Implementation**:
  - 4-chord progression: C Major → A Minor → F Major → G Major
  - Each chord uses 3 sine wave harmonics
  - ADSR envelope for smooth, pad-like sound:
    - Attack: 150ms (gentle fade-in)
    - Decay: 100ms
    - Sustain: 60% level
    - Release: 400ms (gentle fade-out)
  - Duration: 1.2 seconds per chord
  - Volume: -8dB (audible but not overwhelming)

## Design Principles Applied

✅ **Brown/Pink Noise Base Layer**: Engine hum masks distractions  
✅ **Harmonic Feedback**: Chords use consonant intervals (major/minor triads)  
✅ **Predictable Rhythm**: Chord progressions follow familiar I-vi-IV-V pattern  
✅ **No Abrasive Sounds**: All tones use smooth sine waves with ADSR envelopes  
✅ **Soft Fascination**: Audio rewards are pleasant but not demanding

## Files Modified

1. **`scripts/audio_system.gd`** (NEW)
   - Core audio generation system
   - Brown noise generator
   - Chord progression player

2. **`scripts/game_manager.gd`** (MODIFIED)
   - Added `audio_system` reference
   - Added `setup_audio()` function
   - Modified `add_harmony()` to trigger chord progressions

## How It Works

1. **Game Start**: 
   - GameManager initializes AudioSystem
   - Brown noise engine starts immediately
   - Runs continuously in background

2. **Gate Collection**:
   - Player passes through gate
   - `gate.gd` calls `game_manager.add_harmony()`
   - GameManager triggers `audio_system.play_chord()`
   - Next chord in progression plays with smooth envelope

## Testing

To test the audio system:
1. Run the game in Godot
2. Listen for subtle brown noise "engine hum" immediately
3. Drive through a gate
4. Hear a relaxing chord progression (C → Am → F → G cycle)

## Future Enhancements

Potential improvements:
- Add volume controls in settings
- Implement dynamic chord selection based on game state
- Add subtle reverb/delay effects
- Vary brown noise intensity with speed

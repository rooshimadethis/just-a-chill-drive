# Metronome Debug Overlay

A visual debug tool to verify that the metronome system is working correctly.

## How to Use

1. **Add to Scene:**
   - Open your main game scene in Godot
   - Add a new `CanvasLayer` node
   - Attach the `metronome_debug_overlay.gd` script to it
   - Run the game

2. **What You'll See:**
   - Current metronome time
   - Current beat number and phase (0-100%)
   - Current bar number and phase (0-100%)
   - Which beat in the bar (1/4, 2/4, 3/4, 4/4)
   - Visual beat indicator (█ shows current beat)
   - Progress bar showing beat phase

3. **Visual Feedback:**
   - Text flashes **yellow** on each beat (every 1 second)
   - Text flashes **orange** on each bar (every 4 seconds)

## What to Look For

### Correct Behavior:
- Beat number increments every 1 second
- Bar number increments every 4 seconds
- Beat phase smoothly goes from 0% to 100% over 1 second
- Visual beat indicator moves through all 4 positions
- Lane lines spawn when beat phase is near 0%
- Gates spawn when bar phase is near 0%
- Kick drum plays when text flashes yellow

### Synchronization Test:
1. Watch the beat indicator (█)
2. Listen for the kick drum
3. Watch for lane line spawns
4. They should all happen at the exact same moment

### Lag Test:
1. Pause the game for a few seconds (using debugger or Alt+Tab)
2. Resume the game
3. Everything should still be synchronized
4. No drift should occur

## Removing the Debug Overlay

When you're satisfied that everything is synchronized:
1. Delete the `CanvasLayer` node with the debug script
2. Or disable the script by unchecking it in the Inspector

## Troubleshooting

**"GameManager not found!"**
- Make sure your GameManager is at `/root/Game/GameManager`
- Check that the GameManager script is attached and running

**Beat/Bar not incrementing:**
- Check that `GameManager._process()` is being called
- Verify that `metronome_time` is increasing

**No flashing on beats:**
- Verify that signals are being emitted
- Check that the debug overlay is connected to the signals

**Spawns not synchronized:**
- Check that spawners are connected to the metronome signals
- Verify that `_on_beat_occurred()` or `_on_bar_occurred()` callbacks are being called

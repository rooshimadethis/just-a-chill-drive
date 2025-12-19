# Mandala Effect Debug Visualization Guide

## What You're Seeing

The debug overlay shows you exactly how the mandala/kaleidoscope effect works:

### 🔴 Red Crosshair (Center Point)
- This is the **source point** of the mandala effect
- Currently positioned at `(0.5, 0.25)` in normalized screen coordinates
- This means it's at the horizontal center and 25% down from the top
- All mirroring radiates from this point

### 🟠 Orange Solid Lines (Mirror Segments)
- These are the **primary mirror boundaries**
- With 8 segments, the screen is divided into 8 pizza-slice-like sections
- Each section is mirrored to create the kaleidoscope pattern

### 🟠 Orange Dashed Lines (Half-Segments)
- These show where the **mirroring happens within each segment**
- The shader mirrors content across these lines for perfect symmetry
- This creates the characteristic kaleidoscope "fold" effect

### 🔵 Cyan Solid Line (Sky Threshold)
- This horizontal line shows where the mandala effect **starts to apply**
- Currently at `0.4` (40% down from the top)
- Above this line = full mandala effect
- Below this line = normal view (no effect)

### 🔵 Cyan Dashed Lines (Blend Range)
- These show the **soft transition zone**
- The effect gradually fades in/out between these lines
- Prevents harsh cutoff between mandala and normal view

## How It Works

1. **Source**: The shader samples pixels from around the red crosshair
2. **Segments**: It divides the view into 8 equal angular segments
3. **Mirroring**: Each segment is mirrored across its half-line
4. **Masking**: Only pixels above the cyan threshold line get the effect
5. **Blending**: The transition is smoothed in the dashed line zone

## Toggling Debug View

To turn off the debug visualization, you can:
- Set `enable_debug = false` in the MandalaDebug node properties
- Or comment out/remove the MandalaDebug node from the scene

## Adjusting Parameters

All these values can be adjusted in the inspector:
- `mirror_segments`: More segments = more complex patterns
- `center_offset`: Move the mandala center point
- `sky_threshold`: Adjust where the effect starts
- `blend_softness`: Make the transition harder or softer

---
trigger: always_on
---

When making decisions for this game, ensure you're trying to make it relaxing and not aggressive or attention-grabbing. The purpose of this game is to find a way to relax and recharge during short games between work sessions.

Project Goal: Develop a driving game designed specifically to induce Attention Restoration (psychological recovery) for a software engineer during work breaks. The priority is Soft Fascination over Challenge.

Core Scientific Principles (Attention Restoration Theory applied to Game Dev):

1. Visual Guidelines (Biophilic & Fractal Design)

Color Palette: Use low-contrast, analog color schemes (blues, greens, soft purples). Avoid high-contrast "danger" colors (red/orange) unless used for warm, non-threatening lighting.

Motion: All movement must be fluid. Avoid jerky, instant transitions. Use ease-in/ease-out interpolation for UI and camera movements.

Geometry: Prefer "Fractal Fluency." Procedural generation should mimic natural curves (Perlin/Simplex noise) rather than rigid grid structures or sharp 90-degree angles.

UI Policy: Minimalist/Diegetic only. No score counters, timers, or flashing health bars on the HUD. Information should be conveyed through environmental cues (lighting changes, audio pitch).

2. Audio Guidelines (Entrainment & Masking)

Soundscape: Base layer must be "Brown Noise" or "Pink Noise" (e.g., a steady engine hum or wind) to mask external distractions.

Music Logic: If music is present, it must be quantized and predictable. Avoid irregular jazz/staccato rhythms. Target 60-90 BPM to encourage alpha brain wave states.

Feedback: Audio feedback for actions (collecting items) must be harmonic (chimes/pads), not abrasive (buzzers/crashes).

3. Gameplay Mechanics (Flow over Fight)

The "No-Fail" Rule: There are no "Game Over" states. The player cannot die, crash, or lose progress.

Collision Logic: "Soft Collisions" only. If the player hits an obstacle, use a repulsion force (bouncy physics) rather than a hard stop. Preserve momentum.

Input Handling: Implement lerp (Linear Interpolation) on player inputs. The car should follow the cursor/finger with a weighted delay (weight = 0.1 to 0.3), creating a "towing" sensation rather than 1:1 twitchy movement.

Goal Structure: Goals must be "opt-in." Missing a collectable has zero penalty. Hitting a collectable offers a sensory reward.

4. Anti-Patterns (Strictly Forbidden)

Do not implement "Dodging" mechanics that require twitch reactions.

Do not implement "Resource Scarcity" (fuel, health, ammo).

Do not implement high-frequency flashing lights (strobe effects).

Implementation Instruction for Code Generation: When asked to generate code (GDScript/C#), prioritize readability and smooth interpolation (Mathf.Lerp / move_toward) over rigid grid movement. Physics calculations should favor "arcade flow" over "realistic friction."
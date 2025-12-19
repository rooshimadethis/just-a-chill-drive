shader_type canvas_item;

// Screen texture uniform for Godot 4
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Mandala/Kaleidoscope parameters
uniform int mirror_segments : hint_range(3, 16) = 8;
uniform float rotation_speed : hint_range(0.0, 2.0) = 0.05;
uniform vec2 center_offset = vec2(0.5, 0.5); // Center point of kaleidoscope
uniform float zoom : hint_range(0.1, 3.0) = 1.0;

// Sky masking parameters
uniform float sky_threshold : hint_range(0.0, 1.0) = 0.5; // Y position below which effect is disabled
uniform float blend_softness : hint_range(0.0, 0.5) = 0.1; // Softness of the transition
uniform float opacity : hint_range(0.0, 1.0) = 0.2; // Overall opacity of the mandala effect

void fragment() {
    // Get screen UV coordinates
    vec2 screen_uv = SCREEN_UV;
    
    // Calculate sky mask based on vertical position
    // 0.0 = top of screen (sky), 1.0 = bottom of screen (road)
    float sky_mask = smoothstep(sky_threshold + blend_softness, sky_threshold - blend_softness, screen_uv.y);
    
    // Only apply kaleidoscope effect if we're in the sky area
    vec4 final_color;
    
    if (sky_mask > 0.01) {
        // Center around the kaleidoscope center
        vec2 uv = screen_uv - center_offset;
        
        // Apply zoom
        uv *= zoom;
        
        // Convert to polar coordinates
        float angle = atan(uv.y, uv.x);
        float radius = length(uv);
        
        // Add rotation over time
        angle += TIME * rotation_speed;
        
        // Create mirror segments
        float segment_angle = 6.28318530718 / float(mirror_segments); // 2*PI / segments
        
        // Rotate the entire pattern one segment counter-clockwise
        // Counter-clockwise = add positive angle (in standard math coords)
        angle += segment_angle;
        
        angle = mod(angle, segment_angle);
        
        // Mirror every other segment for perfect symmetry
        float half_segment = segment_angle * 0.5;
        if (angle > half_segment) {
            angle = segment_angle - angle;
        }
        
        // Convert back to cartesian coordinates
        vec2 mirrored_uv = vec2(cos(angle), sin(angle)) * radius;
        
        // Offset back to screen UV space
        mirrored_uv += center_offset;
        
        // Clamp to avoid sampling outside screen bounds
        mirrored_uv = clamp(mirrored_uv, vec2(0.0), vec2(1.0));
        
        // Sample the screen texture at the mirrored position
        vec4 kaleidoscope_color = texture(screen_texture, mirrored_uv);
        
        // Sample the original screen texture
        vec4 original_color = texture(screen_texture, screen_uv);
        
        // Blend between kaleidoscope and original based on sky mask and opacity
        final_color = mix(original_color, kaleidoscope_color, sky_mask * opacity);
    } else {
        // Just show the original for non-sky areas
        final_color = texture(screen_texture, screen_uv);
    }
    
    COLOR = final_color;
}


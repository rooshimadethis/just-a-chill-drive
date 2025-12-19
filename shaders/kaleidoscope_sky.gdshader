shader_type sky;

// Kaleidoscope parameters
uniform float rotation_speed : hint_range(0.0, 2.0) = 0.05;
uniform int mirror_segments : hint_range(3, 12) = 6;
uniform float pattern_scale : hint_range(0.1, 5.0) = 1.5;
uniform vec3 color_tint_1 : source_color = vec3(0.3, 0.6, 0.9); // Soft blue
uniform vec3 color_tint_2 : source_color = vec3(0.6, 0.3, 0.8); // Soft purple
uniform vec3 color_tint_3 : source_color = vec3(0.4, 0.8, 0.7); // Soft cyan
uniform float brightness : hint_range(0.1, 2.0) = 1.0;
uniform float fractal_detail : hint_range(1.0, 6.0) = 3.0;
uniform float kaleidoscope_blend : hint_range(0.0, 1.0) = 0.4; // How much kaleidoscope vs gradient

// Sky gradient colors
uniform vec3 horizon_color : source_color = vec3(0.7, 0.5, 0.6); // Soft pink/purple horizon
uniform vec3 zenith_color : source_color = vec3(0.1, 0.2, 0.4); // Deep blue zenith

// Noise function for organic patterns
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for complex patterns
float fbm(vec2 p, float detail) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(float i = 0.0; i < detail; i += 1.0) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

// Create kaleidoscope effect by mirroring
vec2 kaleidoscope(vec2 uv, float segments, float time) {
    // Convert to polar coordinates
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    
    // Add rotation
    angle += time * rotation_speed;
    
    // Create mirror segments
    float segment_angle = 6.28318530718 / segments; // 2*PI / segments
    angle = mod(angle, segment_angle);
    
    // Mirror every other segment for symmetry
    float half_segment = segment_angle * 0.5;
    if (angle > half_segment) {
        angle = segment_angle - angle;
    }
    
    // Convert back to cartesian
    return vec2(cos(angle), sin(angle)) * radius;
}

void sky() {
    // Get direction vector
    vec3 dir = EYEDIR;
    
    // Calculate gradient factor based on vertical direction
    // -1 = looking down, 0 = horizon, 1 = looking up
    float gradient_factor = dir.y;
    
    // Create smooth gradient from horizon to zenith
    // Use smoothstep for natural atmospheric falloff
    float sky_gradient = smoothstep(-0.1, 0.8, gradient_factor);
    
    // Base sky color (natural gradient)
    vec3 base_sky = mix(horizon_color, zenith_color, sky_gradient);
    
    // Project to 2D (using spherical projection)
    vec2 uv = vec2(atan(dir.x, dir.z), asin(dir.y));
    uv *= pattern_scale;
    
    // Apply kaleidoscope effect
    float time = TIME * 0.1; // Slow rotation for relaxation
    vec2 kaleid_uv = kaleidoscope(uv, float(mirror_segments), time);
    
    // Generate fractal pattern
    float pattern1 = fbm(kaleid_uv * 2.0 + vec2(time * 0.3, 0.0), fractal_detail);
    float pattern2 = fbm(kaleid_uv * 3.0 - vec2(0.0, time * 0.2), fractal_detail);
    float pattern3 = fbm(kaleid_uv * 1.5 + vec2(time * 0.15, time * 0.15), fractal_detail);
    
    // Combine patterns with colors
    vec3 kaleidoscope_color = vec3(0.0);
    kaleidoscope_color += color_tint_1 * pattern1;
    kaleidoscope_color += color_tint_2 * pattern2;
    kaleidoscope_color += color_tint_3 * pattern3;
    
    // Add some shimmer based on angle
    float shimmer = sin(length(kaleid_uv) * 10.0 - time * 2.0) * 0.5 + 0.5;
    kaleidoscope_color += vec3(shimmer * 0.1);
    
    // Normalize kaleidoscope
    kaleidoscope_color = kaleidoscope_color * 0.5; // Tone down for blending
    
    // Blend kaleidoscope pattern with natural sky gradient
    // More kaleidoscope at horizon, more gradient at zenith for natural look
    float blend_factor = kaleidoscope_blend * (1.0 - sky_gradient * 0.5);
    vec3 final_color = mix(base_sky, base_sky + kaleidoscope_color, blend_factor);
    
    // Apply overall brightness
    final_color = final_color * brightness;
    
    COLOR = final_color;
}

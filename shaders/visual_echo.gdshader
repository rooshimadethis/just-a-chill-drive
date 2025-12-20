shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    // Get the screen texture (captured by BackBufferCopy)
    vec4 color = texture(screen_texture, SCREEN_UV);
    
    // Create multiple samples with radial offset from center
    // This creates a "trailing echo" effect (Zoom Blur)
    vec2 center = vec2(0.5, 0.5);
    vec2 offset = SCREEN_UV - center;
    
    // Multiple echo samples at different distances
    float sep = 0.02 * strength;
    
    vec4 echo1 = texture(screen_texture, center + offset * (1.0 - sep));
    vec4 echo2 = texture(screen_texture, center + offset * (1.0 - sep * 2.0));
    vec4 echo3 = texture(screen_texture, center + offset * (1.0 - sep * 3.0));
    vec4 echo4 = texture(screen_texture, center + offset * (1.0 - sep * 4.0));
    
    // Blend echoes with additive style and cyan tint
    vec3 result = color.rgb;
    
    // Add echoes with decreasing opacity and slight color shift
    result += echo1.rgb * 0.25 * strength * vec3(0.8, 1.0, 1.2);
    result += echo2.rgb * 0.15 * strength * vec3(0.7, 0.9, 1.3);
    result += echo3.rgb * 0.10 * strength * vec3(0.6, 0.8, 1.4);
    result += echo4.rgb * 0.05 * strength * vec3(0.5, 0.7, 1.5);
    
    COLOR = vec4(result, 1.0);
}

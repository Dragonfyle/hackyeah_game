shader_type canvas_item;



uniform float burst_progress : hint_range(0.0, 1.0) = 0.0; // animate 0 → 1

uniform float spread_strength : hint_range(0.0, 2.0) = 1.0; // how far pixels fly out

uniform float distortion_strength : hint_range(0.0, 0.2) = 0.05; // wavy distortion

uniform float fade_start : hint_range(0.0, 1.0) = 0.7; // when to start fading alpha
uniform float health_fill : hint_range(0.0, 1.0) = 0.0; // 0.0 = puste (100% życia), 1.0 = pełne (0% życia)



void fragment() {

    // Center UVs

    vec2 centered_uv = UV - vec2(0.5);



    // Direction from center

    vec2 dir = normalize(centered_uv);



    // Distance from center

    float dist = length(centered_uv);



    // Push pixels outward over time

    vec2 uv_outward = centered_uv + dir * burst_progress * spread_strength;



    // Add distortion for energy-like wobble

    uv_outward += distortion_strength * vec2(

        sin(dist * 20.0 - TIME * 10.0),

        cos(dist * 20.0 - TIME * 8.0)

    ) * burst_progress;



    // Return to standard UV space

    vec2 final_uv = uv_outward + vec2(0.5);



    // Sample texture

    vec4 tex = texture(TEXTURE, final_uv);



    // Fade out towards the end

    float alpha_factor = 1.0 - smoothstep(fade_start, 1.0, burst_progress);

    tex.a *= alpha_factor;
    
    // Health bar - fills the gray interior from bottom with white, keeping colorful border
    // health_fill: 0.0 = full health (100%), 1.0 = no health (0%)
    if (health_fill > 0.0 && tex.a > 0.1) {
        float vertical_position = UV.y; // 0.0 = top, 1.0 = bottom
        float health_threshold = 1.0 - health_fill;

        // Detect if pixel is part of the dark/gray interior (not the colorful border)
        float brightness = (tex.r + tex.g + tex.b) / 3.0;
        float saturation = max(max(tex.r, tex.g), tex.b) - min(min(tex.r, tex.g), tex.b);

        // Dark gray interior has low brightness and low saturation
        bool is_interior = brightness < 0.4 && saturation < 0.3;

        // Fill from bottom up based on missing health
        if (vertical_position >= health_threshold && is_interior) {
            // Pure white fill with subtle edge glow
            float edge_dist = vertical_position - health_threshold;
            float edge_glow = smoothstep(0.08, 0.0, edge_dist);

            vec3 fill_color = vec3(1.0); // Pure white
            fill_color = mix(fill_color, vec3(1.2), edge_glow * 0.5); // Slight glow at edge

            // Fill with white only the interior
            tex.rgb = mix(tex.rgb, fill_color, 0.95);
        }
    }

    COLOR = tex;

}

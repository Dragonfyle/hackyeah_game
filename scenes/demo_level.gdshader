shader_type canvas_item;

uniform bool enabled = true;
uniform float dot_scale : hint_range(0.01, 1.0) = 0.5;
uniform float contrast : hint_range(0.1, 3.0) = 1.5;
uniform float brightness : hint_range(-1.0, 1.0) = 0.0;
uniform float threshold : hint_range(0.0, 1.0) = 0.5;
uniform float smoothness : hint_range(0.01, 0.3) = 0.1;
uniform float color_separation : hint_range(0.0, 1.0) = 0.3;
uniform vec2 texture_size = vec2(1024.0, 768.0);
uniform vec3 warm_tint : source_color = vec3(1.0, 0.9, 0.7);
uniform float shimmer_speed : hint_range(0.1, 5.0) = 1.5;
uniform float shimmer_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float color_boost : hint_range(1.0, 3.0) = 1.8;

// Halftone pattern function from https://www.shadertoy.com/view/4dSSRG
float vx(float x, float y, float a)
{
    float l = 1.0 / sqrt(a * a + (1.0 - a) * (1.0 - a));
    float u = x * a - y * (1.0 - a);
    float v = x * (1.0 - a) + y * a;
    u *= l;
    v *= l;

    float scale = dot_scale;
    u = fract(u * scale) - 0.5;
    v = fract(v * scale) - 0.5;
    return 1.7 - sqrt(u * u + v * v) * 4.0;
}

void fragment() {
    if (!enabled) {
        COLOR = texture(TEXTURE, UV);
    } else {
        // Convert UV to centered coordinates for halftone positioning
        vec2 uv = UV * 4.0 - 0.5;

        // Apply aspect ratio correction to keep dots circular
        float aspect_ratio = texture_size.x / texture_size.y;
        if (aspect_ratio > 1.0) {
            uv.y /= aspect_ratio;
        } else {
            uv.x *= aspect_ratio;
        }

        vec4 tex_color = texture(TEXTURE, UV);
        vec3 adjusted_color = (tex_color.rgb + brightness) * contrast;
        adjusted_color = clamp(adjusted_color, 0.0, 1.0);

        float red_pattern = adjusted_color.r * 2.0 - threshold - 1.0;
        float green_pattern = adjusted_color.g * 2.0 - threshold - 1.0;
        float blue_pattern = adjusted_color.b * 2.0 - threshold - 1.0;

        float base_halftone = vx(uv.x * 150.0, uv.y * 150.0, 0.0);
        float red_halftone = vx(uv.x * 150.0, uv.y * 150.0, 0.12);
        float green_halftone = vx(uv.x * 150.0, uv.y * 150.0, 0.34);
        float blue_halftone = vx(uv.x * 150.0, uv.y * 150.0, 0.69);

        // Blend between unified and separated patterns
        float final_red_halftone = mix(base_halftone, red_halftone, color_separation);
        float final_green_halftone = mix(base_halftone, green_halftone, color_separation);
        float final_blue_halftone = mix(base_halftone, blue_halftone, color_separation);

        // Apply halftone pattern
        float red_raw = (red_pattern + final_red_halftone);
        float green_raw = (green_pattern + final_green_halftone);
        float blue_raw = (blue_pattern + final_blue_halftone);

        float red = smoothstep(0.5 - smoothness, 0.5 + smoothness, red_raw);
        float green = smoothstep(0.5 - smoothness, 0.5 + smoothness, green_raw);
        float blue = smoothstep(0.5 - smoothness, 0.5 + smoothness, blue_raw);

        vec3 halftone_color = vec3(red, green, blue) * warm_tint;

        // Create grayscale version
        float gray = dot(halftone_color, vec3(0.299, 0.587, 0.114));
        gray = gray * 0.7 + 0.1;
        vec3 grayscale = vec3(gray);

        // Detect bright areas in the original texture
        float brightness_mask = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
        brightness_mask = smoothstep(0.3, 0.6, brightness_mask);

        // Create shimmer effect that oscillates between 0 and 1
        float shimmer = sin(TIME * shimmer_speed + UV.x * 10.0 + UV.y * 10.0) * 0.5 + 0.5;
        shimmer = pow(shimmer, 2.0) * shimmer_intensity;

        // Apply shimmer only to bright areas
        shimmer *= brightness_mask;

        // Boost the original bright colors
        vec3 boosted_colors = halftone_color * color_boost;
        boosted_colors = clamp(boosted_colors, 0.0, 1.0);

        // Mix between grayscale and bright colors based on shimmer
        vec3 final_color = mix(grayscale, boosted_colors, shimmer);

        COLOR = vec4(final_color, tex_color.a);
    }
}

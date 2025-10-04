shader_type canvas_item;

uniform float wave_speed : hint_range(0.1, 10.0) = 3.0;
uniform float wave_amplitude : hint_range(0.0, 1.0) = 0.2;
uniform float sprite_rotation : hint_range(-3.14159, 3.14159) = 0.0;

void fragment() {
	// Center UV coordinates
	vec2 centered_uv = UV - vec2(0.5);

	// Counter-rotate UVs to keep wave effect orientation consistent
	float cos_angle = cos(-sprite_rotation);
	float sin_angle = sin(-sprite_rotation);
	vec2 rotated_uv = vec2(
		centered_uv.x * cos_angle - centered_uv.y * sin_angle,
		centered_uv.x * sin_angle + centered_uv.y * cos_angle
	);

	// Restore UV coordinates
	rotated_uv += vec2(0.5);

	float wave_mask = smoothstep(0.33, 0.4, rotated_uv.x);
	float wave_offset = sin((rotated_uv.x * 4.0 * 3.14159) - TIME * wave_speed) * wave_amplitude * wave_mask;
	rotated_uv.y += wave_offset;
	COLOR = texture(TEXTURE, rotated_uv);
}

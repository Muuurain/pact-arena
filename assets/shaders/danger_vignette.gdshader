shader_type canvas_item;

uniform float danger_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pact_pulse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 1.414;
	float edge = smoothstep(0.52, 1.0, d);
	float pulse = 0.78 + 0.22 * sin(TIME * 4.5);
	float alpha = edge * clamp(danger_intensity * 0.48 * pulse + pact_pulse * 0.22, 0.0, 0.65);
	vec3 col = mix(vec3(0.55, 0.08, 0.25), vec3(0.98, 0.14, 0.28), danger_intensity);
	COLOR = vec4(col, alpha);
}

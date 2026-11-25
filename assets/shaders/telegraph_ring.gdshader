shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.5;
uniform vec4 fill_color : source_color = vec4(0.96, 0.18, 0.36, 0.28);
uniform vec4 rim_color : source_color = vec4(1.0, 0.42, 0.52, 0.92);

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered) * 2.0;
	if (dist > 1.0) {
		COLOR = vec4(0.0);
	} else {
		float outer_rim = smoothstep(0.93, 0.96, dist) * (1.0 - smoothstep(0.985, 1.0, dist));
		float inner_fill = step(dist, progress) * 0.85;
		float inner_ring = smoothstep(progress - 0.05, progress, dist) * step(dist, progress);
		vec4 col = fill_color * (0.35 + inner_fill * 0.65);
		col = mix(col, rim_color, clamp(outer_rim + inner_ring * 0.8, 0.0, 1.0));
		COLOR = col;
	}
}

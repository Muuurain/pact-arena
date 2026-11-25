shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 armor_break_tint : source_color = vec4(1.0, 0.35, 0.45, 1.0);
uniform float armor_break_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	vec3 rgb = mix(tex.rgb, armor_break_tint.rgb, armor_break_amount * 0.45);
	rgb = mix(rgb, flash_color.rgb, flash_amount);
	COLOR = vec4(rgb, tex.a);
}

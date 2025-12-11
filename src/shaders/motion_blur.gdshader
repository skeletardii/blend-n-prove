shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 dir = vec2(1.0, 0.0);

void fragment() {
	if (strength <= 0.001) {
		COLOR = texture(TEXTURE, UV);
	} else {
		vec4 color = vec4(0.0);
		int samples = 8;
		
		for (int i = 0; i < samples; i++) {
			float t = float(i) / float(samples - 1);
			// Sample backwards from current position to simulate trail
			vec2 offset = -dir * strength * t * 0.1; 
			color += texture(TEXTURE, UV + offset);
		}
		
		COLOR = color / float(samples);
	}
}
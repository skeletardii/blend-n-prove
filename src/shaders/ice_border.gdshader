shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ice_color : source_color = vec4(0.4, 0.7, 1.0, 1.0);

// Simple pseudo-random function
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// 2D Noise function
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

// Fractal Brownian Motion for "fractal" look
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	vec2 center = vec2(0.5);
	
	// Calculate distance from center (rectangular distance for border effect)
	vec2 dist_vec = abs(uv - center) * 2.0;
	float dist = max(dist_vec.x, dist_vec.y);
	
	// Create a vignette/border mask
	// Only show when close to edges (dist > 0.6)
	float mask = smoothstep(0.6, 1.0, dist);
	
	// Generate ice pattern using FBM
	// Animate slowly with TIME
	float pattern = fbm(uv * 5.0 + vec2(TIME * 0.05));
	
	// Add "cracks" using domain warping or just high frequency noise
	float cracks = smoothstep(0.4, 0.6, noise(uv * 20.0));
	
	// Combine
	float ice = mask * (pattern + cracks * 0.2);
	
	// Apply intensity
	float alpha = ice * intensity * 1.5; // boost brightness
	
	COLOR = ice_color;
	COLOR.a = clamp(alpha, 0.0, 1.0);
}

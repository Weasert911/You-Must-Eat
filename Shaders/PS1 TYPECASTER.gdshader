shader_type spatial;
render_mode diffuse_lambert_wrap, specular_disabled; // PS1 style flat shading

uniform vec4 base_color : source_color = vec4(1.0); // Change this to change model color
uniform sampler2D texture_albedo : source_color, filter_nearest;
uniform float jitter : hint_range(0.0, 1.0) = 0.5;
uniform float resolution_scale = 160.0;

varying vec4 vertex_color;

void vertex() {
	// 1. Capture Vertex Color (for Godot's built-in lighting)
	vertex_color = COLOR;

	// 2. PS1 Vertex Jitter Logic
	vec4 snapped_pos = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0);
	
	if (jitter > 0.0) {
		float grid_size = resolution_scale / jitter;
		snapped_pos.xyz /= snapped_pos.w;
		snapped_pos.xy = floor(snapped_pos.xy * grid_size) / grid_size;
		snapped_pos.xyz *= snapped_pos.w;
	}
	
	POSITION = snapped_pos;
}

void fragment() {
	// 3. Combine Texture + Uniform Color + Vertex Lighting
	vec4 tex = texture(texture_albedo, UV);
	
	// This line multiplies the texture by your chosen color 
	// AND the scene's lighting (vertex_color)
	vec3 final_color = tex.rgb * base_color.rgb;
	
	ALBEDO = final_color;
	
	// 4. "Crunchy" PS1 Alpha (Optional)
	// If your texture has holes, this makes them sharp, not blurry
	ALPHA = tex.a * base_color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
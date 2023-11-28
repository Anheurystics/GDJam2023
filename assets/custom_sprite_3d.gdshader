// Minimal version of the Sprite3D shader that we can modify for fancy custom shader operations

shader_type spatial;
render_mode diffuse_lambert, depth_prepass_alpha;

uniform bool is_fading;
uniform float y_cutoff;
uniform sampler2D tex: source_color, filter_nearest;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	float tex_width = float(textureSize(tex, 0).x);
	float tex_size_x = 1.0 / tex_width;
	vec4 texture_albedo = texture(tex, UV);
	if (is_fading && UV.y < y_cutoff + (random(floor(UV * tex_width)/tex_width) * tex_size_x * 5.0)) {
		ALBEDO = texture_albedo.rgb;
	} else {
		ALBEDO = vec3(0.0, 0.0, 0.0);
	}
	SPECULAR = 0.0;
	ALPHA = texture_albedo.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
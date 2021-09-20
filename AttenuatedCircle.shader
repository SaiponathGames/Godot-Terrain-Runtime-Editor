shader_type spatial;
// by Sairam
uniform float radius = 3.0;
uniform float attenuated_radius = 0.01;
uniform float attenuation_strength = 1.0;
uniform float attenuated_size_multiplier = 1.0;
uniform float max_power = 1;
uniform float min_power = 0;

uniform vec4 color : hint_color = vec4(0.0, 1.0, 1.0, 0.5);

varying vec3 vertex_1;

float get_power_at_position(vec3 point) {
	vec3 origin = vec3(0.0, 0.0, 0.0);
	float dist = pow(distance(origin, point), 2.0);
	
	if (dist >= radius*radius) {
		return min_power;
	}
	if (dist <= attenuated_radius*attenuated_radius) {
		return max_power;
	}

	float ratio = 1.0 - ((dist - attenuated_radius*attenuated_radius) / (radius*radius - attenuated_radius*attenuated_radius));
	return mix(min_power, max_power, ratio) * attenuation_strength*attenuated_size_multiplier;
}

void vertex() {
	vertex_1 = VERTEX;
}

void fragment() {
	ALBEDO = color.xyz;
	ALPHA = get_power_at_position(vertex_1) * color.a;
}
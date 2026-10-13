shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

// Används på en PlaneMesh med storlek 2 x 2, så att skalan = radien i meter.

uniform vec4 safe_color : source_color = vec4(1.0, 1.0, 1.0, 0.35);
uniform vec4 warn_color : source_color = vec4(1.0, 0.6, 0.1, 0.6);
uniform vec4 danger_color : source_color = vec4(1.0, 0.15, 0.1, 0.85);
uniform float thickness = 0.05;
uniform float fill_strength = 0.08;

// Sätts från noise_emitter.gd
instance uniform float danger = 0.0;   // 0 = säkert, 1 = en vakt hör dig
instance uniform float pulse = 0.0;    // blinkar till vid varje fotsteg

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;   // 0 i mitten, 1 vid kanten

	// Själva ringen ytterst
	float ring = 1.0 - smoothstep(0.0, thickness, abs(d - (1.0 - thickness)));
	// Svag fyllning innanför, som blir tydligare när det är farligt
	float fill = (1.0 - step(1.0, d)) * fill_strength * (0.5 + danger);

	vec4 col = danger < 0.5
		? mix(safe_color, warn_color, danger * 2.0)
		: mix(warn_color, danger_color, (danger - 0.5) * 2.0);

	ALBEDO = col.rgb;
	ALPHA = clamp(col.a * (ring + fill) * (1.0 + pulse * 0.8), 0.0, 1.0);
}

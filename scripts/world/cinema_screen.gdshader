shader_type canvas_item;
// The Flashback Cinema's screen: one frame of a strip of scene frames at a time, slowly cross-faded to
// the next, in sepia with film grain, a flicker, a hop of the gate now and then, a couple of vertical
// scratches that come and go, and a vignette. darkness cuts it to black, flash whites it out, and burn
// eats a hole from the middle with a glowing rim, for the Projectionist. Drawn unshaded, as a lit
// screen in a dark house.
render_mode unshaded;

uniform int frames = 3;
// How long each frame holds, then how long it takes to fade into the next, in seconds.
uniform float hold = 5.0;
uniform float fade = 2.5;
uniform float darkness : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float burn : hint_range(0.0, 1.0) = 0.0;
// Keeps two screens out of step.
uniform float seed = 0.0;
// How bright the brightest part of the film is, so the screen never burns to white beside the HUD.
uniform float peak = 0.82;
uniform vec2 picture_size = vec2(160.0, 58.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = TIME + seed * 7.31;
	float cycle = hold + fade;
	float phase = t / cycle;
	int count = max(frames, 1);
	int index = int(floor(phase)) % count;
	int next = (index + 1) % count;
	float blend = smoothstep(hold, cycle, fract(phase) * cycle);
	// The gate hops a pixel for a moment now and then.
	float weave = step(0.94, hash(vec2(floor(t * 9.0), seed))) / picture_size.y;
	vec2 uv = vec2(UV.x, clamp(UV.y + weave, 0.0, 0.999));
	vec3 now = texture(TEXTURE, vec2((float(index) + uv.x) / float(count), uv.y)).rgb;
	vec3 then = texture(TEXTURE, vec2((float(next) + uv.x) / float(count), uv.y)).rgb;
	vec3 film = mix(now, then, blend);
	float lum = dot(film, vec3(0.299, 0.587, 0.114));
	vec3 sepia = vec3(lum * 1.07 + 0.03, lum * 0.88 + 0.02, lum * 0.64 + 0.01);
	sepia *= 0.9 + 0.1 * hash(vec2(floor(t * 14.0), 3.17));
	vec2 pixel = floor(UV * picture_size);
	sepia += (hash(pixel + vec2(floor(t * 24.0) * 1.7, 0.0)) - 0.5) * 0.12;
	for (int i = 0; i < 2; i++) {
		float slot = floor(t * 1.6 + float(i) * 13.0);
		float x = hash(vec2(slot, float(i) + seed));
		float shows = step(0.45, hash(vec2(slot, 9.0 + float(i))));
		float line = 1.0 - smoothstep(0.0, 0.7 / picture_size.x, abs(UV.x - x));
		vec3 scratch = mod(slot, 2.0) < 1.0 ? vec3(0.96, 0.9, 0.76) : vec3(0.12, 0.08, 0.05);
		sepia = mix(sepia, scratch, line * shows * 0.55);
	}
	vec2 middle = UV - 0.5;
	sepia *= 1.0 - dot(middle * vec2(1.0, 1.6), middle * vec2(1.0, 1.6)) * 0.8;
	sepia = min(sepia, vec3(peak));
	if (burn > 0.0) {
		vec2 aspect = vec2(picture_size.x / picture_size.y, 1.0);
		float r = length(middle * aspect) / length(vec2(0.5) * aspect);
		float edge = burn * 1.1;
		float rim = smoothstep(edge - 0.07, edge - 0.02, r) * (1.0 - smoothstep(edge, edge + 0.05, r));
		sepia = mix(sepia, vec3(1.0, 0.82, 0.45), rim);
		sepia = mix(sepia, vec3(0.03, 0.02, 0.02), step(r, edge - 0.07));
	}
	sepia = mix(sepia, vec3(0.0), darkness);
	sepia = mix(sepia, vec3(1.0, 0.98, 0.92), flash);
	COLOR = vec4(clamp(sepia, 0.0, 1.0), 1.0);
}

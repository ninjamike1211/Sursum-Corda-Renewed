#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex6;
uniform sampler2D colortex15;
uniform mat4 gbufferModelView;
uniform bool inEnd;
uniform bool inNether;

#include "/functions.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0,15 */
layout(location = 0) out vec4 albedo;
layout(location = 1) out vec4 historyOut;

void main() {
	albedo = texture2D(colortex0, texcoord);

	#ifdef TAA
		vec2 velocity = texture2D(colortex6, texcoord).xy;
		vec4 history = texture2D(colortex15, texcoord - velocity);

		vec2 pixel = 1.0 / vec2(viewWidth, viewHeight);
		vec3 nearColor0 = texture2D(colortex0, texcoord + vec2(pixel.x, 0.0)).rgb;
		vec3 nearColor1 = texture2D(colortex0, texcoord + vec2(0.0, pixel.y)).rgb;
		vec3 nearColor2 = texture2D(colortex0, texcoord - vec2(pixel.x, 0.0)).rgb;
		vec3 nearColor3 = texture2D(colortex0, texcoord - vec2(0.0, pixel.y)).rgb;

		vec3 boxMin = min(albedo.rgb, min(nearColor0, min(nearColor1, min(nearColor2, nearColor3))));
		vec3 boxMax = max(albedo.rgb, max(nearColor0, max(nearColor1, max(nearColor2, nearColor3))));

		history.rgb = clamp(history.rgb, boxMin.rgb, boxMax);

		if(clamp(texcoord - velocity, 0.0, 1.0) == texcoord - velocity) {
			// albedo.rgb = mix(albedo.rgb, history, 0.9);
			// albedo.rgb = mix(albedo.rgb, history, frameCount / (frameCount + 1));

			float currentFrame = (history.a == 0) ? 1.0 : (1.0 / (1.0/history.a - 1.0) + 1.0);
			float currentBlend = currentFrame / (currentFrame+1.0);

			albedo.rgb = mix(albedo.rgb, history.rgb, currentBlend);
			historyOut.a = currentBlend;

		}
		else {
			historyOut.a = 0.0;
		}
		if(clamp(history.rgb, boxMin.rgb, boxMax) != history.rgb) {
			historyOut.a = 0.0;
		}

		// albedo.rgb = vec3(frameCount != 0);

		// frameCountOut = frameCount + 1;
		historyOut.rgb = albedo.rgb;
	#endif
}
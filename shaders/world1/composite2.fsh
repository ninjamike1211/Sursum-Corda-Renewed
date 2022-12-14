#version 420 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex6;
uniform sampler2D colortex15;

#include "/lib/defines.glsl"

/*
    AABB Clipping from "Temporal Reprojection Anti-Aliasing in INSIDE"
    http://s3.amazonaws.com/arena-attachments/655504/c5c71c5507f0f8bf344252958254fb7d.pdf?1468341463
*/

vec3 YCoCg2RGB(vec3 YCoCg) {
	YCoCg.gb -= 0.5;
	return mat3(1.0, 1.0, -1.0, 1.0, 0.0, 1.0, 1.0, -1.0, -1.0) * YCoCg;
}

vec3 RGB2YCoCg(vec3 rgb) {
	return mat3(0.25, 0.5, 0.25, 0.5, 0.0, -0.5, -0.25, 0.5, -0.25) * rgb + vec3(0.0, 0.5, 0.5);
}

vec3 clipAABB(vec3 prevColor, vec3 minColor, vec3 maxColor) {
    vec3 pClip = 0.5 * (maxColor + minColor); // Center
    vec3 eClip = 0.5 * (maxColor - minColor); // Size

    vec3 vClip  = prevColor - pClip;
    vec3 aUnit  = abs(vClip / eClip);
    float denom = max(aUnit.x, max(aUnit.y, aUnit.z));

    return denom > 1.0 ? pClip + vClip / denom : prevColor;
}

vec3 neighbourhoodClipping(sampler2D currTex, vec3 prevColor) {
    vec3 minColor = vec3(1e5), maxColor = vec3(-1e5);

    for(int x = -TAA_NEIGHBORHOOD_SIZE; x <= TAA_NEIGHBORHOOD_SIZE; x++) {
        for(int y = -TAA_NEIGHBORHOOD_SIZE; y <= TAA_NEIGHBORHOOD_SIZE; y++) {
            vec3 color = texelFetch(currTex, ivec2(gl_FragCoord.xy) + ivec2(x, y), 0).rgb;
            minColor = min(minColor, color); maxColor = max(maxColor, color); 
        }
    }
    return clipAABB(prevColor, minColor, maxColor);
}

in vec2 texcoord;

/* RENDERTARGETS: 0,15 */
layout(location = 0) out vec4 albedo;
layout(location = 1) out vec4 historyOut;

void main() {
	albedo = texture2D(colortex0, texcoord);

	#ifdef TAA
		vec2 velocity = texture2D(colortex6, texcoord).xy;
		vec4 history = texture2D(colortex15, texcoord - velocity);

		// vec2 pixel = 1.0 / vec2(viewWidth, viewHeight);
		// vec3 nearColor0 = texture2D(colortex0, texcoord + vec2(pixel.x, 0.0)).rgb;
		// vec3 nearColor1 = texture2D(colortex0, texcoord + vec2(0.0, pixel.y)).rgb;
		// vec3 nearColor2 = texture2D(colortex0, texcoord - vec2(pixel.x, 0.0)).rgb;
		// vec3 nearColor3 = texture2D(colortex0, texcoord - vec2(0.0, pixel.y)).rgb;

		// vec3 boxMin = min(albedo.rgb, min(nearColor0, min(nearColor1, min(nearColor2, nearColor3))));
		// vec3 boxMax = max(albedo.rgb, max(nearColor0, max(nearColor1, max(nearColor2, nearColor3))));

		// history.rgb = clamp(history.rgb, boxMin.rgb, boxMax);

		history.rgb = neighbourhoodClipping(colortex0, history.rgb);

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
		// if(clamp(history.rgb, boxMin.rgb, boxMax) != history.rgb) {
		// 	historyOut.a = 0.0;
		// }


		// albedo.rgb = neighbourhoodClipping(colortex0, history);

		// albedo.rgb = vec3(frameCount != 0);

		// frameCountOut = frameCount + 1;
		historyOut.rgb = albedo.rgb;
	#endif
}
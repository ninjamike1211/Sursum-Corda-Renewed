#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/sky.glsl"

in vec2 texcoord;

#include "/lib/sample.glsl"
#include "/lib/DOF.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex12;
uniform sampler2D colortex13;
uniform float aspectRatio;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 sceneColor;

void main() {
	sceneColor = texture(colortex0, texcoord);
	float coc = texture(colortex12, texcoord).r * DOF_MaxRadius;

	if(abs(coc) >= DOF_MinRadius) {
		int samples = 128;
		int samplesUsed = 1;
		for(int i = 1; i < samples; i++) {
			vec2 sampleOffset = (abs(coc) - DOF_MinRadius) * GetVogelDiskSample(i, samples, 0.0) * vec2(1.0, aspectRatio);
			float sampleCoc = texture(colortex12, texcoord + sampleOffset).x * DOF_MaxRadius;

			if(sign(sampleCoc) == sign(coc)) {
				sceneColor.rgb += texture(colortex0, texcoord + sampleOffset).rgb;
				samplesUsed++;
			}

			// if(abs(sampleCoc) >= length(sampleOffset) && sampleCoc <= coc) {
				// colorVal += texture(colortex0, texcoord + sampleOffset).rgb;
				// samplesUsed++;
			// }
		}

		sceneColor.rgb /= samplesUsed;
	}
}
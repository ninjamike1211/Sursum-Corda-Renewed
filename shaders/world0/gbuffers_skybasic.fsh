#version 120

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/sky.glsl"

uniform float viewHeight;
uniform float viewWidth;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 sunPosition;
uniform float sunAngle;
uniform float eyeAltitude;

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

float fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos) {
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(skyColor, fogColor, fogify(max(upDot, 0.0), 0.25));
}

void main() {
	vec3 color = vec3(0.0);
	if (starData.a > 0.5) {
		color = starData.rgb;
	}
	// else {
	// 	vec4 pos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
	// 	pos = gbufferProjectionInverse * pos;
	// 	color = calcSkyColor(normalize(pos.xyz));
	// }

	color.rgb = sRGBToLinear3(color.rgb);

	vec3 ndcPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0);
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
	vec3 scenePos = mat3(gbufferModelViewInverse) * viewPos;

	// color.rgb += getSkyColor(normalize(scenePos), sunPosition, sunAngle, gbufferModelViewInverse);

	vec3 sunDir = mat3(gbufferModelViewInverse) * normalize(sunPosition);
	// color.rgb += getSkyColor(eyeAltitude, normalize(scenePos), sunDir);

/* DRAWBUFFERS:2 */
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}
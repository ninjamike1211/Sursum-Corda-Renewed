#version 400 compatibility

#include "/lib/material.glsl"

in vec4 starData;

/* RENDERTARGETS: 1,2 */
layout(location = 0) out vec4  albedo;
layout(location = 1) out uvec3 specMapOut;

void main() {
    // if(starData.a > 0.5)
    //     discard;
    // color = vec4(0.0);

    // color = vec4(step(0.5, starData.a));
    // color = 0.5 * starData * starData.a;
    albedo = vec4(1.0, 0.0, 0.5, 1.0);

    specMapOut = uvec3(0, 0, SpecularEncode(vec4(0.0, 0.0, 0.0, 0.5)));
}

// #version 150
// #extension GL_ARB_explicit_attrib_location : enable

// //the vanilla sky uses a lot of fog effects to render.
// //these effects are messy to re-implement,
// //so the code provided here replaces all
// //of that messyness with a simple gradient.

// uniform float viewHeight;
// uniform float viewWidth;
// uniform mat4 gbufferModelView;
// uniform mat4 gbufferProjectionInverse;
// uniform vec3 fogColor;
// uniform vec3 skyColor;

// in vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

// float fogify(float x, float w) {
// 	return w / (x * x + w);
// }

// vec3 calcSkyColor(vec3 viewPosNorm) {
// 	float upDot = dot(viewPosNorm, gbufferModelView[1].xyz);
// 	return mix(skyColor, fogColor, fogify(max(upDot, 0.0), 0.25));
// }

// /* DRAWBUFFERS:2 */
// layout(location = 0) out vec4 colortex0Out;

// void main() {
// 	vec3 color;
// 	if (starData.a > 0.5) {
// 		color = starData.rgb;
// 	}
// 	else {
// 		vec4 clipPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
// 		vec4 tmp = gbufferProjectionInverse * clipPos;
// 		color = calcSkyColor(normalize(tmp.xyz));
// 	}

// 	colortex0Out = vec4(color, 1.0);
// }
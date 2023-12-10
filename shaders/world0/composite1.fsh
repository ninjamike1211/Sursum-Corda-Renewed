#version 430 compatibility

#include "/lib/defines.glsl"
#include "/lib/functions.glsl"
#include "/lib/material.glsl"
#include "/lib/spaceConvert.glsl"
#include "/lib/raytrace.glsl"
#include "/lib/sky.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex10;
uniform sampler2D depthtex0;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform vec3 sunPosition;
uniform float sunAngle;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform int frameCounter;

in vec2 texcoord;
in vec3 viewVector;

layout(std430, binding = 0) buffer Histogram {
    uint HistogramGlobal[256];
    float averageLum;
};


/* DRAWBUFFERS:09 */

void main() {

	float depth = texture(depthtex0, texcoord).r;
	vec3 linearColor = texture(colortex0, texcoord).rgb;

	if(depth < 1.0) {
		vec3 albedo = texture(colortex2, texcoord).rgb;
		vec4 rawNormal = texture(colortex3, texcoord);
		vec4 specular = texture(colortex4, texcoord);

		vec3 viewPos = calcViewPos(viewVector, depth, gbufferProjection);
		vec3 viewDir = normalize(viewPos);
		vec3 normal = mat3(gbufferModelView) * unpackNormalVec2(rawNormal.xy);

		vec3 fresnel = calcFresnel(max(dot(normal, normalize(-viewPos)), 0.0), specular, albedo);

		vec3 reflectDir = reflect(viewDir, normal);
		vec3 hitPos;
		bool hit = screenspaceRaymarch(vec3(texcoord, depth), viewPos, reflectDir, 32, 4, 1.0, hitPos, frameCounter, vec2(viewWidth, viewHeight), near, far, depthtex0, gbufferProjection);
		// bool hit = raytrace(viewPos, reflectDir, 64, 1.0, frameCounter, vec2(viewWidth, viewHeight), hitPos, depthtex0, gbufferProjection);
		vec3 reflectColor = vec3(0.0);

		if(hit) {
			reflectColor = /* fresnel * specular.r *  */texture(colortex0, hitPos.xy).rgb;
		}
		else {
			vec3 sceneReflectDir = mat3(gbufferModelViewInverse) * reflectDir;
			// reflectColor = /* fresnel * specular.r *  */getSkyColor(sceneReflectDir, sunPosition, sunAngle, gbufferModelViewInverse);
			vec2 skySamplePos = projectSphere(sceneReflectDir);
			reflectColor = texture(colortex10, skySamplePos).rgb;
		}

		linearColor.rgb += fresnel * specular.r * reflectColor;
		// linearColor.rgb += cookTorrancePBRReflection(albedo, -viewDir, normal, specular, reflectColor, reflectDir);
		// linearColor.rgb = cookTorrancePBRLighting(vec3(0.0), -viewDir, normal, specular, reflectColor, reflectDir);

		gl_FragData[1] = vec4(fresnel, 1.0);

		// gl_FragData[1] = vec4(reflectDir, 1.0);
	}

	linearColor /= 9.6 * averageLum;


	// linearColor = ACESFilm(linearColor);
	vec3 sRGB = ACESFitted(linearToSRGB3(linearColor) * 2.0);

	gl_FragData[0] = vec4(sRGB, 1.0); //gcolor
}
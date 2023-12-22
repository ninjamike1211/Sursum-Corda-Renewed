#include "/lib/defines.glsl"

const vec3 sunLightColor = 50.0 * vec3(1.0, 0.85, 0.8);
const vec3 moonLightColor = vec3(0.1, 0.2, 0.4) * 0.025;

layout(std430, binding = 1) buffer ssbo_sky {
    vec3 skyDirect;
    vec3 skyAmbient;
} skyLight;

/*
    Projection functions
    Thx Belmu/Kneemund
*/
vec2 projectSphere(in vec3 direction) {
    float longitude = atan(-direction.x, -direction.z);
    float latitude  = acos(direction.y);

    return vec2(longitude * (1.0 / TAU) + 0.5, latitude / PI);
}

vec3 unprojectSphere(in vec2 coord) {
    float longitude = coord.x * TAU;
    float latitude  = coord.y * PI;
    return vec3(vec2(sin(longitude), cos(longitude)) * sin(latitude), cos(latitude)).xzy;
}

const vec3 hemisphereDirs[16] = vec3[](
   vec3( 0     ,    1.0000,    0),
   vec3(-0.2606,    0.9355,    0.2387),
   vec3( 0.0430,    0.8710,   -0.4895),
   vec3( 0.3598,    0.8065,    0.4693),
   vec3(-0.6602,    0.7419,   -0.1168),
   vec3( 0.6207,    0.6774,   -0.3948),
   vec3(-0.2051,    0.6129,    0.7631),
   vec3(-0.3854,    0.5484,   -0.7421),
   vec3( 0.8220,    0.4839,    0.3002),
   vec3(-0.8391,    0.4194,    0.3464),
   vec3( 0.3963,    0.3548,   -0.8468),
   vec3( 0.2864,    0.2903,    0.9131),
   vec3(-0.8429,    0.2258,   -0.4885),
   vec3( 0.9639,    0.1613,   -0.2119),
   vec3(-0.5724,    0.0968,    0.8142),
   vec3(-0.1284,    0.0323,   -0.9912)
);

float moonPhaseMultiplier(int moonPhase) {
    // return cos(0.25 * PI * moonPhase) * 0.25 + 0.75;
    return smoothstep(0.0, 4.0, abs(moonPhase-4.0)) * 0.5 + 0.5;
    // return smootherstep(0.0, 4.0, abs(moonPhase-4.0)) * 0.5 + 0.5;
}

vec3 skyLightSample(sampler2D skySampler) {
    vec3 skyColor = vec3(0.0);

	for(int i = 0; i < 16; i++) {
        skyColor += texture(skySampler, projectSphere(hemisphereDirs[i])).rgb;
    }

    return skyColor / 16.0;
}

vec3 sunLightSample(float sunAngle, float rainStrength, int moonPhase) {

    vec3 color;
    float shadowHeight = abs(sin(TAU * sunAngle));

    if(sunAngle < 0.5) {
        color = mix(sunLightColor * vec3(1.0, 0.45, 0.2), sunLightColor, smoothstep(0.0, 0.4, shadowHeight)) * smoothstep(0.0, 0.1, shadowHeight);
        color *= mix(1.0, 0.1, rainStrength);
    }
    else {
        color = moonLightColor * moonPhaseMultiplier(moonPhase) * smoothstep(0.0, 0.1, shadowHeight);
        color *= mix(1.0, 0.3, rainStrength);
    }

    return color;
}

vec3 getSkyColor(vec3 sceneDir, vec3 sunPosition, float sunAngle, mat4 modelViewInverseMatrix) {

    vec3 sunDir = mat3(modelViewInverseMatrix) * normalize(sunPosition);
    float sunDot = dot(sceneDir, sunDir);

    vec3 sunColor = vec3(0.13, 0.09, 0.00);
    vec3 moonColor = vec3(0.1);

    vec3 horizonColor = vec3(0.3, 0.45, 0.9) * max(sin(sunAngle * TAU), 0.0);
    vec3 skyTopColor  = vec3(0.2, 0.3, 0.75) * max(sunDir.y, 0.0);

    vec3 color = vec3(0.0);
    color += sunColor * smootherstep(0.5, 1.0, sunDot) * smootherstep(-0.3, 0.0, sceneDir.y);
    color += moonColor * smootherstep(0.5, 1.0, -sunDot) * smootherstep(-0.3, 0.0, sceneDir.y);
    color += horizonColor * smootherstep(0.7, 0.0, sceneDir.y) * (smootherstep(-0.3, 0.0, sceneDir.y) * 0.55 + 0.45);
    color += skyTopColor * smootherstep(0.0, 0.7, sceneDir.y);

    return color;
}

float horizonFadeFactor(vec3 sceneDir) {
    return smoothstep(-0.034, 0.05, sceneDir.y);
}

void applySunDisk(inout vec3 sceneColor, vec3 sceneDir, vec3 sunDir) {
    float mixFactor = smoothstep(0.9997, 0.9999, dot(sceneDir, sunDir)) * horizonFadeFactor(sceneDir);
    sceneColor *= mix(1.0, 100.0, mixFactor);
}

#define Atmospheric_Samples 16
#define Atmospheric_LightSamples 8

struct sky_data {
    float planetRadius;
    float atmosphereRadius;

    float gMie;
    float aMie;

    vec3 kRayleight;
    vec3 kMie;

    float scaleHeightR;
    float scaleHeightM;
};

/*
    Ray sphere intersection function
*/
vec2 ray_sphere_intersection(vec3 position, vec3 direction, float radius) {
	float b = dot(position, direction);
	float c = dot(position, position) - radius * radius;
	
	float d = b * b - c;
    
	if (d < 0.0)
		return vec2(-1.0);

	d = sqrt(d);
	
	return vec2(-b - d, -b + d);
}

float phaseRayleight(float angle) {
    return 3.0 * (1.0 + angle * angle) / (16.0 * PI);
}

/*
    Cornette-Shank Mie phase
    Thanks Jessie!
*/
float phaseMie(float angle, float g) {
    float g_sqr = g * g;
	float p1 = 3.0 * (1.0 - g_sqr) * (1.0 / (PI * (2.0 + g_sqr)));
	float p2 = (1.0 + (angle * angle)) * (1.0/pow((1.0 + g_sqr - 2.0 * g * angle), 1.5));
    
	float phase = (p1 * p2);
	phase *= 1.0 / (PI * 9.0);
    
	return max(phase, 0.0);
}

float getRayleightDensity(float height, sky_data skyData) {
    return exp(-height / skyData.scaleHeightR);
}

float getMieDensity(float height, sky_data skyData) {
    return exp(-height / skyData.scaleHeightM);
}

vec3 lightTransmittance(vec3 rayPos, vec3 lightDir, sky_data skyData) {
    float dist = ray_sphere_intersection(rayPos, lightDir, skyData.atmosphereRadius).y;
    float stepSize = dist / Atmospheric_LightSamples;
    vec3 rayIncrement = stepSize * lightDir;
    rayPos += 0.5 * rayIncrement;

    vec3 transmittance = vec3(1.0);

    for(int i = 0; i < Atmospheric_LightSamples; i++) {
        float height = length(rayPos) - skyData.planetRadius;

        float densityR = getRayleightDensity(height, skyData);
        float densityM = getMieDensity(height, skyData);

        float massR = densityR * stepSize;
        float massM = densityM * stepSize;

        vec3 opticalDepth = (skyData.kRayleight * massR) + (skyData.kMie / skyData.aMie * massM);
        vec3 stepTransmittance = exp(-opticalDepth);

        transmittance *= stepTransmittance;

        rayPos += rayIncrement;
    }
    
    return transmittance;
}

vec3 atmosphericScattering(vec3 origin, vec3 viewDir, vec3 lightDir, sky_data skyData) {

    float atmosphereDist = ray_sphere_intersection(origin, viewDir, skyData.atmosphereRadius).y;
    float planetDist = ray_sphere_intersection(origin, viewDir, skyData.planetRadius).x;
    float dist = (planetDist < 0.0) ? atmosphereDist : planetDist;

    float stepSize = dist / Atmospheric_Samples;
    vec3 rayIncrement = stepSize * viewDir;
    vec3 rayPos = origin + 0.5 * rayIncrement;

    float lightAngle = dot(viewDir, lightDir);
    float phaseR = phaseRayleight(lightAngle);
    float phaseM = phaseMie(lightAngle, skyData.gMie);

    vec3 inScattering = vec3(0.0);
    vec3 transmittance = vec3(1.0);

    for(int i = 0; i < Atmospheric_Samples; i++) {

        float height = length(rayPos) - skyData.planetRadius;

        float densityR = getRayleightDensity(height, skyData);
        float densityM = getMieDensity(height, skyData);

        float massR = densityR * stepSize;
        float massM = densityM * stepSize;

        vec3 opticalDepth = (skyData.kRayleight * massR) + (skyData.kMie / skyData.aMie * massM);
        vec3 stepTransmittance = exp(-opticalDepth);

        vec3 lightTransmittance = lightTransmittance(rayPos, lightDir, skyData);

        vec3 scatteringR = skyData.kRayleight * phaseR * massR * lightTransmittance;
        vec3 scatteringM = skyData.kMie       * phaseM * massM * lightTransmittance;

        vec3 scatteringIntegral = (scatteringR + scatteringM) * (1 - stepTransmittance) / max(vec3(1e-8), opticalDepth);
        inScattering += scatteringIntegral * transmittance;
        transmittance *= stepTransmittance;

        rayPos += rayIncrement;
    }

    return inScattering;
}

vec3 getSkyColor(float playerAltitude, vec3 sceneDir, vec3 sunDir, vec3 moonDir, int moonPhase) {
    sky_data skyData;

    skyData.planetRadius = 6370e3;
    skyData.atmosphereRadius = 6471e3;
    
    skyData.gMie = 0.8;
    skyData.aMie = 0.9;

    skyData.kRayleight = vec3(5.8e-6, 13.3e-6, 33.31e-6);;
    skyData.kMie = vec3(21e-6);

    skyData.scaleHeightR = 8e3;
    skyData.scaleHeightM = 1.9e3;

    vec3 sunScattering = 10.0 * sunLightColor * atmosphericScattering(vec3(0.0, skyData.planetRadius + playerAltitude + 4000, 0.0), sceneDir, sunDir, skyData);
    vec3 moonScattering = 2.0 * moonLightColor * moonPhaseMultiplier(moonPhase) * atmosphericScattering(vec3(0.0, skyData.planetRadius + playerAltitude + 4000, 0.0), sceneDir, moonDir, skyData);

    return sunScattering + moonScattering;
}
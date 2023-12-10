#include "/lib/defines.glsl"

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
    float mixFactor = smoothstep(0.9997, 0.9998, dot(sceneDir, sunDir)) * horizonFadeFactor(sceneDir);
    sceneColor *= mix(1.0, 100.0, mixFactor);
}

#define Atmospheric_Samples 16
#define Atmospheric_LightSamples 8

struct sky_data {
    float planetRadius;
    float atmosphereRadius;

    float sunStrength;

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

vec3 lightTransmittance(vec3 rayPos, vec3 sunDir, sky_data skyData) {
    float dist = ray_sphere_intersection(rayPos, sunDir, skyData.atmosphereRadius).y;
    float stepSize = dist / Atmospheric_LightSamples;
    vec3 rayIncrement = stepSize * sunDir;
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

vec3 atmosphericScattering(vec3 origin, vec3 viewDir, vec3 sunDir, sky_data skyData) {

    // float dist = skyData.atmosphereRadius - skyData.planetRadius;
    float atmosphereDist = ray_sphere_intersection(origin, viewDir, skyData.atmosphereRadius).y;
    float planetDist = ray_sphere_intersection(origin, viewDir, skyData.planetRadius).x;
    float dist = (planetDist < 0.0) ? atmosphereDist : planetDist;

    float stepSize = dist / Atmospheric_Samples;
    vec3 rayIncrement = stepSize * viewDir;
    vec3 rayPos = origin + 0.5 * rayIncrement;

    float lightAngle = dot(viewDir, sunDir);
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

        vec3 lightTransmittance = lightTransmittance(rayPos, sunDir, skyData);

        vec3 scatteringR = skyData.kRayleight * phaseR * massR * lightTransmittance;
        vec3 scatteringM = skyData.kMie       * phaseM * massM * lightTransmittance;

        vec3 scatteringIntegral = (scatteringR + scatteringM) * (1 - stepTransmittance) / max(vec3(1e-8), opticalDepth);
        inScattering += scatteringIntegral * transmittance;
        transmittance *= stepTransmittance;

        rayPos += rayIncrement;
    }

    return vec3(skyData.sunStrength * inScattering);
}

vec3 getSkyColor(float playerAltitude, vec3 sceneDir, vec3 sunDir) {
    sky_data skyData;

    skyData.planetRadius = 6370e3;
    skyData.atmosphereRadius = 6471e3;
    skyData.sunStrength = 10.5;
    
    skyData.gMie = 0.8;
    skyData.aMie = 0.9;

    skyData.kRayleight = vec3(5.8e-6, 13.3e-6, 33.31e-6);;
    skyData.kMie = vec3(21e-6);

    skyData.scaleHeightR = 8e3;
    skyData.scaleHeightM = 1.9e3;

    return atmosphericScattering(vec3(0.0, skyData.planetRadius + playerAltitude + 4000, 0.0), sceneDir, sunDir, skyData);
}
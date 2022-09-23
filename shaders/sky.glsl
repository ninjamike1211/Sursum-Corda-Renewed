// https://gist.github.com/wwwtyro/beecc31d65d1004f5a9d
float intersectFromInside(vec3 r0, vec3 rd, vec3 s0, float sr) {
    // - r0: ray origin
    // - rd: normalized ray direction
    // - s0: sphere center
    // - sr: sphere radius
    // - Returns distance from r0 to first intersecion with sphere,
    //   or -1.0 if no intersection.
    float a = dot(rd, rd);
    vec3 s0_r0 = r0 - s0;
    float b = 2.0 * dot(rd, s0_r0);
    float c = dot(s0_r0, s0_r0) - (sr * sr);
    if (b*b - 4.0*a*c < 0.0) {
        return -1.0;
    }
    return (-b + sqrt((b*b) - 4.0*a*c))/(2.0*a);
}

float intersectFromOutside(vec3 r0, vec3 rd, vec3 s0, float sr) {
    // - r0: ray origin
    // - rd: normalized ray direction
    // - s0: sphere center
    // - sr: sphere radius
    // - Returns distance from r0 to first intersecion with sphere,
    //   or -1.0 if no intersection.
    float a = dot(rd, rd);
    vec3 s0_r0 = r0 - s0;
    float b = 2.0 * dot(rd, s0_r0);
    float c = dot(s0_r0, s0_r0) - (sr * sr);
    if (b*b - 4.0*a*c < 0.0) {
        return -1.0;
    }
    return (-b - sqrt((b*b) - 4.0*a*c))/(2.0*a);
}

vec3 skyColor(vec3 viewDir, vec3 sunDir, float altitude, mat3 modelViewInverse) {

    vec3 eyeDir = modelViewInverse * viewDir;
    vec3 eyeOrigin = vec3(0.0, earthRadius + 20 * (altitude-seaLevel), 0.0);
    vec3 eyeSunDir = modelViewInverse * sunDir;

    float tmin = 0.0;
    float tmax = intersectFromInside(eyeOrigin, eyeDir, vec3(0.0), atmosphereRadius);
    float tmaxPlanet = intersectFromOutside(eyeOrigin, eyeDir, vec3(0.0), earthRadius);
    if(tmaxPlanet > -0.5)
        tmax = min(tmax, tmaxPlanet);

    float tCurrent = tmin;
    float segmentLength = (tmax - tmin) / skySamples; 

    vec3 sumR = vec3(0.0);
    vec3 sumM = vec3(0.0);
    float opticalDepthR = 0;
    float opticalDepthM = 0; 

    float mu = dot(eyeDir, eyeSunDir);
    float phaseR = 3.0 / (16.0 * PI) * (1 + mu * mu);
    float phaseM = 3.0 / (8.0 * PI) * ((1.0 - meanCosine * meanCosine) * (1.0 + mu * mu)) / ((2.0 + meanCosine * meanCosine) * pow(1.0 + meanCosine * meanCosine - 2.0 * meanCosine * mu, 1.5));

    for(int i = 0; i < skySamples; ++i) {
        vec3 samplePosition = eyeOrigin + (tCurrent + segmentLength*0.5) * eyeDir;
        float height = length(samplePosition) - earthRadius;

        float hr = exp(-height / rayleighScaleHeight) * segmentLength;
        float hm = exp(-height / mieScaleHeight) * segmentLength;
        opticalDepthR += hr;
        opticalDepthM += hm;

        float t1Light = intersectFromInside(samplePosition, eyeSunDir, vec3(0.0), atmosphereRadius);

        float segmentLengthLight = t1Light / lightSamples;
        float tCurrentLight = 0;
        float opticalDepthLightR = 0;
        float opticalDepthLightM = 0; 

        int j = 0;
        for (j = 0; j < lightSamples; ++j) { 
            vec3 samplePositionLight = samplePosition + (tCurrentLight + segmentLengthLight * 0.5f) * eyeSunDir; 
            float heightLight = length(samplePositionLight) - earthRadius;

            if (heightLight < 0) break;

            opticalDepthLightR += exp(-heightLight / rayleighScaleHeight) * segmentLengthLight; 
            opticalDepthLightM += exp(-heightLight / mieScaleHeight) * segmentLengthLight; 
            tCurrentLight += segmentLengthLight; 
        }

        if (j == lightSamples) { 
            vec3 tau = rayleighScatter * (opticalDepthR + opticalDepthLightR) + mieScatter * 1.1 * (opticalDepthM + opticalDepthLightM); 
            vec3 attenuation = exp(-tau);
            sumR += attenuation * hr; 
            sumM += attenuation * hm; 
        } 
        tCurrent += segmentLength; 
    }
 

    float sunDisk = smoothstep(0.9975, 0.9985, dot(viewDir, sunDir)) * float(tmax != tmaxPlanet);

    // We use a magic number here for the intensity of the sun (20). We will make it more
    // scientific in a future revision of this lesson/code
    vec3 result = 0.3 * (sumR * rayleighScatter * phaseR + sumM * mieScatter * phaseM) * mix(35, 500, sunDisk);

    // const float gamma = 2.2;
    // result = pow(result, vec3(gamma));
    // result = sRGBToLinear(vec4(result, 1.0)).rgb;

    // // reinhard tone mapping
    // result = vec3(1.0) - exp(-result * 0.4);
    // // gamma correction 
    // // result = pow(result, vec3(1.0 / gamma));
    // result = linearToSRGB(vec4(result, 1.0)).rgb;

    // result.r = result.r < 1.413 ? pow(result.r * 0.38317, 1.0 / gamma) : 1.0 - exp(-result.r); 
    // result.g = result.g < 1.413 ? pow(result.g * 0.38317, 1.0 / gamma) : 1.0 - exp(-result.g); 
    // result.b = result.b < 1.413 ? pow(result.b * 0.38317, 1.0 / gamma) : 1.0 - exp(-result.b); 

    return result;
}

vec3 skyMoonColor(vec3 viewDir, vec3 sunDir, float altitude, mat3 modelViewInverse) {

    vec3 eyeDir = modelViewInverse * viewDir;
    vec3 eyeOrigin = vec3(0.0, earthRadius + 20 * (altitude-seaLevel), 0.0);
    vec3 eyeSunDir = modelViewInverse * sunDir;

    float tmin = 0.0;
    float tmax = intersectFromInside(eyeOrigin, eyeDir, vec3(0.0), atmosphereRadiusMoon);
    float tmaxPlanet = intersectFromOutside(eyeOrigin, eyeDir, vec3(0.0), earthRadius);
    if(tmaxPlanet > -0.5)
        tmax = min(tmax, tmaxPlanet);

    float tCurrent = tmin;
    float segmentLength = (tmax - tmin) / skySamples; 

    vec3 sumR = vec3(0.0);
    vec3 sumM = vec3(0.0);
    float opticalDepthR = 0;
    float opticalDepthM = 0; 

    float mu = dot(eyeDir, eyeSunDir);
    float phaseR = 3.0 / (16.0 * PI) * (1 + mu * mu);
    float phaseM = 3.0 / (8.0 * PI) * ((1.0 - meanCosine * meanCosine) * (1.0 + mu * mu)) / ((2.0 + meanCosine * meanCosine) * pow(1.0 + meanCosine * meanCosine - 2.0 * meanCosine * mu, 1.5));

    for(int i = 0; i < skySamples; ++i) {
        vec3 samplePosition = eyeOrigin + (tCurrent + segmentLength*0.5) * eyeDir;
        float height = length(samplePosition) - earthRadius;

        float hr = exp(-height / rayleighScaleHeight) * segmentLength;
        float hm = exp(-height / mieScaleHeight) * segmentLength;
        opticalDepthR += hr;
        opticalDepthM += hm;

        float t1Light = intersectFromInside(samplePosition, eyeSunDir, vec3(0.0), atmosphereRadiusMoon);

        float segmentLengthLight = t1Light / lightSamples;
        float tCurrentLight = 0;
        float opticalDepthLightR = 0;
        float opticalDepthLightM = 0; 

        int j = 0;
        for (j = 0; j < lightSamples; ++j) { 
            vec3 samplePositionLight = samplePosition + (tCurrentLight + segmentLengthLight * 0.5f) * eyeSunDir; 
            float heightLight = length(samplePositionLight) - earthRadius;

            if (heightLight < 0) break;

            opticalDepthLightR += exp(-heightLight / rayleighScaleHeight) * segmentLengthLight; 
            opticalDepthLightM += exp(-heightLight / mieScaleHeight) * segmentLengthLight; 
            tCurrentLight += segmentLengthLight; 
        }

        if (j == lightSamples) { 
            vec3 tau = rayleighScatter * (opticalDepthR + opticalDepthLightR) + mieScatter * 1.1 * (opticalDepthM + opticalDepthLightM); 
            vec3 attenuation = exp(-tau);
            sumR += attenuation * hr; 
            sumM += attenuation * hm; 
        } 
        tCurrent += segmentLength; 
    }
 

    // float sunDisk = smoothstep(0.9985, 0.999, dot(viewDir, sunDir)) * float(tmax != tmaxPlanet);

    // We use a magic number here for the intensity of the sun (20). We will make it more
    // scientific in a future revision of this lesson/code
    vec3 result = (sumR * rayleighScatter * phaseR + sumM * mieScatter * phaseM) * 0.01 /* * vec3(0.2, 0.5, 1.0) */;
    result = pow(result, vec3(0.6));

    // const float gamma = 2.2;
    // result = pow(result, vec3(gamma));
    // result = sRGBToLinear(vec4(result, 1.0)).rgb;

    // // reinhard tone mapping
    // result = vec3(1.0) - exp(-result * 0.4);
    // // gamma correction 
    // // result = pow(result, vec3(1.0 / gamma));
    // result = linearToSRGB(vec4(result, 1.0)).rgb;

    // result.r = result.r < 1.413 ? pow(result.r * 0.38317, 1.0 / gamma) : 1.0 - exp(-result.r); 
    // result.g = result.g < 1.413 ? pow(result.g * 0.38317, 1.0 / gamma) : 1.0 - exp(-result.g); 
    // result.b = result.b < 1.413 ? pow(result.b * 0.38317, 1.0 / gamma) : 1.0 - exp(-result.b); 

    return result;
}

vec3 lightColor(vec3 sunDir, vec3 moonDir, float altitude, mat3 modelViewInverse) {
    vec3 eyeOrigin = vec3(0.0, earthRadius + 20 * (altitude-seaLevel), 0.0);
    vec3 eyeSunDir = modelViewInverse * sunDir;
    vec3 eyeMoonDir = modelViewInverse * moonDir;

    float tmin = 0.0;
    float tmaxSun = intersectFromInside(eyeOrigin, eyeSunDir, vec3(0.0), atmosphereRadius);
    float tmaxMoon = intersectFromInside(eyeOrigin, eyeMoonDir, vec3(0.0), atmosphereRadius);

    float tCurrentSun = tmin;
    float tCurrentMoon = tmin;
    float segmentLengthSun = (tmaxSun - tmin) / skySamples; 
    float segmentLengthMoon = (tmaxMoon - tmin) / skySamples; 

    vec3 sumR = vec3(0.0);
    vec3 sumM = vec3(0.0);
    float opticalDepthRSun = 0;
    float opticalDepthMSun = 0;
    float opticalDepthRMoon = 0;
    float opticalDepthMMoon = 0;  

    float phaseR = 6.0 / (16.0 * PI);
    float phaseM = 6.0 / (8.0 * PI) * (1.0 - meanCosine * meanCosine) / ((2.0 + meanCosine * meanCosine) * pow(1.0 + meanCosine * meanCosine - 2.0 * meanCosine, 1.5));

    for(int i = 0; i < skySamples; ++i) {
        vec3 samplePositionSun = eyeOrigin + (tCurrentSun + segmentLengthSun*0.5) * eyeSunDir;
        vec3 samplePositionMoon = eyeOrigin + (tCurrentMoon + segmentLengthMoon*0.5) * eyeMoonDir;
        float heightSun = length(samplePositionSun) - earthRadius;
        float heightMoon = length(samplePositionMoon) - earthRadius;

        float hrSun = exp(-heightSun / rayleighScaleHeight) * segmentLengthSun;
        float hmSun = exp(-heightSun / mieScaleHeight) * segmentLengthSun;
        opticalDepthRSun += hrSun;
        opticalDepthMSun += hmSun;

        float hrMoon = exp(-heightMoon / rayleighScaleHeight) * segmentLengthMoon;
        float hmMoon = exp(-heightMoon / mieScaleHeight) * segmentLengthMoon;
        opticalDepthRMoon += hrMoon;
        opticalDepthMMoon += hmMoon;

        float segmentLengthLightSun = tmaxSun / lightSamples;
        float tCurrentLightSun = 0;
        float opticalDepthLightRSun = 0;
        float opticalDepthLightMSun = 0;

        float segmentLengthLightMoon = tmaxMoon / lightSamples;
        float tCurrentLightMoon = 0;
        float opticalDepthLightRMoon = 0;
        float opticalDepthLightMMoon = 0; 

        int j = 0;
        for (j = 0; j < lightSamples; ++j) { 
            vec3 samplePositionLightSun = samplePositionSun + (tCurrentLightSun + segmentLengthLightSun * 0.5f) * eyeSunDir; 
            float heightLightSun = length(samplePositionLightSun) - earthRadius;

            vec3 samplePositionLightMoon = samplePositionMoon + (tCurrentLightMoon + segmentLengthLightMoon * 0.5f) * eyeMoonDir; 
            float heightLightMoon = length(samplePositionLightMoon) - earthRadius;

            if (heightLightSun < 0) break;

            opticalDepthLightRSun += exp(-heightLightSun / rayleighScaleHeight) * segmentLengthLightSun; 
            opticalDepthLightMSun += exp(-heightLightSun / mieScaleHeight) * segmentLengthLightSun; 
            tCurrentLightSun += segmentLengthLightSun; 
        }
        if (j == lightSamples) { 
            vec3 tau = rayleighScatter * (opticalDepthRSun + opticalDepthLightRSun) + mieScatter * 1.1 * (opticalDepthMSun + opticalDepthLightMSun); 
            vec3 attenuation = exp(-tau);
            sumR += attenuation * hrSun * 220; 
            sumM += attenuation * hmSun * 220; 
        } 

        for (j = 0; j < lightSamples; ++j) {

            vec3 samplePositionLightMoon = samplePositionMoon + (tCurrentLightMoon + segmentLengthLightMoon * 0.5f) * eyeMoonDir; 
            float heightLightMoon = length(samplePositionLightMoon) - earthRadius;

            if (heightLightMoon < 0) break;

            opticalDepthLightRMoon += exp(-heightLightMoon / rayleighScaleHeight) * segmentLengthLightMoon; 
            opticalDepthLightMMoon += exp(-heightLightMoon / mieScaleHeight) * segmentLengthLightMoon; 
            tCurrentLightMoon += segmentLengthLightMoon; 
        }
        if (j == lightSamples) { 
            vec3 tau = rayleighScatter * (opticalDepthRMoon + opticalDepthLightRMoon) + mieScatter * 1.1 * (opticalDepthMMoon + opticalDepthLightMMoon); 
            vec3 attenuation = exp(-tau);
            sumR += attenuation * hrMoon; 
            sumM += attenuation * hmMoon; 
        } 

        tCurrentSun += segmentLengthSun;
        tCurrentMoon += segmentLengthMoon; 
    }

    // We use a magic number here for the intensity of the sun (20). We will make it more
    // scientific in a future revision of this lesson/code
    vec3 result = (sumR * rayleighScatter * phaseR + sumM * mieScatter * phaseM);

    // const float gamma = 2.2;
    // result = pow(result, vec3(gamma));
    // result = sRGBToLinear(vec4(result, 1.0)).rgb;

    // reinhard tone mapping
    result = vec3(1.0) - exp(-result * 0.4);
    // gamma correction 
    // result = pow(result, vec3(1.0 / gamma));
    result = linearToSRGB(vec4(result, 1.0)).rgb;

    // result.r = result.r < 1.413 ? pow(result.r * 0.38317, 1.0 / gamma) : 1.0 - exp(-result.r); 
    // result.g = result.g < 1.413 ? pow(result.g * 0.38317, 1.0 / gamma) : 1.0 - exp(-result.g); 
    // result.b = result.b < 1.413 ? pow(result.b * 0.38317, 1.0 / gamma) : 1.0 - exp(-result.b); 

    return result;
}
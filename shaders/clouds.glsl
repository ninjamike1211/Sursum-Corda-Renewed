
// #include "/defines.glsl"
// #include "/noise.glsl"

// uniform float far;
// uniform vec3 lightDir;
// uniform vec3 sunDir

void getCloudCoords(vec3 eyeDir, vec3 eyeOrigin, float height, float radius, out vec2 cloudCoords, out float dist, out vec2 angles) {
	float sphereCenter = height - radius;
	dist = ray_sphere_intersection(eyeOrigin - vec3(0.0, sphereCenter, 0.0), eyeDir, radius).y;

	vec3 hitPos = eyeAltitude-sphereCenter + dist * eyeDir;
	vec3 rayDir = normalize(hitPos);

	angles = atan(hitPos.yy, hitPos.xz);
	cloudCoords = radius * sin(angles) - cameraPosition.xz;
}

void applyCloudColor(vec3 eyeDir, vec3 eyeOrigin, inout vec3 baseColor, vec3 lightColor) {

	vec2 cloudCoordsHigh, cloudAnglesHigh;
	float cloudDistHigh;
	getCloudCoords(eyeDir, eyeOrigin, highCloudHeight, highCloudRadius, cloudCoordsHigh, cloudDistHigh, cloudAnglesHigh);

	vec3 noise  = 0.61 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.00045 + 0.03 * frameTimeCounter);
		 noise += 0.32 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.0015  + 0.07 * vec2(1.0, -1.0) * frameTimeCounter);
		 noise += 0.06 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.005   - 0.1  * frameTimeCounter);
		 noise += 0.01 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.015   + 0.1  * vec2(-1.0, 1.0) * frameTimeCounter);

	float density = noise.x * 0.33 + 0.63;

	mat3 rotMatrx = mat3(cos(cloudAnglesHigh.y), -sin(cloudAnglesHigh.y)*cos(cloudAnglesHigh.x),  sin(cloudAnglesHigh.y)*sin(cloudAnglesHigh.x),
						 sin(cloudAnglesHigh.y),  cos(cloudAnglesHigh.y)*cos(cloudAnglesHigh.x), -cos(cloudAnglesHigh.y)*sin(cloudAnglesHigh.x),
						 0,                       sin(cloudAnglesHigh.x),                         cos(cloudAnglesHigh.x));
	
	vec3 normal = vec3(-noise.z, 5.0, -noise.y);
	normal = normalize(normal);
	normal = rotMatrx * normal;
	float cloudDotL = dot(normal, lightDir);

	float sunDot = smoothstep(0.965, 0.9999999999, dot(eyeDir, sunDir));

	vec3 cloudColorHigh = lightColor * mix(0.3, 0.35, rainStrength) * (abs(cloudDotL) * 0.5 + 0.5);
	float cloudAlphaHigh = smoothstep(1.5 - 1.5*rainStrength, 6.0 - 5.0*rainStrength, exp(density)) * smoothstep(far*190, far*(1+50*rainStrength), cloudDistHigh);

	baseColor = mix(baseColor, cloudColorHigh, cloudAlphaHigh);


	#ifdef cloudDualLayer
		vec2 cloudCoords2Low;
		float cloudDist2Low;
		vec2 cloudAngles2Low;
		getCloudCoords(eyeDir, eyeOrigin, lowCloud2Height, lowCloud2Radius, cloudCoords2Low, cloudDist2Low, cloudAngles2Low);

		noise = 0.52 * SimplexPerlin2D_Deriv(cloudCoords2Low.xy * 0.0004 + 0.02 * frameTimeCounter);
		noise += 0.36 * SimplexPerlin2D_Deriv(cloudCoords2Low.xy * 0.0009 + 0.03 * frameTimeCounter);
		noise += 0.12 * SimplexPerlin2D_Deriv(cloudCoords2Low.xy * 0.003 + 0.07 * vec2(1.0, -1.0) * frameTimeCounter + 0.06);
		noise += 0.02 * SimplexPerlin2D_Deriv(cloudCoords2Low.xy * 0.01 - 0.1 * frameTimeCounter);

		density = noise.x * .745 + .745;

		mat3 rotMatrx2 = mat3(cos(cloudAngles2Low.y), -sin(cloudAngles2Low.y)*cos(cloudAngles2Low.x),  sin(cloudAngles2Low.y)*sin(cloudAngles2Low.x),
		                      sin(cloudAngles2Low.y),  cos(cloudAngles2Low.y)*cos(cloudAngles2Low.x), -cos(cloudAngles2Low.y)*sin(cloudAngles2Low.x),
		                      0,                       sin(cloudAngles2Low.x),                         cos(cloudAngles2Low.x));
		
		vec3 normal2 = vec3(-noise.z, 5.0, -noise.y);
		normal2 = normalize(normal2);
		normal2 = rotMatrx2 * normal2;
		cloudDotL = dot(normal2, normalize(shadowLightPosition));

		
		float cloudAlpha2Low = smoothstep(2.1 - 2.1*wetness, 3.3 - 0.7*wetness, exp(density)) * smoothstep(far*40, far*5, cloudDist2Low);
		vec3 cloudColor2Low = lightColor * mix(0.3, 0.7, wetness) * (abs(cloudDotL) * 0.5 + 0.5);

		baseColor = mix(baseColor, cloudColor2Low, cloudAlpha2Low);
	#endif



	vec2 cloudCoordsLow;
	float cloudDistLow;
	vec2 cloudAnglesLow;
	getCloudCoords(eyeDir, eyeOrigin, lowCloudHeight, lowCloudRadius, cloudCoordsLow, cloudDistLow, cloudAnglesLow);

	noise  = 0.52 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.0004 + 0.02 * frameTimeCounter);
	noise += 0.36 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.0009 + 0.03 * frameTimeCounter);
	noise += 0.12 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.003  + 0.07 * vec2(1.0, -1.0) * frameTimeCounter + 0.06);
	noise += 0.02 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.01   - 0.1  * frameTimeCounter);

	density = noise.x * .745 + .745;

	rotMatrx = mat3(cos(cloudAnglesLow.y), -sin(cloudAnglesLow.y)*cos(cloudAnglesLow.x),  sin(cloudAnglesLow.y)*sin(cloudAnglesLow.x),
	                sin(cloudAnglesLow.y),  cos(cloudAnglesLow.y)*cos(cloudAnglesLow.x), -cos(cloudAnglesLow.y)*sin(cloudAnglesLow.x),
	                0,                      sin(cloudAnglesLow.x),                        cos(cloudAnglesLow.x));
	
	normal = vec3(-noise.y, 5.0, -noise.z);
	normal = normalize(normal);
	normal = rotMatrx * normal;
	cloudDotL = dot(normal, lightDir);

	
	float cloudAlphaLow = smoothstep(2.1 - 0.3*rainStrength, 3.3 - 0.7*rainStrength, exp(density)) * smoothstep(far*43, far*(8), cloudDistLow);
	vec3 cloudColorLow = lightColor * mix(0.3, 0.30, rainStrength) * (abs(cloudDotL) * 0.5 + 0.5);

	baseColor = mix(baseColor, cloudColorLow, cloudAlphaLow);
}

void applyNetherCloudColor(vec3 eyeDir, vec3 eyeOrigin, inout vec3 baseColor, vec3 fogColor) {

	vec2 cloudCoordsHigh;
	float cloudDistHigh;
	vec2 cloudAnglesHigh;
	getCloudCoords(eyeDir, eyeOrigin, highCloudHeight, highCloudRadius, cloudCoordsHigh, cloudDistHigh, cloudAnglesHigh);

	vec3 noise = 0.61 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.00045 + vec2(0.09, 0.09) * frameTimeCounter);
	noise += 0.32 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.0015 + vec2(0.21, -0.21) * frameTimeCounter);
	noise += 0.06 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.005 + vec2(-0.3, -0.3) * frameTimeCounter);
	noise += 0.01 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.015 + vec2(-0.3, 0.3) * frameTimeCounter);

	float density = noise.x * 0.2 + 1.5;
	float cloudDotL = 1.0;

	mat3 rotMatrx = mat3(   cos(cloudAnglesHigh.y),  -sin(cloudAnglesHigh.y)*cos(cloudAnglesHigh.x),   sin(cloudAnglesHigh.y)*sin(cloudAnglesHigh.x),
							sin(cloudAnglesHigh.y),  cos(cloudAnglesHigh.y)*cos(cloudAnglesHigh.x),    -cos(cloudAnglesHigh.y)*sin(cloudAnglesHigh.x),
							0,                      sin(cloudAnglesHigh.x),                          cos(cloudAnglesHigh.x));
	vec3 normal = vec3(-noise.z, 5.0, -noise.y);
	normal = normalize(normal);
	normal = rotMatrx * normal;
	cloudDotL = dot(normal, lightDir);

	float sunDot = smoothstep(0.965, 0.9999999999, dot(eyeDir, sunDir));

	vec3 cloudColorHigh = (0.5*vec3(0.4, 0.02, 0.01) + 0.5*fogColor) * (abs(cloudDotL) * 0.5 + 0.5);
	float cloudAlphaHigh = smoothstep(1.5, 6.0, exp(density)) * smoothstep(200000.0, 400.0, cloudDistHigh);

	baseColor = mix(baseColor, cloudColorHigh, cloudAlphaHigh);


	vec2 cloudCoordsLow;
	float cloudDistLow;
	vec2 cloudAnglesLow;
	getCloudCoords(eyeDir, eyeOrigin, lowCloudHeight, lowCloudRadius, cloudCoordsLow, cloudDistLow, cloudAnglesLow);

	noise = 0.52 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.0004 + vec2(-0.3, 0.1) * frameTimeCounter);
	noise += 0.36 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.0009 + vec2(-0.2, 0.21) * frameTimeCounter);
	noise += 0.12 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.003 + vec2(-0.4, -0.5) * frameTimeCounter + 0.06);
	noise += 0.02 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.01 + vec2(0.7, 0.6) * frameTimeCounter);

	density = noise.x * .745 + .745;

	rotMatrx = mat3(   cos(cloudAnglesLow.y),  -sin(cloudAnglesLow.y)*cos(cloudAnglesLow.x),   sin(cloudAnglesLow.y)*sin(cloudAnglesLow.x),
						sin(cloudAnglesLow.y),  cos(cloudAnglesLow.y)*cos(cloudAnglesLow.x),    -cos(cloudAnglesLow.y)*sin(cloudAnglesLow.x),
						0,                      sin(cloudAnglesLow.x),                          cos(cloudAnglesLow.x));
	normal = vec3(-noise.y, 5.0, -noise.z);
	normal = normalize(normal);
	normal = rotMatrx * normal;
	cloudDotL = dot(normal, lightDir);

	
	float cloudAlphaLow = smoothstep(2.1, 3.3, exp(density)) * smoothstep(40000, 0, cloudDistLow);
	vec3 cloudColorLow = (0.7*vec3(0.4, 0.02, 0.01) + 0.3*fogColor) * (abs(cloudDotL) * 0.5 + 0.5);

	baseColor = mix(baseColor, cloudColorLow, cloudAlphaLow);
}

void applyEndCloudColor(vec3 eyeDir, vec3 eyeOrigin, inout vec3 baseColor, vec3 lightColor) {

	vec2 cloudCoordsHigh;
	float cloudDistHigh;
	vec2 cloudAnglesHigh;
	getCloudCoords(eyeDir, eyeOrigin, highCloudHeight, 50000, cloudCoordsHigh, cloudDistHigh, cloudAnglesHigh);

	vec3 noise = 0.61 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.00045 + 0.15 * frameTimeCounter);
	noise += 0.32 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.0015 + 0.35 * vec2(1.0, -1.0) * frameTimeCounter);
	noise += 0.06 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.005 - 0.5 * frameTimeCounter);
	noise += 0.01 * SimplexPerlin2D_Deriv(cloudCoordsHigh.xy * 0.015 + 0.5 * vec2(-1.0, 1.0) * frameTimeCounter);

	float density = noise.x * 0.33 + 0.63;
	float cloudDotL = 1.0;

	mat3 rotMatrx = mat3(   cos(cloudAnglesHigh.y),  -sin(cloudAnglesHigh.y)*cos(cloudAnglesHigh.x),   sin(cloudAnglesHigh.y)*sin(cloudAnglesHigh.x),
							sin(cloudAnglesHigh.y),  cos(cloudAnglesHigh.y)*cos(cloudAnglesHigh.x),    -cos(cloudAnglesHigh.y)*sin(cloudAnglesHigh.x),
							0,                      sin(cloudAnglesHigh.x),                          cos(cloudAnglesHigh.x));
	
	vec3 normal = vec3(-noise.z, 5.0, -noise.y);
	normal = normalize(normal);
	normal = rotMatrx * normal;
	cloudDotL = dot(normal, lightDir);

	float sunDot = smoothstep(0.965, 0.9999999999, dot(eyeDir, sunDir));

	vec3 cloudColorHigh = lightColor * 0.3 * (abs(cloudDotL) * 0.5 + 0.5);
	float cloudAlphaHigh = smoothstep(1.5, 3.0, exp(density)) * smoothstep(far*190, far, cloudDistHigh);

	baseColor = mix(baseColor, cloudColorHigh, cloudAlphaHigh);



	vec2 cloudCoordsLow;
	float cloudDistLow;
	vec2 cloudAnglesLow;
	getCloudCoords(eyeDir, eyeOrigin, lowCloudHeight, 20000, cloudCoordsLow, cloudDistLow, cloudAnglesLow);

	noise = 0.52 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.0004 + 0.1 * frameTimeCounter);
	noise += 0.36 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.0009 + 0.15 * frameTimeCounter);
	noise += 0.12 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.003 + 0.35 * vec2(1.0, -1.0) * frameTimeCounter + 0.06);
	noise += 0.02 * SimplexPerlin2D_Deriv(cloudCoordsLow.xy * 0.01 - 0.5 * frameTimeCounter);

	density = noise.x * .745 + .745;

	rotMatrx = mat3(   cos(cloudAnglesLow.y),  -sin(cloudAnglesLow.y)*cos(cloudAnglesLow.x),   sin(cloudAnglesLow.y)*sin(cloudAnglesLow.x),
							sin(cloudAnglesLow.y),  cos(cloudAnglesLow.y)*cos(cloudAnglesLow.x),    -cos(cloudAnglesLow.y)*sin(cloudAnglesLow.x),
							0,                      sin(cloudAnglesLow.x),                          cos(cloudAnglesLow.x));
	
	normal = vec3(-noise.y, 5.0, -noise.z);
	normal = normalize(normal);
	normal = rotMatrx * normal;
	cloudDotL = dot(normal, lightDir);

	
	float cloudAlphaLow = smoothstep(1.5, 3.0, exp(density)) * smoothstep(far*53, far*(8), cloudDistLow);
	vec3 cloudColorLow = lightColor * 0.3 * (abs(cloudDotL) * 0.5 + 0.5);

	baseColor = mix(baseColor, cloudColorLow, cloudAlphaLow);
}
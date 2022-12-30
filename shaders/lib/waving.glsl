#ifndef WAVING
#define WAVING

// #include "/noise.glsl"
// #include "/functions.glsl"

// uniform float frameTime;
// uniform float frameTimeCounter;
// uniform float rainStrength;

vec3 wavingOffset(vec3 worldPos, int entity, vec3 midBlock, vec3 normal, sampler2D varSampler) {

	// float prevWindAmplitude = 0.1 * (snoise(vec2(0.05 * (frameTimeCounter - frameTime) + worldPos.x + worldPos.z)) * 0.5 + 0.5);

	// float windAngle     = snoise(vec2(0.03 * frameTimeCounter /* + worldPos.x + worldPos.z */, 0.0)) * PI + PI;
	// vec2  windDirection = vec2(cos(windAngle), sin(windAngle));
	// float windAmplitude = mix(0.1, 0.2, rainStrength) + mix(0.1, 0.0, rainStrength) * (snoise(vec2(0.03 * frameTimeCounter /* + worldPos.x + worldPos.z */)) * 0.5 + 0.5);
	
	vec4 windData = texelFetch(varSampler, ivec2(0,1), 0);

	float windAmplitude = windData.r;
	float windAngle     = windData.g * TAU;
	float windPhase     = (windData.b /* + windData.b / 255.0 */) * TAU;

	vec2  windDirection = vec2(cos(windAngle), sin(windAngle));

	switch(entity) {
		case 10001: { // Leaves

			float windWave   = sin(windPhase + Wind_Leaf_Wavelength * (worldPos.x + worldPos.z + Wind_Leaf_YFactor * worldPos.y));
			float windOffset = (windAmplitude * Wind_Leaf_Offset) + (windAmplitude * Wind_Leaf_WaveStrength) * windWave;

			return vec3(
				windDirection.x * windOffset,
				0.0,
				windDirection.y * windOffset
			);
		}
		case 10002: { // Single tall plants

			// float isTop = step(texcoord.y, textureBounds.y);
			float isTop = (0.5 - (midBlock.y / 64.0)) * step(midBlock.y, 32.0);

			float windWave   = sin(windPhase + Wind_Plant_Wavelength * (worldPos.x + worldPos.z));
			float windOffset = (windAmplitude * Wind_Plant_Offset) + (windAmplitude * Wind_Plant_Wavestrength) * windWave;

			return vec3(
				isTop * windDirection.x * windOffset,
				0.0,
				isTop * windDirection.y * windOffset
			);
		}
		case 10003: { // Double tall plants bottom

			// float isTop = step(texcoord.y, textureBounds.y);
			float isTop = 0.5 - (midBlock.y / 64.0);

			float windWave   = sin(windPhase + Wind_Plant_Wavelength * (worldPos.x + worldPos.z));
			float windOffset = (windAmplitude * Wind_Plant_Offset) + (windAmplitude * Wind_Plant_Wavestrength) * windWave;

			return 0.5 * isTop * vec3(
				windDirection.x * windOffset,
				0.0,
				windDirection.y * windOffset
			);
		}
		case 10004: { // Double tall plants top

			// float isTop = step(texcoord.y, textureBounds.y);
			float isTop = 0.5 - (midBlock.y / 64.0);

			float windWave   = sin(windPhase + Wind_Plant_Wavelength * (worldPos.x + worldPos.z));
			float windOffset = (windAmplitude * Wind_Plant_Offset) + (windAmplitude * Wind_Plant_Wavestrength) * windWave;

			return (isTop * 0.5 + 0.5) * vec3(
				windDirection.x * windOffset,
				0.0,
				windDirection.y * windOffset
			);
		}
		case 10006: { // Vines

			float facingX = step(0.1, abs(normal.x));

			float windWave   = sin(windPhase + Wind_Vine_YWavelength * worldPos.y + Wind_Vine_XZWavelength * (worldPos.x + worldPos.z));
			float windOffset = (windAmplitude * Wind_Vine_Offset) + ((windAmplitude * 0.1 + 0.3) * Wind_Vine_Wavestrength) * windWave;

			return vec3(
				(facingX * 0.5 + 0.5) * windDirection.x * windOffset,
				0.0,
				((1.0 - facingX) * 0.5 + 0.5) * windDirection.y * windOffset
			);
		}
	}

	return vec3(0.0);
}

vec3 wavingNormal(vec3 worldPos, int entity, vec2 texcoord, vec4 textureBounds, vec3 normal) {
	switch(entity) {
		case 10001: { // Leaves
			// return vec3(
			// 	mix(0.05, 0.08, rainStrength) * ((pow(sin((worldPos.x + frameTimeCounter) * PI * 0.25), 2.0) - 0.5) * mix(1.0, cos(worldPos.z + frameTimeCounter * PI * 2.0), rainStrength) - 0.0), 
			// 	mix(0.05, 0.08, rainStrength) * ((pow(cos((worldPos.y + frameTimeCounter) * PI * 0.125), 2.0) - 0.5) * mix(1.0, sin(worldPos.x + frameTimeCounter * PI * 2.0), rainStrength) - 0.0),
			// 	mix(0.05, 0.08, rainStrength) * ((pow(cos((worldPos.z + frameTimeCounter) * PI * 0.25), 2.0) - 0.5) * mix(1.0, sin(worldPos.y + frameTimeCounter * PI * 2.0), rainStrength) - 0.0)
			// );

			return normal;
		}
		case 10002: { // Single tall plants
			// float isTop = step(texcoord.y, textureBounds.y);

			// // vec2 subOffset = vec2(0.0);
			// vec2 subOffset = 0.005 * cossin(worldPos.xz * 10.0 + frameTimeCounter * vec2(9.2, 8.9));
			// subOffset +=     0.0   * cossin(worldPos.xz * 10.0 + frameTimeCounter * 9.2);
			// subOffset +=     0.1   * sincos(worldPos.xz * 10.0 + frameTimeCounter * vec2(1.4, 1.6));

			// subOffset *= isTop;
	
			// return vec3(
			// 	subOffset.x,
			// 	0.0, // (1.0 - fract(worldPos.y)) * (1.0 - isTop),
			// 	subOffset.y
			// );

			return normal;
		}
		case 10003: { // Double tall plants bottom
			// float isTop = step(texcoord.y, textureBounds.y);

			// return isTop * 0.05 * vec3(
			// 	SimplexPerlin2D(vec2(worldPos.x + 0.1 * frameTimeCounter, 0.0)) * sin(worldPos.x + 3.0 * frameTimeCounter),
			// 	0.0,
			// 	SimplexPerlin2D(vec2(worldPos.z + 0.1 * frameTimeCounter, 0.0)) * cos(worldPos.z + 3.0 * frameTimeCounter)
			// );

			return normal;
		}
		case 10004: { // Double tall plants top
			// float isTop = step(texcoord.y, textureBounds.y);

			// return (isTop * 0.05 + 0.05) * vec3(
			// 	SimplexPerlin2D(vec2(worldPos.x + 0.1 * frameTimeCounter, 0.0)) * sin(worldPos.x + 3.0 * frameTimeCounter),
			// 	0.0,
			// 	SimplexPerlin2D(vec2(worldPos.z + 0.1 * frameTimeCounter, 0.0)) * cos(worldPos.z + 3.0 * frameTimeCounter)
			// );

			return normal;
		}
		case 10006: { // Vines
			float facingX = step(0.1, abs(normal.x));

			// return vec3(
			// 	0.1 * sin(worldPos.y + frameTimeCounter) * facingX,
			// 	0.0,
			// 	0.1 * sin(worldPos.y + frameTimeCounter) * (1.0 - facingX)
			// );

			return normalize(vec3(
				facingX,
				0.1 * cos(worldPos.y + frameTimeCounter) * facingX,
				1.0 - facingX
			));
		}
	}

	return normal;
}

#endif
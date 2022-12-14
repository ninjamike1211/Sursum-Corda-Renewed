// #include "/noise.glsl"
// #include "/functions.glsl"

// uniform float frameTimeCounter;
// uniform float rainStrength;

vec3 wavingOffset(vec3 worldPos, int entity, vec2 texcoord, vec4 textureBounds) {

	switch(entity) {
		case 10001: { // Leaves
			return vec3(
				mix(0.05, 0.08, rainStrength) * ((pow(sin((worldPos.x + frameTimeCounter) * PI * 0.25), 2.0) - 0.5) * mix(1.0, cos(worldPos.z + frameTimeCounter * PI * 2.0), rainStrength) - 0.0), 
				mix(0.05, 0.08, rainStrength) * ((pow(cos((worldPos.y + frameTimeCounter) * PI * 0.125), 2.0) - 0.5) * mix(1.0, sin(worldPos.x + frameTimeCounter * PI * 2.0), rainStrength) - 0.0),
				mix(0.05, 0.08, rainStrength) * ((pow(cos((worldPos.z + frameTimeCounter) * PI * 0.25), 2.0) - 0.5) * mix(1.0, sin(worldPos.y + frameTimeCounter * PI * 2.0), rainStrength) - 0.0)
			);
		}
		case 10002: { // Single tall plants
			float isTop = step(texcoord.y, textureBounds.y);

			// vec2 subOffset = vec2(0.0);
			vec2 subOffset = 0.005 * cossin(worldPos.xz * 10.0 + frameTimeCounter * vec2(9.2, 8.9));
			subOffset +=     0.0   * cossin(worldPos.xz * 10.0 + frameTimeCounter * 9.2);
			subOffset +=     0.1   * sincos(worldPos.xz * 10.0 + frameTimeCounter * vec2(1.4, 1.6));

			subOffset *= isTop;
	
			return vec3(
				subOffset.x,
				0.0, // (1.0 - fract(worldPos.y)) * (1.0 - isTop),
				subOffset.y
			);
		}
		case 10003: { // Double tall plants bottom
			float isTop = step(texcoord.y, textureBounds.y);

			return isTop * 0.05 * vec3(
				SimplexPerlin2D(vec2(worldPos.x + 0.1 * frameTimeCounter, 0.0)) * sin(worldPos.x + 3.0 * frameTimeCounter),
				0.0,
				SimplexPerlin2D(vec2(worldPos.z + 0.1 * frameTimeCounter, 0.0)) * cos(worldPos.z + 3.0 * frameTimeCounter)
			);
		}
		case 10004: { // Double tall plants top
			float isTop = step(texcoord.y, textureBounds.y);

			return (isTop * 0.05 + 0.05) * vec3(
				SimplexPerlin2D(vec2(worldPos.x + 0.1 * frameTimeCounter, 0.0)) * sin(worldPos.x + 3.0 * frameTimeCounter),
				0.0,
				SimplexPerlin2D(vec2(worldPos.z + 0.1 * frameTimeCounter, 0.0)) * cos(worldPos.z + 3.0 * frameTimeCounter)
			);
		}
		case 10006: { // Vines
			float facingX = step(0.1, abs(glNormal.x));

			return vec3(
				0.1 * sin(worldPos.y + frameTimeCounter) * facingX,
				0.0,
				0.1 * sin(worldPos.y + frameTimeCounter) * (1.0 - facingX)
			);
		}
	}

	return vec3(0.0);
}

vec3 wavingNormal(vec3 worldPos, int entity, vec2 texcoord, vec4 textureBounds) {
	switch(entity) {
		case 10001: { // Leaves
			// return vec3(
			// 	mix(0.05, 0.08, rainStrength) * ((pow(sin((worldPos.x + frameTimeCounter) * PI * 0.25), 2.0) - 0.5) * mix(1.0, cos(worldPos.z + frameTimeCounter * PI * 2.0), rainStrength) - 0.0), 
			// 	mix(0.05, 0.08, rainStrength) * ((pow(cos((worldPos.y + frameTimeCounter) * PI * 0.125), 2.0) - 0.5) * mix(1.0, sin(worldPos.x + frameTimeCounter * PI * 2.0), rainStrength) - 0.0),
			// 	mix(0.05, 0.08, rainStrength) * ((pow(cos((worldPos.z + frameTimeCounter) * PI * 0.25), 2.0) - 0.5) * mix(1.0, sin(worldPos.y + frameTimeCounter * PI * 2.0), rainStrength) - 0.0)
			// );

			return glNormal;
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

			return glNormal;
		}
		case 10003: { // Double tall plants bottom
			// float isTop = step(texcoord.y, textureBounds.y);

			// return isTop * 0.05 * vec3(
			// 	SimplexPerlin2D(vec2(worldPos.x + 0.1 * frameTimeCounter, 0.0)) * sin(worldPos.x + 3.0 * frameTimeCounter),
			// 	0.0,
			// 	SimplexPerlin2D(vec2(worldPos.z + 0.1 * frameTimeCounter, 0.0)) * cos(worldPos.z + 3.0 * frameTimeCounter)
			// );

			return glNormal;
		}
		case 10004: { // Double tall plants top
			// float isTop = step(texcoord.y, textureBounds.y);

			// return (isTop * 0.05 + 0.05) * vec3(
			// 	SimplexPerlin2D(vec2(worldPos.x + 0.1 * frameTimeCounter, 0.0)) * sin(worldPos.x + 3.0 * frameTimeCounter),
			// 	0.0,
			// 	SimplexPerlin2D(vec2(worldPos.z + 0.1 * frameTimeCounter, 0.0)) * cos(worldPos.z + 3.0 * frameTimeCounter)
			// );

			return glNormal;
		}
		case 10006: { // Vines
			float facingX = step(0.1, abs(glNormal.x));

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

	return glNormal;
}

// #include "/defines.glsl"
// #include "/functions.glsl"

// uniform ivec2 atlasSize;
// uniform sampler2D normals;

#if POM_Filter == 0
	float sampleHeigth(vec2 texcoord, vec4 texcoordRange, float lod) {
		return 1.0 - textureLod(normals, texcoord, lod).a;
	}
#elif POM_Filter == 1
	// Interpolates height map (bilinear filtering), used for a smooth POM
	float sampleHeigth(vec2 texcoord, vec4 texcoordRange, float lod) {

		float lodFactor = exp2(-floor(lod));
		vec2 pixelCoord = texcoord * atlasSize * lodFactor - 0.5;
		vec4 texelRange = texcoordRange * atlasSize.xyxy * lodFactor - vec4(0.5, 0.5, 0.0, 0.0);
		ivec2 singleTexelSize = ivec2(texelRange.zw - texelRange.xy);

		ivec4 sampleCoords = ivec4(pixelCoord, ceil(pixelCoord));

		sampleCoords.xy -= ivec2(floor((sampleCoords.xy - texelRange.xy) / singleTexelSize) * singleTexelSize);
		sampleCoords.zw -= ivec2(floor((sampleCoords.zw - texelRange.xy) / singleTexelSize) * singleTexelSize);

		float topLeft      = texelFetch(normals, sampleCoords.xy, int(lod)).a;
		float topRight     = texelFetch(normals, sampleCoords.zy, int(lod)).a;
		float bottomLeft   = texelFetch(normals, sampleCoords.xw, int(lod)).a;
		float bottomRight  = texelFetch(normals, sampleCoords.zw, int(lod)).a;

		return 1.0 - mix(mix(topLeft, topRight, fract(pixelCoord.x)), mix(bottomLeft, bottomRight, fract(pixelCoord.x)), fract(pixelCoord.y));
	}
#elif POM_Filter == 2
	// 16 sample Bicubic from Bálint#1673, https://www.shadertoy.com/view/slycDm

	ivec2 wrapCoord(ivec2 iFragCoord, ivec4 bounds) {
		return ((iFragCoord - bounds.xy) % (bounds.zw - bounds.xy + 1)) + bounds.xy;
	}

	vec4 cubicHeight(float x) {
		const float A = -0.75;
		vec4 res = vec4(
			((A * (x + 1.0) - 5.0 * A) * (x + 1.0) + 8.0 * A) * (x + 1.0) - 4.0 * A,
			((A + 2.0) * x - (A + 2.0)) * x * x + 1.0,
			((A + 2.0) * (1.0 - x) - (A + 3.0)) * (1.0 - x) * (1.0 - x) + 1.0,
			0.0
		);
		res.w = 1.0 - res.x - res.y - res.z;
		return res;
	}

	float cubicHeight(float A, float B, float C, float D, float t) {
		float t2 = t*t;
		float t3 = t*t*t;
		float a = -A/2.0 + (3.0*B)/2.0 - (3.0*C)/2.0 + D/2.0;
		float b = A - (5.0*B)/2.0 + 2.0*C - D / 2.0;
		float c = -A/2.0 + C/2.0;
		float d = B;
		
		return a*t3 + b*t2 + c*t + d;
	}

	float sampleHeigth(vec2 texcoord, vec4 bounds, float lod) {
		vec2 texSize = textureSize(normals, int(lod));
		vec2 fragCoord = texcoord * texSize;
		ivec2 iFragCoord = ivec2(fragCoord);
		ivec4 iBounds = ivec4(bounds * texSize.xyxy);
		
		vec2 f = fract(fragCoord);
		
		float vert1 = cubicHeight(
			texelFetch(normals, wrapCoord(iFragCoord + ivec2(-1, -1), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 0, -1), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 1, -1), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 2, -1), iBounds), int(lod)).a,
			f.x
		);
		float vert2 = cubicHeight(
			texelFetch(normals, wrapCoord(iFragCoord + ivec2(-1, 0), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 0, 0), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 1, 0), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 2, 0), iBounds), int(lod)).a,
			f.x
		);
		float vert3 = cubicHeight(
			texelFetch(normals, wrapCoord(iFragCoord + ivec2(-1, 1), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 0, 1), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 1, 1), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 2, 1), iBounds), int(lod)).a,
			f.x
		);
		float vert4 = cubicHeight(
			texelFetch(normals, wrapCoord(iFragCoord + ivec2(-1, 2), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 0, 2), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 1, 2), iBounds), int(lod)).a,
			texelFetch(normals, wrapCoord(iFragCoord + ivec2( 2, 2), iBounds), int(lod)).a,
			f.x
		);
		
		return 1.0 - cubicHeight(
			vert1,
			vert2,
			vert3,
			vert4,
			f.y
		);
	}
#endif

#ifdef POM_SlopeNormals
vec3 parallaxSmoothSlopeNormal(vec2 texcoord, vec4 texcoordRange, float lod) {

	float lodFactor = exp2(-floor(lod));
	vec2 pixelCoord = texcoord * atlasSize * lodFactor - 0.5;
	vec4 texelRange = texcoordRange * atlasSize.xyxy * lodFactor - vec4(0.5, 0.5, 0.0, 0.0);
	ivec2 singleTexelSize = ivec2(texelRange.zw - texelRange.xy);

	ivec4 sampleCoords = ivec4(pixelCoord, ceil(pixelCoord));

	sampleCoords.xy -= ivec2(floor((sampleCoords.xy - texelRange.xy) / singleTexelSize) * singleTexelSize);
	sampleCoords.zw -= ivec2(floor((sampleCoords.zw - texelRange.xy) / singleTexelSize) * singleTexelSize);

	vec2 offset = 1.0 / (singleTexelSize);

	vec3 topLeft      = vec3(0.0,      0.0,      texelFetch(normals, sampleCoords.xy, int(lod)).a * POM_Depth);
	vec3 topRight     = vec3(offset.x, 0.0,      texelFetch(normals, sampleCoords.zy, int(lod)).a * POM_Depth);
	vec3 bottomLeft   = vec3(0.0,      offset.y, texelFetch(normals, sampleCoords.xw, int(lod)).a * POM_Depth);
	vec3 bottomRight  = vec3(offset.x, offset.y, texelFetch(normals, sampleCoords.zw, int(lod)).a * POM_Depth);

	return normalize(cross(bottomRight - topLeft, bottomLeft - topRight));
}

vec2 parallaxSlopeNormal(inout vec2 texcoord, vec2 viewVector, inout float currentLayerDepth, float layerThickness, vec4 texcoordRange, float lod) {
	vec2 nearestEdge = floor(texcoord * atlasSize + (sign(-viewVector) * 0.5 + 0.5)) / atlasSize;
	vec2 viewVecNorm = normalize(viewVector);

	int i = 0;
	while(i < 3) {

		vec2 dists = vec2(length(viewVector / viewVector.x * (nearestEdge.x - texcoord.x)), length(viewVector / viewVector.y * (nearestEdge.y - texcoord.y)));

		if(dists.x < dists.y) {
			texcoord -= dists.x * viewVecNorm;
			vec2 texcoordOffset = -vec2(0.01 / atlasSize.x * viewVecNorm.x, 0.0);
			texcoord -= floor((texcoord + texcoordOffset - texcoordRange.xy) / singleTexSize) * singleTexSize;
			currentLayerDepth -= dists.x / length(viewVector) * layerThickness;
			float heightMapDepth = 1.0 - textureLod(normals, texcoord + texcoordOffset, lod).a;

			if(currentLayerDepth - heightMapDepth > 0.9 * layerThickness) {
				nearestEdge.x -= sign(viewVector.x) / atlasSize.x;
			}
			else {
				texcoord -= texcoordOffset;
				// texcoord -= floor((texcoord - texcoordRange.xy) / singleTexSize) * singleTexSize;
				return vec2(sign(-viewVector.x), 0.0);
			}
		}
		else {
			texcoord -= dists.y * viewVecNorm;
			vec2 texcoordOffset = -vec2(0.0, 0.01 / atlasSize.y * viewVecNorm.y);
			texcoord -= floor((texcoord + texcoordOffset - texcoordRange.xy) / singleTexSize) * singleTexSize;
			currentLayerDepth -= dists.y / length(viewVector) * layerThickness;
			float heightMapDepth = 1.0 - textureLod(normals, texcoord + texcoordOffset, lod).a;

			if(currentLayerDepth - heightMapDepth > 0.9 * layerThickness) {
				nearestEdge.y -= sign(viewVector.y) / atlasSize.y;
			}
			else {
				texcoord -= texcoordOffset;
				// texcoord -= floor((texcoord - texcoordRange.xy) / singleTexSize) * singleTexSize;
				return vec2(0.0, sign(-viewVector.y));
			}
		}
	
		i++;
	}
}
#endif

// Parallax Occlusion Mapping, outputs new texcoord with inout parameter and returns texture-alligned depth into texture after POM
float parallaxMapping(inout vec2 texcoord, vec3 pos, mat3 tbn, vec4 texcoordRange, vec2 texWorldSize, float lod, float layerCount, float fadeAmount, out vec3 shadowTexcoord, out bool onEdge, out vec2 norm) {

	 vec3 texDir = normalize(pos) * tbn;

	// Calculate texture space vectors and deltas used in loop
	float layerDepth    = 1.0 / layerCount;
	vec2  viewVector    = (-texDir.xy / texDir.z) / texWorldSize * 0.25 * POM_Depth * singleTexSize * fadeAmount;
	vec2  deltaTexcoord = viewVector / layerCount;

	// Set up depth varialbes and read initial height map value
	float currentLayerDepth = 0.0;
	float lastDepthMapValue = 0.0;

	float currentDepthMapValue = sampleHeigth(texcoord, texcoordRange, lod);
	
	// loop until the view vector hits the height map
	for(int i = 0; i < layerCount; i++) {

		if(currentLayerDepth >= currentDepthMapValue || currentDepthMapValue < 0.5/255.0)
			break;

		// shift texture coordinates along direction of view vector
		texcoord += deltaTexcoord;
		texcoord -= floor((texcoord - texcoordRange.xy) / singleTexSize) * singleTexSize;

		// get depthmap value at current texture coordinates
		currentLayerDepth += layerDepth;
		lastDepthMapValue  = currentDepthMapValue;

		currentDepthMapValue = sampleHeigth(texcoord, texcoordRange, lod);
	}

	// Linear Interpolation between last 2 layers
	#if POM_Filter > 0
		onEdge = false;

		vec2 prevTexcoord = texcoord - deltaTexcoord;

		float beforeDepth = lastDepthMapValue    - currentLayerDepth + layerDepth;
		float afterDepth  = currentDepthMapValue - currentLayerDepth;
		float weight      = afterDepth / (afterDepth - beforeDepth);

		texcoord  = mix(texcoord, prevTexcoord, weight);
		texcoord -= floor((texcoord - texcoordRange.xy) / singleTexSize) * singleTexSize;

		float depth = mix(currentDepthMapValue, lastDepthMapValue, weight);

		shadowTexcoord = vec3(texcoord, depth);

		// Return texture alligned depth difference after POM
		return depth * 0.25 * POM_Depth * fadeAmount;
	#else
		onEdge = currentLayerDepth - currentDepthMapValue > layerDepth;

		#ifdef POM_SlopeNormals
		if(onEdge)
			norm = parallaxSlopeNormal(texcoord, viewVector, currentLayerDepth, layerDepth, texcoordRange, lod) * float(onEdge);
		#endif

		shadowTexcoord = vec3(texcoord, currentLayerDepth) /* - vec3(deltaTexcoord, layerDepth) */;
		return currentLayerDepth * 0.25 * POM_Depth * fadeAmount;
	#endif
}

float parallaxShadows(vec3 shadowTexcoord, mat3 tbn, vec4 texcoordRange, vec2 texWorldSize, float lod, float layerCount, float fadeAmount, vec2 norm) {

	vec3 texLightDir = normalize(lightDir) * tbn;

	// Calculate texture space vectors and deltas used in loop
	float layerDepth = 1.0 / layerCount;
	vec2 viewVector = (texLightDir.xy / texLightDir.z) / texWorldSize * 0.25 * POM_Depth * singleTexSize * fadeAmount;
	vec2 deltaTexcoord = viewVector / layerCount;

	#ifdef POM_SlopeNormals
	if(dot(normalize(viewVector.xy), norm) < 0.0)
		return 0.0;
	#endif

	// Set up depth varialbes and read initial height map value
	float currentLayerDepth = shadowTexcoord.z;
	vec2 texcoord = shadowTexcoord.xy;
	
	float currentDepthMapValue = sampleHeigth(texcoord, texcoordRange, lod);
	float lastDepthMapValue = currentDepthMapValue;

	bool onSurface = (currentLayerDepth - currentDepthMapValue) < layerDepth;


	// loop until the view vector hits the surface of the block
	for(int i = 0; i < layerCount; i++) {

		if(currentLayerDepth <= 0.0)
			break;
	// while(currentLayerDepth > 0.0) {

		// shift texture coordinates along direction of view vector
		texcoord += deltaTexcoord;
		currentLayerDepth -= layerDepth;

		// wrap texture coordinates if they extend out of range
		texcoord -= floor((texcoord - texcoordRange.xy) / singleTexSize) * singleTexSize;

		// get depthmap value at current texture coordinates
		lastDepthMapValue = currentDepthMapValue;
		currentDepthMapValue = sampleHeigth(texcoord, texcoordRange, lod);

		// onSurface = (currentLayerDepth - currentDepthMapValue) < layerDepth;

		// #ifdef POM_Smooth
		//     float beforeDepth = lastDepthMapValue - currentLayerDepth + layerDepth;
		//     float afterDepth = currentDepthMapValue - currentLayerDepth;

		//     float weight = afterDepth / (afterDepth - beforeDepth);
		//     float smoothDepth = mix(lastDepthMapValue, currentDepthMapValue, weight);

		//     if(smoothDepth >= currentDepthMapValue)
		//         return 0.0;
		// #else
			if(/* onSurface &&  */ /* ivec2(texcoord * atlasSize) != initialTexel && */ currentLayerDepth >= currentDepthMapValue)
				return 0.0;
		// #endif
	}

	return 1.0;
}

// calculates POM and calculates and returns new screen space depth, to be stored in gl_FragDepth
float parallaxDepthOffset(inout vec2 texcoord, vec3 pos, mat3 tbn, vec4 texcoordRange, vec2 texWorldSize, float lod, float fadeAmount, out vec2 norm) {
	// Calculates POM and stores texture alligned depth from POM
	vec3 shadowTexcoord = vec3(-1.0);
	bool onEdge = false;
	float zOffset = parallaxMapping(texcoord, pos, tbn, texcoordRange, texWorldSize, lod, POM_Layers, fadeAmount, shadowTexcoord, onEdge, norm);

	// Calculate new screen screenspace position from original view space position and POM depth difference
	vec3 texDir = normalize(pos) * tbn;
	vec3 tbnDiff = tbn * ((texDir / texDir.z) * zOffset);

	#ifdef shadowGbuffer
		// vec3 shadowViewPos = (shadowModelView * vec4(pos - tbnDiff, 1.0)).xyz;
		// vec4 clipPos = gl_ProjectionMatrix * vec4(shadowViewPos, 1.0);
		// clipPos.z *= 0.5;

		// testOut = vec4(vec3(zOffset), 1.0);

		vec4 clipPos = gl_ProjectionMatrix * vec4(pos - tbnDiff, 1.0);
		clipPos.z *= 0.5;
	#else
		vec4 clipPos = gl_ModelViewProjectionMatrix * vec4(pos - tbnDiff, 1.0);
	#endif

	// #ifdef shadowGbuffer
	// 	clipPos.z *= 0.5;
	// #endif

	// Return screenspace z position, which is to be stored in gl_FragDepth
	vec3 screenPos = clipPos.xyz / clipPos.w * 0.5 + 0.5;
	return screenPos.z;
}


// calculates POM and calculates and returns new screen space depth, to be stored in gl_FragDepth
float parallaxShadowDepthOffset(inout vec2 texcoord, vec3 pos, out float shadow, mat3 tbn, vec4 texcoordRange, vec2 texWorldSize, float lod, float fadeAmount, out bool onEdge, out vec2 norm) {
	// #ifdef debugOut
	// 	velocityOut = vec4(interpolateHeight(texcoord, texcoordRange, lod), 0.0, 0.0, 1.0);
	// #endif
	
	// Calculates POM and stores texture alligned depth from POM
	vec3 shadowTexcoord = vec3(-1.0);
	onEdge = false;
	float zOffset = parallaxMapping(texcoord, pos, tbn, texcoordRange, texWorldSize, lod, POM_Layers, fadeAmount, shadowTexcoord, onEdge, norm);

	// Calculate shadow
	shadow = parallaxShadows(shadowTexcoord, tbn, texcoordRange, texWorldSize, lod, POM_Shadow_Layers, fadeAmount, norm);
	// shadow = parallaxShadows(texcoord, zOffset, tbn, texcoordRange, texWorldSize, lod, POM_Shadow_Layers);

	// Calculate new screen screenspace position from original view space position and POM depth difference
	vec3 texDir = normalize(pos) * tbn;
	vec3 tbnDiff = tbn * ((texDir / texDir.z) * zOffset);
	#ifdef shadowGbuffer
		vec3 shadowViewPos = (shadowModelView * vec4(pos - tbnDiff, 1.0)).xyz;
		vec4 clipPos = shadowProjection * vec4(shadowViewPos, 1.0);
		clipPos.z *= 0.5;
	#else
		vec4 clipPos = gl_ModelViewProjectionMatrix * vec4(pos - tbnDiff, 1.0);
	#endif

	// Return screenspace z position, which is to be stored in gl_FragDepth
	vec3 screenPos = clipPos.xyz / clipPos.w * 0.5 + 0.5;
	return screenPos.z;
}
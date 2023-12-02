#ifndef PARALLAX
#define PARALLAX

// #include "/defines.glsl"

// uniform ivec2     atlasSize;
// uniform sampler2D normals;
// uniform vec3 lightDir;

#if POM_Filter == 0
	float sampleHeigth(vec2 texcoord, vec4 texcoordRange, mat2 dFdXY) {
		float sampleHeight = textureGrad(normals, texcoord, dFdXY[0], dFdXY[1]).a;
		return (sampleHeight > 0.0) ? (1.0 - sampleHeight) : (0.0);
	}
#elif POM_Filter == 1
	// Interpolates height map (bilinear filtering), used for a smooth POM
	float sampleHeigth(vec2 texcoord, vec4 texcoordRange, mat2 dFdXY) {

		float lod = 0;

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

	float sampleHeigth(vec2 texcoord, vec4 bounds, mat2 dFdXY) {
		float lod = 0

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
vec3 parallaxSmoothSlopeNormal(vec2 texcoord, vec4 texcoordRange) {

	float lod = 0;

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

// Calculates the edge of the POM of the current texcoord, and returns the tangent space xy normal
vec2 parallaxSlopeNormal(inout vec2 texcoord, vec2 traceVector, inout float currentLayerDepth, out vec3 tangentPos, float layerThickness, vec4 texcoordRange) {

	float lod = 0;
	
	vec2  texSize = texcoordRange.zw - texcoordRange.xy;
	float lodFactor = exp2(-floor(lod));
	vec2  atlasSizeLod = atlasSize * lodFactor;
	vec2  texelSizeLod = 1.0 / atlasSizeLod;

	vec2 traceVecNorm = normalize(traceVector);

	vec2 currentTexel = (floor(texcoord * atlasSizeLod) + 0.5) * texelSizeLod;
	vec2 prevTexel = currentTexel;

	
	// Calculates the texcoord for the corner (x and y edges) nearest to the current texcoord along the path of the trace vector
	vec2 nearestEdge = floor(texcoord * atlasSizeLod + (sign(-traceVector) * 0.5 + 0.5)) / atlasSizeLod;

	// Perform up to 3 DDA raytraces to find correct edge
	int i = 0;
	while(i < 3) {
		
		// Calculate the distance to each edge along the path of the trace vector
		vec2 dists = vec2(length(traceVector / traceVector.x * (nearestEdge.x - texcoord.x)), length(traceVector / traceVector.y * (nearestEdge.y - texcoord.y)));

		// Hit the edge of a texel on the x axis
		if(dists.x < dists.y) {
			// move texcoord to edge along trace vector
			texcoord -= dists.x * traceVecNorm;
			currentLayerDepth -= dists.x / length(traceVector) * layerThickness;

			prevTexel = currentTexel;
			currentTexel.x -= sign(traceVecNorm.x) * texelSizeLod.x;
			currentTexel.x -= floor((currentTexel.x - texcoordRange.x) / texSize.x) * texSize.x;
			float heightMapDepth = 1.0 - textureLod(normals, currentTexel, lod).a;

			if(currentLayerDepth - heightMapDepth < 0.95 * layerThickness) {
				// texcoord += 0.02 * traceVecNorm * texelSizeLod;
				// texcoord -= floor((texcoord - texcoordRange.xy) / texSize) * texSize;
				
				tangentPos = vec3(texcoord, currentLayerDepth);
				texcoord = prevTexel;
				return vec2(sign(-traceVector.x), 0.0);
			}
			else {
				nearestEdge.x -= sign(traceVector.x) * texelSizeLod.x;
			}
		}

		// Hit the edge of a texel on the y axis
		else {
			// move texcoord to edge along trace vector
			texcoord -= dists.y * traceVecNorm;
			currentLayerDepth -= dists.y / length(traceVector) * layerThickness;

			prevTexel = currentTexel;
			currentTexel.y -= sign(traceVecNorm.y) * texelSizeLod.y;
			currentTexel.y -= floor((currentTexel.y - texcoordRange.y) / texSize.y) * texSize.y;
			float heightMapDepth = 1.0 - textureLod(normals, currentTexel, lod).a;

			if(currentLayerDepth - heightMapDepth < 0.95 * layerThickness) {
				// texcoord += 0.02 * traceVecNorm * texelSizeLod;
				// texcoord -= floor((texcoord - texcoordRange.xy) / texSize) * texSize;
				
				tangentPos = vec3(texcoord, currentLayerDepth);
				texcoord = prevTexel;
				return vec2(0.0, sign(-traceVector.y));
			}
			else {
				nearestEdge.y -= sign(traceVector.y) * texelSizeLod.y;
			}
		}
	
		i++;
	}
}
#endif

// Parallax Occlusion Mapping, outputs new texcoord with inout parameter and returns texture-alligned depth into texture after POM
float parallaxMapping(inout vec2 texcoord, vec3 pos, mat3 tbn, vec4 texcoordRange, vec2 texWorldSize, mat2 dFdXY, float layerCount, float fadeAmount, out vec3 tangentPos, out bool onEdge, out vec2 norm) {

	vec2 texSize = texcoordRange.zw - texcoordRange.xy;

	vec3 texDir = normalize(pos) * tbn;

	// Calculate texture space vectors and deltas used in loop
	float layerDepth    = 1.0 / layerCount;
	vec2  traceVector    = (-texDir.xy / texDir.z) / texWorldSize * 0.25 * POM_Depth * texSize * fadeAmount;
	vec2  deltaTexcoord = traceVector / layerCount;

	// Set up depth varialbes and read initial height map value
	float currentLayerDepth = 0.0;
	float lastDepthMapValue = 0.0;

	float currentDepthMapValue = sampleHeigth(texcoord, texcoordRange, dFdXY);
	
	// loop until the view vector hits the height map
	for(int i = 0; i < layerCount; i++) {

		if(currentLayerDepth >= currentDepthMapValue || currentDepthMapValue < 0.5/255.0)
			break;

		// shift texture coordinates along direction of view vector
		texcoord += deltaTexcoord;
		texcoord -= floor((texcoord - texcoordRange.xy) / texSize) * texSize;

		// get depthmap value at current texture coordinates
		currentLayerDepth += layerDepth;
		lastDepthMapValue  = currentDepthMapValue;

		currentDepthMapValue = sampleHeigth(texcoord, texcoordRange, dFdXY);
	}

	// Linear Interpolation between last 2 layers
	#if POM_Filter > 0
		onEdge = false;

		vec2 prevTexcoord = texcoord - deltaTexcoord;

		float beforeDepth = lastDepthMapValue    - currentLayerDepth + layerDepth;
		float afterDepth  = currentDepthMapValue - currentLayerDepth;
		float weight      = afterDepth / (afterDepth - beforeDepth);

		texcoord  = mix(texcoord, prevTexcoord, weight);
		texcoord -= floor((texcoord - texcoordRange.xy) / texSize) * texSize;

		float depth = mix(currentDepthMapValue, lastDepthMapValue, weight);

		tangentPos = vec3(texcoord, depth);

		// Return texture alligned depth difference after POM
		return depth * 0.25 * POM_Depth * fadeAmount;
	#else
		onEdge = currentLayerDepth - currentDepthMapValue >= layerDepth;

		tangentPos = vec3(texcoord, currentLayerDepth) /* - vec3(deltaTexcoord, layerDepth) */;

		#ifdef POM_SlopeNormals
		if(onEdge)
			norm = parallaxSlopeNormal(texcoord, traceVector, currentLayerDepth, tangentPos, layerDepth, texcoordRange) * float(onEdge);
		#endif

		// #ifdef debugOut
		// 	testOut = vec4((texcoord - texcoordRange.xy) / texSize, 0.0, 1.0);
		// 	// testOut = vec4(vec3(onEdge), 1.0);
		// #endif

		return currentLayerDepth * 0.25 * POM_Depth * fadeAmount;
	#endif
}

float parallaxShadows(vec3 shadowTexcoord, mat3 tbn, vec3 lightDir, vec4 texcoordRange, vec2 texWorldSize, mat2 dFdXY, float layerCount, float fadeAmount, vec2 norm) {

	vec2 texSize = texcoordRange.zw - texcoordRange.xy;

	vec3 texLightDir = normalize(lightDir) * tbn;

	// Calculate texture space vectors and deltas used in loop
	float layerDepth = 1.0 / layerCount;
	vec2 traceVector = (texLightDir.xy / texLightDir.z) / texWorldSize * 0.25 * POM_Depth * texSize * fadeAmount;
	vec2 deltaTexcoord = traceVector / layerCount;

	#ifdef POM_SlopeNormals
	if(dot(normalize(traceVector.xy), norm) < 0.0)
		return 0.0;
	#endif

	// Set up depth varialbes and read initial height map value
	float currentLayerDepth = shadowTexcoord.z;
	vec2 texcoord = shadowTexcoord.xy;
	
	float currentDepthMapValue = sampleHeigth(texcoord, texcoordRange, dFdXY);
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
		texcoord -= floor((texcoord - texcoordRange.xy) / texSize) * texSize;

		// get depthmap value at current texture coordinates
		lastDepthMapValue = currentDepthMapValue;
		currentDepthMapValue = sampleHeigth(texcoord, texcoordRange, dFdXY);

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
float parallaxDepthOffset(inout vec2 texcoord, vec3 pos, mat3 tbn, vec4 texcoordRange, vec2 texWorldSize, mat2 dFdXY, float fadeAmount, out vec2 norm) {
	// Calculates POM and stores texture alligned depth from POM
	vec3 shadowTexcoord = vec3(-1.0);
	bool onEdge = false;
	float zOffset = parallaxMapping(texcoord, pos, tbn, texcoordRange, texWorldSize, dFdXY, POM_Layers, fadeAmount, shadowTexcoord, onEdge, norm);

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
float parallaxShadowDepthOffset(inout vec2 texcoord, vec3 pos, vec3 lightDir, out float shadow, mat3 tbn, vec4 texcoordRange, vec2 texWorldSize, mat2 dFdXY, float fadeAmount, out bool onEdge, out vec2 norm) {
	
	// Calculates POM and stores texture alligned depth from POM
	vec3 shadowTexcoord = vec3(-1.0);
	onEdge = false;
	float zOffset = parallaxMapping(texcoord, pos, tbn, texcoordRange, texWorldSize, dFdXY, POM_Layers, fadeAmount, shadowTexcoord, onEdge, norm);

	// Calculate shadow
	shadow = parallaxShadows(shadowTexcoord, tbn, lightDir, texcoordRange, texWorldSize, dFdXY, POM_Shadow_Layers, fadeAmount, norm);
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

#endif
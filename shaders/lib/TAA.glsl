#ifndef TAAGLSL
#define TAAGLSL

#define TAA_NEIGHBORHOOD_SIZE 1

const vec2 TAAOffsets[16] = vec2[] (
    vec2(0.500000, 0.333333),
    vec2(0.250000, 0.666667),
    vec2(0.750000, 0.111111),
    vec2(0.125000, 0.444444),
    vec2(0.625000, 0.777778),
    vec2(0.375000, 0.222222),
    vec2(0.875000, 0.555556),
    vec2(0.062500, 0.888889),
    vec2(0.562500, 0.037037),
    vec2(0.312500, 0.370370),
    vec2(0.812500, 0.703704),
    vec2(0.187500, 0.148148),
    vec2(0.687500, 0.481481),
    vec2(0.437500, 0.814815),
    vec2(0.937500, 0.259259),
    vec2(0.031250, 0.592593)
);

/*
    AABB Clipping from "Temporal Reprojection Anti-Aliasing in INSIDE"
    http://s3.amazonaws.com/arena-attachments/655504/c5c71c5507f0f8bf344252958254fb7d.pdf?1468341463
*/

vec2 taaOffset(int frameCounter, vec2 screenSize) {
	// if(cameraMoved)
	// 	return vec2(0.0);
	
	int taaIndex = frameCounter % 16;
	return vec2((TAAOffsets[taaIndex] * 2.0 - 1.0) / screenSize);
}

#ifdef taaFragment
#define reprojectFunc

    vec3 YCoCg2RGB(vec3 YCoCg) {
        YCoCg.gb -= 0.5;
        return mat3(1.0, 1.0, -1.0, 1.0, 0.0, 1.0, 1.0, -1.0, -1.0) * YCoCg;
    }

    vec3 RGB2YCoCg(vec3 rgb) {
        return mat3(0.25, 0.5, 0.25, 0.5, 0.0, -0.5, -0.25, 0.5, -0.25) * rgb + vec3(0.0, 0.5, 0.5);
    }

    vec3 clipAABB(vec3 prevColor, vec3 minColor, vec3 maxColor) {
        vec3 pClip = 0.5 * (maxColor + minColor); // Center
        vec3 eClip = 0.5 * (maxColor - minColor); // Size

        vec3 vClip  = prevColor - pClip;
        vec3 aUnit  = abs(vClip / eClip);
        float denom = max(aUnit.x, max(aUnit.y, aUnit.z));

        return denom > 1.0 ? pClip + vClip / denom : prevColor;
    }

    vec3 neighbourhoodClipping(sampler2D currTex, vec3 prevColor) {
        vec3 minColor = vec3(1e5), maxColor = vec3(-1e5);

        for(int x = -TAA_NEIGHBORHOOD_SIZE; x <= TAA_NEIGHBORHOOD_SIZE; x++) {
            for(int y = -TAA_NEIGHBORHOOD_SIZE; y <= TAA_NEIGHBORHOOD_SIZE; y++) {
                vec3 color = texelFetch(currTex, ivec2(gl_FragCoord.xy) + ivec2(x, y), 0).rgb;
                minColor = min(minColor, color); maxColor = max(maxColor, color); 
            }
        }
        return clipAABB(prevColor, minColor, maxColor);
    }

    uniform mat4 gbufferPreviousProjection;
    uniform mat4 gbufferPreviousModelView;
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 gbufferModelViewInverse;
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;
    // Fast screen reprojection by Eldeston#3590 with reference from Chocapic13 and Jessie#7257
    // Source: https://discord.com/channels/237199950235041794/525510804494221312/955506913834070016
    vec2 reprojectScreenPos(vec2 currScreenPos, float depth){
        vec3 currViewPos = vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * (currScreenPos.xy * 2.0 - 1.0) + gbufferProjectionInverse[3].xy, gbufferProjectionInverse[3].z);
        currViewPos /= (gbufferProjectionInverse[2].w * (depth * 2.0 - 1.0) + gbufferProjectionInverse[3].w);
        vec3 currFeetPlayerPos = mat3(gbufferModelViewInverse) * currViewPos + gbufferModelViewInverse[3].xyz;

        vec3 prevFeetPlayerPos = depth > 0.56 ? currFeetPlayerPos + cameraPosition - previousCameraPosition : currFeetPlayerPos;
        vec3 prevViewPos = mat3(gbufferPreviousModelView) * prevFeetPlayerPos + gbufferPreviousModelView[3].xyz;
        vec2 finalPos = vec2(gbufferPreviousProjection[0].x, gbufferPreviousProjection[1].y) * prevViewPos.xy + gbufferPreviousProjection[3].xy;
        return (finalPos / -prevViewPos.z) * 0.5 + 0.5;
    }

    void applyTAA(inout vec4 colorOut, out vec4 historyColor, vec2 texcoord, float depth, sampler2D colorBuffer, sampler2D historyBuffer) {
        // vec2 velocity = texture2D(velocityBuffer, texcoord).xy;
        // vec2 velocity = vec2(0);
        vec2 historPos = reprojectScreenPos(texcoord, depth);
        
        historyColor = texture2D(historyBuffer, historPos);
        // historyColor.rgb = colorOut.rgb;
        // colorOut.rgb = texture2D(historyBuffer, texcoord - velocity).rgb;

        if(any(isnan(historyColor)))
            historyColor = vec4(0.0);

        // vec2 pixel = 1.0 / vec2(viewWidth, viewHeight);
        // vec3 nearColor0 = texture2D(colortex0, texcoord + vec2(pixel.x, 0.0)).rgb;
        // vec3 nearColor1 = texture2D(colortex0, texcoord + vec2(0.0, pixel.y)).rgb;
        // vec3 nearColor2 = texture2D(colortex0, texcoord - vec2(pixel.x, 0.0)).rgb;
        // vec3 nearColor3 = texture2D(colortex0, texcoord - vec2(0.0, pixel.y)).rgb;

        // vec3 boxMin = min(albedo.rgb, min(nearColor0, min(nearColor1, min(nearColor2, nearColor3))));
        // vec3 boxMax = max(albedo.rgb, max(nearColor0, max(nearColor1, max(nearColor2, nearColor3))));

        // history.rgb = clamp(history.rgb, boxMin.rgb, boxMax);

        historyColor.rgb = neighbourhoodClipping(colorBuffer, historyColor.rgb);

        if(clamp(historPos, 0.0, 1.0) != historPos || historyColor.a < 0.1) {
            historyColor.a = 0.5;
            // colorOut.rgb = vec3(0.0, 0.0, 1.0);
        }
        else /* if(clamp(texcoord - velocity, 0.0, 1.0) == texcoord - velocity) */ {
            // albedo.rgb = mix(albedo.rgb, history, 0.9);
            // albedo.rgb = mix(albedo.rgb, history, frameCount / (frameCount + 1));

            float currentFrame = (historyColor.a == 0) ? 1.0 : (1.0 / (1.0/historyColor.a - 1.0) + 1.0);
            float currentBlend = currentFrame / (currentFrame+1.0);

            colorOut.rgb = mix(colorOut.rgb, historyColor.rgb, currentBlend);
            historyColor.a = currentBlend;
        }
        // else {
        // 	historyOut.a = 0.0;
        // }
        // if(clamp(history.rgb, boxMin.rgb, boxMax) != history.rgb) {
        // 	historyOut.a = 0.0;
        // }


        // albedo.rgb = neighbourhoodClipping(colortex0, history);

        // albedo.rgb = vec3(frameCount != 0);

        // frameCountOut = frameCount + 1;
        historyColor.rgb = colorOut.rgb;
    }

#endif
#endif
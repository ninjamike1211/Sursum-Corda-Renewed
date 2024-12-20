#ifndef BLOOM_GLSL
#define BLOOM_GLSL


// Bloom by Alexander Christensen
// https://learnopengl.com/Guest-Articles/2022/Phys.-Based-Bloom
vec3 bloomDownscale(vec2 texcoord, sampler2D bloomSampler, vec2 viewSize, vec4 bounds) {
    vec2 srcTexelSize = 1.0 / viewSize;
    float x = srcTexelSize.x;
    float y = srcTexelSize.y;

    // Take 13 samples around current texel:
    // a - b - c
    // - j - k -
    // d - e - f
    // - l - m -
    // g - h - i
    // === ('e' is the current texel) ===
    vec3 a = texture(bloomSampler, clamp(vec2(texcoord.x - 2*x, texcoord.y + 2*y), bounds.xy, bounds.zw)).rgb;
    vec3 b = texture(bloomSampler, clamp(vec2(texcoord.x,       texcoord.y + 2*y), bounds.xy, bounds.zw)).rgb;
    vec3 c = texture(bloomSampler, clamp(vec2(texcoord.x + 2*x, texcoord.y + 2*y), bounds.xy, bounds.zw)).rgb;

    vec3 d = texture(bloomSampler, clamp(vec2(texcoord.x - 2*x, texcoord.y), bounds.xy, bounds.zw)).rgb;
    vec3 e = texture(bloomSampler, clamp(vec2(texcoord.x,       texcoord.y), bounds.xy, bounds.zw)).rgb;
    vec3 f = texture(bloomSampler, clamp(vec2(texcoord.x + 2*x, texcoord.y), bounds.xy, bounds.zw)).rgb;

    vec3 g = texture(bloomSampler, clamp(vec2(texcoord.x - 2*x, texcoord.y - 2*y), bounds.xy, bounds.zw)).rgb;
    vec3 h = texture(bloomSampler, clamp(vec2(texcoord.x,       texcoord.y - 2*y), bounds.xy, bounds.zw)).rgb;
    vec3 i = texture(bloomSampler, clamp(vec2(texcoord.x + 2*x, texcoord.y - 2*y), bounds.xy, bounds.zw)).rgb;

    vec3 j = texture(bloomSampler, clamp(vec2(texcoord.x - x, texcoord.y + y), bounds.xy, bounds.zw)).rgb;
    vec3 k = texture(bloomSampler, clamp(vec2(texcoord.x + x, texcoord.y + y), bounds.xy, bounds.zw)).rgb;
    vec3 l = texture(bloomSampler, clamp(vec2(texcoord.x - x, texcoord.y - y), bounds.xy, bounds.zw)).rgb;
    vec3 m = texture(bloomSampler, clamp(vec2(texcoord.x + x, texcoord.y - y), bounds.xy, bounds.zw)).rgb;

    // Apply weighted distribution:
    // 0.5 + 0.125 + 0.125 + 0.125 + 0.125 = 1
    // a,b,d,e * 0.125
    // b,c,e,f * 0.125
    // d,e,g,h * 0.125
    // e,f,h,i * 0.125
    // j,k,l,m * 0.5
    // This shows 5 square areas that are being sampled. But some of them overlap,
    // so to have an energy preserving downsample we need to make some adjustments.
    // The weights are the distributed, so that the sum of j,k,l,m (e.g.)
    // contribute 0.5 to the final color output. The code below is written
    // to effectively yield this sum. We get:
    // 0.125*5 + 0.03125*4 + 0.0625*4 = 1
    vec3 downsample = e*0.125;
    downsample += (a+c+g+i)*0.03125;
    downsample += (b+d+f+h)*0.0625;
    downsample += (j+k+l+m)*0.125;

    return downsample;
}

vec3 bloomUpscale(vec2 texcoord, sampler2D bloomSampler, vec2 viewSize, vec4 bounds) {
    // The filter kernel is applied with a radius, specified in texture
    // coordinates, so that the radius will vary across mip resolutions.
    vec2 srcTexelSize = 1.0 / viewSize;
    float x = srcTexelSize.x;
    float y = srcTexelSize.y;

    bounds.xy += 0.5 * srcTexelSize;
    bounds.zw -= 0.5 * srcTexelSize;

    // Take 9 samples around current texel:
    // a - b - c
    // d - e - f
    // g - h - i
    // === ('e' is the current texel) ===
    vec3 a = texture(bloomSampler, clamp(vec2(texcoord.x - x, texcoord.y + y), bounds.xy, bounds.zw)).rgb;
    vec3 b = texture(bloomSampler, clamp(vec2(texcoord.x,     texcoord.y + y), bounds.xy, bounds.zw)).rgb;
    vec3 c = texture(bloomSampler, clamp(vec2(texcoord.x + x, texcoord.y + y), bounds.xy, bounds.zw)).rgb;

    vec3 d = texture(bloomSampler, clamp(vec2(texcoord.x - x, texcoord.y), bounds.xy, bounds.zw)).rgb;
    vec3 e = texture(bloomSampler, clamp(vec2(texcoord.x,     texcoord.y), bounds.xy, bounds.zw)).rgb;
    vec3 f = texture(bloomSampler, clamp(vec2(texcoord.x + x, texcoord.y), bounds.xy, bounds.zw)).rgb;

    vec3 g = texture(bloomSampler, clamp(vec2(texcoord.x - x, texcoord.y - y), bounds.xy, bounds.zw)).rgb;
    vec3 h = texture(bloomSampler, clamp(vec2(texcoord.x,     texcoord.y - y), bounds.xy, bounds.zw)).rgb;
    vec3 i = texture(bloomSampler, clamp(vec2(texcoord.x + x, texcoord.y - y), bounds.xy, bounds.zw)).rgb;

    // Apply weighted distribution, by using a 3x3 tent filter:
    //  1   | 1 2 1 |
    // -- * | 2 4 2 |
    // 16   | 1 2 1 |
    vec3 upsample = e*4.0;
    upsample += (b+d+f+h)*2.0;
    upsample += (a+c+g+i);
    upsample *= 1.0 / 16.0;

    return upsample;
}

#ifdef VERTEX

    out vec2 texcoord;

    const vec2 scaleFactor = vec2(2.0, 1.0) / exp2(BLOOM_TILE-1);
    const vec2 shiftFactor = vec2(-1.0, -1.0 + (exp2(BLOOM_TILE-1)-1) / exp2(BLOOM_TILE-2));

    void main() {
        gl_Position = vec4(scaleFactor * gl_Vertex.xy + shiftFactor, 0.0, 1.0);
        texcoord = gl_Vertex.xy;
    }
    
#else
#ifdef FRAGMENT

    #include "/lib/defines.glsl"

    #if defined BLOOM_DOWNSCALE && BLOOM_TILE == 1
        #define BLOOM_SAMPLER colortex0
    #else
        #define BLOOM_SAMPLER colortex11
    #endif

    uniform sampler2D BLOOM_SAMPLER;

    uniform float viewWidth;
    uniform float viewHeight;

    in vec2 texcoord;

    /* RENDERTARGETS: 11 */
    layout(location = 0) out vec4 colorOut;

    void main() {
        #ifdef BLOOM_DOWNSCALE
            const vec2 coordScale  = vec2(min(exp2(-BLOOM_TILE+2), 1.0), exp2(-BLOOM_TILE+1));
            const vec2 coordShift  = vec2(0.0, max((exp2(BLOOM_TILE-2)-1) / exp2(BLOOM_TILE-2), 0.0));
            const vec4 coordBounds = vec4(coordShift, coordScale + coordShift);
            const float widthMult = (BLOOM_TILE == 1) ? 1.0 : 0.5;

            colorOut = vec4(bloomDownscale(coordScale * texcoord + coordShift, BLOOM_SAMPLER, vec2(widthMult*viewWidth, viewHeight), coordBounds), 1.0);
            
        #else
        #ifdef BLOOM_UPSCALE
            const vec2 coordScale  = vec2(exp2(-BLOOM_TILE), exp2(-BLOOM_TILE-1));
            const vec2 coordShift  = vec2(0.0, (exp2(BLOOM_TILE)-1) / exp2(BLOOM_TILE));
            const vec4 coordBounds = vec4(coordShift, coordScale + coordShift);
            
            colorOut = vec4(bloomUpscale(coordScale * texcoord + coordShift, BLOOM_SAMPLER, vec2(0.5*viewWidth, viewHeight), coordBounds), 1.0);

        #endif
        #endif
    }


#endif
#endif

#endif